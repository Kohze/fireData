#' @title Cloud Firestore Service
#' @description Functions for interacting with Google Cloud Firestore NoSQL database
#' @name firebase_firestore
#'
#' @section Overview:
#' Cloud Firestore is a flexible, scalable NoSQL cloud database. Unlike the
#' Realtime Database which stores data as one large JSON tree, Firestore
#' stores data in documents organized into collections.
#'
#' @section Data Model:
#' - **Collections**: Containers for documents (like folders)
#' - **Documents**: Individual records containing fields (like files)
#' - **Fields**: Key-value pairs within documents
#' - **Subcollections**: Collections nested within documents
#'
#' @section Authentication:
#' Firestore requires authentication. Use either:
#' - Service account credentials (recommended for server-side)
#' - User authentication token from `auth_sign_in()`
NULL

# Firestore value type mappings
FIRESTORE_TYPES <- list(
 "NULL" = "nullValue",
 "logical" = "booleanValue",
 "integer" = "integerValue",
 "numeric" = "doubleValue",
 "character" = "stringValue",
 "raw" = "bytesValue",
 "POSIXct" = "timestampValue",
 "POSIXlt" = "timestampValue",
 "Date" = "timestampValue"
)

#' Get Firestore Document
#'
#' Retrieves a single document from Cloud Firestore.
#'
#' @param conn Firebase connection object
#' @param collection Collection path (e.g., "users" or "users/uid/posts")
#' @param document Document ID
#' @param project_id Project ID (uses connection or config if NULL)
#' @param token Authentication token (uses connection if NULL)
#' @return Document data as a list, or NULL if not found
#' @export
#' @examples
#' \dontrun{
#' conn <- firebase_connect(project_id = "my-project")
#' conn <- firebase_set_token(conn, auth_sign_in(conn, "user@example.com", "password"))
#'
#' # Get a single document
#' user <- firestore_get(conn, "users", "user123")
#' print(user$name)
#'
#' # Get from subcollection
#' post <- firestore_get(conn, "users/user123/posts", "post456")
#' }
firestore_get <- function(conn = NULL,
                          collection,
                          document,
                          project_id = NULL,
                          token = NULL) {
 # Resolve parameters
 if (!is.null(conn) && is_firebase_connection(conn)) {
   project_id <- project_id %||% conn$project_id
   token <- token %||% get_connection_token(conn)
 }
 project_id <- firebase_config_get("project_id", value = project_id)

 if (is.null(project_id)) {
   stop_firebase("validation", "project_id is required for Firestore operations")
 }

 # Build URL
 url <- build_firestore_document_url(project_id, collection, document)

 # Make request
 tryCatch({
   response <- firebase_get(url, token = token, token_type = "bearer")
   firestore_parse_document(response)
 }, error = function(e) {
   if (inherits(e, "firebase_not_found_error")) {
     warning(sprintf("Document '%s/%s' not found", collection, document))
     return(NULL)
   }
   stop(e)
 })
}

#' Set Firestore Document
#'
#' Creates or overwrites a document in Cloud Firestore.
#'
#' @param conn Firebase connection object
#' @param collection Collection path
#' @param document Document ID
#' @param data List of fields to store
#' @param project_id Project ID (uses connection or config if NULL)
#' @param token Authentication token (uses connection if NULL)
#' @return The created/updated document data
#' @export
#' @examples
#' \dontrun{
#' conn <- firebase_connect(project_id = "my-project")
#'
#' # Create or overwrite a document
#' firestore_set(conn, "users", "user123", list(
#'   name = "John Doe",
#'   email = "john@example.com",
#'   age = 30,
#'   active = TRUE
#' ))
#' }
firestore_set <- function(conn = NULL,
                          collection,
                          document,
                          data,
                          project_id = NULL,
                          token = NULL) {
 # Resolve parameters
 if (!is.null(conn) && is_firebase_connection(conn)) {
   project_id <- project_id %||% conn$project_id
   token <- token %||% get_connection_token(conn)
 }
 project_id <- firebase_config_get("project_id", value = project_id)

 if (is.null(project_id)) {
   stop_firebase("validation", "project_id is required for Firestore operations")
 }

 # Build URL
 url <- build_firestore_document_url(project_id, collection, document)

 # Convert data to Firestore format
 body <- list(fields = firestore_encode_fields(data))

 # Make request (PATCH creates or overwrites)
 response <- firebase_patch(url, body = body, token = token, token_type = "bearer")
 firestore_parse_document(response)
}

#' Add Firestore Document
#'
#' Creates a new document with an auto-generated ID.
#'
#' @param conn Firebase connection object
#' @param collection Collection path
#' @param data List of fields to store
#' @param project_id Project ID (uses connection or config if NULL)
#' @param token Authentication token (uses connection if NULL)
#' @return The created document data including the generated ID
#' @export
#' @examples
#' \dontrun{
#' conn <- firebase_connect(project_id = "my-project")
#'
#' # Add document with auto-generated ID
#' result <- firestore_add(conn, "messages", list(
#'   text = "Hello, Firestore!",
#'   timestamp = Sys.time(),
#'   author = "R User"
#' ))
#'
#' # Get the generated document ID
#' print(result$.id)
#' }
firestore_add <- function(conn = NULL,
                          collection,
                          data,
                          project_id = NULL,
                          token = NULL) {
 # Resolve parameters
 if (!is.null(conn) && is_firebase_connection(conn)) {
   project_id <- project_id %||% conn$project_id
   token <- token %||% get_connection_token(conn)
 }
 project_id <- firebase_config_get("project_id", value = project_id)

 if (is.null(project_id)) {
   stop_firebase("validation", "project_id is required for Firestore operations")
 }

 # Build URL for collection (POST creates new document)
 url <- build_firestore_collection_url(project_id, collection)

 # Convert data to Firestore format
 body <- list(fields = firestore_encode_fields(data))

 # Make request
 response <- firebase_post(url, body = body, token = token, token_type = "bearer")
 firestore_parse_document(response)
}

#' Update Firestore Document
#'
#' Updates specific fields in a document without overwriting the entire document.
#'
#' @param conn Firebase connection object
#' @param collection Collection path
#' @param document Document ID
#' @param data List of fields to update
#' @param project_id Project ID (uses connection or config if NULL)
#' @param token Authentication token (uses connection if NULL)
#' @return The updated document data
#' @export
#' @examples
#' \dontrun{
#' conn <- firebase_connect(project_id = "my-project")
#'
#' # Update only specific fields
#' firestore_update(conn, "users", "user123", list(
#'   lastLogin = Sys.time(),
#'   loginCount = 42
#' ))
#' }
firestore_update <- function(conn = NULL,
                             collection,
                             document,
                             data,
                             project_id = NULL,
                             token = NULL) {
 # Resolve parameters
 if (!is.null(conn) && is_firebase_connection(conn)) {
   project_id <- project_id %||% conn$project_id
   token <- token %||% get_connection_token(conn)
 }
 project_id <- firebase_config_get("project_id", value = project_id)

 if (is.null(project_id)) {
   stop_firebase("validation", "project_id is required for Firestore operations")
 }

 # Build URL with updateMask to only update specified fields
 url <- build_firestore_document_url(project_id, collection, document)

 # Add updateMask query parameters
 field_names <- names(data)
 mask_params <- paste(sprintf("updateMask.fieldPaths=%s", field_names), collapse = "&")
 url <- paste0(url, "?", mask_params)

 # Convert data to Firestore format
 body <- list(fields = firestore_encode_fields(data))

 # Make request
 response <- firebase_patch(url, body = body, token = token, token_type = "bearer")
 firestore_parse_document(response)
}

#' Delete Firestore Document
#'
#' Deletes a document from Cloud Firestore.
#'
#' @param conn Firebase connection object
#' @param collection Collection path
#' @param document Document ID
#' @param project_id Project ID (uses connection or config if NULL)
#' @param token Authentication token (uses connection if NULL)
#' @return TRUE if successful
#' @export
#' @examples
#' \dontrun{
#' conn <- firebase_connect(project_id = "my-project")
#'
#' # Delete a document
#' firestore_delete(conn, "users", "user123")
#' }
firestore_delete <- function(conn = NULL,
                             collection,
                             document,
                             project_id = NULL,
                             token = NULL) {
 # Resolve parameters
 if (!is.null(conn) && is_firebase_connection(conn)) {
   project_id <- project_id %||% conn$project_id
   token <- token %||% get_connection_token(conn)
 }
 project_id <- firebase_config_get("project_id", value = project_id)

 if (is.null(project_id)) {
   stop_firebase("validation", "project_id is required for Firestore operations")
 }

 # Build URL
 url <- build_firestore_document_url(project_id, collection, document)

 # Make request
 firebase_delete(url, token = token, token_type = "bearer")
 invisible(TRUE)
}

#' List Firestore Documents
#'
#' Lists documents in a collection.
#'
#' @param conn Firebase connection object
#' @param collection Collection path
#' @param page_size Maximum number of documents to return (default 100)
#' @param page_token Token for pagination (from previous response)
#' @param order_by Field to order by (prefix with "-" for descending)
#' @param project_id Project ID (uses connection or config if NULL)
#' @param token Authentication token (uses connection if NULL)
#' @return List containing documents and optional nextPageToken
#' @export
#' @examples
#' \dontrun{
#' conn <- firebase_connect(project_id = "my-project")
#'
#' # List all users (up to 100)
#' result <- firestore_list(conn, "users")
#' for (user in result$documents) {
#'   print(user$name)
#' }
#'
#' # Paginate through results
#' result <- firestore_list(conn, "users", page_size = 10)
#' while (!is.null(result$nextPageToken)) {
#'   result <- firestore_list(conn, "users", page_size = 10,
#'                            page_token = result$nextPageToken)
#' }
#' }
firestore_list <- function(conn = NULL,
                           collection,
                           page_size = 100,
                           page_token = NULL,
                           order_by = NULL,
                           project_id = NULL,
                           token = NULL) {
 # Resolve parameters
 if (!is.null(conn) && is_firebase_connection(conn)) {
   project_id <- project_id %||% conn$project_id
   token <- token %||% get_connection_token(conn)
 }
 project_id <- firebase_config_get("project_id", value = project_id)

 if (is.null(project_id)) {
   stop_firebase("validation", "project_id is required for Firestore operations")
 }

 # Build URL
 url <- build_firestore_collection_url(project_id, collection)

 # Add query parameters
 params <- list()
 params$pageSize <- page_size
 if (!is.null(page_token)) params$pageToken <- page_token
 if (!is.null(order_by)) params$orderBy <- order_by

 if (length(params) > 0) {
   query_string <- paste(names(params), unlist(params), sep = "=", collapse = "&")
   url <- paste0(url, "?", query_string)
 }

 # Make request
 response <- firebase_get(url, token = token, token_type = "bearer")

 # Parse documents
 documents <- lapply(response$documents %||% list(), firestore_parse_document)

 list(
   documents = documents,
   nextPageToken = response$nextPageToken
 )
}

#' Query Firestore Documents
#'
#' Runs a structured query against a Firestore collection.
#'
#' @param conn Firebase connection object
#' @param collection Collection path to query
#' @param project_id Project ID (uses connection or config if NULL)
#' @param token Authentication token (uses connection if NULL)
#' @return A firestore_query object for building the query
#' @export
#' @examples
#' \dontrun{
#' conn <- firebase_connect(project_id = "my-project")
#'
#' # Query with filters
#' results <- firestore_query(conn, "users") |>
#'   fs_where("age", ">=", 18) |>
#'   fs_where("active", "==", TRUE) |>
#'   fs_order_by("name") |>
#'   fs_limit(10) |>
#'   fs_execute()
#' }
firestore_query <- function(conn = NULL,
                            collection,
                            project_id = NULL,
                            token = NULL) {
 # Resolve parameters
 if (!is.null(conn) && is_firebase_connection(conn)) {
   project_id <- project_id %||% conn$project_id
   token <- token %||% get_connection_token(conn)
 }
 project_id <- firebase_config_get("project_id", value = project_id)

 if (is.null(project_id)) {
   stop_firebase("validation", "project_id is required for Firestore operations")
 }

 structure(
   list(
     project_id = project_id,
     token = token,
     collection = collection,
     filters = list(),
     order_by = list(),
     limit = NULL,
     offset = NULL,
     select_fields = NULL
   ),
   class = "firestore_query"
 )
}

#' Add Where Filter to Firestore Query
#'
#' Adds a field filter to a Firestore query.
#'
#' @param query A firestore_query object
#' @param field Field name to filter on
#' @param op Comparison operator: "==", "!=", "<", "<=", ">", ">=",
#'   "array-contains", "array-contains-any", "in", "not-in"
#' @param value Value to compare against
#' @return Updated firestore_query object
#' @export
#' @examples
#' \dontrun{
#' query <- firestore_query(conn, "users") |>
#'   fs_where("age", ">=", 21) |>
#'   fs_where("status", "==", "active")
#' }
fs_where <- function(query, field, op, value) {
 if (!inherits(query, "firestore_query")) {
   stop_firebase("validation", "query must be a firestore_query object")
 }

 # Map operator to Firestore operator
 op_map <- list(
   "==" = "EQUAL",
   "!=" = "NOT_EQUAL",
   "<" = "LESS_THAN",
   "<=" = "LESS_THAN_OR_EQUAL",
   ">" = "GREATER_THAN",
   ">=" = "GREATER_THAN_OR_EQUAL",
   "array-contains" = "ARRAY_CONTAINS",
   "array-contains-any" = "ARRAY_CONTAINS_ANY",
   "in" = "IN",
   "not-in" = "NOT_IN"
 )

 firestore_op <- op_map[[op]]
 if (is.null(firestore_op)) {
   stop_firebase("validation", sprintf("Unknown operator: %s", op))
 }

 filter <- list(
   fieldFilter = list(
     field = list(fieldPath = field),
     op = firestore_op,
     value = firestore_encode_value(value)
   )
 )

 query$filters <- c(query$filters, list(filter))
 query
}

#' Add Order By to Firestore Query
#'
#' Adds ordering to a Firestore query.
#'
#' @param query A firestore_query object
#' @param field Field name to order by
#' @param direction Sort direction: "asc" or "desc"
#' @return Updated firestore_query object
#' @export
fs_order_by <- function(query, field, direction = "asc") {
 if (!inherits(query, "firestore_query")) {
   stop_firebase("validation", "query must be a firestore_query object")
 }

 dir_map <- list(asc = "ASCENDING", desc = "DESCENDING")
 firestore_dir <- dir_map[[tolower(direction)]]
 if (is.null(firestore_dir)) {
   stop_firebase("validation", "direction must be 'asc' or 'desc'")
 }

 order <- list(
   field = list(fieldPath = field),
   direction = firestore_dir
 )

 query$order_by <- c(query$order_by, list(order))
 query
}

#' Limit Firestore Query Results
#'
#' Limits the number of documents returned by a query.
#'
#' @param query A firestore_query object
#' @param n Maximum number of documents to return
#' @return Updated firestore_query object
#' @export
fs_limit <- function(query, n) {
 if (!inherits(query, "firestore_query")) {
   stop_firebase("validation", "query must be a firestore_query object")
 }
 query$limit <- as.integer(n)
 query
}

#' Offset Firestore Query Results
#'
#' Skips a number of documents before returning results.
#'
#' @param query A firestore_query object
#' @param n Number of documents to skip
#' @return Updated firestore_query object
#' @export
fs_offset <- function(query, n) {
 if (!inherits(query, "firestore_query")) {
   stop_firebase("validation", "query must be a firestore_query object")
 }
 query$offset <- as.integer(n)
 query
}

#' Select Fields in Firestore Query
#'
#' Specifies which fields to return in query results.
#'
#' @param query A firestore_query object
#' @param ... Field names to select
#' @return Updated firestore_query object
#' @export
fs_select <- function(query, ...) {
 if (!inherits(query, "firestore_query")) {
   stop_firebase("validation", "query must be a firestore_query object")
 }
 query$select_fields <- c(...)
 query
}

#' Execute Firestore Query
#'
#' Executes a Firestore query and returns the results.
#'
#' @param query A firestore_query object
#' @return List of documents matching the query
#' @export
#' @examples
#' \dontrun{
#' results <- firestore_query(conn, "products") |>
#'   fs_where("price", "<", 100) |>
#'   fs_order_by("price", "asc") |>
#'   fs_limit(20) |>
#'   fs_execute()
#' }
fs_execute <- function(query) {
 if (!inherits(query, "firestore_query")) {
   stop_firebase("validation", "query must be a firestore_query object")
 }

 # Build the structured query
 structured_query <- list(
   from = list(list(collectionId = basename(query$collection)))
 )

 # Add filters
 if (length(query$filters) > 0) {
   if (length(query$filters) == 1) {
     structured_query$where <- query$filters[[1]]
   } else {
     structured_query$where <- list(
       compositeFilter = list(
         op = "AND",
         filters = query$filters
       )
     )
   }
 }

 # Add ordering
 if (length(query$order_by) > 0) {
   structured_query$orderBy <- query$order_by
 }

 # Add limit
 if (!is.null(query$limit)) {
   structured_query$limit <- query$limit
 }

 # Add offset
 if (!is.null(query$offset)) {
   structured_query$offset <- query$offset
 }

 # Add field selection
 if (!is.null(query$select_fields)) {
   structured_query$select <- list(
     fields = lapply(query$select_fields, function(f) list(fieldPath = f))
   )
 }

 # Build URL
 # Handle nested collection paths
 collection_parts <- strsplit(query$collection, "/")[[1]]
 if (length(collection_parts) > 1) {
   # Nested collection: users/user123/posts -> parent is users/user123
   parent_path <- paste(collection_parts[-length(collection_parts)], collapse = "/")
   url <- sprintf("%s/projects/%s/databases/(default)/documents/%s:runQuery",
                  FIREBASE_FIRESTORE_URL, query$project_id, parent_path)
 } else {
   url <- sprintf("%s/projects/%s/databases/(default)/documents:runQuery",
                  FIREBASE_FIRESTORE_URL, query$project_id)
 }

 # Make request
 body <- list(structuredQuery = structured_query)
 response <- firebase_post(url, body = body, token = query$token, token_type = "bearer")

 # Parse results
 documents <- list()
 if (is.list(response)) {
   for (item in response) {
     if (!is.null(item$document)) {
       documents <- c(documents, list(firestore_parse_document(item$document)))
     }
   }
 }

 documents
}

#' Print Firestore Query
#'
#' @param x A firestore_query object
#' @param ... Additional arguments (ignored)
#' @return Invisibly returns x
#' @export
print.firestore_query <- function(x, ...) {
 cat("<firestore_query>\n")
 cat("  Collection:", x$collection, "\n")
 cat("  Filters:", length(x$filters), "\n")
 cat("  Order by:", length(x$order_by), "fields\n")
 if (!is.null(x$limit)) cat("  Limit:", x$limit, "\n")
 if (!is.null(x$offset)) cat("  Offset:", x$offset, "\n")
 invisible(x)
}

# =============================================================================
# Internal Helper Functions
# =============================================================================

#' Build Firestore Document URL
#' @keywords internal
build_firestore_document_url <- function(project_id, collection, document) {
 sprintf("%s/projects/%s/databases/(default)/documents/%s/%s",
         FIREBASE_FIRESTORE_URL, project_id, collection, document)
}

#' Build Firestore Collection URL
#' @keywords internal
build_firestore_collection_url <- function(project_id, collection) {
 sprintf("%s/projects/%s/databases/(default)/documents/%s",
         FIREBASE_FIRESTORE_URL, project_id, collection)
}

#' Encode R Value to Firestore Value
#' @keywords internal
firestore_encode_value <- function(value) {
 if (is.null(value)) {
   return(list(nullValue = NULL))
 }

 # Check if this is a vector with length > 1 (should be treated as array)
 # But exclude named lists which should be maps
 if (length(value) > 1 && !is.list(value)) {
   return(list(arrayValue = list(
     values = lapply(value, firestore_encode_value)
   )))
 }

 if (is.logical(value)) {
   return(list(booleanValue = value))
 }

 if (is.integer(value)) {
   return(list(integerValue = as.character(value)))
 }

 if (is.numeric(value)) {
   return(list(doubleValue = value))
 }

 if (inherits(value, c("POSIXct", "POSIXlt"))) {
   return(list(timestampValue = format(value, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")))
 }

 if (inherits(value, "Date")) {
   return(list(timestampValue = format(as.POSIXct(value), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")))
 }

 if (is.character(value)) {
   return(list(stringValue = value))
 }

 if (is.list(value) && !is.null(names(value))) {
   # Named list = map
   return(list(mapValue = list(fields = firestore_encode_fields(value))))
 }

 if (is.list(value)) {
   # Unnamed list = array
   return(list(arrayValue = list(
     values = lapply(value, firestore_encode_value)
   )))
 }

 # Default to string representation
 list(stringValue = as.character(value))
}

#' Encode R List to Firestore Fields
#' @keywords internal
firestore_encode_fields <- function(data) {
 if (!is.list(data)) {
   stop_firebase("validation", "data must be a list")
 }

 fields <- list()
 for (name in names(data)) {
   fields[[name]] <- firestore_encode_value(data[[name]])
 }
 fields
}

#' Decode Firestore Value to R Value
#' @keywords internal
firestore_decode_value <- function(value) {
 if (is.null(value)) return(NULL)

 # Check if "nullValue" key exists (its value IS null, so we check the key)
 if ("nullValue" %in% names(value)) return(NULL)
 if (!is.null(value$booleanValue)) return(value$booleanValue)
 if (!is.null(value$integerValue)) return(as.integer(value$integerValue))
 if (!is.null(value$doubleValue)) return(as.numeric(value$doubleValue))
 if (!is.null(value$stringValue)) return(value$stringValue)
 if (!is.null(value$bytesValue)) return(jsonlite::base64_dec(value$bytesValue))

 if (!is.null(value$timestampValue)) {
   return(as.POSIXct(value$timestampValue, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC"))
 }

 if (!is.null(value$geoPointValue)) {
   return(list(
     latitude = value$geoPointValue$latitude,
     longitude = value$geoPointValue$longitude
   ))
 }

 if (!is.null(value$arrayValue)) {
   return(lapply(value$arrayValue$values %||% list(), firestore_decode_value))
 }

 if (!is.null(value$mapValue)) {
   return(firestore_decode_fields(value$mapValue$fields))
 }

 if (!is.null(value$referenceValue)) {
   return(value$referenceValue)
 }

 # Unknown type
 value
}

#' Decode Firestore Fields to R List
#' @keywords internal
firestore_decode_fields <- function(fields) {
 if (is.null(fields)) return(list())

 result <- list()
 for (name in names(fields)) {
   result[[name]] <- firestore_decode_value(fields[[name]])
 }
 result
}

#' Parse Firestore Document Response
#' @keywords internal
firestore_parse_document <- function(doc) {
 if (is.null(doc)) return(NULL)

 # Decode fields
 result <- firestore_decode_fields(doc$fields)

 # Add document metadata
 if (!is.null(doc$name)) {
   # Extract document ID from path
   parts <- strsplit(doc$name, "/")[[1]]
   result$.id <- parts[length(parts)]
   result$.path <- doc$name
 }

 if (!is.null(doc$createTime)) {
   result$.createTime <- as.POSIXct(doc$createTime, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC")
 }

 if (!is.null(doc$updateTime)) {
   result$.updateTime <- as.POSIXct(doc$updateTime, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC")
 }

 result
}
