#' @title Firebase Authentication Service
#' @description Functions for user authentication with Firebase Auth
#' @name firebase_auth
NULL

#' Sign In with Email and Password
#'
#' Authenticates a user with email and password credentials.
#'
#' @param conn Firebase connection object (or NULL to use config)
#' @param email User email address
#' @param password User password
#' @param api_key Firebase API key (used if conn is NULL)
#' @return Authentication response containing idToken, refreshToken, localId, email, and expiresIn
#' @export
#' @examples
#' \dontrun{
#' # With connection object
#' conn <- firebase_connect(project_id = "my-project", api_key = "AIzaSy...")
#' result <- auth_sign_in(conn, "user@example.com", "password123")
#'
#' # Update connection with token
#' conn <- firebase_set_token(conn, result)
#'
#' # Without connection (uses config/environment)
#' result <- auth_sign_in(email = "user@example.com", password = "password123")
#' }
auth_sign_in <- function(conn = NULL,
                         email = NULL,
                         password = NULL,
                         api_key = NULL) {
  # Resolve API key
  if (!is.null(conn) && is_firebase_connection(conn)) {
    api_key <- conn$api_key
  }
  api_key <- firebase_config_get("api_key", value = api_key)

  if (is.null(api_key)) {
    stop_firebase("validation", "API key is required for authentication")
  }

  # Prompt for credentials if interactive
  email <- prompt_if_missing(email, prompt = "Email")
  password <- prompt_if_missing(password, prompt = "Password")

  if (is.null(email) || is.null(password)) {
    stop_firebase("validation", "Email and password are required")
  }

  # Build URL for modern Firebase Auth API
  url <- build_auth_url("accounts:signInWithPassword", api_key)

  # Make request
  response <- firebase_post(
    url = url,
    body = list(
      email = email,
      password = password,
      returnSecureToken = TRUE
    ),
    max_retries = 1  # Don't retry auth requests
  )

  response
}

#' Sign In Anonymously
#'
#' Signs in a user anonymously. Anonymous users can be upgraded to
#' full accounts later by linking credentials.
#'
#' @param conn Firebase connection object (or NULL to use config)
#' @param api_key Firebase API key (used if conn is NULL)
#' @return Authentication response containing idToken, refreshToken, and localId
#' @export
#' @examples
#' \dontrun{
#' conn <- firebase_connect(project_id = "my-project", api_key = "AIzaSy...")
#' result <- auth_anonymous(conn)
#' }
auth_anonymous <- function(conn = NULL, api_key = NULL) {
  # Resolve API key
  if (!is.null(conn) && is_firebase_connection(conn)) {
    api_key <- conn$api_key
  }
  api_key <- firebase_config_get("api_key", value = api_key)

  if (is.null(api_key)) {
    stop_firebase("validation", "API key is required for authentication")
  }

  # Build URL
  url <- build_auth_url("accounts:signUp", api_key)

  # Make request
  firebase_post(
    url = url,
    body = list(returnSecureToken = TRUE),
    max_retries = 1
  )
}

#' Create User Account
#'
#' Creates a new user account with email and password.
#'
#' @param conn Firebase connection object (or NULL to use config)
#' @param email User email address
#' @param password User password (min 6 characters)
#' @param api_key Firebase API key (used if conn is NULL)
#' @return Registration response containing idToken, email, refreshToken, expiresIn, and localId
#' @export
#' @examples
#' \dontrun{
#' conn <- firebase_connect(project_id = "my-project", api_key = "AIzaSy...")
#' result <- auth_create_user(conn, "newuser@example.com", "password123")
#' }
auth_create_user <- function(conn = NULL,
                             email = NULL,
                             password = NULL,
                             api_key = NULL) {
  # Resolve API key
  if (!is.null(conn) && is_firebase_connection(conn)) {
    api_key <- conn$api_key
  }
  api_key <- firebase_config_get("api_key", value = api_key)

  if (is.null(api_key)) {
    stop_firebase("validation", "API key is required for user creation")
  }

  # Prompt for credentials if interactive
  email <- prompt_if_missing(email, prompt = "Email")
  password <- prompt_if_missing(password, prompt = "Password")

  if (is.null(email) || is.null(password)) {
    stop_firebase("validation", "Email and password are required")
  }

  # Build URL
  url <- build_auth_url("accounts:signUp", api_key)

  # Make request
  firebase_post(
    url = url,
    body = list(
      email = email,
      password = password,
      returnSecureToken = TRUE
    ),
    max_retries = 1
  )
}

#' Send Password Reset Email
#'
#' Sends a password reset email to the specified address.
#'
#' @param conn Firebase connection object (or NULL to use config)
#' @param email User email address
#' @param api_key Firebase API key (used if conn is NULL)
#' @return Response indicating success
#' @export
#' @examples
#' \dontrun{
#' auth_reset_password(conn, "user@example.com")
#' }
auth_reset_password <- function(conn = NULL, email, api_key = NULL) {
  # Resolve API key
  if (!is.null(conn) && is_firebase_connection(conn)) {
    api_key <- conn$api_key
  }
  api_key <- firebase_config_get("api_key", value = api_key)

  if (is.null(api_key)) {
    stop_firebase("validation", "API key is required")
  }

  if (is.null(email) || !nzchar(email)) {
    stop_firebase("validation", "Email is required")
  }

  # Build URL
  url <- build_auth_url("accounts:sendOobCode", api_key)

  # Make request
  tryCatch({
    response <- firebase_post(
      url = url,
      body = list(
        email = email,
        requestType = "PASSWORD_RESET"
      ),
      max_retries = 1
    )
    message(paste0("Password reset email sent to ", email))
    invisible(response)
  }, firebase_auth_error = function(e) {
    if (grepl("EMAIL_NOT_FOUND", e$code, ignore.case = TRUE)) {
      warning(paste0("User email ", email, " was not found in the database"))
    } else {
      stop(e)
    }
  })
}

#' Refresh Authentication Token
#'
#' Refreshes an expired ID token using a refresh token.
#'
#' @param conn Firebase connection object (or NULL to use config)
#' @param refresh_token The refresh token from initial authentication
#' @param api_key Firebase API key (used if conn is NULL)
#' @return Response containing new id_token, refresh_token, expires_in, token_type, and user_id
#' @export
#' @examples
#' \dontrun{
#' # Refresh using stored refresh token
#' new_tokens <- auth_refresh_token(conn, old_refresh_token)
#' }
auth_refresh_token <- function(conn = NULL,
                               refresh_token,
                               api_key = NULL) {
  # Resolve API key
  if (!is.null(conn) && is_firebase_connection(conn)) {
    api_key <- conn$api_key
  }
  api_key <- firebase_config_get("api_key", value = api_key)

  if (is.null(api_key)) {
    stop_firebase("validation", "API key is required")
  }

  if (is.null(refresh_token) || !nzchar(refresh_token)) {
    stop_firebase("validation", "Refresh token is required")
  }

  # Build URL for token refresh
  url <- build_token_url(api_key)

  # Make request
  firebase_post(
    url = url,
    body = list(
      grant_type = "refresh_token",
      refresh_token = refresh_token
    ),
    encode = "form",
    max_retries = 1
  )
}

#' Get Current User Data
#'
#' Retrieves account info for the currently authenticated user.
#'
#' @param conn Firebase connection object with valid token
#' @param id_token ID token (used if conn doesn't have token)
#' @param api_key Firebase API key
#' @return User account information
#' @export
#' @examples
#' \dontrun{
#' user_info <- auth_get_user(conn)
#' }
auth_get_user <- function(conn = NULL, id_token = NULL, api_key = NULL) {
  # Resolve credentials
  if (!is.null(conn) && is_firebase_connection(conn)) {
    api_key <- conn$api_key
    id_token <- id_token %||% get_connection_token(conn)
  }
  api_key <- firebase_config_get("api_key", value = api_key)

  if (is.null(api_key)) {
    stop_firebase("validation", "API key is required")
  }

  if (is.null(id_token)) {
    stop_firebase("auth", "ID token is required to get user info")
  }

  # Build URL
  url <- build_auth_url("accounts:lookup", api_key)

  # Make request
  response <- firebase_post(
    url = url,
    body = list(idToken = id_token),
    max_retries = 1
  )

  # Return first user (should be only one)
  if (!is.null(response$users) && length(response$users) > 0) {
    response$users[[1]]
  } else {
    response
  }
}

#' Update User Profile
#'
#' Updates the display name and/or photo URL of the authenticated user.
#'
#' @param conn Firebase connection object with valid token
#' @param display_name New display name (or NULL to keep current)
#' @param photo_url New photo URL (or NULL to keep current)
#' @param id_token ID token (used if conn doesn't have token)
#' @param api_key Firebase API key
#' @return Updated user data
#' @export
#' @examples
#' \dontrun{
#' auth_update_profile(conn, display_name = "John Doe")
#' }
auth_update_profile <- function(conn = NULL,
                                display_name = NULL,
                                photo_url = NULL,
                                id_token = NULL,
                                api_key = NULL) {
  # Resolve credentials
  if (!is.null(conn) && is_firebase_connection(conn)) {
    api_key <- conn$api_key
    id_token <- id_token %||% get_connection_token(conn)
  }
  api_key <- firebase_config_get("api_key", value = api_key)

  if (is.null(api_key)) {
    stop_firebase("validation", "API key is required")
  }

  if (is.null(id_token)) {
    stop_firebase("auth", "ID token is required to update profile")
  }

  # Build request body
  body <- list(idToken = id_token, returnSecureToken = TRUE)
  if (!is.null(display_name)) body$displayName <- display_name
  if (!is.null(photo_url)) body$photoUrl <- photo_url

  # Build URL
  url <- build_auth_url("accounts:update", api_key)

  # Make request
  firebase_post(url = url, body = body, max_retries = 1)
}

#' Delete User Account
#'
#' Deletes the authenticated user's account.
#'
#' @param conn Firebase connection object with valid token
#' @param id_token ID token (used if conn doesn't have token)
#' @param api_key Firebase API key
#' @return Empty response on success
#' @export
#' @examples
#' \dontrun{
#' auth_delete_user(conn)
#' }
auth_delete_user <- function(conn = NULL, id_token = NULL, api_key = NULL) {
  # Resolve credentials
  if (!is.null(conn) && is_firebase_connection(conn)) {
    api_key <- conn$api_key
    id_token <- id_token %||% get_connection_token(conn)
  }
  api_key <- firebase_config_get("api_key", value = api_key)

  if (is.null(api_key)) {
    stop_firebase("validation", "API key is required")
  }

  if (is.null(id_token)) {
    stop_firebase("auth", "ID token is required to delete user")
  }

  # Build URL
  url <- build_auth_url("accounts:delete", api_key)

  # Make request
  firebase_post(url = url, body = list(idToken = id_token), max_retries = 1)
}

#' Sign In with OAuth Credentials
#'
#' Signs in a user with OAuth credentials from a third-party provider.
#'
#' @param conn Firebase connection object (or NULL to use config)
#' @param request_uri The URI to which the IDP redirects the user back
#' @param post_body OAuth credential (ID token or access token) and provider ID
#' @param return_idp_credential Whether to return the OAuth credential
#' @param api_key Firebase API key
#' @return Authentication response
#' @export
#' @examples
#' \dontrun{
#' # After obtaining OAuth token from provider
#' post_body <- "id_token=<google_id_token>&providerId=google.com"
#' result <- auth_oauth(conn, "http://localhost", post_body)
#' }
auth_oauth <- function(conn = NULL,
                       request_uri,
                       post_body,
                       return_idp_credential = TRUE,
                       api_key = NULL) {
  # Resolve API key
  if (!is.null(conn) && is_firebase_connection(conn)) {
    api_key <- conn$api_key
  }
  api_key <- firebase_config_get("api_key", value = api_key)

  if (is.null(api_key)) {
    stop_firebase("validation", "API key is required")
  }

  # Build URL
  url <- build_auth_url("accounts:signInWithIdp", api_key)

  # Make request
  firebase_post(
    url = url,
    body = list(
      requestUri = request_uri,
      postBody = post_body,
      returnSecureToken = TRUE,
      returnIdpCredential = return_idp_credential
    ),
    max_retries = 1
  )
}

#' Sign In with Google
#'
#' Initiates Google OAuth flow and signs in to Firebase.
#'
#' @param conn Firebase connection object (or NULL to use config)
#' @param client_id Google OAuth client ID
#' @param client_secret Google OAuth client secret
#' @param request_uri Request URI for OAuth callback
#' @param redirect_uri Redirect URI (defaults to httr callback)
#' @param return_idp_credential Whether to return OAuth credentials
#' @param cache Whether to cache the OAuth token
#' @param api_key Firebase API key
#' @return Authentication response
#' @export
#' @examples
#' \dontrun{
#' result <- auth_google(
#'   conn,
#'   client_id = "your-client-id.apps.googleusercontent.com",
#'   client_secret = "your-secret",
#'   request_uri = "http://localhost"
#' )
#' }
auth_google <- function(conn = NULL,
                        client_id = NULL,
                        client_secret = NULL,
                        request_uri,
                        redirect_uri = httr::oauth_callback(),
                        return_idp_credential = TRUE,
                        cache = FALSE,
                        api_key = NULL) {
  # Resolve API key
  if (!is.null(conn) && is_firebase_connection(conn)) {
    api_key <- conn$api_key
  }
  api_key <- firebase_config_get("api_key", value = api_key)

  # Resolve OAuth credentials
  client_id <- prompt_if_missing(client_id, "client_id", "Web Client ID")
  client_secret <- prompt_if_missing(client_secret, "client_secret", "Web Client Secret")

  if (is.null(api_key)) {
    stop_firebase("validation", "API key is required")
  }

  if (is.null(client_id) || is.null(client_secret)) {
    stop_firebase("validation", "OAuth client_id and client_secret are required")
  }

  # Create OAuth app and get token
  app <- httr::oauth_app(
    "google",
    key = client_id,
    secret = client_secret,
    redirect_uri = redirect_uri
  )

  google_token <- httr::oauth2.0_token(
    httr::oauth_endpoints("google"),
    app,
    scope = "https://www.googleapis.com/auth/userinfo.profile",
    cache = cache
  )

  # Build post body with Google ID token
  post_body <- paste0("id_token=", google_token$credentials$id_token, "&providerId=google.com")

  # Exchange for Firebase token
  auth_oauth(
    conn = conn,
    request_uri = request_uri,
    post_body = post_body,
    return_idp_credential = return_idp_credential,
    api_key = api_key
  )
}

# ============================================================================
# Deprecated Legacy Functions (Backward Compatibility)
# ============================================================================

#' @title User Authentication (Legacy)
#' @description Legacy authentication function. Use auth_sign_in() instead.
#' @param projectAPI The Firebase Project API key
#' @param email User email
#' @param password User password
#' @return Authentication response
#' @export
#' @examples
#' \dontrun{
#' auth(projectAPI = "AIzaSy...", email = "user@example.com", password = "password")
#' }
auth <- function(projectAPI, email = "prompt", password = "prompt") {
  .Deprecated("auth_sign_in")

  # Handle legacy prompt behavior
  if (identical(email, "prompt") && identical(password, "prompt") && interactive()) {
    email <- readline(prompt = "Email: ")
    password <- readline(prompt = "Password: ")
    print(paste0("Connecting to ", projectAPI, ":"))
  }

  # Use legacy endpoint for full backward compatibility
  auth_url <- paste0(
    "https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=",
    projectAPI
  )

  response <- httr::POST(
    url = auth_url,
    body = list(
      email = email,
      password = password,
      returnSecureToken = "True"
    ),
    encode = "json"
  )

  httr::content(response)
}

#' @title Anonymous Login (Legacy)
#' @description Legacy anonymous login. Use auth_anonymous() instead.
#' @param project_api The Firebase Project API key
#' @return Authentication response
#' @export
anonymous_login <- function(project_api) {
  .Deprecated("auth_anonymous")

  auth_url <- paste0(
    "https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser?key=",
    project_api
  )

  response <- httr::POST(
    url = auth_url,
    body = list(returnSecureToken = "True"),
    encode = "json"
  )

  httr::content(response)
}

#' @title Create User (Legacy)
#' @description Legacy user creation. Use auth_create_user() instead.
#' @param projectAPI The Firebase Project API key
#' @param email User email
#' @param password User password
#' @return Registration response
#' @export
createUser <- function(projectAPI, email = "prompt", password = "prompt") {
  .Deprecated("auth_create_user")

  if (identical(email, "prompt") && identical(password, "prompt") && interactive()) {
    email <- readline(prompt = "Email: ")
    password <- readline(prompt = "Password: ")
    print(paste0("Connecting to ", projectAPI, ":"))
  }

  auth_url <- paste0(
    "https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser?key=",
    projectAPI
  )

  response <- httr::POST(
    url = auth_url,
    body = list(email = email, password = password),
    encode = "json"
  )

  httr::content(response)
}

#' @title Reset Password (Legacy)
#' @description Legacy password reset. Use auth_reset_password() instead.
#' @param projectAPI The Firebase Project API key
#' @param email User email
#' @return Success or warning message
#' @export
resetPassword <- function(projectAPI, email) {
  .Deprecated("auth_reset_password")

  auth_url <- paste0(
    "https://www.googleapis.com/identitytoolkit/v3/relyingparty/getOobConfirmationCode?key=",
    projectAPI
  )

  response <- httr::POST(
    url = auth_url,
    body = list(email = email, requestType = "PASSWORD_RESET"),
    encode = "json"
  )

  content <- httr::content(response)

  if ("error" %in% names(content)) {
    warning(paste0("User email ", email, " was not found in the database"))
  } else {
    print(paste0("Password reset email was send to ", email))
  }

  invisible(content)
}

#' @title OAuth Login (Legacy)
#' @description Legacy OAuth login. Use auth_oauth() instead.
#' @param project_api Firebase API key
#' @param request_uri Request URI
#' @param post_body OAuth post body
#' @param return_idp_credential Whether to return IDP credential
#' @return Authentication response
#' @export
o_auth_login <- function(project_api, request_uri, post_body, return_idp_credential) {
  .Deprecated("auth_oauth")

  auth_url <- paste0(
    "https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyAssertion?key=",
    project_api
  )

  response <- httr::POST(
    url = auth_url,
    body = list(
      requestUri = request_uri,
      postBody = post_body,
      returnSecureToken = "True",
      returnIdpCredential = return_idp_credential
    ),
    encode = "json"
  )

  httr::content(response)
}

#' @title Google Login (Legacy)
#' @description Legacy Google login. Use auth_google() instead.
#' @param project_api Firebase API key
#' @param web_client_id Google OAuth client ID
#' @param web_client_secret Google OAuth client secret
#' @param request_uri Request URI
#' @param redirect_uri Redirect URI
#' @param return_idp_credential Whether to return IDP credential
#' @param cache Whether to cache token
#' @return Authentication response
#' @export
google_login <- function(project_api,
                         web_client_id = "prompt",
                         web_client_secret = "prompt",
                         request_uri,
                         redirect_uri = httr::oauth_callback(),
                         return_idp_credential = TRUE,
                         cache = FALSE) {
  .Deprecated("auth_google")

  if (identical(web_client_id, "prompt") && identical(web_client_secret, "prompt") && interactive()) {
    web_client_id <- readline(prompt = "Web Client ID: ")
    web_client_secret <- readline(prompt = "Web Client Secret: ")
    print(paste0("Connecting to ", project_api, ":"))
  }

  app <- httr::oauth_app(
    "google",
    key = web_client_id,
    secret = web_client_secret,
    redirect_uri = redirect_uri
  )

  google_token <- httr::oauth2.0_token(
    httr::oauth_endpoints("google"),
    app,
    scope = "https://www.googleapis.com/auth/userinfo.profile",
    cache = cache
  )

  post_body <- paste0("id_token=", google_token$credentials$id_token, "&providerId=google.com")

  o_auth_login(
    project_api = project_api,
    request_uri = request_uri,
    post_body = post_body,
    return_idp_credential = return_idp_credential
  )
}
