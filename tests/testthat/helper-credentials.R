# Test helper for credentials
# NEVER hardcode credentials - use environment variables

#' Get test API key from environment
#' @return API key or skips test if not set
get_test_api_key <- function() {
  api_key <- Sys.getenv("FIREDATA_TEST_API_KEY", unset = NA)
  if (is.na(api_key)) {
    testthat::skip("FIREDATA_TEST_API_KEY not set - skipping test requiring Firebase credentials")
  }
  api_key
}

#' Get test project URL from environment
#' @return Project URL or skips test if not set
get_test_project_url <- function() {
  url <- Sys.getenv("FIREDATA_TEST_PROJECT_URL", unset = NA)
  if (is.na(url)) {
    testthat::skip("FIREDATA_TEST_PROJECT_URL not set - skipping test requiring Firebase credentials")
  }
  url
}

#' Get test project ID from environment
#' @return Project ID or skips test if not set
get_test_project_id <- function() {
  project_id <- Sys.getenv("FIREDATA_TEST_PROJECT_ID", unset = NA)
  if (is.na(project_id)) {
    testthat::skip("FIREDATA_TEST_PROJECT_ID not set - skipping test requiring Firebase credentials")
  }
  project_id
}

#' Get test email from environment
#' @return Email or skips test if not set
get_test_email <- function() {
  email <- Sys.getenv("FIREDATA_TEST_EMAIL", unset = NA)
  if (is.na(email)) {
    testthat::skip("FIREDATA_TEST_EMAIL not set - skipping integration test")
  }
  email
}

#' Get test password from environment
#' @return Password or skips test if not set
get_test_password <- function() {
  password <- Sys.getenv("FIREDATA_TEST_PASSWORD", unset = NA)
  if (is.na(password)) {
    testthat::skip("FIREDATA_TEST_PASSWORD not set - skipping integration test")
  }
  password
}

#' Check if integration tests should run
#' @return TRUE if FIREDATA_RUN_INTEGRATION_TESTS is set to "true"
should_run_integration_tests <- function() {
  Sys.getenv("FIREDATA_RUN_INTEGRATION_TESTS", unset = "false") == "true"
}

#' Skip if not running integration tests
skip_if_no_integration <- function() {
  if (!should_run_integration_tests()) {
    testthat::skip("Integration tests disabled. Set FIREDATA_RUN_INTEGRATION_TESTS=true to enable.")
  }
}

#' Create a test connection (skips if no credentials)
#' @return A firebase_connection object
get_test_connection <- function() {
  api_key <- get_test_api_key()
  project_url <- get_test_project_url()

  # Try to get project ID for Firestore support
  project_id <- Sys.getenv("FIREDATA_TEST_PROJECT_ID", unset = NA)

  firebase_connect(
    api_key = api_key,
    database_url = project_url,
    project_id = if (is.na(project_id)) NULL else project_id
  )
}
