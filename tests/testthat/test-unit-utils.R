# Unit tests for utility functions
# These tests don't require Firebase credentials

test_that("path_sanitize replaces invalid characters", {
  expect_warning(result <- path_sanitize("path/with/slash"))
  expect_equal(result, "path-with-slash")

  expect_warning(result <- path_sanitize("path.with.dots"))
  expect_equal(result, "path-with-dots")

  expect_warning(result <- path_sanitize("path$dollar"))
  expect_equal(result, "path-dollar")

  expect_warning(result <- path_sanitize("path#hash"))
  expect_equal(result, "path-hash")

  expect_warning(result <- path_sanitize("path[bracket]"))
  expect_equal(result, "path-bracket-")
})

test_that("path_sanitize passes valid paths unchanged", {
  expect_silent(result <- path_sanitize("valid-path"))
  expect_equal(result, "valid-path")

  expect_silent(result <- path_sanitize("valid_path"))
  expect_equal(result, "valid_path")

  expect_silent(result <- path_sanitize("validPath123"))
  expect_equal(result, "validPath123")
})

test_that("path_sanitize handles empty strings", {
  expect_equal(path_sanitize(""), "")
  expect_equal(path_sanitize(NULL), NULL)
})

test_that("file_conversion passes non-S4 objects unchanged", {
  df <- data.frame(a = 1:3, b = letters[1:3])
  result <- fireData:::file_conversion(df)
  expect_identical(result, df)

  lst <- list(x = 1, y = "test")
  result <- fireData:::file_conversion(lst)
  expect_identical(result, lst)
})

test_that("clean_path removes leading and trailing slashes", {
  expect_equal(fireData:::clean_path("/path/to/data/"), "path/to/data")
  expect_equal(fireData:::clean_path("///path///"), "path")
  expect_equal(fireData:::clean_path("path"), "path")
  expect_equal(fireData:::clean_path(NULL), "")
})

test_that("combine_paths joins path segments", {
  expect_equal(fireData:::combine_paths("a", "b", "c"), "a/b/c")
  expect_equal(fireData:::combine_paths("/a/", "/b/", "/c/"), "a/b/c")
  expect_equal(fireData:::combine_paths("users", "user123"), "users/user123")
})

test_that("is_valid_email validates email format", {
  expect_true(fireData:::is_valid_email("user@example.com"))
  expect_true(fireData:::is_valid_email("user.name@example.co.uk"))
  expect_false(fireData:::is_valid_email("invalid"))
  expect_false(fireData:::is_valid_email("@example.com"))
  expect_false(fireData:::is_valid_email(""))
  expect_false(fireData:::is_valid_email(NULL))
})

test_that("format_bytes formats correctly", {
  expect_equal(fireData:::format_bytes(500), "500 B")
  expect_equal(fireData:::format_bytes(1024), "1 KB")
  expect_equal(fireData:::format_bytes(1536), "1.5 KB")
  expect_equal(fireData:::format_bytes(1048576), "1 MB")
  expect_equal(fireData:::format_bytes(NULL), "unknown")
})

test_that("generate_id creates unique IDs", {
  id1 <- fireData:::generate_id()
  id2 <- fireData:::generate_id()

  expect_equal(nchar(id1), 20)
  expect_equal(nchar(id2), 20)
  expect_false(id1 == id2)

  # Custom length
  id_short <- fireData:::generate_id(10)
  expect_equal(nchar(id_short), 10)
})
