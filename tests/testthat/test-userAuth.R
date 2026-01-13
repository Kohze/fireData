# Integration tests for user authentication
# These tests require Firebase credentials set via environment variables:
#   FIREDATA_TEST_API_KEY
#   FIREDATA_TEST_EMAIL
#   FIREDATA_TEST_PASSWORD
#   FIREDATA_RUN_INTEGRATION_TESTS=true

test_that("auth_sign_in works with valid credentials", {
  skip_if_no_integration()

  api_key <- get_test_api_key()
  email <- get_test_email()
  password <- get_test_password()

  response <- auth_sign_in(api_key = api_key, email = email, password = password)

  expect_true("idToken" %in% names(response))
  expect_true("refreshToken" %in% names(response))
  expect_equal(response$email, email)
})

test_that("auth_anonymous returns valid token", {
  skip_if_no_integration()

  api_key <- get_test_api_key()

  response <- auth_anonymous(api_key = api_key)

  expect_true("idToken" %in% names(response))
  expect_true("localId" %in% names(response))
})

test_that("auth_reset_password warns for unknown email", {
  skip_if_no_integration()

  api_key <- get_test_api_key()
  email <- paste0("unknown_", Sys.time(), "@example.com")

  expect_warning(
    auth_reset_password(api_key = api_key, email = email),
    "not found"
  )
})

test_that("auth_create_user creates new user", {
  skip_if_no_integration()

  api_key <- get_test_api_key()
  # Generate unique email for test
  email <- paste0("test_", as.integer(Sys.time()), "_", sample(1000:9999, 1), "@example.com")
  password <- "TestPassword123!"

  response <- auth_create_user(api_key = api_key, email = email, password = password)

  expect_true("email" %in% names(response))
  expect_equal(response$email, email)
})

# Legacy function tests (for backward compatibility)
test_that("Legacy auth() function still works", {
  skip_if_no_integration()

  api_key <- get_test_api_key()
  email <- get_test_email()
  password <- get_test_password()

  # Should warn about deprecation but still work
  expect_warning(
    response <- auth(projectAPI = api_key, email = email, password = password),
    "deprecated"
  )

  expect_true("idToken" %in% names(response))
})

test_that("Legacy anonymous_login() function still works", {
  skip_if_no_integration()

  api_key <- get_test_api_key()

  expect_warning(
    response <- anonymous_login(project_api = api_key),
    "deprecated"
  )

  expect_true("idToken" %in% names(response))
})
