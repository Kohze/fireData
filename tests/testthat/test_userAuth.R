library("testthat")
library("fireData")

test_that("Test the firebase user authentication", {
  email = "robin@kohze.com"
  projectAPI = "AIzaSyAjZLO9-CRV3gObpwdFz-k8AiTOxHSBmdc"
  password = 12341234
  response = auth(projectAPI = projectAPI, email = email, password = password)
  expect_identical(response$email, "robin@kohze.com")

})

test_that("Test the email reset", {
  email = "wrong@email.com"
  projectAPI = "AIzaSyAjZLO9-CRV3gObpwdFz-k8AiTOxHSBmdc"
  expect_warning(resetPassword(projectAPI = projectAPI, email = email))
})
