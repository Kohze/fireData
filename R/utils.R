#' @title Utility Functions for fireData
#' @description Internal utility functions for data conversion and path handling
#' @name firebase_utils
NULL

#' Sanitize Firebase Path
#'
#' Replaces disallowed characters in Firebase paths with hyphens.
#' Firebase paths cannot contain: . $ # [ ] /
#'
#' @param path The database path string
#' @return The sanitized path string
#' @export
#' @examples
#' # Path with invalid characters
#' path_sanitize("users/john.doe")
#' # Returns: "users-john-doe" with a warning
#'
#' # Valid path passes through unchanged
#' path_sanitize("users-johndoe")
#' # Returns: "users-johndoe"
path_sanitize <- function(path) {
  if (is.null(path) || !nzchar(path)) {
    return(path)
  }

  # Replace disallowed characters (Firebase paths cannot contain . $ # [ ] / { })
  path_replaced <- gsub("\\$", "-", path)
  path_replaced <- gsub("#", "-", path_replaced)
  path_replaced <- gsub("\\]", "-", path_replaced)
  path_replaced <- gsub("\\[", "-", path_replaced)
  path_replaced <- gsub("\\{", "-", path_replaced)
  path_replaced <- gsub("\\}", "-", path_replaced)
  path_replaced <- gsub("/", "-", path_replaced)
  path_replaced <- gsub("\\.", "-", path_replaced)

  if (path_replaced != path) {
    warning(paste0("Path contained invalid characters. Changed to: ", path_replaced))
  }

  path_replaced
}

#' @rdname path_sanitize
#' @export
path_check <- function(path) {
  .Deprecated("path_sanitize")
  # Original implementation returned the original path (bug)
  # We maintain this for backward compatibility but the new function fixes it
  path_replaced <- gsub("\\$", "-", path)
  path_replaced <- gsub("#", "-", path_replaced)
  path_replaced <- gsub("\\]", "-", path_replaced)
  path_replaced <- gsub("\\[", "-", path_replaced)
  path_replaced <- gsub("/", "-", path_replaced)
  path_replaced <- gsub("\\.", "-", path_replaced)

  if (path_replaced != path) {
    warning(paste0("path changed to ", path_replaced))
  }

  # Return original path (legacy behavior - this was a bug in v1)
  path
}

#' Convert Data for Firebase Storage
#'
#' Internal function that converts R objects to Firebase-compatible format.
#' S4 class objects are converted to base64-encoded binary.
#'
#' @param x The input data (data.frame, list, or S4 object)
#' @return Converted data suitable for JSON serialization
#' @keywords internal
file_conversion <- function(x) {
  if (isS4(x)) {
    class_conversion(x)
  } else {
    x
  }
}

#' @rdname file_conversion
#' @keywords internal
fileConversion <- function(x) {
  # Legacy function name for backward compatibility
  file_conversion(x)
}

#' Convert S4 Class to Base64
#'
#' Internal function that serializes S4 class objects to base64-encoded
#' binary format for storage in Firebase.
#'
#' @param x The S4 class object
#' @return A list containing the base64-encoded binary data
#' @keywords internal
class_conversion <- function(x) {
  if (!isS4(x)) {
    stop_firebase("validation", "Expected an S4 class object")
  }

  # Serialize to temporary file
  temp_path <- tempfile()
  on.exit(unlink(temp_path), add = TRUE)

  saveRDS(x, file = temp_path)

  # Read as binary and encode
  binary_data <- readBin(temp_path, what = "raw", n = file.info(temp_path)$size)
  base64_data <- jsonlite::base64_enc(binary_data)

  list(base64Set = base64_data)
}

#' @rdname class_conversion
#' @keywords internal
classConversion <- function(x) {
  # Legacy function name for backward compatibility
  class_conversion(x)
}

#' Restore S4 Class from Base64
#'
#' Restores an S4 class object from base64-encoded binary data.
#'
#' @param data List containing base64Set field
#' @return The restored S4 object
#' @keywords internal
class_restore <- function(data) {
  if (is.null(data$base64Set)) {
    stop_firebase("validation", "Data does not contain base64Set field")
  }

  # Decode and write to temp file
  temp_path <- tempfile()
  on.exit(unlink(temp_path), add = TRUE)

  binary_data <- jsonlite::base64_dec(data$base64Set)
  writeBin(binary_data, temp_path)

  # Read back as RDS
 readRDS(temp_path)
}

#' Check if Data is Base64-Encoded S4 Object
#'
#' @param data Data to check
#' @return TRUE if data appears to be a base64-encoded S4 object
#' @keywords internal
is_encoded_s4 <- function(data) {
  is.list(data) && !is.null(data$base64Set)
}

#' Validate Email Format
#'
#' Basic email format validation.
#'
#' @param email Email address to validate
#' @return TRUE if valid format, FALSE otherwise
#' @keywords internal
is_valid_email <- function(email) {
  if (is.null(email) || !is.character(email) || !nzchar(email)) {
    return(FALSE)
  }
  grepl("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", email)
}

#' Validate Firebase Project ID
#'
#' Firebase project IDs must be 6-30 characters, lowercase letters,
#' numbers, and hyphens only.
#'
#' @param project_id Project ID to validate
#' @return TRUE if valid, FALSE otherwise
#' @keywords internal
is_valid_project_id <- function(project_id) {
  if (is.null(project_id) || !is.character(project_id)) {
    return(FALSE)
  }
  grepl("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", project_id)
}

#' Clean Firebase Path
#'
#' Removes leading/trailing slashes and normalizes path.
#'
#' @param path Path to clean
#' @return Cleaned path
#' @keywords internal
clean_path <- function(path) {
  if (is.null(path)) {
    return("")
  }
  # Remove leading slashes
  path <- gsub("^/+", "", path)
  # Remove trailing slashes
  path <- gsub("/+$", "", path)
  # Collapse multiple slashes
  path <- gsub("/+", "/", path)
  path
}

#' Combine Paths
#'
#' Combines path segments, handling slashes properly.
#'
#' @param ... Path segments to combine
#' @return Combined path
#' @keywords internal
combine_paths <- function(...) {
  parts <- list(...)
  parts <- parts[!sapply(parts, is.null)]
  parts <- sapply(parts, as.character)
  parts <- parts[nzchar(parts)]

  if (length(parts) == 0) {
    return("")
  }

  # Clean each part and combine
  parts <- sapply(parts, clean_path)
  parts <- parts[nzchar(parts)]

  paste(parts, collapse = "/")
}

#' Convert Response to Data Frame
#'
#' Converts Firebase response (typically a named list of records) to a data frame.
#'
#' @param data Firebase response data
#' @param id_column Name of column to store record IDs (default: ".id")
#' @return A data frame
#' @keywords internal
response_to_df <- function(data, id_column = ".id") {
  if (is.null(data)) {
    return(data.frame())
  }

  if (is.data.frame(data)) {
    return(data)
  }

  if (!is.list(data)) {
    return(data)
  }

  # Handle list of records
  if (length(data) == 0) {
    return(data.frame())
  }

  # If it's a named list of records, convert to data frame with IDs
  if (!is.null(names(data))) {
    ids <- names(data)
    records <- lapply(seq_along(data), function(i) {
      record <- data[[i]]
      if (is.list(record)) {
        record[[id_column]] <- ids[i]
        as.data.frame(record, stringsAsFactors = FALSE)
      } else {
        data.frame(value = record, stringsAsFactors = FALSE)
      }
    })

    tryCatch(
      do.call(rbind, records),
      error = function(e) data
    )
  } else {
    data
  }
}

#' Format Bytes for Display
#'
#' @param bytes Number of bytes
#' @return Human-readable string
#' @keywords internal
format_bytes <- function(bytes) {
  if (is.null(bytes) || is.na(bytes)) {
    return("unknown")
  }

  bytes <- as.numeric(bytes)

  if (bytes < 1024) {
    paste(bytes, "B")
  } else if (bytes < 1024^2) {
    paste(round(bytes / 1024, 1), "KB")
  } else if (bytes < 1024^3) {
    paste(round(bytes / 1024^2, 1), "MB")
  } else {
    paste(round(bytes / 1024^3, 1), "GB")
  }
}

#' Generate Random ID
#'
#' Generates a random ID similar to Firebase push IDs.
#'
#' @param length Length of ID (default: 20)
#' @return Random ID string
#' @keywords internal
generate_id <- function(length = 20) {
  chars <- c(letters, LETTERS, 0:9, "-", "_")
  paste(sample(chars, length, replace = TRUE), collapse = "")
}
