library("testthat")
library("fireData")

test_that("Test path remapping", {
  path = "abc./d}e"
  expect_warning(path_check("abc./d}e"))
})

test_that("Test class to binary conversion", {
  conversion = fireData:::classConversion(mtcars)
  expect_equal(nchar(conversion$base64Set), 1646)
})
