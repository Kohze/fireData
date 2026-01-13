#' @title HTTP Layer for fireData
#' @description Provides unified HTTP request handling for Firebase REST APIs
#' @name firebase_http
#' @keywords internal
NULL

# Firebase API base URLs
FIREBASE_AUTH_URL <- "https://identitytoolkit.googleapis.com/v1"
FIREBASE_TOKEN_URL <- "https://securetoken.googleapis.com/v1"
FIREBASE_STORAGE_URL <- "https://storage.googleapis.com"
FIREBASE_FIRESTORE_URL <- "https://firestore.googleapis.com/v1"
FIREBASE_DYNAMIC_LINKS_URL <- "https://firebasedynamiclinks.googleapis.com/v1"
FIREBASE_REMOTE_CONFIG_URL <- "https://firebaseremoteconfig.googleapis.com/v1"

#' Build Firebase Realtime Database URL
#'
#' @param project_id Firebase project ID
#' @param database_url Custom database URL (optional)
#' @return The database base URL
#' @keywords internal
build_rtdb_url <- function(project_id = NULL, database_url = NULL) {
  if (!is.null(database_url)) {
    # Remove trailing slash if present
    gsub("/$", "", database_url)
  } else if (!is.null(project_id)) {
    paste0("https://", project_id, "-default-rtdb.firebaseio.com")
  } else {
    stop_firebase("validation", "Either project_id or database_url must be provided")
  }
}

#' Build Firebase Firestore URL
#'
#' @param project_id Firebase project ID
#' @return The Firestore base URL
#' @keywords internal
build_firestore_url <- function(project_id) {
  paste0(FIREBASE_FIRESTORE_URL, "/projects/", project_id, "/databases/(default)/documents")
}

#' Perform HTTP Request with Retry Logic
#'
#' Executes an HTTP request with exponential backoff retry for transient errors.
#'
#' @param method HTTP method ("GET", "POST", "PUT", "PATCH", "DELETE")
#' @param url The request URL
#' @param body Request body (will be JSON encoded if list)
#' @param headers Named list of HTTP headers
#' @param query Named list of query parameters
#' @param token Authentication token (added as auth query param or Bearer header)
#' @param token_type How to send token: "query" (for RTDB) or "bearer" (for other APIs)
#' @param max_retries Maximum number of retry attempts
#' @param base_delay Base delay in seconds for exponential backoff
#' @param timeout Request timeout in seconds
#' @param encode Encoding for body ("json", "form", "multipart")
#' @return Parsed response content
#' @keywords internal
firebase_request <- function(method,
                             url,
                             body = NULL,
                             headers = list(),
                             query = list(),
                             token = NULL,
                             token_type = "query",
                             max_retries = 3,
                             base_delay = 1,
                             timeout = 120,
                             encode = "json") {
  # Add authentication
  if (!is.null(token) && token != "none" && nzchar(token)) {
    if (token_type == "query") {
      query$auth <- token
    } else if (token_type == "bearer") {
      headers$Authorization <- paste("Bearer", token)
    }
  }

  # Build request using httr (maintaining compatibility with existing code)
  # We'll support both httr and httr2 in the future
  attempt <- 0
  last_error <- NULL
  retryable_codes <- c(429, 500, 502, 503, 504)

  while (attempt <= max_retries) {
    response <- tryCatch({
      # Add query params to URL
      if (length(query) > 0) {
        query_string <- paste(
          names(query),
          sapply(query, utils::URLencode, reserved = TRUE),
          sep = "=",
          collapse = "&"
        )
        url_with_query <- if (grepl("\\?", url)) {
          paste0(url, "&", query_string)
        } else {
          paste0(url, "?", query_string)
        }
      } else {
        url_with_query <- url
      }

      # Prepare body
      if (!is.null(body) && is.list(body) && encode == "json") {
        body_encoded <- jsonlite::toJSON(body, auto_unbox = TRUE)
        headers$`Content-Type` <- "application/json"
      } else {
        body_encoded <- body
      }

      # Execute request
      httr::VERB(
        verb = method,
        url = url_with_query,
        body = body_encoded,
        httr::add_headers(.headers = unlist(headers)),
        httr::timeout(timeout),
        encode = if (encode == "json") "raw" else encode
      )
    }, error = function(e) {
      # Network error
      last_error <<- firebase_network_error(
        message = paste("Network error:", conditionMessage(e))
      )
      NULL
    })

    if (is.null(response)) {
      # Network error occurred
      attempt <- attempt + 1
      if (attempt > max_retries) {
        stop(last_error)
      }
      delay <- calculate_backoff(attempt, base_delay)
      Sys.sleep(delay)
      next
    }

    status <- httr::status_code(response)

    # Success
    if (status >= 200 && status < 300) {
      return(parse_response(response))
    }

    # Check if retryable
    if (status %in% retryable_codes) {
      attempt <- attempt + 1
      if (attempt > max_retries) {
        stop(parse_firebase_error(response))
      }

      # Check for Retry-After header
      retry_after <- httr::headers(response)$`retry-after`
      if (!is.null(retry_after)) {
        delay <- as.numeric(retry_after)
      } else {
        delay <- calculate_backoff(attempt, base_delay)
      }

      message(sprintf("Request failed with status %d. Retrying in %.1f seconds...", status, delay))
      Sys.sleep(delay)
      next
    }

    # Non-retryable error
    stop(parse_firebase_error(response))
  }
}

#' Calculate Exponential Backoff Delay
#'
#' @param attempt Current attempt number (1-based)
#' @param base_delay Base delay in seconds
#' @param max_delay Maximum delay in seconds
#' @return Delay in seconds with jitter
#' @keywords internal
calculate_backoff <- function(attempt, base_delay = 1, max_delay = 60) {
  delay <- min(base_delay * (2 ^ (attempt - 1)), max_delay)
  # Add jitter (0-10% of delay)
  jitter <- stats::runif(1, 0, delay * 0.1)
  delay + jitter
}

#' Parse HTTP Response
#'
#' @param response An httr response object
#' @return Parsed response content
#' @keywords internal
parse_response <- function(response) {
  content_type <- httr::http_type(response)

  if (grepl("json", content_type, ignore.case = TRUE)) {
    content_text <- httr::content(response, as = "text", encoding = "UTF-8")
    if (nzchar(content_text)) {
      jsonlite::fromJSON(content_text, simplifyVector = TRUE)
    } else {
      NULL
    }
  } else {
    httr::content(response, as = "text", encoding = "UTF-8")
  }
}

#' Firebase GET Request
#'
#' @param url Request URL
#' @param ... Additional arguments passed to firebase_request
#' @return Parsed response
#' @keywords internal
firebase_get <- function(url, ...) {
  firebase_request(method = "GET", url = url, ...)
}

#' Firebase POST Request
#'
#' @param url Request URL
#' @param body Request body
#' @param ... Additional arguments passed to firebase_request
#' @return Parsed response
#' @keywords internal
firebase_post <- function(url, body = NULL, ...) {
  firebase_request(method = "POST", url = url, body = body, ...)
}

#' Firebase PUT Request
#'
#' @param url Request URL
#' @param body Request body
#' @param ... Additional arguments passed to firebase_request
#' @return Parsed response
#' @keywords internal
firebase_put <- function(url, body = NULL, ...) {
  firebase_request(method = "PUT", url = url, body = body, ...)
}

#' Firebase PATCH Request
#'
#' @param url Request URL
#' @param body Request body
#' @param ... Additional arguments passed to firebase_request
#' @return Parsed response
#' @keywords internal
firebase_patch <- function(url, body = NULL, ...) {
  firebase_request(method = "PATCH", url = url, body = body, ...)
}

#' Firebase DELETE Request
#'
#' @param url Request URL
#' @param ... Additional arguments passed to firebase_request
#' @return Parsed response
#' @keywords internal
firebase_delete <- function(url, ...) {
  firebase_request(method = "DELETE", url = url, ...)
}

#' Build Authentication API URL
#'
#' @param endpoint Auth endpoint (e.g., "accounts:signInWithPassword")
#' @param api_key Firebase API key
#' @return Complete URL for the auth endpoint
#' @keywords internal
build_auth_url <- function(endpoint, api_key) {
  paste0(FIREBASE_AUTH_URL, "/", endpoint, "?key=", api_key)
}

#' Build Token Refresh URL
#'
#' @param api_key Firebase API key
#' @return Complete URL for token refresh
#' @keywords internal
build_token_url <- function(api_key) {
  paste0(FIREBASE_TOKEN_URL, "/token?key=", api_key)
}

#' Build Realtime Database Path URL
#'
#' @param base_url Database base URL
#' @param path Database path
#' @return Complete URL with .json suffix
#' @keywords internal
build_rtdb_path_url <- function(base_url, path) {
  # Clean up path
  path <- gsub("^/+", "", path)
  path <- gsub("/+$", "", path)

  if (nzchar(path)) {
    paste0(base_url, "/", path, ".json")
  } else {
    paste0(base_url, "/.json")
  }
}

#' Build Storage API URL
#'
#' @param bucket Bucket name
#' @param object Object path (optional)
#' @param upload Whether this is an upload URL
#' @return Complete storage URL
#' @keywords internal
build_storage_url <- function(bucket, object = NULL, upload = FALSE) {
  base <- if (upload) {
    paste0(FIREBASE_STORAGE_URL, "/upload/storage/v1/b/", bucket, "/o")
  } else {
    paste0(FIREBASE_STORAGE_URL, "/storage/v1/b/", bucket, "/o")
  }

  if (!is.null(object) && nzchar(object)) {
    paste0(base, "/", utils::URLencode(object, reserved = TRUE))
  } else {
    base
  }
}

#' Check if Response Indicates Success
#'
#' @param response An httr response object
#' @return TRUE if successful, FALSE otherwise
#' @keywords internal
is_success <- function(response) {
  status <- httr::status_code(response)
  status >= 200 && status < 300
}

#' Check if Response Indicates Error
#'
#' @param response An httr response object
#' @return TRUE if error, FALSE otherwise
#' @keywords internal
is_error <- function(response) {
  !is_success(response)
}
