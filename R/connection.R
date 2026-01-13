#' @title Firebase Connection Object
#' @description Provides a connection object for Firebase operations
#' @name firebase_connection
NULL

#' Create a Firebase Connection
#'
#' Creates a connection object that stores Firebase project configuration
#' and can be passed to various fireData functions. The connection handles
#' configuration resolution from multiple sources (arguments, environment,
#' config files).
#'
#' @param project_id Firebase project ID (e.g., "my-project-12345")
#' @param api_key Firebase Web API key
#' @param database_url Realtime Database URL. If NULL, constructed from project_id.
#' @param storage_bucket Cloud Storage bucket name. If NULL, defaults to \code{project_id.appspot.com}
#' @param credentials Service account credentials (path to JSON file or ServiceAccountCredentials object)
#' @param token User authentication token (FirebaseToken object or token string)
#' @return A firebase_connection S3 object
#' @export
#' @examples
#' \dontrun{
#' # Create connection with explicit values
#' conn <- firebase_connect(
#'   project_id = "my-project",
#'   api_key = "AIzaSy..."
#' )
#'
#' # Create connection from environment variables
#' # (Set FIREBASE_PROJECT_ID, FIREBASE_API_KEY, etc.)
#' conn <- firebase_connect()
#'
#' # Create connection with service account
#' conn <- firebase_connect(
#'   project_id = "my-project",
#'   credentials = "path/to/service-account.json"
#' )
#' }
firebase_connect <- function(project_id = NULL,
                             api_key = NULL,
                             database_url = NULL,
                             storage_bucket = NULL,
                             credentials = NULL,
                             token = NULL) {
  # Resolve configuration from various sources
  project_id <- firebase_config_get("project_id", value = project_id)
  api_key <- firebase_config_get("api_key", value = api_key)
  database_url <- firebase_config_get("database_url", value = database_url)
  storage_bucket <- firebase_config_get("storage_bucket", value = storage_bucket)

  # Validate minimum requirements
  if (is.null(project_id) && is.null(database_url)) {
    stop_firebase("validation",
      "Either project_id or database_url must be provided. " %+%
      "Set via function argument, FIREBASE_PROJECT_ID environment variable, " %+%
      "or config file."
    )
  }

  # Build database URL if not provided
  if (is.null(database_url) && !is.null(project_id)) {
    database_url <- build_rtdb_url(project_id = project_id)
  }

  # Build storage bucket if not provided
  if (is.null(storage_bucket) && !is.null(project_id)) {
    storage_bucket <- paste0(project_id, ".appspot.com")
  }

  # Handle credentials
  service_credentials <- NULL
  if (!is.null(credentials)) {
    if (inherits(credentials, "ServiceAccountCredentials")) {
      service_credentials <- credentials
    } else if (is.character(credentials)) {
      service_credentials <- load_service_account(credentials)
    }
  }

  # Handle token
  auth_token <- NULL
  if (!is.null(token)) {
    if (inherits(token, "FirebaseToken")) {
      auth_token <- token
    } else if (is.character(token) && !identical(token, "none") && nzchar(token)) {
      # Wrap raw token string in a simple structure
      auth_token <- token
    }
  }

  # Create connection object
  conn <- structure(
    list(
      project_id = project_id,
      api_key = api_key,
      database_url = database_url,
      storage_bucket = storage_bucket,
      credentials = service_credentials,
      token = auth_token,
      created_at = Sys.time()
    ),
    class = c("firebase_connection", "list")
  )

  conn
}

#' String concatenation operator
#'
#' @param a First string
#' @param b Second string
#' @return Concatenated string
#' @keywords internal
`%+%` <- function(a, b) paste0(a, b)

#' Print Firebase Connection
#'
#' @param x A firebase_connection object
#' @param ... Additional arguments (ignored)
#' @return Invisibly returns x
#' @export
print.firebase_connection <- function(x, ...) {
  cat("<firebase_connection>\n")
  cat("  Project ID:", x$project_id %||% "(not set)", "\n")
  cat("  Database URL:", x$database_url %||% "(not set)", "\n")
  cat("  Storage Bucket:", x$storage_bucket %||% "(not set)", "\n")
  cat("  API Key:", if (!is.null(x$api_key)) paste0(substr(x$api_key, 1, 8), "...") else "(not set)", "\n")
  cat("  Has Credentials:", !is.null(x$credentials), "\n")
  cat("  Has Token:", !is.null(x$token), "\n")
  invisible(x)
}

#' Check if Object is a Firebase Connection
#'
#' @param x Object to check
#' @return TRUE if x is a firebase_connection
#' @export
is_firebase_connection <- function(x) {
  inherits(x, "firebase_connection")
}

#' Get Token from Connection
#'
#' Extracts or resolves an authentication token from the connection.
#'
#' @param conn Firebase connection object
#' @param require_auth Whether to error if no token available
#' @return Token string or NULL
#' @keywords internal
get_connection_token <- function(conn, require_auth = FALSE) {
  if (is.null(conn)) {
    if (require_auth) {
      stop_firebase("auth", "Connection required for authenticated operation")
    }
    return(NULL)
  }

  # Check for user token
  if (!is.null(conn$token)) {
    if (inherits(conn$token, "FirebaseToken")) {
      return(conn$token$get_token())
    }
    return(conn$token)
  }

  # Check for service account
  if (!is.null(conn$credentials)) {
    return(conn$credentials$get_access_token())
  }

  if (require_auth) {
    stop_firebase("auth", "Authentication required but no token or credentials available")
  }

  NULL
}

#' Update Connection Token
#'
#' Updates the authentication token on a connection.
#'
#' @param conn Firebase connection object
#' @param token New token (FirebaseToken object or string)
#' @return Updated connection object
#' @export
#' @examples
#' \dontrun{
#' conn <- firebase_connect(project_id = "my-project", api_key = "...")
#' auth_result <- auth_sign_in(conn, email, password)
#' conn <- firebase_set_token(conn, auth_result)
#' }
firebase_set_token <- function(conn, token) {
  if (!is_firebase_connection(conn)) {
    stop_firebase("validation", "Expected a firebase_connection object")
  }

  if (is.list(token) && !is.null(token$idToken)) {
    # Convert auth response to FirebaseToken
    conn$token <- create_token(token, api_key = conn$api_key)
  } else if (inherits(token, "FirebaseToken")) {
    conn$token <- token
  } else if (is.character(token) && nzchar(token)) {
    conn$token <- token
  } else {
    stop_firebase("validation", "Invalid token: expected FirebaseToken, auth response, or token string")
  }

  conn
}

#' Create Connection from Legacy Parameters
#'
#' Helper to create a connection from the legacy API parameters
#' (projectURL, projectAPI, token, secretKey).
#'
#' @param projectURL Firebase database URL
#' @param projectAPI Firebase API key
#' @param token Authentication token
#' @param secretKey Database secret key (legacy)
#' @return A firebase_connection object
#' @keywords internal
legacy_to_connection <- function(projectURL = NULL,
                                 projectAPI = NULL,
                                 token = NULL,
                                 secretKey = NULL) {
  # Extract project ID from URL if possible
  project_id <- NULL
  if (!is.null(projectURL)) {
    # Try to extract from URL like "https://project-id.firebaseio.com"
    match <- regmatches(projectURL, regexpr("https://([^.]+)", projectURL))
    if (length(match) > 0) {
      project_id <- sub("https://", "", match)
      # Handle -default-rtdb suffix
      project_id <- sub("-default-rtdb$", "", project_id)
    }
  }

  # Use secretKey as token if provided (legacy admin access)
  effective_token <- if (!is.null(secretKey) && secretKey != "none" && secretKey != "prompt") {
    secretKey
  } else if (!is.null(token) && token != "none") {
    token
  } else {
    NULL
  }

  firebase_connect(
    project_id = project_id,
    api_key = projectAPI,
    database_url = projectURL,
    token = effective_token
  )
}

#' Close Firebase Connection
#'
#' Clears the connection's authentication state. Note that this doesn't
#' actually close any persistent connections since the REST API is stateless.
#'
#' @param conn Firebase connection object
#' @return Updated connection with cleared auth state
#' @export
firebase_close <- function(conn) {
  if (!is_firebase_connection(conn)) {
    stop_firebase("validation", "Expected a firebase_connection object")
  }

  conn$token <- NULL
  conn
}
