#' @title Firebase Cloud Storage Service
#' @description Functions for file storage operations with Firebase/Google Cloud Storage
#' @name firebase_storage
NULL

#' Upload File to Storage
#'
#' Uploads a file to Firebase Cloud Storage.
#'
#' @param conn Firebase connection object
#' @param file_path Local path to the file to upload
#' @param object_name Name/path for the object in storage (e.g., "images/photo.jpg")
#' @param content_type MIME type (auto-detected if NULL)
#' @param predefined_acl Access control ("publicRead", "private", etc.)
#' @param client_id OAuth client ID (for user auth)
#' @param client_secret OAuth client secret (for user auth)
#' @return Storage object metadata including URL
#' @export
#' @examples
#' \dontrun{
#' conn <- firebase_connect(project_id = "my-project", storage_bucket = "my-bucket")
#'
#' # Upload with service account
#' result <- storage_upload(conn, "local/photo.jpg", "images/photo.jpg")
#'
#' # Get the public URL
#' print(result$url)
#' }
storage_upload <- function(conn,
                           file_path,
                           object_name,
                           content_type = NULL,
                           predefined_acl = "publicRead",
                           client_id = NULL,
                           client_secret = NULL) {
  # Validate connection and file
  if (!is_firebase_connection(conn)) {
    stop_firebase("validation", "Expected a firebase_connection object")
  }

  if (is.null(conn$storage_bucket)) {
    stop_firebase("validation", "Storage bucket not configured in connection")
  }

  if (!is.null(file_path) && !file.exists(file_path)) {
    stop_firebase("validation", paste("File not found:", file_path))
  }

  # Get OAuth token for storage
  token <- get_storage_token(conn, client_id, client_secret)

  # Build upload URL
  upload_url <- paste0(
    "https://www.googleapis.com/upload/storage/v1/b/",
    conn$storage_bucket,
    "/o?uploadType=media&name=",
    utils::URLencode(object_name, reserved = TRUE),
    "&predefinedAcl=",
    predefined_acl
  )

  # Prepare headers
  headers <- list(Authorization = paste("Bearer", token))

  # Upload file or create folder
  if (is.null(file_path)) {
    # Create empty object (folder marker)
    response <- httr::POST(
      url = upload_url,
      httr::add_headers(.headers = unlist(headers))
    )
  } else {
    # Upload file
    response <- httr::POST(
      url = upload_url,
      body = httr::upload_file(file_path),
      httr::add_headers(.headers = unlist(headers))
    )
  }

  if (httr::http_error(response)) {
    stop(parse_firebase_error(response))
  }

  # Parse response and add convenience URL
  data <- httr::content(response)
  data$url <- paste("https://storage.cloud.google.com", conn$storage_bucket, object_name, sep = "/")

  data
}

#' Download File from Storage
#'
#' Downloads a file from Firebase Cloud Storage.
#'
#' @param conn Firebase connection object
#' @param object_name Name/path of the object in storage
#' @param dest_file Local destination path (if NULL, returns content)
#' @param client_id OAuth client ID
#' @param client_secret OAuth client secret
#' @return If dest_file is NULL, returns file content; otherwise returns dest_file path
#' @export
#' @examples
#' \dontrun{
#' # Download to file
#' storage_download(conn, "images/photo.jpg", "local/photo.jpg")
#'
#' # Download to memory
#' content <- storage_download(conn, "data/config.json")
#' }
storage_download <- function(conn,
                             object_name,
                             dest_file = NULL,
                             client_id = NULL,
                             client_secret = NULL) {
  if (!is_firebase_connection(conn)) {
    stop_firebase("validation", "Expected a firebase_connection object")
  }

  if (is.null(conn$storage_bucket)) {
    stop_firebase("validation", "Storage bucket not configured")
  }

  # Get OAuth token
  token <- get_storage_token(conn, client_id, client_secret, read_only = TRUE)

  # Build download URL
  download_url <- paste0(
    "https://storage.googleapis.com/storage/v1/b/",
    conn$storage_bucket,
    "/o/",
    utils::URLencode(object_name, reserved = TRUE),
    "?alt=media"
  )

  headers <- list(Authorization = paste("Bearer", token))

  if (!is.null(dest_file)) {
    # Download to file
    response <- httr::GET(
      url = download_url,
      httr::add_headers(.headers = unlist(headers)),
      httr::write_disk(dest_file, overwrite = TRUE)
    )

    if (httr::http_error(response)) {
      stop(parse_firebase_error(response))
    }

    dest_file
  } else {
    # Return content
    response <- httr::GET(
      url = download_url,
      httr::add_headers(.headers = unlist(headers))
    )

    if (httr::http_error(response)) {
      stop(parse_firebase_error(response))
    }

    httr::content(response)
  }
}

#' Delete File from Storage
#'
#' Deletes a file from Firebase Cloud Storage.
#'
#' @param conn Firebase connection object
#' @param object_name Name/path of the object to delete
#' @param client_id OAuth client ID
#' @param client_secret OAuth client secret
#' @return NULL on success
#' @export
#' @examples
#' \dontrun{
#' storage_delete(conn, "images/old-photo.jpg")
#' }
storage_delete <- function(conn,
                           object_name,
                           client_id = NULL,
                           client_secret = NULL) {
  if (!is_firebase_connection(conn)) {
    stop_firebase("validation", "Expected a firebase_connection object")
  }

  if (is.null(conn$storage_bucket)) {
    stop_firebase("validation", "Storage bucket not configured")
  }

  token <- get_storage_token(conn, client_id, client_secret)

  delete_url <- paste0(
    "https://www.googleapis.com/storage/v1/b/",
    conn$storage_bucket,
    "/o/",
    utils::URLencode(object_name, reserved = TRUE)
  )

  response <- httr::DELETE(
    url = delete_url,
    httr::add_headers(Authorization = paste("Bearer", token))
  )

  if (httr::http_error(response)) {
    stop(parse_firebase_error(response))
  }

  invisible(NULL)
}

#' List Files in Storage
#'
#' Lists all files in a storage bucket or prefix.
#'
#' @param conn Firebase connection object
#' @param prefix Filter results to objects with this prefix
#' @param delimiter Use "/" to list only immediate children
#' @param max_results Maximum number of results
#' @param client_id OAuth client ID
#' @param client_secret OAuth client secret
#' @return List of storage objects
#' @export
#' @examples
#' \dontrun{
#' # List all files
#' files <- storage_list(conn)
#'
#' # List files in a "folder"
#' images <- storage_list(conn, prefix = "images/")
#' }
storage_list <- function(conn,
                         prefix = NULL,
                         delimiter = NULL,
                         max_results = 1000,
                         client_id = NULL,
                         client_secret = NULL) {
  if (!is_firebase_connection(conn)) {
    stop_firebase("validation", "Expected a firebase_connection object")
  }

  if (is.null(conn$storage_bucket)) {
    stop_firebase("validation", "Storage bucket not configured")
  }

  token <- get_storage_token(conn, client_id, client_secret, read_only = TRUE)

  # Build URL with query params
  list_url <- paste0(
    "https://www.googleapis.com/storage/v1/b/",
    conn$storage_bucket,
    "/o"
  )

  query <- list(maxResults = max_results)
  if (!is.null(prefix)) query$prefix <- prefix
  if (!is.null(delimiter)) query$delimiter <- delimiter

  response <- httr::GET(
    url = list_url,
    httr::add_headers(Authorization = paste("Bearer", token)),
    query = query
  )

  if (httr::http_error(response)) {
    stop(parse_firebase_error(response))
  }

  httr::content(response)
}

#' Get Storage Object Metadata
#'
#' Retrieves metadata for a storage object.
#'
#' @param conn Firebase connection object
#' @param object_name Name/path of the object
#' @param client_id OAuth client ID
#' @param client_secret OAuth client secret
#' @return Object metadata
#' @export
storage_get_metadata <- function(conn,
                                 object_name,
                                 client_id = NULL,
                                 client_secret = NULL) {
  if (!is_firebase_connection(conn)) {
    stop_firebase("validation", "Expected a firebase_connection object")
  }

  if (is.null(conn$storage_bucket)) {
    stop_firebase("validation", "Storage bucket not configured")
  }

  token <- get_storage_token(conn, client_id, client_secret, read_only = TRUE)

  metadata_url <- paste0(
    "https://www.googleapis.com/storage/v1/b/",
    conn$storage_bucket,
    "/o/",
    utils::URLencode(object_name, reserved = TRUE)
  )

  response <- httr::GET(
    url = metadata_url,
    httr::add_headers(Authorization = paste("Bearer", token))
  )

  if (httr::http_error(response)) {
    stop(parse_firebase_error(response))
  }

  httr::content(response)
}

#' Get Download URL for Storage Object
#'
#' Generates a download URL for a storage object.
#'
#' @param conn Firebase connection object
#' @param object_name Name/path of the object
#' @param client_id OAuth client ID
#' @param client_secret OAuth client secret
#' @return Download URL string
#' @export
#' @examples
#' \dontrun{
#' url <- storage_get_url(conn, "images/photo.jpg")
#' browseURL(url)
#' }
storage_get_url <- function(conn,
                            object_name,
                            client_id = NULL,
                            client_secret = NULL) {
  # Get metadata to find download token
  metadata <- storage_get_metadata(conn, object_name, client_id, client_secret)

  # Build Firebase Storage URL with token
  paste0(
    "https://firebasestorage.googleapis.com/v0/b/",
    conn$storage_bucket,
    "/o/",
    utils::URLencode(object_name, reserved = TRUE),
    "?alt=media&token=",
    metadata$metadata$firebaseStorageDownloadTokens
  )
}

#' Upload Folder to Storage
#'
#' Uploads all files from a local folder to storage.
#'
#' @param conn Firebase connection object
#' @param folder_path Local folder path
#' @param prefix Storage prefix/path for uploaded files
#' @param client_id OAuth client ID
#' @param client_secret OAuth client secret
#' @return List of upload results
#' @export
#' @examples
#' \dontrun{
#' results <- storage_upload_folder(conn, "local/images", "images")
#' }
storage_upload_folder <- function(conn,
                                  folder_path,
                                  prefix = "",
                                  client_id = NULL,
                                  client_secret = NULL) {
  if (!is_firebase_connection(conn)) {
    stop_firebase("validation", "Expected a firebase_connection object")
  }

  if (!dir.exists(folder_path)) {
    stop_firebase("validation", paste("Folder not found:", folder_path))
  }

  # Get files recursively
  files <- list.files(folder_path, full.names = FALSE, recursive = TRUE)

  if (length(files) == 0) {
    message("No files found in folder")
    return(list())
  }

  # Get token once for all uploads
  token <- get_storage_token(conn, client_id, client_secret)

  results <- list()
  for (file in files) {
    local_path <- file.path(folder_path, file)
    object_name <- if (nzchar(prefix)) paste0(prefix, "/", file) else file

    message("Uploading: ", object_name)

    upload_url <- paste0(
      "https://www.googleapis.com/upload/storage/v1/b/",
      conn$storage_bucket,
      "/o?uploadType=media&name=",
      utils::URLencode(object_name, reserved = TRUE)
    )

    response <- httr::POST(
      url = upload_url,
      body = httr::upload_file(local_path),
      httr::add_headers(Authorization = paste("Bearer", token))
    )

    results[[file]] <- httr::content(response)
  }

  results
}

#' Get OAuth Token for Storage Operations
#'
#' Internal helper to get an OAuth token for storage operations.
#'
#' @param conn Firebase connection object
#' @param client_id OAuth client ID
#' @param client_secret OAuth client secret
#' @param read_only Whether to request read-only scope
#' @return Access token string
#' @keywords internal
get_storage_token <- function(conn, client_id = NULL, client_secret = NULL, read_only = FALSE) {
  # Try service account first
  if (!is.null(conn$credentials)) {
    scopes <- if (read_only) {
      "https://www.googleapis.com/auth/devstorage.read_only"
    } else {
      "https://www.googleapis.com/auth/devstorage.read_write"
    }
    return(conn$credentials$get_access_token(scopes))
  }

  # Fall back to OAuth
  scope <- if (read_only) {
    "https://www.googleapis.com/auth/devstorage.read_only"
  } else {
    "https://www.googleapis.com/auth/devstorage.read_write"
  }

  oauth_token <- get_oauth_token(client_id, client_secret, scope)
  oauth_token$credentials$access_token
}

# ============================================================================
# Deprecated Legacy Functions (Backward Compatibility)
# ============================================================================

#' @title Upload to Storage (Legacy)
#' @description Legacy function. Use storage_upload() instead.
#' @param bucket_name Storage bucket name
#' @param object_name Object name in storage
#' @param web_client_id OAuth client ID
#' @param web_client_secret OAuth client secret
#' @param file_path Local file path
#' @param predefined_acl Access control
#' @return Storage object metadata
#' @export
upload_storage <- function(bucket_name,
                           object_name,
                           web_client_id = "prompt",
                           web_client_secret = "prompt",
                           file_path = NULL,
                           predefined_acl = "publicRead") {
  .Deprecated("storage_upload")

  google_token <- google_devstorage_read_write(web_client_id, web_client_secret)

  upload_url <- paste0(
    "https://www.googleapis.com/upload/storage/v1/b/",
    bucket_name,
    "/o?uploadType=media&name=",
    object_name,
    "&predefinedAcl=",
    predefined_acl
  )

  headers <- c(Authorization = paste("Bearer", google_token$credentials$access_token))

  if (is.null(file_path)) {
    response <- httr::POST(url = upload_url, httr::add_headers(headers))
  } else {
    response <- httr::POST(
      url = upload_url,
      body = httr::upload_file(file_path),
      httr::add_headers(headers)
    )
  }

  data <- httr::content(response)
  data["url"] <- paste("https://storage.cloud.google.com", bucket_name, object_name, sep = "/")
  data
}

#' @title Delete from Storage (Legacy)
#' @description Legacy function. Use storage_delete() instead.
#' @param bucket_name Storage bucket name
#' @param object_name Object name to delete
#' @param web_client_id OAuth client ID
#' @param web_client_secret OAuth client secret
#' @return NULL on success
#' @export
delete_storage <- function(bucket_name, object_name, web_client_id = "prompt", web_client_secret = "prompt") {
  .Deprecated("storage_delete")

  google_token <- google_devstorage_read_write(web_client_id, web_client_secret)

  delete_url <- paste0(
    "https://www.googleapis.com/storage/v1/b/",
    bucket_name,
    "/o/",
    object_name
  )

  response <- httr::DELETE(
    url = delete_url,
    httr::add_headers(Authorization = paste("Bearer", google_token$credentials$access_token))
  )

  httr::content(response)
}

#' @title List Storage (Legacy)
#' @description Legacy function. Use storage_list() instead.
#' @param bucket_name Storage bucket name
#' @param web_client_id OAuth client ID
#' @param web_client_secret OAuth client secret
#' @return List of objects
#' @export
list_storage <- function(bucket_name, web_client_id = "prompt", web_client_secret = "prompt") {
  .Deprecated("storage_list")

  google_token <- google_devstorage_read_only(web_client_id, web_client_secret)

  list_url <- paste0("https://www.googleapis.com/storage/v1/b/", bucket_name, "/o")

  response <- httr::GET(
    url = list_url,
    httr::add_headers(Authorization = paste("Bearer", google_token$credentials$access_token))
  )

  httr::content(response)
}

#' @title Get Storage Metadata (Legacy)
#' @description Legacy function. Use storage_get_metadata() instead.
#' @param bucket_name Storage bucket name
#' @param object_name Object name
#' @param web_client_id OAuth client ID
#' @param web_client_secret OAuth client secret
#' @return Object metadata
#' @export
get_storage <- function(bucket_name, object_name, web_client_id = "prompt", web_client_secret = "prompt") {
  .Deprecated("storage_get_metadata")

  google_token <- google_devstorage_read_only(web_client_id, web_client_secret)

  url <- paste0(
    "https://www.googleapis.com/storage/v1/b/",
    bucket_name,
    "/o/",
    object_name
  )

  response <- httr::GET(
    url = url,
    httr::add_headers(Authorization = paste("Bearer", google_token$credentials$access_token))
  )

  httr::content(response)
}

#' @title Get Storage URL (Legacy)
#' @description Legacy function. Use storage_get_url() instead.
#' @param bucket_name Storage bucket name
#' @param object_name Object name
#' @param web_client_id OAuth client ID
#' @param web_client_secret OAuth client secret
#' @return Download URL
#' @export
get_url <- function(bucket_name, object_name, web_client_id = "prompt", web_client_secret = "prompt") {
  .Deprecated("storage_get_url")

  object_resources <- get_storage(bucket_name, object_name, web_client_id, web_client_secret)

  paste0(
    "https://firebasestorage.googleapis.com/v0/b/",
    bucket_name,
    "/o/",
    object_name,
    "?alt=media&token=",
    object_resources$metadata$firebaseStorageDownloadTokens
  )
}

#' @title Upload Folder (Legacy)
#' @description Legacy function. Use storage_upload_folder() instead.
#' @param bucket_name Storage bucket name
#' @param web_client_id OAuth client ID
#' @param web_client_secret OAuth client secret
#' @param folder_path Local folder path
#' @return List of upload results
#' @export
upload_folder <- function(bucket_name, web_client_id = "prompt", web_client_secret = "prompt", folder_path) {
  .Deprecated("storage_upload_folder")

  files <- list.files(path = folder_path, full.names = FALSE, recursive = TRUE)
  google_token <- google_devstorage_read_write(web_client_id, web_client_secret)

  responses <- list()

  for (file in files) {
    object_name <- paste0(folder_path, "/", file)
    print(object_name)

    upload_url <- paste0(
      "https://www.googleapis.com/upload/storage/v1/b/",
      bucket_name,
      "/o?uploadType=media&name=",
      file
    )

    response <- httr::POST(
      url = upload_url,
      body = httr::upload_file(paste0(folder_path, "/", file)),
      httr::add_headers(Authorization = paste("Bearer", google_token$credentials$access_token))
    )

    responses <- append(responses, httr::content(response))
  }

  responses
}

#' @title Get Storage Token with Read/Write Access (Legacy)
#' @description Legacy function for OAuth token.
#' @param web_client_id OAuth client ID
#' @param web_client_secret OAuth client secret
#' @return OAuth token
#' @export
google_devstorage_read_write <- function(web_client_id = "prompt", web_client_secret = "prompt") {
  client_id <- prompt_if_missing(web_client_id, "client_id", "Web Client ID")
  client_secret <- prompt_if_missing(web_client_secret, "client_secret", "Web Client Secret")

  app <- httr::oauth_app("google", key = client_id, secret = client_secret)
  httr::oauth2.0_token(
    httr::oauth_endpoints("google"),
    app,
    scope = "https://www.googleapis.com/auth/devstorage.read_write"
  )
}

#' @title Get Storage Token with Read-Only Access (Legacy)
#' @description Legacy function for OAuth token.
#' @param web_client_id OAuth client ID
#' @param web_client_secret OAuth client secret
#' @return OAuth token
#' @export
google_devstorage_read_only <- function(web_client_id = "prompt", web_client_secret = "prompt") {
  client_id <- prompt_if_missing(web_client_id, "client_id", "Web Client ID")
  client_secret <- prompt_if_missing(web_client_secret, "client_secret", "Web Client Secret")

  app <- httr::oauth_app("google", key = client_id, secret = client_secret)
  httr::oauth2.0_token(
    httr::oauth_endpoints("google"),
    app,
    scope = "https://www.googleapis.com/auth/devstorage.read_only"
  )
}

#' @title Get Firestore Token (Legacy)
#' @description Legacy function for Firestore OAuth token.
#' @param web_client_id OAuth client ID
#' @param web_client_secret OAuth client secret
#' @param cache Whether to cache token
#' @return OAuth token
#' @export
google_firestore <- function(web_client_id = "prompt", web_client_secret = "prompt", cache = FALSE) {
  client_id <- prompt_if_missing(web_client_id, "client_id", "Web Client ID")
  client_secret <- prompt_if_missing(web_client_secret, "client_secret", "Web Client Secret")

  app <- httr::oauth_app("google", key = client_id, secret = client_secret)
  httr::oauth2.0_token(
    httr::oauth_endpoints("google"),
    app,
    scope = "https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/cloud-platform",
    cache = cache
  )
}

#' @title Deploy R Markdown (Legacy)
#' @description Legacy function to deploy R Markdown to storage.
#' @param rmarkdown_path Path to R Markdown file
#' @param bucket_name Storage bucket
#' @param object_name Output object name
#' @param web_client_id OAuth client ID
#' @param web_client_secret OAuth client secret
#' @return Upload result
#' @export
deploy_rmarkdown <- function(rmarkdown_path, bucket_name, object_name,
                             web_client_id = "prompt", web_client_secret = "prompt") {
  if (!requireNamespace("rmarkdown", quietly = TRUE)) {
    stop_firebase("validation", "Package 'rmarkdown' is required for this function")
  }

  html_file <- rmarkdown::render(input = rmarkdown_path, output_format = "html_document")

  upload_storage(
    bucket_name = bucket_name,
    web_client_id = web_client_id,
    web_client_secret = web_client_secret,
    object_name = object_name,
    file_path = html_file
  )
}
