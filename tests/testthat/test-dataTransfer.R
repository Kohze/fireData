# Integration tests for data transfer (CRUD operations)
# These tests require Firebase credentials set via environment variables:
#   FIREDATA_TEST_API_KEY
#   FIREDATA_TEST_PROJECT_URL
#   FIREDATA_RUN_INTEGRATION_TESTS=true

test_that("rtdb_push and rtdb_get work correctly", {
  skip_if_no_integration()

  conn <- get_test_connection()

  # Create test data
  test_data <- list(
    name = "Test User",
    value = 42,
    timestamp = as.character(Sys.time())
  )

  # Push data
  result_path <- rtdb_push(conn, "test_data", test_data)
  expect_true(grepl("^test_data/", result_path))

  # Extract the key
  key <- sub("test_data/", "", result_path)

  # Get data back
  retrieved <- rtdb_get(conn, paste0("test_data/", key))

  expect_equal(retrieved$name, test_data$name)
  expect_equal(retrieved$value, test_data$value)

  # Clean up
  rtdb_delete(conn, paste0("test_data/", key))
})

test_that("rtdb_set overwrites data", {
  skip_if_no_integration()

  conn <- get_test_connection()
  test_path <- paste0("test_set_", as.integer(Sys.time()))

  # Set initial data
  rtdb_set(conn, test_path, list(a = 1, b = 2))

  # Overwrite with new data
  rtdb_set(conn, test_path, list(c = 3))

  # Get data - should only have c, not a or b
  retrieved <- rtdb_get(conn, test_path)
  expect_equal(retrieved$c, 3)
  expect_null(retrieved$a)
  expect_null(retrieved$b)

  # Clean up
  rtdb_delete(conn, test_path)
})

test_that("rtdb_update merges data", {
  skip_if_no_integration()

  conn <- get_test_connection()
  test_path <- paste0("test_update_", as.integer(Sys.time()))

  # Set initial data
  rtdb_set(conn, test_path, list(a = 1, b = 2))

  # Update with partial data
  rtdb_update(conn, test_path, list(b = 20, c = 3))

  # Get data - should have merged values
  retrieved <- rtdb_get(conn, test_path)
  expect_equal(retrieved$a, 1)   # Unchanged
  expect_equal(retrieved$b, 20)  # Updated
  expect_equal(retrieved$c, 3)   # Added

  # Clean up
  rtdb_delete(conn, test_path)
})

test_that("rtdb_delete removes data", {
  skip_if_no_integration()

  conn <- get_test_connection()
  test_path <- paste0("test_delete_", as.integer(Sys.time()))

  # Create data
  rtdb_set(conn, test_path, list(data = "to delete"))

  # Verify it exists
  retrieved <- rtdb_get(conn, test_path)
  expect_false(is.null(retrieved))

  # Delete it
  rtdb_delete(conn, test_path)

  # Verify it's gone (should return NULL with warning)
  expect_warning(
    result <- rtdb_get(conn, test_path),
    "No data found"
  )
  expect_null(result)
})

test_that("rtdb_get returns NULL for nonexistent path", {
  skip_if_no_integration()

  conn <- get_test_connection()

  expect_warning(
    result <- rtdb_get(conn, "nonexistent/path/12345"),
    "No data found"
  )
  expect_null(result)
})

# Legacy function tests
test_that("Legacy upload() and download() still work", {
  skip_if_no_integration()

  project_url <- get_test_project_url()

  # Upload test data
  test_data <- data.frame(x = 1:3, y = c("a", "b", "c"))

  expect_warning(
    result_path <- upload(x = test_data, projectURL = project_url, directory = "legacy_test"),
    "deprecated"
  )
  expect_true(grepl("^legacy_test/", result_path))

  # Download
  key <- sub("legacy_test/", "", result_path)

  expect_warning(
    retrieved <- download(projectURL = project_url, fileName = paste0("legacy_test/", key)),
    "deprecated"
  )

  expect_equal(retrieved$x, test_data$x)

  # Clean up
  expect_warning(
    delete(x = test_data, projectURL = project_url, directory = paste0("legacy_test/", key)),
    "deprecated"
  )
})
