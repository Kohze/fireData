# CRAN Resubmission Comments - fireData 2.0.1

## Submission context

This is a resubmission following Leonore Hochhauser's review of September 7,
2026. Earlier fireData versions, including 2.0.0, were
distributed through GitHub but were not published on CRAN.

## Changes addressing the review

- Removed the redundant reference to R from the title and the start of the
  description. The title is now "Connect to 'Google Firebase'".
- Quoted software, service, and package names in DESCRIPTION, including the
  correctly capitalized package name 'shiny'.
- Added <https://firebase.google.com/> to the Description field.
- Replaced `\dontrun{}` with `if (interactive()) {}` for the configuration
  wizard, Google sign-in, and Shiny app examples. Examples that need private
  Firebase credentials or local configuration files remain unexecuted.
- Replaced informational `print()` calls in R/auth.R, R/realtime-db.R, and
  R/storage.R with `message()` and disabled curl progress bars, so messages can
  be suppressed. `firebase_config_show()` now returns a masked configuration
  list for explicit printing. Remaining console output is in print methods
  or the interactive configuration wizard.
- The configuration wizard now defaults to `save = FALSE`. Saving requires
  `save = TRUE`, an explicit file path, and confirmation in the interactive
  wizard. The implicit home-directory path and directory creation were removed.
- Download, backup, and configuration-writing examples use temporary paths.
  Legacy Storage OAuth helpers disable disk caching, and legacy R Markdown
  deployment renders into temporary storage and removes it after upload.
- Regenerated help files and the vignette, and added regression tests for
  configuration saving, suppressible output, OAuth caching, and temporary
  rendering/cleanup. Tests use temporary paths and mocked network calls.
- Follow-up audit: enabled runnable local examples, explicitly guarded browser
  launching, replaced the obsolete Dynamic Links success example with `try()`,
  and added temporary-file cleanup to examples and legacy S4 downloads.
  The testthat minimum version is now 3.2.0 to support the mocking helpers used.

The repository history used the maintainer name Robin Kohze and email address
Robin@Kohze.com. The current maintainer record is Robin Gounder
<robin@gounder.com>, ORCID 0009-0008-7755-7081; this is the same maintainer.

## R CMD check results

Local `R CMD check --as-cran fireData_2.0.1.tar.gz` on September 8, 2026:

0 errors | 0 warnings | 2 notes

- CRAN incoming feasibility could not validate external URLs or the ORCID iD.
  This network-restricted Windows sandbox reports libcurl error 35
  (`schannel: AcquireCredentialsHandle failed: SEC_E_NO_CREDENTIALS`) for HTTPS
  requests and cannot retrieve the CRAN/Bioconductor package indexes.
- The future-file-timestamp check reported `unable to verify current time`.

All other checks passed, including examples, tests, vignette rebuilding, and
PDF/HTML manuals. The audited archive's test suite reported 188 passing expectations, no failures,
no warnings, and 18 skipped integration tests. These notes leave external
URL/ORCID and time validation unverified in this environment.

## Test environments

- Local: Windows 11 x64, R 4.4.0, September 8, 2026.
- GitHub Actions is configured for R release on Linux, Windows, and macOS,
  R-devel on Linux, and R-oldrel on Linux.

## Additional notes

Integration tests that require private Firebase credentials are skipped when
those credentials are unavailable. Unit tests and package examples do not make
authenticated Firebase requests during CRAN checks.
