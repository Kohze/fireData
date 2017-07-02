library("testthat")
library("fireData")


test_that("Test the Firebase upload functionality", {
  response = fireData::upload(mtcars,"https://firedata-efa5a.firebaseio.com",directory = "test")
  expect_identical(names(response), "name")
})

test_that("Test the Firebase download functionality", {
  response = fireData::download("https://firedata-efa5a.firebaseio.com/directory","-KnsrqkNIDOFa993pcI9")
  responseDataFrame = fromJSON(response)
  expect_true(is.data.frame(responseDataFrame))
})


test_that("Test the firebase backup functionality", {
  response = DataBackup(projectURL = "https://firedata-efa5a.firebaseio.com",
                        secretKey = "2bYA6k72wKna90MqPGa6yuMG7jAysoDJZwJqYXsm",
                        "test.json")
  expect_equal(nchar(response), 27)
})
