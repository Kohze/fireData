# Unit tests for Cloud Firestore
# These tests don't require Firebase credentials

test_that("firestore_encode_value handles NULL", {
 result <- fireData:::firestore_encode_value(NULL)
 expect_true("nullValue" %in% names(result))
})

test_that("firestore_encode_value handles logical values", {
 result <- fireData:::firestore_encode_value(TRUE)
 expect_equal(result$booleanValue, TRUE)

 result <- fireData:::firestore_encode_value(FALSE)
 expect_equal(result$booleanValue, FALSE)
})

test_that("firestore_encode_value handles integer values", {
 result <- fireData:::firestore_encode_value(42L)
 expect_equal(result$integerValue, "42")
})

test_that("firestore_encode_value handles numeric values", {
 result <- fireData:::firestore_encode_value(3.14)
 expect_equal(result$doubleValue, 3.14)
})

test_that("firestore_encode_value handles character values", {
 result <- fireData:::firestore_encode_value("hello")
 expect_equal(result$stringValue, "hello")
})

test_that("firestore_encode_value handles POSIXct timestamps", {
 time <- as.POSIXct("2024-01-15 12:00:00", tz = "UTC")
 result <- fireData:::firestore_encode_value(time)
 expect_true("timestampValue" %in% names(result))
 expect_true(grepl("2024-01-15", result$timestampValue))
})

test_that("firestore_encode_value handles named lists as maps", {
 data <- list(name = "John", age = 30)
 result <- fireData:::firestore_encode_value(data)
 expect_true("mapValue" %in% names(result))
 expect_true("fields" %in% names(result$mapValue))
})

test_that("firestore_encode_value handles vectors as arrays", {
 data <- c(1, 2, 3)
 result <- fireData:::firestore_encode_value(data)
 expect_true("arrayValue" %in% names(result))
 expect_equal(length(result$arrayValue$values), 3)
})

test_that("firestore_encode_fields converts R list to Firestore fields", {
 data <- list(
   name = "Test",
   count = 42L,
   active = TRUE,
   score = 98.5
 )
 result <- fireData:::firestore_encode_fields(data)

 expect_equal(result$name$stringValue, "Test")
 expect_equal(result$count$integerValue, "42")
 expect_equal(result$active$booleanValue, TRUE)
 expect_equal(result$score$doubleValue, 98.5)
})

test_that("firestore_decode_value handles all basic types", {
 # Null
 expect_null(fireData:::firestore_decode_value(list(nullValue = NULL)))

 # Boolean
 expect_equal(fireData:::firestore_decode_value(list(booleanValue = TRUE)), TRUE)

 # Integer
 expect_equal(fireData:::firestore_decode_value(list(integerValue = "42")), 42L)

 # Double
 expect_equal(fireData:::firestore_decode_value(list(doubleValue = 3.14)), 3.14)

 # String
 expect_equal(fireData:::firestore_decode_value(list(stringValue = "test")), "test")
})

test_that("firestore_decode_value handles arrays", {
 value <- list(arrayValue = list(values = list(
   list(integerValue = "1"),
   list(integerValue = "2"),
   list(integerValue = "3")
 )))
 result <- fireData:::firestore_decode_value(value)
 expect_equal(result, list(1L, 2L, 3L))
})

test_that("firestore_decode_value handles maps", {
 value <- list(mapValue = list(fields = list(
   name = list(stringValue = "John"),
   age = list(integerValue = "30")
 )))
 result <- fireData:::firestore_decode_value(value)
 expect_equal(result$name, "John")
 expect_equal(result$age, 30L)
})

test_that("firestore_parse_document extracts document ID", {
 doc <- list(
   name = "projects/test/databases/(default)/documents/users/user123",
   fields = list(
     name = list(stringValue = "Test User")
   ),
   createTime = "2024-01-15T12:00:00.000Z",
   updateTime = "2024-01-15T12:00:00.000Z"
 )
 result <- fireData:::firestore_parse_document(doc)

 expect_equal(result$.id, "user123")
 expect_equal(result$name, "Test User")
 expect_true(".createTime" %in% names(result))
 expect_true(".updateTime" %in% names(result))
})

test_that("firestore_query creates query object", {
 firebase_config_set(project_id = "test-project")

 query <- firestore_query(collection = "users")

 expect_s3_class(query, "firestore_query")
 expect_equal(query$collection, "users")
 expect_equal(query$project_id, "test-project")

 firebase_config_clear()
})

test_that("fs_where adds filter to query", {
 firebase_config_set(project_id = "test-project")

 query <- firestore_query(collection = "users") |>
   fs_where("age", ">=", 18)

 expect_equal(length(query$filters), 1)
 expect_equal(query$filters[[1]]$fieldFilter$op, "GREATER_THAN_OR_EQUAL")

 firebase_config_clear()
})

test_that("fs_where supports all operators", {
 firebase_config_set(project_id = "test-project")

 operators <- c("==", "!=", "<", "<=", ">", ">=",
                "array-contains", "array-contains-any", "in", "not-in")

 for (op in operators) {
   query <- firestore_query(collection = "test") |>
     fs_where("field", op, "value")
   expect_equal(length(query$filters), 1,
                info = sprintf("Operator %s should work", op))
 }

 firebase_config_clear()
})

test_that("fs_order_by adds ordering to query", {
 firebase_config_set(project_id = "test-project")

 query <- firestore_query(collection = "users") |>
   fs_order_by("name", "asc") |>
   fs_order_by("age", "desc")

 expect_equal(length(query$order_by), 2)
 expect_equal(query$order_by[[1]]$direction, "ASCENDING")
 expect_equal(query$order_by[[2]]$direction, "DESCENDING")

 firebase_config_clear()
})

test_that("fs_limit sets limit on query", {
 firebase_config_set(project_id = "test-project")

 query <- firestore_query(collection = "users") |>
   fs_limit(10)

 expect_equal(query$limit, 10L)

 firebase_config_clear()
})

test_that("fs_offset sets offset on query", {
 firebase_config_set(project_id = "test-project")

 query <- firestore_query(collection = "users") |>
   fs_offset(20)

 expect_equal(query$offset, 20L)

 firebase_config_clear()
})

test_that("fs_select sets field selection on query", {
 firebase_config_set(project_id = "test-project")

 query <- firestore_query(collection = "users") |>
   fs_select("name", "email")

 expect_equal(query$select_fields, c("name", "email"))

 firebase_config_clear()
})

test_that("build_firestore_document_url constructs correct URL", {
 url <- fireData:::build_firestore_document_url("my-project", "users", "user123")
 expect_true(grepl("my-project", url))
 expect_true(grepl("users/user123", url))
 expect_true(grepl("firestore.googleapis.com", url))
})

test_that("build_firestore_collection_url constructs correct URL", {
 url <- fireData:::build_firestore_collection_url("my-project", "users")
 expect_true(grepl("my-project", url))
 expect_true(grepl("/users$", url))
})

test_that("firestore functions require project_id", {
 firebase_config_clear()

 expect_error(
   firestore_get(collection = "test", document = "doc1"),
   "project_id is required"
 )

 expect_error(
   firestore_set(collection = "test", document = "doc1", data = list(x = 1)),
   "project_id is required"
 )

 expect_error(
   firestore_add(collection = "test", data = list(x = 1)),
   "project_id is required"
 )
})
