Dear Leonore,

Thank you for reviewing fireData. I have addressed the requested changes in
version 2.0.1:

- Removed the redundant reference to R from the title and the beginning of the
  description.
- Put software, service, and package names in single quotes and corrected
  'shiny' to its case-sensitive package name.
- Added <https://firebase.google.com/> to the Description field.
- Used `if (interactive())` for the configuration wizard, Google sign-in, and
  Shiny app examples.
- Replaced informational printing in the indicated files with suppressible
  messages. Configuration inspection now returns a list for explicit printing.
- Removed the configuration wizard's default home-directory output path.
  It now configures only the current session by default; saving requires an
  explicit path. File-writing examples use temporary paths. I also disabled
  implicit legacy OAuth disk caching and moved R Markdown rendering into
  temporary storage.

The help files and vignette have been regenerated, and regression tests cover
the revised behavior. Local `R CMD check --as-cran` completed with 0 errors,
0 warnings, and 2 notes concerning external URL/ORCID and current-time
verification in the network-restricted check environment. All 188 test
expectations passed; 18 live integration tests were skipped. Full details are
in cran-comments.md.

Best regards,
Robin Gounder
