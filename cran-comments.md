# CRAN Submission Comments - fireData 2.0.0

## R CMD check results

0 errors | 0 warnings | 2 notes

### Notes

1. **New submission**

   This is a major version update (v2.0.0) of the fireData package with significant
   improvements including:
   - Complete package modernization with modular architecture
   - New Cloud Firestore support
   - Modern snake_case API (old functions deprecated but still work)
   - Connection object pattern for easier configuration
   - Comprehensive test suite

2. **Packages suggested but not available for checking: 'httptest2', 'covr'**

   These are optional development dependencies used for HTTP mocking in tests
   and code coverage reporting. They are not required for package functionality.

## Test environments

* Local: Windows 11 x64, R 4.4.0
* GitHub Actions: ubuntu-latest, R release
* GitHub Actions: windows-latest, R release
* GitHub Actions: macos-latest, R release

## Downstream dependencies

This package has no reverse dependencies on CRAN.

## Additional notes

- All tests pass (124 tests, 18 skipped integration tests that require Firebase credentials)
- Package includes comprehensive documentation and vignette
- Backward compatibility maintained with deprecated function wrappers
