# Unit tests for path remapping and class conversion
# These tests don't require Firebase credentials

test_that("path_check warns on invalid characters (legacy)", {
  expect_warning(path_check("abc./d}e"))
  expect_warning(path_check("path/with/slash"))
  expect_warning(path_check("path.with.dots"))
})

test_that("path_sanitize replaces invalid characters", {
  expect_warning(result <- path_sanitize("abc./d}e"))
  expect_false(grepl("[./}]", result))
})

test_that("classConversion converts S4 objects to base64", {
  # Create a simple S4 class for testing
  setClass("TestS4", slots = list(x = "numeric", y = "character"))
  test_obj <- new("TestS4", x = 1:3, y = "test")

  conversion <- fireData:::classConversion(test_obj)

  expect_true(is.list(conversion))
  expect_true("base64Set" %in% names(conversion))
  expect_true(nchar(conversion$base64Set) > 0)

  # Clean up
  removeClass("TestS4")
})

test_that("class_conversion can be reversed with class_restore", {
  # Create S4 class
  setClass("TestRestore", slots = list(value = "numeric"))
  original <- new("TestRestore", value = 42)

  # Convert to base64
  encoded <- fireData:::class_conversion(original)

  # Restore
  restored <- fireData:::class_restore(encoded)

  expect_s4_class(restored, "TestRestore")
  expect_equal(restored@value, 42)

  # Clean up
  removeClass("TestRestore")
})

test_that("is_encoded_s4 detects base64-encoded S4 objects", {
  encoded <- list(base64Set = "some_base64_data")
  not_encoded <- list(data = "regular data")

  expect_true(fireData:::is_encoded_s4(encoded))
  expect_false(fireData:::is_encoded_s4(not_encoded))
  expect_false(fireData:::is_encoded_s4("string"))
  expect_false(fireData:::is_encoded_s4(NULL))
})
