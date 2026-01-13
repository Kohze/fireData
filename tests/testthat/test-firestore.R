# Integration tests for Cloud Firestore
# These tests require Firebase credentials set via environment variables:
#   FIREDATA_TEST_API_KEY
#   FIREDATA_TEST_PROJECT_ID
#   FIREDATA_TEST_EMAIL
#   FIREDATA_TEST_PASSWORD
#   FIREDATA_RUN_INTEGRATION_TESTS=true

test_that("firestore_set and firestore_get work correctly", {
 skip_if_no_integration()

 conn <- get_test_connection()

 # Authenticate
 api_key <- get_test_api_key()
 email <- get_test_email()
 password <- get_test_password()

 auth_result <- auth_sign_in(api_key = api_key, email = email, password = password)
 conn <- firebase_set_token(conn, auth_result)

 # Create test document
 test_id <- paste0("test_", as.integer(Sys.time()), "_", sample(1000:9999, 1))
 test_data <- list(
   name = "Test User",
   value = 42,
   active = TRUE,
   timestamp = Sys.time()
 )

 # Set document
 result <- firestore_set(conn, "firedata_tests", test_id, test_data)
 expect_equal(result$name, test_data$name)
 expect_equal(result$value, test_data$value)

 # Get document
 retrieved <- firestore_get(conn, "firedata_tests", test_id)
 expect_equal(retrieved$name, test_data$name)
 expect_equal(retrieved$value, test_data$value)
 expect_equal(retrieved$active, TRUE)

 # Clean up
 firestore_delete(conn, "firedata_tests", test_id)
})

test_that("firestore_add creates document with auto ID", {
 skip_if_no_integration()

 conn <- get_test_connection()

 # Authenticate
 api_key <- get_test_api_key()
 email <- get_test_email()
 password <- get_test_password()

 auth_result <- auth_sign_in(api_key = api_key, email = email, password = password)
 conn <- firebase_set_token(conn, auth_result)

 # Add document
 result <- firestore_add(conn, "firedata_tests", list(
   text = "Auto ID test",
   created = Sys.time()
 ))

 expect_true(".id" %in% names(result))
 expect_true(nchar(result$.id) > 0)

 # Clean up
 firestore_delete(conn, "firedata_tests", result$.id)
})

test_that("firestore_update updates specific fields", {
 skip_if_no_integration()

 conn <- get_test_connection()

 # Authenticate
 api_key <- get_test_api_key()
 email <- get_test_email()
 password <- get_test_password()

 auth_result <- auth_sign_in(api_key = api_key, email = email, password = password)
 conn <- firebase_set_token(conn, auth_result)

 # Create document
 test_id <- paste0("test_update_", as.integer(Sys.time()))
 firestore_set(conn, "firedata_tests", test_id, list(
   a = 1,
   b = 2,
   c = 3
 ))

 # Update only field b
 firestore_update(conn, "firedata_tests", test_id, list(b = 20))

 # Verify
 retrieved <- firestore_get(conn, "firedata_tests", test_id)
 expect_equal(retrieved$a, 1)
 expect_equal(retrieved$b, 20)
 expect_equal(retrieved$c, 3)

 # Clean up
 firestore_delete(conn, "firedata_tests", test_id)
})

test_that("firestore_delete removes document", {
 skip_if_no_integration()

 conn <- get_test_connection()

 # Authenticate
 api_key <- get_test_api_key()
 email <- get_test_email()
 password <- get_test_password()

 auth_result <- auth_sign_in(api_key = api_key, email = email, password = password)
 conn <- firebase_set_token(conn, auth_result)

 # Create document
 test_id <- paste0("test_delete_", as.integer(Sys.time()))
 firestore_set(conn, "firedata_tests", test_id, list(data = "to delete"))

 # Delete
 result <- firestore_delete(conn, "firedata_tests", test_id)
 expect_true(result)

 # Verify deleted
 expect_warning(
   retrieved <- firestore_get(conn, "firedata_tests", test_id),
   "not found"
 )
 expect_null(retrieved)
})

test_that("firestore_list returns documents", {
 skip_if_no_integration()

 conn <- get_test_connection()

 # Authenticate
 api_key <- get_test_api_key()
 email <- get_test_email()
 password <- get_test_password()

 auth_result <- auth_sign_in(api_key = api_key, email = email, password = password)
 conn <- firebase_set_token(conn, auth_result)

 # Create test documents
 test_ids <- c()
 for (i in 1:3) {
   test_id <- paste0("test_list_", as.integer(Sys.time()), "_", i)
   firestore_set(conn, "firedata_tests", test_id, list(index = i))
   test_ids <- c(test_ids, test_id)
 }

 # List documents
 result <- firestore_list(conn, "firedata_tests", page_size = 10)
 expect_true(is.list(result))
 expect_true("documents" %in% names(result))
 expect_true(length(result$documents) >= 3)

 # Clean up
 for (test_id in test_ids) {
   firestore_delete(conn, "firedata_tests", test_id)
 }
})

test_that("firestore_query executes queries", {
 skip_if_no_integration()

 conn <- get_test_connection()

 # Authenticate
 api_key <- get_test_api_key()
 email <- get_test_email()
 password <- get_test_password()

 auth_result <- auth_sign_in(api_key = api_key, email = email, password = password)
 conn <- firebase_set_token(conn, auth_result)

 # Create test documents with different values
 test_ids <- c()
 for (i in 1:5) {
   test_id <- paste0("test_query_", as.integer(Sys.time()), "_", i)
   firestore_set(conn, "firedata_tests", test_id, list(
     score = i * 10,
     category = if (i <= 3) "A" else "B"
   ))
   test_ids <- c(test_ids, test_id)
 }

 # Query with filter
 results <- firestore_query(conn, "firedata_tests") |>
   fs_where("score", ">=", 30) |>
   fs_limit(10) |>
   fs_execute()

 expect_true(length(results) >= 3)

 # Clean up
 for (test_id in test_ids) {
   firestore_delete(conn, "firedata_tests", test_id)
 }
})
