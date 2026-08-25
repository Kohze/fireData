# Unit tests for configuration management
# These tests don't require Firebase credentials

test_that("firebase_config_set and firebase_config_get work correctly", {
  # Clear any existing config
  firebase_config_clear()

  # Set config
  firebase_config_set(project_id = "test-project", api_key = "test-key")

  # Get config
  expect_equal(firebase_config_get("project_id"), "test-project")
  expect_equal(firebase_config_get("api_key"), "test-key")

  # Clear and verify
  firebase_config_clear()
  expect_null(firebase_config_get("project_id"))
  expect_null(firebase_config_get("api_key"))
})

test_that("firebase_config_get respects priority order", {
  # Clear existing config
  firebase_config_clear()

  # Set session config
  firebase_config_set(project_id = "session-project")

  # Explicit value should take priority
  result <- firebase_config_get("project_id", value = "explicit-project")
  expect_equal(result, "explicit-project")

  # Session config should be returned when no explicit value
  result <- firebase_config_get("project_id")
  expect_equal(result, "session-project")

  # Cleanup
  firebase_config_clear()
})

test_that("firebase_config_get returns default when not set", {
  firebase_config_clear()

  result <- firebase_config_get("nonexistent_key", default = "default-value")
  expect_equal(result, "default-value")

  result <- firebase_config_get("nonexistent_key")
  expect_null(result)
})

test_that("firebase_config_set warns on unknown keys", {
  expect_warning(
    firebase_config_set(unknown_key = "value"),
    "Unknown configuration key"
  )
})

test_that("firebase_config_clear works for specific keys", {
  firebase_config_set(project_id = "project1", api_key = "key1")

  firebase_config_clear("project_id")

  expect_null(firebase_config_get("project_id"))
  expect_equal(firebase_config_get("api_key"), "key1")

  firebase_config_clear()
})

test_that("firebase_connect uses the current default Storage bucket format", {
  firebase_config_clear()
  conn <- firebase_connect(project_id = "test-project")

  expect_equal(conn$storage_bucket, "test-project.firebasestorage.app")
})

test_that("firebase_connect preserves an explicit legacy Storage bucket", {
  firebase_config_clear()
  conn <- firebase_connect(
    project_id = "test-project",
    storage_bucket = "test-project.appspot.com"
  )

  expect_equal(conn$storage_bucket, "test-project.appspot.com")
})

test_that("Dynamic Links helpers fail without making obsolete requests", {
  expect_error(
    dynlink_create(
      link = "https://example.com",
      domain_uri_prefix = "https://example.page.link"
    ),
    "shut down on August 25, 2025",
    class = "firebase_validation_error"
  )
})

test_that("Storage upload URLs omit ACLs by default", {
  url <- fireData:::build_storage_upload_url(
    "test-project.firebasestorage.app",
    "images/example file.jpg"
  )

  expect_match(url, "images%2Fexample%20file.jpg", fixed = TRUE)
  expect_false(grepl("predefinedAcl", url, fixed = TRUE))

  public_url <- fireData:::build_storage_upload_url(
    "test-project.appspot.com",
    "public/example.jpg",
    predefined_acl = "publicRead"
  )
  expect_match(public_url, "predefinedAcl=publicRead", fixed = TRUE)
})

test_that("service account tokens are cached separately by scope", {
  credentials_file <- tempfile(fileext = ".json")
  on.exit(unlink(credentials_file), add = TRUE)
  jsonlite::write_json(
    list(
      project_id = "test-project",
      client_email = "test@test-project.iam.gserviceaccount.com",
      private_key = "unused-in-cache-test"
    ),
    credentials_file,
    auto_unbox = TRUE
  )

  credentials <- ServiceAccountCredentials$new(credentials_file)
  credentials$token_cache[["scope-a"]] <- list(
    access_token = "token-a",
    expires_at = Sys.time() + 3600
  )
  credentials$token_cache[["scope-b"]] <- list(
    access_token = "token-b",
    expires_at = Sys.time() + 3600
  )

  expect_equal(credentials$get_access_token("scope-a"), "token-a")
  expect_equal(credentials$get_access_token("scope-b"), "token-b")
})
