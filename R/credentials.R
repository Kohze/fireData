#' @title Credential Management for fireData
#' @description Provides credential storage, retrieval, and token management
#' @name firebase_credentials
NULL

#' Firebase Token Class
#'
#' Represents an authenticated Firebase token with automatic refresh capability.
#'
#' @export
FirebaseToken <- R6::R6Class(
  "FirebaseToken",
  public = list(
    #' @field id_token Firebase ID token (JWT)
    id_token = NULL,
    #' @field refresh_token Refresh token for obtaining new ID tokens
    refresh_token = NULL,
    #' @field local_id User's local ID (UID)
    local_id = NULL,
    #' @field email User's email (if available)
    email = NULL,
    #' @field expires_at POSIXct timestamp when the token expires
    expires_at = NULL,
    #' @field api_key Firebase API key (needed for refresh)
    api_key = NULL,

    #' Create a new FirebaseToken
    #'
    #' @param auth_response Response from Firebase auth API
    #' @param api_key Firebase API key for token refresh
    #' @return A new FirebaseToken object
    initialize = function(auth_response, api_key = NULL) {
      self$id_token <- auth_response$idToken
      self$refresh_token <- auth_response$refreshToken
      self$local_id <- auth_response$localId
      self$email <- auth_response$email
      self$api_key <- api_key

      # Calculate expiration time
      expires_in <- as.numeric(auth_response$expiresIn %||% 3600)
      self$expires_at <- Sys.time() + expires_in
    },

    #' Check if token is expired
    #'
    #' @param buffer_seconds Seconds before actual expiry to consider expired
    #' @return TRUE if token is expired or will expire within buffer
    is_expired = function(buffer_seconds = 300) {
      if (is.null(self$expires_at)) {
        return(TRUE)
      }
      Sys.time() >= (self$expires_at - buffer_seconds)
    },

    #' Refresh the token if expired
    #'
    #' @param force Force refresh even if not expired
    #' @return Self (invisibly)
    refresh = function(force = FALSE) {
      if (!force && !self$is_expired()) {
        return(invisible(self))
      }

      if (is.null(self$refresh_token)) {
        stop_firebase("auth", "Cannot refresh: no refresh token available")
      }

      if (is.null(self$api_key)) {
        self$api_key <- firebase_config_get("api_key")
      }

      if (is.null(self$api_key)) {
        stop_firebase("auth", "Cannot refresh: API key not available")
      }

      # Call token refresh endpoint
      url <- build_token_url(self$api_key)
      response <- firebase_post(
        url = url,
        body = list(
          grant_type = "refresh_token",
          refresh_token = self$refresh_token
        ),
        encode = "form"
      )

      # Update token fields
      self$id_token <- response$id_token
      self$refresh_token <- response$refresh_token
      expires_in <- as.numeric(response$expires_in %||% 3600)
      self$expires_at <- Sys.time() + expires_in

      invisible(self)
    },

    #' Get the current valid token
    #'
    #' Automatically refreshes if expired.
    #'
    #' @return The ID token string
    get_token = function() {
      if (self$is_expired()) {
        self$refresh()
      }
      self$id_token
    },

    #' Print token summary
    #'
    #' @param ... Ignored
    print = function(...) {
      cat("<FirebaseToken>\n")
      cat("  User ID:", self$local_id %||% "(unknown)", "\n")
      if (!is.null(self$email)) {
        cat("  Email:", self$email, "\n")
      }
      cat("  Expires:", format(self$expires_at), "\n")
      cat("  Expired:", self$is_expired(0), "\n")
      invisible(self)
    }
  )
)

#' Create Firebase Token from Auth Response
#'
#' Factory function to create a FirebaseToken from an authentication response.
#'
#' @param auth_response Response from Firebase auth API
#' @param api_key Firebase API key for token refresh
#' @return A FirebaseToken object
#' @export
#' @examples
#' \dontrun{
#' # After successful authentication
#' response <- auth_sign_in(conn, "user@example.com", "password")
#' token <- create_token(response, api_key = "your-api-key")
#' }
create_token <- function(auth_response, api_key = NULL) {
  if (is.null(auth_response$idToken)) {
    stop_firebase("auth", "Invalid auth response: missing idToken")
  }
  FirebaseToken$new(auth_response, api_key)
}

#' OAuth2 Token Helpers
#'
#' Functions to obtain OAuth2 tokens for various Google/Firebase services.
#' @name oauth_helpers
NULL

#' Get OAuth2 Token for Google APIs
#'
#' Creates an OAuth2 token for accessing Google APIs.
#'
#' @param client_id OAuth2 client ID
#' @param client_secret OAuth2 client secret
#' @param scopes OAuth2 scopes to request
#' @param cache Whether to cache the token
#' @return An httr OAuth2 token object
#' @keywords internal
get_oauth_token <- function(client_id, client_secret, scopes, cache = FALSE) {
  # Resolve credentials from config if needed
  client_id <- prompt_if_missing(client_id, "client_id", "Web Client ID")
  client_secret <- prompt_if_missing(client_secret, "client_secret", "Web Client Secret")

  if (is.null(client_id) || is.null(client_secret)) {
    stop_firebase("validation", "OAuth client_id and client_secret are required")
  }

  app <- httr::oauth_app(
    "google",
    key = client_id,
    secret = client_secret
  )

  httr::oauth2.0_token(
    httr::oauth_endpoints("google"),
    app,
    scope = scopes,
    cache = cache
  )
}

#' Service Account Credentials
#'
#' Represents credentials from a Google service account.
#'
#' @export
ServiceAccountCredentials <- R6::R6Class(
  "ServiceAccountCredentials",
  public = list(
    #' @field project_id GCP project ID from service account
    project_id = NULL,
    #' @field client_email Service account email address
    client_email = NULL,
    #' @field private_key RSA private key for signing JWTs
    private_key = NULL,
    #' @field access_token Current OAuth access token
    access_token = NULL,
    #' @field token_expires_at Access token expiration time
    token_expires_at = NULL,

    #' Create from service account JSON file
    #'
    #' @param path Path to service account JSON file
    #' @return A new ServiceAccountCredentials object
    initialize = function(path = NULL) {
      if (is.null(path)) {
        path <- firebase_config_get("service_account")
      }

      if (is.null(path)) {
        # Try inline JSON from environment
        json_str <- firebase_config_get("service_account_json")
        if (!is.null(json_str)) {
          sa <- jsonlite::fromJSON(json_str)
        } else {
          stop_firebase("validation", "Service account path or JSON not provided")
        }
      } else {
        if (!file.exists(path)) {
          stop_firebase("validation", paste("Service account file not found:", path))
        }
        sa <- jsonlite::fromJSON(path)
      }

      self$project_id <- sa$project_id
      self$client_email <- sa$client_email
      self$private_key <- sa$private_key
    },

    #' Get an access token
    #'
    #' @param scopes OAuth2 scopes to request
    #' @return Access token string
    get_access_token = function(scopes = c(
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/datastore",
      "https://www.googleapis.com/auth/devstorage.read_write"
    )) {
      # Check if current token is still valid
      if (!is.null(self$access_token) && !is.null(self$token_expires_at)) {
        if (Sys.time() < self$token_expires_at - 60) {
          return(self$access_token)
        }
      }

      # Create JWT
      jwt <- self$create_jwt(scopes)

      # Exchange for access token
      response <- httr::POST(
        "https://oauth2.googleapis.com/token",
        body = list(
          grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer",
          assertion = jwt
        ),
        encode = "form"
      )

      if (httr::http_error(response)) {
        stop(parse_firebase_error(response))
      }

      content <- httr::content(response)
      self$access_token <- content$access_token
      self$token_expires_at <- Sys.time() + as.numeric(content$expires_in %||% 3600)

      self$access_token
    },

    #' Create a signed JWT
    #'
    #' @param scopes OAuth2 scopes
    #' @param lifetime Token lifetime in seconds
    #' @return Signed JWT string
    #' @keywords internal
    create_jwt = function(scopes, lifetime = 3600) {
      now <- as.numeric(Sys.time())

      header <- list(alg = "RS256", typ = "JWT")
      claims <- list(
        iss = self$client_email,
        sub = self$client_email,
        aud = "https://oauth2.googleapis.com/token",
        iat = now,
        exp = now + lifetime,
        scope = paste(scopes, collapse = " ")
      )

      # Base64URL encode
      header_b64 <- base64url_encode(jsonlite::toJSON(header, auto_unbox = TRUE))
      claims_b64 <- base64url_encode(jsonlite::toJSON(claims, auto_unbox = TRUE))

      signing_input <- paste(header_b64, claims_b64, sep = ".")

      # Sign with private key
      key <- openssl::read_key(self$private_key)
      signature <- openssl::signature_create(
        charToRaw(signing_input),
        key,
        hash = "sha256"
      )
      signature_b64 <- base64url_encode(signature)

      paste(signing_input, signature_b64, sep = ".")
    },

    #' Print credentials summary
    #' @param ... Ignored
    print = function(...) {
      cat("<ServiceAccountCredentials>\n")
      cat("  Project ID:", self$project_id %||% "(unknown)", "\n")
      cat("  Client Email:", self$client_email %||% "(unknown)", "\n")
      cat("  Has Access Token:", !is.null(self$access_token), "\n")
      invisible(self)
    }
  )
)

#' Base64URL Encode
#'
#' @param data Raw bytes or string to encode
#' @return Base64URL encoded string
#' @keywords internal
base64url_encode <- function(data) {
  if (is.character(data)) {
    data <- charToRaw(data)
  }
  b64 <- jsonlite::base64_enc(data)
  # Convert to URL-safe base64
  b64 <- gsub("\\+", "-", b64)
  b64 <- gsub("/", "_", b64)
  gsub("=+$", "", b64)
}

#' Load Service Account Credentials
#'
#' Creates ServiceAccountCredentials from a file or environment.
#'
#' @param path Path to service account JSON file (optional)
#' @return A ServiceAccountCredentials object
#' @export
#' @examples
#' \dontrun{
#' # From file
#' creds <- load_service_account("path/to/service-account.json")
#'
#' # From GOOGLE_APPLICATION_CREDENTIALS environment variable
#' creds <- load_service_account()
#' }
load_service_account <- function(path = NULL) {
  ServiceAccountCredentials$new(path)
}

#' Resolve Credentials
#'
#' Attempts to resolve credentials from various sources:
#' 1. Explicitly provided token/credentials
#' 2. Service account from environment
#' 3. Cached user credentials
#' 4. Interactive OAuth (if in interactive session)
#'
#' @param token Existing token or NULL
#' @param service_account Path to service account JSON
#' @param require_auth Whether authentication is required
#' @return A token string or NULL
#' @keywords internal
resolve_credentials <- function(token = NULL,
                                service_account = NULL,
                                require_auth = FALSE) {
  # 1. Use provided token
  if (!is.null(token) && !identical(token, "none") && nzchar(token)) {
    if (inherits(token, "FirebaseToken")) {
      return(token$get_token())
    }
    return(token)
  }

  # 2. Try service account
  sa_path <- service_account %||% firebase_config_get("service_account")
  if (!is.null(sa_path)) {
    tryCatch({
      creds <- ServiceAccountCredentials$new(sa_path)
      return(creds$get_access_token())
    }, error = function(e) {
      warning("Failed to load service account: ", conditionMessage(e))
    })
  }

  # 3. No credentials available
  if (require_auth) {
    stop_firebase("auth", "Authentication required but no credentials available")
  }

  NULL
}
