#' @title Configuration Management for fireData
#' @description Provides configuration loading and management for Firebase settings
#' @name firebase_config
NULL

# Package environment for storing configuration
.firedata_env <- new.env(parent = emptyenv())

#' Environment Variable Names
#' @keywords internal
ENV_VARS <- list(
  project_id = "FIREBASE_PROJECT_ID",
  api_key = "FIREBASE_API_KEY",
  database_url = "FIREBASE_DATABASE_URL",
  storage_bucket = "FIREBASE_STORAGE_BUCKET",
  service_account = "GOOGLE_APPLICATION_CREDENTIALS",
  service_account_json = "FIREBASE_SERVICE_ACCOUNT_JSON",
  client_id = "FIREBASE_CLIENT_ID",
  client_secret = "FIREBASE_CLIENT_SECRET"
)

#' Get Firebase Configuration Value
#'
#' Retrieves a configuration value using the following priority:
#' 1. Explicitly passed value
#' 2. Session configuration (set via firebase_config_set)
#' 3. Environment variables
#' 4. Config file (~/.firedata/config.yml or .firedata.yml)
#' 5. Default value
#'
#' @param key Configuration key to retrieve
#' @param value Explicit value (highest priority)
#' @param default Default value if not found
#' @param profile Configuration profile (for config file)
#' @return The configuration value or default
#' @export
#' @examples
#' \dontrun{
#' # Get API key from environment or config
#' api_key <- firebase_config_get("api_key")
#'
#' # Get with explicit value override
#' api_key <- firebase_config_get("api_key", value = "my-api-key")
#' }
firebase_config_get <- function(key, value = NULL, default = NULL, profile = "default") {
  # 1. Explicit value
 if (!is.null(value) && !identical(value, "prompt") && nzchar(as.character(value))) {
    return(value)
  }

  # 2. Session configuration
  session_value <- .firedata_env[[key]]
  if (!is.null(session_value)) {
    return(session_value)
  }

  # 3. Environment variable
  env_var_name <- ENV_VARS[[key]]
  if (!is.null(env_var_name)) {
    env_value <- Sys.getenv(env_var_name, unset = "")
    if (nzchar(env_value)) {
      return(env_value)
    }
  }

  # 4. Config file
  config_value <- get_config_file_value(key, profile)
  if (!is.null(config_value)) {
    return(config_value)
  }

  # 5. Default value
  default
}

#' Set Firebase Configuration Values for Session
#'
#' Sets configuration values that persist for the current R session.
#'
#' @param ... Named configuration values (project_id, api_key, database_url, storage_bucket)
#' @return Invisibly returns the previous values
#' @export
#' @examples
#' \dontrun{
#' firebase_config_set(
#'   project_id = "my-project",
#'   api_key = "AIzaSy..."
#' )
#' }
firebase_config_set <- function(...) {
  args <- list(...)
  valid_keys <- c("project_id", "api_key", "database_url", "storage_bucket",
                  "client_id", "client_secret")

  previous <- list()
  for (key in names(args)) {
    if (!key %in% valid_keys) {
      warning(sprintf("Unknown configuration key: %s", key))
      next
    }
    previous[[key]] <- .firedata_env[[key]]
    .firedata_env[[key]] <- args[[key]]
  }

  invisible(previous)
}

#' Clear Firebase Configuration
#'
#' Clears session configuration values.
#'
#' @param keys Specific keys to clear, or NULL to clear all
#' @return Invisibly returns NULL
#' @export
#' @examples
#' \dontrun{
#' # Clear specific keys
#' firebase_config_clear(c("api_key", "project_id"))
#'
#' # Clear all
#' firebase_config_clear()
#' }
firebase_config_clear <- function(keys = NULL) {
  if (is.null(keys)) {
    rm(list = ls(.firedata_env), envir = .firedata_env)
  } else {
    for (key in keys) {
      if (exists(key, envir = .firedata_env)) {
        rm(list = key, envir = .firedata_env)
      }
    }
  }
  invisible(NULL)
}

#' Load Configuration from File
#'
#' Loads configuration from a YAML file into session configuration.
#'
#' @param path Path to config file. If NULL, searches in standard locations.
#' @param profile Configuration profile to load (default: "default")
#' @return Invisibly returns the loaded configuration
#' @export
#' @examples
#' \dontrun{
#' # Load from default locations
#' firebase_config_load()
#'
#' # Load specific file
#' firebase_config_load("path/to/config.yml")
#'
#' # Load specific profile
#' firebase_config_load(profile = "production")
#' }
firebase_config_load <- function(path = NULL, profile = "default") {
  if (is.null(path)) {
    path <- find_config_file()
  }

  if (is.null(path) || !file.exists(path)) {
    message("No configuration file found.")
    return(invisible(NULL))
  }

  config <- tryCatch(
    yaml::read_yaml(path),
    error = function(e) {
      warning(sprintf("Failed to read config file: %s", conditionMessage(e)))
      NULL
    }
  )

  if (is.null(config)) {
    return(invisible(NULL))
  }

  # Get profile config
  profile_config <- config[[profile]]
  if (is.null(profile_config)) {
    warning(sprintf("Profile '%s' not found in config file", profile))
    return(invisible(NULL))
  }

  # Set each value
  do.call(firebase_config_set, profile_config)

  message(sprintf("Loaded configuration from '%s' (profile: %s)", path, profile))
  invisible(profile_config)
}

#' Find Configuration File
#'
#' Searches for configuration file in standard locations:
#' 1. .firedata.yml in current directory
#' 2. .firedata.yml in home directory
#' 3. ~/.firedata/config.yml
#'
#' @return Path to config file or NULL if not found
#' @keywords internal
find_config_file <- function() {
  locations <- c(
    file.path(getwd(), ".firedata.yml"),
    file.path(getwd(), ".firedata.yaml"),
    file.path(Sys.getenv("HOME"), ".firedata.yml"),
    file.path(Sys.getenv("HOME"), ".firedata.yaml"),
    file.path(Sys.getenv("HOME"), ".firedata", "config.yml"),
    file.path(Sys.getenv("HOME"), ".firedata", "config.yaml")
  )

  for (loc in locations) {
    if (file.exists(loc)) {
      return(loc)
    }
  }

  NULL
}

#' Get Value from Config File
#'
#' @param key Configuration key
#' @param profile Configuration profile
#' @return Value or NULL
#' @keywords internal
get_config_file_value <- function(key, profile = "default") {
  path <- find_config_file()
  if (is.null(path)) {
    return(NULL)
  }

  config <- tryCatch(
    yaml::read_yaml(path),
    error = function(e) NULL
  )

  if (is.null(config)) {
    return(NULL)
  }

  config[[profile]][[key]]
}

#' Interactive Configuration Wizard
#'
#' Guides the user through setting up Firebase configuration interactively.
#'
#' @param save Whether to save configuration to file
#' @param path Path to save config file (default: ~/.firedata/config.yml)
#' @return Invisibly returns the configuration list
#' @export
#' @examples
#' \dontrun{
#' # Run interactive setup
#' firebase_config_wizard()
#' }
firebase_config_wizard <- function(save = TRUE, path = NULL) {
  if (!interactive()) {
    stop_firebase("validation", "Configuration wizard requires an interactive session")
  }

  cat("Firebase Configuration Wizard\n")
  cat("============================\n\n")
  cat("Enter your Firebase project settings.\n")
  cat("You can find these values in the Firebase Console.\n\n")

  project_id <- readline("Project ID: ")
  api_key <- readline("API Key (Web API Key): ")
  database_url <- readline("Database URL (or press Enter to use default): ")
  storage_bucket <- readline("Storage Bucket (or press Enter to skip): ")

  # Build database URL if not provided
  if (!nzchar(database_url) && nzchar(project_id)) {
    database_url <- paste0("https://", project_id, "-default-rtdb.firebaseio.com")
  }

  config <- list(
    project_id = if (nzchar(project_id)) project_id else NULL,
    api_key = if (nzchar(api_key)) api_key else NULL,
    database_url = if (nzchar(database_url)) database_url else NULL,
    storage_bucket = if (nzchar(storage_bucket)) storage_bucket else NULL
  )

  # Remove NULL entries
  config <- config[!sapply(config, is.null)]

  # Set session config
  do.call(firebase_config_set, config)

  cat("\nConfiguration set for current session.\n")

  if (save && length(config) > 0) {
    save_config <- readline("Save to config file? (y/n): ")
    if (tolower(save_config) == "y") {
      if (is.null(path)) {
        config_dir <- file.path(Sys.getenv("HOME"), ".firedata")
        if (!dir.exists(config_dir)) {
          dir.create(config_dir, recursive = TRUE)
        }
        path <- file.path(config_dir, "config.yml")
      }

      yaml_content <- list(default = config)
      yaml::write_yaml(yaml_content, path)
      cat(sprintf("Configuration saved to: %s\n", path))
    }
  }

  invisible(config)
}

#' Get All Current Configuration
#'
#' Returns all currently set configuration values from all sources.
#'
#' @param profile Configuration profile for file lookup
#' @return Named list of all configuration values
#' @export
#' @examples
#' \dontrun{
#' # View current configuration
#' firebase_config_show()
#' }
firebase_config_show <- function(profile = "default") {
  keys <- c("project_id", "api_key", "database_url", "storage_bucket",
            "client_id", "client_secret")

  config <- lapply(keys, function(key) {
    val <- firebase_config_get(key, profile = profile)
    # Mask sensitive values
    if (key %in% c("api_key", "client_secret") && !is.null(val) && nchar(val) > 8) {
      paste0(substr(val, 1, 8), "...")
    } else {
      val
    }
  })
  names(config) <- keys

  # Print nicely
  cat("Firebase Configuration:\n")
  cat("=======================\n")
  for (key in keys) {
    val <- config[[key]]
    if (is.null(val)) {
      cat(sprintf("  %s: (not set)\n", key))
    } else {
      cat(sprintf("  %s: %s\n", key, val))
    }
  }

  invisible(config)
}

#' Prompt for Value if Not Set
#'
#' Internal helper to prompt user for a value if not already set.
#' Supports both interactive prompts and environment variable fallback.
#'
#' @param value Current value
#' @param key Configuration key for lookup
#' @param prompt Prompt message for interactive input
#' @param secret Whether to hide input (for passwords)
#' @return The resolved value
#' @keywords internal
prompt_if_missing <- function(value, key = NULL, prompt = NULL, secret = FALSE) {
  # Check if already have a valid value
  if (!is.null(value) && !identical(value, "prompt") && nzchar(as.character(value))) {
    return(value)
  }

  # Try config lookup
  if (!is.null(key)) {
    config_value <- firebase_config_get(key)
    if (!is.null(config_value)) {
      return(config_value)
    }
  }

  # Interactive prompt
  if (interactive() && !is.null(prompt)) {
    if (secret) {
      # For passwords, we'd ideally use a secure input method
      # but readline will have to do for basic compatibility
      readline(paste0(prompt, ": "))
    } else {
      readline(paste0(prompt, ": "))
    }
  } else {
    NULL
  }
}
