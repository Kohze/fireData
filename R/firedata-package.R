#' @keywords internal
"_PACKAGE"

#' fireData: Connecting R to Google Firebase
#'
#' The fireData package provides comprehensive API access to Google Firebase
#' services from R, including Realtime Database, Authentication, Cloud Storage,
#' Dynamic Links, and Shiny integration.
#'
#' @section Main Functions:
#'
#' **Connection:**
#' * [firebase_connect()] - Create a Firebase connection object
#' * [firebase_config_set()] - Set configuration for the session
#' * [firebase_config_wizard()] - Interactive configuration setup
#'
#' **Authentication:**
#' * [auth_sign_in()] - Sign in with email/password
#' * [auth_anonymous()] - Sign in anonymously
#' * [auth_create_user()] - Create new user account
#' * [auth_reset_password()] - Send password reset email
#' * [auth_google()] - Sign in with Google OAuth
#'
#' **Realtime Database:**
#' * [rtdb_get()] - Read data from database
#' * [rtdb_set()] - Write data (overwrite)
#' * [rtdb_push()] - Add data with auto-generated key
#' * [rtdb_update()] - Update specific fields
#' * [rtdb_delete()] - Delete data
#' * [rtdb_query()] - Query with filtering and sorting
#' * [rtdb_backup()] - Backup entire database
#'
#' **Cloud Storage:**
#' * [storage_upload()] - Upload file to storage
#' * [storage_download()] - Download file from storage
#' * [storage_delete()] - Delete file from storage
#' * [storage_list()] - List files in bucket
#' * [storage_get_url()] - Get download URL
#'
#' **Dynamic Links:**
#' * [dynlink_create()] - Create shortened dynamic link
#'
#' @section Getting Started:
#'
#' 1. Set up a Firebase project at \url{https://console.firebase.google.com}
#' 2. Get your project's API key from Project Settings > General
#' 3. Get your database URL from Realtime Database
#'
#' ```r
#' # Option 1: Set environment variables
#' Sys.setenv(FIREBASE_PROJECT_ID = "my-project")
#' Sys.setenv(FIREBASE_API_KEY = "AIzaSy...")
#'
#' # Option 2: Use the configuration wizard
#' firebase_config_wizard()
#'
#' # Create connection and start using Firebase
#' conn <- firebase_connect()
#' rtdb_push(conn, "messages", list(text = "Hello from R!"))
#' ```
#'
#' @section Migration from v1.x:
#'
#' Version 2.0 introduces a new API with consistent naming. The old functions
#' are deprecated but still work:
#'
#' | Old (v1.x) | New (v2.0) |
#' |------------|------------|
#' | `auth()` | `auth_sign_in()` |
#' | `upload()` | `rtdb_push()` |
#' | `download()` | `rtdb_get()` |
#' | `put()` | `rtdb_set()` |
#' | `patch()` | `rtdb_update()` |
#' | `delete()` | `rtdb_delete()` |
#' | `upload_storage()` | `storage_upload()` |
#'
#' @section Configuration:
#'
#' fireData looks for configuration in this order:
#' 1. Function arguments
#' 2. Session configuration (via [firebase_config_set()])
#' 3. Environment variables (FIREBASE_PROJECT_ID, FIREBASE_API_KEY, etc.)
#' 4. Config file (~/.firedata/config.yml)
#'
#' @section Service Account Authentication:
#'
#' For server-side and automated workflows, use a service account:
#'
#' ```r
#' # Set path to service account JSON
#' Sys.setenv(GOOGLE_APPLICATION_CREDENTIALS = "/path/to/service-account.json")
#'
#' # Or pass directly to connection
#' conn <- firebase_connect(credentials = "service-account.json")
#' ```
#'
#' @name fireData-package
#' @aliases fireData
#'
#' @importFrom httr GET POST PUT PATCH DELETE add_headers oauth_app oauth2.0_token
#'   oauth_endpoints oauth_callback upload_file content status_code http_error
#'   headers http_type
#' @importFrom jsonlite toJSON fromJSON base64_enc base64_dec
#' @importFrom curl curl_download
#' @importFrom R6 R6Class
#' @importFrom openssl read_key signature_create
#' @importFrom yaml read_yaml write_yaml
#' @importFrom stats runif
#' @importFrom utils URLencode
NULL

#' Package Startup Message
#' @keywords internal
.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "fireData 2.0.0 - Connecting R to Google Firebase\n",
    "See ?fireData for documentation or visit: https://github.com/Kohze/fireData"
  )
}

#' Package Load Hook
#' @keywords internal
.onLoad <- function(libname, pkgname) {
  # Initialize package environment
  # Nothing needed currently
  invisible()
}
