# Simulate only the wizard's interactive input; all configuration and file
# operations still use the real implementation.
mock_wizard <- function(answers) {
  wizard <- firebase_config_wizard
  environment(wizard) <- list2env(list(
    interactive = function() TRUE,
    readline = function(...) {
      if (!length(answers)) stop("Unexpected wizard prompt")
      answer <- answers[[1L]]
      answers <<- answers[-1L]
      answer
    }
  ), parent = environment(firebase_config_wizard))
  wizard
}

test_that("the wizard does not write files by default", {
  on.exit(firebase_config_clear(), add = TRUE)
  wizard <- mock_wizard(c("test-project", "test-key", "", ""))
  output <- tempfile(fileext = ".yml")
  # Supplying a path alone must not opt in to writing or add a save prompt.
  invisible(capture.output(config <- wizard(path = output)))
  expect_false(file.exists(output))
  expect_equal(config$project_id, "test-project")
  expect_equal(firebase_config_get("api_key"), "test-key")
})

test_that("saving configuration requires a valid explicit path before prompting", {
  wizard <- mock_wizard(character())
  for (path in list(NULL, "", "  ", NA_character_, character(), c("a", "b"), 1)) {
    expect_error(wizard(save = TRUE, path = path), "explicit file path",
                 class = "firebase_validation_error")
  }
  for (save in list(NULL, NA, c(TRUE, FALSE), "yes", 1)) {
    expect_error(wizard(save = save), "save must be TRUE or FALSE",
                 class = "firebase_validation_error")
  }
})

test_that("the wizard saves only to the requested temporary file after consent", {
  on.exit(firebase_config_clear(), add = TRUE)
  output <- tempfile(fileext = ".yml")
  on.exit(unlink(output), add = TRUE)
  wizard <- mock_wizard(c("test-project", "test-key", "", "", "y"))
  invisible(capture.output(config <- wizard(save = TRUE, path = output)))
  expect_equal(yaml::read_yaml(output), list(default = config))

  declined <- tempfile(fileext = ".yml")
  wizard <- mock_wizard(c("test-project", "test-key", "", "", "n"))
  invisible(capture.output(wizard(save = TRUE, path = declined)))
  expect_false(file.exists(declined))
})

test_that("the configuration wizard rejects noninteractive sessions", {
  wizard <- firebase_config_wizard
  environment(wizard) <- list2env(list(interactive = function() FALSE),
                                  parent = environment(wizard))
  expect_error(wizard(), "requires an interactive session",
               class = "firebase_validation_error")
})

test_that("configuration can be inspected without printing", {
  on.exit(firebase_config_clear(), add = TRUE)
  firebase_config_set(project_id = "test-project", api_key = "long-secret-key")
  expect_output(config <- firebase_config_show(), NA)
  expect_equal(config$project_id, "test-project")
  expect_equal(config$api_key, "long-sec...")
})

test_that("backup progress is suppressible and output paths are preserved", {
  testthat::local_mocked_bindings(
    curl_download = function(url, destfile, quiet) {
      expect_true(quiet)
      writeLines("{}", destfile)
      invisible(destfile)
    },
    .package = "curl"
  )
  output <- tempfile(fileext = ".json")
  on.exit(unlink(output), add = TRUE)
  conn <- firebase_connect(project_id = "test-project")
  expect_message(
    expect_message(result <- rtdb_backup(conn, output, token = "test-token"),
                   "Fetching data"),
    "Backup created"
  )
  expect_identical(result, output)
  expect_silent(suppressMessages(rtdb_backup(conn, output, token = "test-token")))
  expect_silent(suppressWarnings(suppressMessages(
    dataBackup(conn$database_url, secretKey = "test-token", fileName = output)
  )))
  expect_equal(readLines(output), "{}")
})

test_that("legacy Storage OAuth helpers disable implicit disk caches", {
  testthat::local_mocked_bindings(
    oauth2.0_token = function(endpoint, app, scope, cache) {
      expect_false(cache)
      list(credentials = list(access_token = "test-token"))
    },
    .package = "httr"
  )
  expect_equal(google_devstorage_read_write("client", "secret")$credentials$access_token,
               "test-token")
  expect_equal(google_devstorage_read_only("client", "secret")$credentials$access_token,
               "test-token")
})

test_that("legacy folder upload progress is suppressible", {
  folder <- tempfile("firedata-upload-")
  dir.create(folder)
  on.exit(unlink(folder, recursive = TRUE), add = TRUE)
  writeLines("test", file.path(folder, "test.txt"))
  testthat::local_mocked_bindings(
    google_devstorage_read_write = function(...) {
      list(credentials = list(access_token = "test-token"))
    }
  )
  testthat::local_mocked_bindings(
    POST = function(...) list(),
    content = function(...) list(name = "test.txt"),
    .package = "httr"
  )
  expect_silent(result <- suppressWarnings(suppressMessages(
    upload_folder("test-bucket", folder_path = folder)
  )))
  expect_equal(result$name, "test.txt")
})

test_that("R Markdown deployments render in temporary storage and clean up", {
  skip_if_not_installed("rmarkdown")
  render_path <- NULL
  testthat::local_mocked_bindings(
    render = function(input, output_format, output_dir, intermediates_dir,
                      knit_root_dir, quiet) {
      expect_identical(output_dir, intermediates_dir)
      expect_identical(output_dir, knit_root_dir)
      expect_identical(normalizePath(dirname(output_dir)), normalizePath(tempdir()))
      expect_true(quiet)
      render_path <<- output_dir
      output <- file.path(output_dir, "report.html")
      writeLines("<html></html>", output)
      output
    },
    .package = "rmarkdown"
  )
  testthat::local_mocked_bindings(
    upload_storage = function(..., file_path) {
      expect_true(file.exists(file_path))
      list(name = "report.html")
    }
  )
  expect_equal(deploy_rmarkdown("report.Rmd", "bucket", "report.html"),
               list(name = "report.html"))
  expect_false(dir.exists(render_path))

  testthat::local_mocked_bindings(
    upload_storage = function(...) stop("Upload failed")
  )
  expect_error(deploy_rmarkdown("report.Rmd", "bucket", "report.html"), "Upload failed")
  expect_false(dir.exists(render_path))
})

test_that("legacy S4 downloads clean temporary files on success and failure", {
  output <- tempfile(fileext = ".rds")
  on.exit(unlink(output), add = TRUE)
  payload <- jsonlite::toJSON(jsonlite::base64_enc(serialize(list(value = 42), NULL)))
  testthat::local_mocked_bindings(
    GET = function(...) list(),
    content = function(...) payload,
    .package = "httr"
  )
  legacy_download <- fireData::download
  environment(legacy_download) <- list2env(list(
    tempfile = function(...) output
  ), parent = environment(legacy_download))
  expect_equal(suppressWarnings(legacy_download("https://example.com", "data", isClass = TRUE)),
               list(value = 42))
  expect_false(file.exists(output))

  payload <- jsonlite::toJSON(jsonlite::base64_enc(charToRaw("invalid RDS")))
  expect_error(suppressWarnings(legacy_download("https://example.com", "data", isClass = TRUE)))
  expect_false(file.exists(output))
})
