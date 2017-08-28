library("testthat")
library("fireData")

projectAPI = "AIzaSyAjZLO9-CRV3gObpwdFz-k8AiTOxHSBmdc"

test_that("Test the firebase user authentication", {
  email = "robin@kohze.com"
  password = 12341234
  response = auth(projectAPI = projectAPI, email = email, password = password)
  expect_identical(response$email, "robin@kohze.com")
})

test_that("Test the email reset", {
  email = "wrong@email.com"
  expect_warning(resetPassword(projectAPI = projectAPI, email = email))
})

test_that("Test passwort reset functionality", {
  email = paste0("testMail", as.numeric(format(Sys.time(), "%OS3")) * 1000, "@googleMail.com")
  createUser(projectAPI = projectAPI, email = email, password = "12341234" )
  expect_equal(resetPassword(projectAPI = projectAPI, email = email), paste0("Password reset email was send to ", email))
}
)

test_that("Test for user creation", {
  expect_true("email" %in% names(createUser(projectAPI = projectAPI, email = paste0("testMail", as.numeric(format(Sys.time(), "%OS3")) * 1000, "@googleMail.com"), password = "12341234" )))
})


