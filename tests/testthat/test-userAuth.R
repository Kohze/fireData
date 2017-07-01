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
  expect_equal(resetPassword(projectAPI = projectAPI, email = "testacc@firedata.com"), "Password reset email was send to testacc@firedata.com")
}
)

test_that("Test for user creation", {
  expect_true("email" %in% names(createUser(projectAPI = projectAPI, email = paste0("testMail", as.numeric(format(Sys.time(), "%OS3")) * 1000, "@googleMail.com"), password = "12341234" )))
})


