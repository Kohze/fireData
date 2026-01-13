#' @title Custom Error Classes for fireData
#' @description Provides a hierarchy of error classes for Firebase operations
#' @name firebase_errors
#' @keywords internal
NULL

#' Create a Firebase error condition
#'
#' @param message Error message
#' @param code Firebase error code (e.g., "INVALID_PASSWORD", "USER_NOT_FOUND")
#' @param status HTTP status code
#' @param details Additional error details
#' @param class Additional error subclass
#' @param call The call that generated the error
#' @return A condition object of class firebase_error
#' @keywords internal
firebase_error <- function(message,
                           code = NULL,
                           status = NULL,
                           details = NULL,
                           class = NULL,
                           call = NULL) {
  structure(
    list(
      message = message,
      code = code,
      status = status,
      details = details,
      call = call
    ),
    class = c(class, "firebase_error", "error", "condition")
  )
}

#' Firebase Authentication Error
#'
#' @param message Error message
#' @param code Firebase auth error code
#' @param ... Additional arguments passed to firebase_error
#' @return A condition object of class firebase_auth_error
#' @keywords internal
firebase_auth_error <- function(message, code = NULL, ...) {
  firebase_error(
    message = message,
    code = code,
    class = "firebase_auth_error",
    ...
  )
}

#' Firebase Permission Denied Error
#'
#' @param message Error message
#' @param path The path that was denied
#' @param ... Additional arguments passed to firebase_error
#' @return A condition object of class firebase_permission_error
#' @keywords internal
firebase_permission_error <- function(message, path = NULL, ...) {
  firebase_error(
    message = message,
    details = list(path = path),
    class = "firebase_permission_error",
    ...
  )
}

#' Firebase Not Found Error
#'
#' @param message Error message
#' @param path The path that was not found
#' @param ... Additional arguments passed to firebase_error
#' @return A condition object of class firebase_not_found_error
#' @keywords internal
firebase_not_found_error <- function(message, path = NULL, ...) {
  firebase_error(
    message = message,
    details = list(path = path),
    class = "firebase_not_found_error",
    ...
  )
}

#' Firebase Validation Error
#'
#' @param message Error message
#' @param field The field that failed validation
#' @param ... Additional arguments passed to firebase_error
#' @return A condition object of class firebase_validation_error
#' @keywords internal
firebase_validation_error <- function(message, field = NULL, ...) {
  firebase_error(
    message = message,
    details = list(field = field),
    class = "firebase_validation_error",
    ...
  )
}

#' Firebase Network Error
#'
#' @param message Error message
#' @param ... Additional arguments passed to firebase_error
#' @return A condition object of class firebase_network_error
#' @keywords internal
firebase_network_error <- function(message, ...) {
  firebase_error(
    message = message,
    class = "firebase_network_error",
    ...
  )
}

#' Firebase Rate Limit Error
#'
#' @param message Error message
#' @param retry_after Seconds to wait before retrying
#' @param ... Additional arguments passed to firebase_error
#' @return A condition object of class firebase_rate_limit_error
#' @keywords internal
firebase_rate_limit_error <- function(message, retry_after = NULL, ...) {
  firebase_error(
    message = message,
    details = list(retry_after = retry_after),
    class = "firebase_rate_limit_error",
    ...
  )
}

#' Parse Firebase API Error Response
#'
#' Parses error responses from Firebase REST APIs and returns the appropriate
#' error object.
#'
#' @param response An httr response object
#' @return A firebase_error subclass based on the error type
#' @keywords internal
parse_firebase_error <- function(response) {
  status <- NULL
  content <- NULL

  # Handle httr response
  if (inherits(response, "response")) {
    status <- httr::status_code(response)
    content <- tryCatch(
      httr::content(response, as = "parsed", type = "application/json"),
      error = function(e) NULL
    )
  }

  # Extract error info from Firebase error format
  error_info <- content$error
  if (is.null(error_info) && !is.null(content$error_description)) {
    # OAuth error format
    error_info <- list(
      message = content$error_description,
      code = content$error
    )
  }

  code <- error_info$message %||% error_info$code %||% "UNKNOWN_ERROR"
  message <- error_info$message %||% paste("HTTP", status, "error")

  # Map Firebase error codes to appropriate error classes
  if (status == 401 || code %in% c("INVALID_ID_TOKEN", "TOKEN_EXPIRED")) {
    firebase_auth_error(
      message = message,
      code = code,
      status = status,
      details = error_info$errors
    )
  } else if (status == 403 || code == "PERMISSION_DENIED") {
    firebase_permission_error(
      message = message,
      status = status,
      details = error_info$errors
    )
  } else if (status == 404) {
    firebase_not_found_error(
      message = message,
      status = status,
      details = error_info$errors
    )
  } else if (status == 429) {
    retry_after <- NULL
    if (inherits(response, "response")) {
      retry_after <- httr::headers(response)$`retry-after`
    }
    firebase_rate_limit_error(
      message = message,
      retry_after = as.numeric(retry_after),
      status = status,
      details = error_info$errors
    )
  } else if (code %in% c("INVALID_EMAIL", "INVALID_PASSWORD", "EMAIL_NOT_FOUND",
                          "USER_DISABLED", "EMAIL_EXISTS", "WEAK_PASSWORD",
                          "OPERATION_NOT_ALLOWED", "TOO_MANY_ATTEMPTS_TRY_LATER")) {
    firebase_auth_error(
      message = message,
      code = code,
      status = status,
      details = error_info$errors
    )
  } else {
    firebase_error(
      message = message,
      code = code,
      status = status,
      details = error_info$errors
    )
  }
}

#' Stop with Firebase Error
#'
#' Convenience function to raise a Firebase error
#'
#' @param type Type of error: "auth", "permission", "not_found", "validation",
#'   "network", "rate_limit", or "generic"
#' @param message Error message
#' @param ... Additional arguments passed to the error constructor
#' @keywords internal
stop_firebase <- function(type = "generic", message, ...) {
  err <- switch(
    type,
    auth = firebase_auth_error(message, ...),
    permission = firebase_permission_error(message, ...),
    not_found = firebase_not_found_error(message, ...),
    validation = firebase_validation_error(message, ...),
    network = firebase_network_error(message, ...),
    rate_limit = firebase_rate_limit_error(message, ...),
    firebase_error(message, ...)
  )
  stop(err)
}

# Null-coalescing operator (internal, no Rd generated)
# @param x Value to check
# @param y Default value if x is NULL
# @return x if not NULL, otherwise y
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

#' Print method for firebase_error
#'
#' @param x A firebase_error object
#' @param ... Additional arguments (ignored)
#' @return Invisibly returns x
#' @export
#' @keywords internal
print.firebase_error <- function(x, ...) {
  cat("<firebase_error>\n")
  if (!is.null(x$code)) {
    cat("  Code:", x$code, "\n")
  }
  if (!is.null(x$status)) {
    cat("  Status:", x$status, "\n")
  }
  cat("  Message:", x$message, "\n")
  if (!is.null(x$details)) {
    cat("  Details:", utils::str(x$details), "\n")
  }
  invisible(x)
}

#' Condition message for firebase_error
#'
#' @param c A firebase_error condition
#' @return The error message as a character string
#' @export
#' @keywords internal
conditionMessage.firebase_error <- function(c) {
  paste0(
    if (!is.null(c$code)) paste0("[", c$code, "] ") else "",
    c$message
  )
}
