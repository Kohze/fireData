library("testthat")
library("fireData")

test_that("Test the Firebase upload functionality / normal objects", {
  response = fireData::upload(mtcars,"https://firedata-efa5a.firebaseio.com",directory = "test")
  expect_identical(names(response), "name")
})

test_that("Test the Firebase upload functionality / s4 classes", {
  setClass("testClass", slots = list(name = "character"))
  testClassObject = new("testClass", name = "testName")
  response = fireData::upload(testClassObject,"https://firedata-efa5a.firebaseio.com",directory = "test")
  expect_identical(names(response), "name")
})

test_that("Test the Firebase download functionality", {
  response = fireData::download("https://firedata-efa5a.firebaseio.com/directory","-KnsrqkNIDOFa993pcI9")
  responseDataFrame = fromJSON(response)
  expect_true(is.data.frame(responseDataFrame))
})

test_that("Test the Firebase download functionality / with secret key", {
  response = fireData::download("https://firedata-efa5a.firebaseio.com/directory","-KnsrqkNIDOFa993pcI9", secretKey = "2bYA6k72wKna90MqPGa6yuMG7jAysoDJZwJqYXsm")
  responseDataFrame = fromJSON(response)
  expect_true(is.data.frame(responseDataFrame))
})

test_that("Test the firebase backup functionality", {
  response = dataBackup(projectURL = "https://firedata-efa5a.firebaseio.com",
                        secretKey = "2bYA6k72wKna90MqPGa6yuMG7jAysoDJZwJqYXsm",
                        "test.json")
  expect_equal(nchar(response), 27)
  file.remove("test.json")
})
