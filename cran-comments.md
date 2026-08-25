# CRAN Submission Comments - fireData 2.0.1

## Submission context

This is a new CRAN submission. Earlier fireData versions, including 2.0.0, were
distributed through GitHub but were not published on CRAN.

Version 2.0.1 prepares the package for CRAN by:

- correcting package and maintainer metadata;
- removing stale CRAN availability claims and repository artifacts;
- updating legacy authentication calls to the current Firebase REST API;
- documenting Firebase Dynamic Links' shutdown and current Storage bucket names;
- clarifying the package's supported Firebase feature scope; and
- removing unused suggested dependencies.

The repository history used the maintainer name Robin Kohze and email address
Robin@Kohze.com. The current maintainer record is Robin Gounder
<robin@gounder.com>, ORCID 0009-0008-7755-7081; this is the same maintainer.

## R CMD check results

Local standard check:

0 errors | 0 warnings | 0 notes

Local `R CMD check --as-cran`:

0 errors | 0 warnings | 1 note

The single NOTE was `unable to verify current time`. The check ran in a
network-restricted sandbox that cannot reach an external time service; it is not
caused by package code or metadata.

## Test environments

- Local: Windows 11 x64, R 4.4.0
- GitHub Actions is configured for R release on Linux, Windows, and macOS,
  R-devel on Linux, and R-oldrel on Linux.

## Downstream dependencies

This package has no reverse dependencies on CRAN.

## Additional notes

Integration tests that require private Firebase credentials are skipped when
those credentials are unavailable. Unit tests and package examples do not make
authenticated Firebase requests during CRAN checks.
