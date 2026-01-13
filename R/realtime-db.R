#' @title Firebase Realtime Database Service
#' @description Functions for CRUD operations on Firebase Realtime Database
#' @name firebase_rtdb
NULL

#' Get Data from Realtime Database
#'
#' Retrieves data from the specified path in the Realtime Database.
#'
#' @param conn Firebase connection object
#' @param path Database path (e.g., "users/user123")
#' @param shallow If TRUE, returns only keys without values (for large datasets)
#' @param is_class If TRUE, data is decoded as an S4 class object
#' @param token Authentication token (overrides connection token)
#' @return The data at the specified path, or NULL if not found
#' @export
#' @examples
#' \dontrun{
#' conn <- firebase_connect(project_id = "my-project", api_key = "...")
#'
#' # Get all users
#' users <- rtdb_get(conn, "users")
#'
#' # Get specific user
#' user <- rtdb_get(conn, "users/user123")
#'
#' # Get only keys (shallow read)
#' keys <- rtdb_get(conn, "users", shallow = TRUE)
#' }
rtdb_get <- function(conn,
                     path,
                     shallow = FALSE,
                     is_class = FALSE,
                     token = NULL) {
  # Validate connection
  if (!is_firebase_connection(conn)) {
    stop_firebase("validation", "Expected a firebase_connection object")
  }

  # Build URL
  url <- build_rtdb_path_url(conn$database_url, path)

  # Build query params
  query <- list()
  if (shallow) query$shallow <- "true"

  # Resolve token
  token <- token %||% get_connection_token(conn)

  # Make request
  data <- firebase_get(
    url = url,
    query = query,
    token = token,
    token_type = "query"
  )

  # Check for null data
  if (is.null(data)) {
    warning("No data found at database location.")
    return(NULL)
  }

  # Handle S4 class decoding
  if (is_class && is_encoded_s4(data)) {
    return(class_restore(data))
  }

  data
}

#' Set Data in Realtime Database (Overwrite)
#'
#' Writes data to the specified path, overwriting any existing data.
#' Use rtdb_update() for partial updates.
#'
#' @param conn Firebase connection object
#' @param path Database path
#' @param data Data to write (data.frame, list, or S4 object)
#' @param token Authentication token (overrides connection token)
#' @return The path where data was written
#' @export
#' @examples
#' \dontrun{
#' conn <- firebase_connect(project_id = "my-project", api_key = "...")
#'
#' # Set user data
#' rtdb_set(conn, "users/user123", list(name = "John", age = 30))
#'
#' # Set data frame
#' rtdb_set(conn, "data/mtcars", mtcars)
#' }
rtdb_set <- function(conn, path, data, token = NULL) {
  # Validate connection
  if (!is_firebase_connection(conn)) {
    stop_firebase("validation", "Expected a firebase_connection object")
  }

  # Convert data
  output <- file_conversion(data)

  # Build URL
  url <- build_rtdb_path_url(conn$database_url, path)

  # Resolve token
  token <- token %||% get_connection_token(conn)

  # Make request (PUT overwrites)
  firebase_put(
    url = url,
    body = output,
    token = token,
    token_type = "query"
  )

  path
}

#' Push Data to Realtime Database (Create with Auto-ID)
#'
#' Adds data to a list with an auto-generated unique key.
#'
#' @param conn Firebase connection object
#' @param path Database path (parent location)
#' @param data Data to push
#' @param token Authentication token (overrides connection token)
#' @return The full path including the generated key
#' @export
#' @examples
#' \dontrun{
#' conn <- firebase_connect(project_id = "my-project", api_key = "...")
#'
#' # Push new message (auto-generates key)
#' path <- rtdb_push(conn, "messages", list(text = "Hello", timestamp = Sys.time()))
#' # Returns something like "messages/-NxYz..."
#' }
rtdb_push <- function(conn, path, data, token = NULL) {
  # Validate connection
  if (!is_firebase_connection(conn)) {
    stop_firebase("validation", "Expected a firebase_connection object")
  }

  # Convert data
  output <- file_conversion(data)

  # Build URL
  url <- build_rtdb_path_url(conn$database_url, path)

  # Resolve token
  token <- token %||% get_connection_token(conn)

  # Make request (POST creates with auto-key)
  response <- firebase_post(
    url = url,
    body = output,
    token = token,
    token_type = "query"
  )

  # Return full path with generated key
  combine_paths(path, response$name)
}

#' Update Data in Realtime Database (Partial Update)
#'
#' Updates specific fields at the specified path without overwriting
#' other existing data. Use rtdb_set() to completely overwrite.
#'
#' @param conn Firebase connection object
#' @param path Database path
#' @param data Data to update (only specified fields will be changed)
#' @param token Authentication token (overrides connection token)
#' @return The path where data was updated
#' @export
#' @examples
#' \dontrun{
#' conn <- firebase_connect(project_id = "my-project", api_key = "...")
#'
#' # Update only the age field
#' rtdb_update(conn, "users/user123", list(age = 31))
#' }
rtdb_update <- function(conn, path, data, token = NULL) {
  # Validate connection
  if (!is_firebase_connection(conn)) {
    stop_firebase("validation", "Expected a firebase_connection object")
  }

  # Convert data
  output <- file_conversion(data)

  # Build URL
  url <- build_rtdb_path_url(conn$database_url, path)

  # Resolve token
  token <- token %||% get_connection_token(conn)

  # Make request (PATCH merges)
  firebase_patch(
    url = url,
    body = output,
    token = token,
    token_type = "query"
  )

  path
}

#' Delete Data from Realtime Database
#'
#' Removes data at the specified path.
#'
#' @param conn Firebase connection object
#' @param path Database path to delete
#' @param token Authentication token (overrides connection token)
#' @return The path that was deleted
#' @export
#' @examples
#' \dontrun{
#' conn <- firebase_connect(project_id = "my-project", api_key = "...")
#'
#' # Delete user
#' rtdb_delete(conn, "users/user123")
#' }
rtdb_delete <- function(conn, path, token = NULL) {
  # Validate connection
  if (!is_firebase_connection(conn)) {
    stop_firebase("validation", "Expected a firebase_connection object")
  }

  # Build URL
  url <- build_rtdb_path_url(conn$database_url, path)

  # Resolve token
  token <- token %||% get_connection_token(conn)

  # Make request
  firebase_delete(
    url = url,
    token = token,
    token_type = "query"
  )

  path
}

#' Backup Realtime Database
#'
#' Downloads the entire database to a JSON file.
#'
#' @param conn Firebase connection object
#' @param file_name Output file path
#' @param token Authentication token (typically admin/service account)
#' @return The file name where backup was saved
#' @export
#' @examples
#' \dontrun{
#' conn <- firebase_connect(
#'   project_id = "my-project",
#'   credentials = "service-account.json"
#' )
#' rtdb_backup(conn, "backup.json")
#' }
rtdb_backup <- function(conn, file_name, token = NULL) {
  # Validate connection
  if (!is_firebase_connection(conn)) {
    stop_firebase("validation", "Expected a firebase_connection object")
  }

  # Resolve token
  token <- token %||% get_connection_token(conn, require_auth = TRUE)

  if (is.null(token)) {
    # Try prompting for secret key (legacy behavior)
    if (interactive()) {
      token <- readline(prompt = "Database secret key: ")
    } else {
      stop_firebase("auth", "Authentication token or secret key required for backup")
    }
  }

  message("Fetching data...")

  # Build URL
  url <- paste0(conn$database_url, "/.json?auth=", token)

  # Download using curl for large files
  curl::curl_download(
    url = url,
    destfile = file_name,
    quiet = FALSE
  )

  message(paste0("Backup created: ", file_name))
  file_name
}

#' Create Database Query
#'
#' Creates a query builder for filtering and sorting database queries.
#'
#' @param conn Firebase connection object
#' @param path Database path to query
#' @return A query builder object
#' @export
#' @examples
#' \dontrun{
#' conn <- firebase_connect(project_id = "my-project", api_key = "...")
#'
#' # Query users ordered by age, limited to 10
#' results <- rtdb_query(conn, "users") |>
#'   query_order_by("age") |>
#'   query_start_at(18) |>
#'   query_limit_to_first(10) |>
#'   query_execute()
#' }
rtdb_query <- function(conn, path) {
  if (!is_firebase_connection(conn)) {
    stop_firebase("validation", "Expected a firebase_connection object")
  }

  structure(
    list(
      conn = conn,
      path = path,
      params = list()
    ),
    class = "rtdb_query"
  )
}

#' Order Query by Field
#'
#' @param query Query builder object
#' @param field Field to order by ("$key", "$value", "$priority", or child key)
#' @return Updated query builder
#' @export
query_order_by <- function(query, field) {
  if (!inherits(query, "rtdb_query")) {
    stop_firebase("validation", "Expected an rtdb_query object")
  }
  query$params$orderBy <- paste0('"', field, '"')
  query
}

#' Limit Query to First N Results
#'
#' @param query Query builder object
#' @param n Number of results
#' @return Updated query builder
#' @export
query_limit_to_first <- function(query, n) {
  if (!inherits(query, "rtdb_query")) {
    stop_firebase("validation", "Expected an rtdb_query object")
  }
  query$params$limitToFirst <- n
  query
}

#' Limit Query to Last N Results
#'
#' @param query Query builder object
#' @param n Number of results
#' @return Updated query builder
#' @export
query_limit_to_last <- function(query, n) {
  if (!inherits(query, "rtdb_query")) {
    stop_firebase("validation", "Expected an rtdb_query object")
  }
  query$params$limitToLast <- n
  query
}

#' Start Query at Value
#'
#' @param query Query builder object
#' @param value Starting value (inclusive)
#' @return Updated query builder
#' @export
query_start_at <- function(query, value) {
  if (!inherits(query, "rtdb_query")) {
    stop_firebase("validation", "Expected an rtdb_query object")
  }
  query$params$startAt <- if (is.character(value)) paste0('"', value, '"') else value
  query
}

#' End Query at Value
#'
#' @param query Query builder object
#' @param value Ending value (inclusive)
#' @return Updated query builder
#' @export
query_end_at <- function(query, value) {
  if (!inherits(query, "rtdb_query")) {
    stop_firebase("validation", "Expected an rtdb_query object")
  }
  query$params$endAt <- if (is.character(value)) paste0('"', value, '"') else value
  query
}

#' Filter Query by Exact Value
#'
#' @param query Query builder object
#' @param value Value to match exactly
#' @return Updated query builder
#' @export
query_equal_to <- function(query, value) {
  if (!inherits(query, "rtdb_query")) {
    stop_firebase("validation", "Expected an rtdb_query object")
  }
  query$params$equalTo <- if (is.character(value)) paste0('"', value, '"') else value
  query
}

#' Execute Query
#'
#' @param query Query builder object
#' @param token Authentication token (optional)
#' @return Query results
#' @export
query_execute <- function(query, token = NULL) {
  if (!inherits(query, "rtdb_query")) {
    stop_firebase("validation", "Expected an rtdb_query object")
  }

  # Build URL with query params
  url <- build_rtdb_path_url(query$conn$database_url, query$path)

  # Resolve token
  token <- token %||% get_connection_token(query$conn)

  # Make request
  firebase_get(
    url = url,
    query = query$params,
    token = token,
    token_type = "query"
  )
}

#' Print Query
#'
#' @param x Query object
#' @param ... Ignored
#' @return Invisibly returns x
#' @export
print.rtdb_query <- function(x, ...) {
  cat("<rtdb_query>\n")
  cat("  Path:", x$path, "\n")
  if (length(x$params) > 0) {
    cat("  Parameters:\n")
    for (name in names(x$params)) {
      cat("    ", name, "=", x$params[[name]], "\n")
    }
  }
  invisible(x)
}

# ============================================================================
# Deprecated Legacy Functions (Backward Compatibility)
# ============================================================================

#' @title Upload Data (Legacy)
#' @description Legacy upload function. Use rtdb_push() instead.
#' @param x Data to upload
#' @param projectURL Firebase database URL
#' @param directory Database path
#' @param token Authentication token
#' @return Path with generated key
#' @export
upload <- function(x, projectURL, directory = "main", token = "none") {
  .Deprecated("rtdb_push")

  output <- fileConversion(x)

  if (token == "none") {
    url <- paste0(projectURL, "/", directory, ".json")
  } else {
    url <- paste0(projectURL, "/", directory, ".json?auth=", token)
  }

  response <- httr::POST(url, body = jsonlite::toJSON(output, auto_unbox = TRUE))
  paste0(directory, "/", httr::content(response)$name)
}

#' @title Download Data (Legacy)
#' @description Legacy download function. Use rtdb_get() instead.
#' @param projectURL Firebase database URL
#' @param fileName Database path
#' @param secretKey Admin secret key
#' @param token Authentication token
#' @param isClass Whether data is S4 class
#' @return Downloaded data
#' @export
download <- function(projectURL, fileName, secretKey = "none", token = "none", isClass = FALSE) {
  .Deprecated("rtdb_get")

  if (secretKey == "none" && token == "none") {
    urlPath <- paste0(projectURL, "/", fileName, ".json")
  } else if (token != "none") {
    urlPath <- paste0(projectURL, "/", fileName, ".json?auth=", token)
  } else {
    urlPath <- paste0(projectURL, "/", fileName, ".json?auth=", secretKey)
  }

  data <- httr::GET(urlPath)

  if (is.null(jsonlite::fromJSON(httr::content(data, "text")))) {
    warning("No data found at database location.")
  }

  if (isClass) {
    retrievedData <- httr::content(data, "text")
    tempPath <- tempfile()
    writeBin(jsonlite::base64_dec(jsonlite::fromJSON(retrievedData)), tempPath)
    return(readRDS(tempPath))
  } else {
    return(jsonlite::fromJSON(httr::content(data, "text")))
  }
}

#' @title Put Data (Legacy)
#' @description Legacy put function. Use rtdb_set() instead.
#' @param x Data to write
#' @param projectURL Firebase database URL
#' @param directory Database path
#' @param token Authentication token
#' @return Path
#' @export
put <- function(x, projectURL, directory = "main", token = "none") {
  .Deprecated("rtdb_set")

  output <- fileConversion(x)

  if (token == "none") {
    url <- paste0(projectURL, "/", directory, ".json")
  } else {
    url <- paste0(projectURL, "/", directory, ".json?auth=", token)
  }

  response <- httr::PUT(url, body = jsonlite::toJSON(output, auto_unbox = TRUE))
  paste0(directory, "/", httr::content(response)$name)
}

#' @title Patch Data (Legacy)
#' @description Legacy patch function. Use rtdb_update() instead.
#' @param x Data to update
#' @param projectURL Firebase database URL
#' @param directory Database path
#' @param token Authentication token
#' @return Path
#' @export
patch <- function(x, projectURL, directory = "main", token = "none") {
  .Deprecated("rtdb_update")

  output <- fileConversion(x)

  if (token == "none") {
    url <- paste0(projectURL, "/", directory, ".json")
  } else {
    url <- paste0(projectURL, "/", directory, ".json?auth=", token)
  }

  response <- httr::PATCH(url, body = jsonlite::toJSON(output, auto_unbox = TRUE))
  paste0(directory, "/", httr::content(response)$name)
}

#' @title Delete Data (Legacy)
#' @description Legacy delete function. Use rtdb_delete() instead.
#' @param x Data (unused, for signature compatibility)
#' @param projectURL Firebase database URL
#' @param directory Database path
#' @param token Authentication token
#' @return Path
#' @export
delete <- function(x, projectURL, directory = "main", token = "none") {
  .Deprecated("rtdb_delete")

  output <- fileConversion(x)

  if (token == "none") {
    url <- paste0(projectURL, "/", directory, ".json")
  } else {
    url <- paste0(projectURL, "/", directory, ".json?auth=", token)
  }

  response <- httr::DELETE(url, body = jsonlite::toJSON(output, auto_unbox = TRUE))
  paste0(directory, "/", httr::content(response)$name)
}

#' @title Database Backup (Legacy)
#' @description Legacy backup function. Use rtdb_backup() instead.
#' @param projectURL Firebase database URL
#' @param secretKey Admin secret key
#' @param fileName Output file name
#' @return File name
#' @export
dataBackup <- function(projectURL, secretKey = "prompt", fileName) {
  .Deprecated("rtdb_backup")

  if (secretKey == "prompt" && interactive()) {
    secretKey <- readline(prompt = "secretKey: ")
    print(paste0("Connecting to ", projectURL, ":"))
  }

  print("Fetching Data")
  urlPath <- paste0(projectURL, "/.json?auth=", secretKey)
  curl::curl_download(url = urlPath, destfile = fileName, quiet = FALSE)
  print(paste0("Backup created in ", fileName))

  fileName
}
