library("testthat")
library("fireData")

test_that("Test path remapping", {
  path = "abc./d}e"
  expect_warning(path_check("abc./d}e"))
})

