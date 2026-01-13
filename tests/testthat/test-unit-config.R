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
