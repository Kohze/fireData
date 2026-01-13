# CRAN Submission Comments - fireData 2.0.0

## R CMD check results

0 errors | 0 warnings | 2 notes

The NOTEs are:

1. `Packages suggested but not available for checking: 'httptest2', 'covr'`
   - These are optional packages for HTTP mocking tests and code coverage reporting
   - Not required for package functionality

2. `unable to verify current time`
   - Transient network/system issue during check
   - Not a package issue

## Test environments

* Local: Windows 11 x64, R 4.4.0
* GitHub Actions (configured):
  - Ubuntu 22.04 (release)
  - Windows latest (release)
  - macOS latest (release)

## Package Dependencies

* All dependencies are available on CRAN
* No system requirements beyond R >= 4.1.0

## This is a major release (2.0.0)

### Summary of Changes

This is a major version release that modernizes the package with:

1. **Modular Architecture**: Split single 792-line file into 12 focused modules
2. **Modern API**: New consistent snake_case function naming
3. **Connection Objects**: New `firebase_connect()` pattern for managing configuration
4. **Configuration Management**: Support for environment variables, config files, and interactive setup
5. **Service Account Support**: Full server-side authentication via Google service accounts
6. **Improved Error Handling**: Custom error classes with detailed messages
7. **Query Builder**: New `rtdb_query()` with fluent interface for filtering/sorting

### Backward Compatibility

All previous functions remain available with deprecation warnings pointing to their new equivalents:
- `auth()` -> `auth_sign_in()`
- `upload()` -> `rtdb_push()`
- `download()` -> `rtdb_get()`
- `put()` -> `rtdb_set()`
- `patch()` -> `rtdb_update()`
- `delete()` -> `rtdb_delete()`
- etc.

### API Access

This package accesses Google Firebase REST APIs:
- Firebase Auth API (identitytoolkit.googleapis.com)
- Firebase Realtime Database API (*.firebaseio.com)
- Google Cloud Storage API (storage.googleapis.com)
- Firebase Dynamic Links API (firebasedynamiclinks.googleapis.com)

All API access requires user-provided credentials (API keys, service accounts, or OAuth tokens).

### Test Coverage

* Unit tests run without external dependencies (67 tests pass)
* Integration tests require Firebase credentials and are skipped by default (12 tests skipped)
* Integration tests can be enabled via environment variable: `FIREDATA_RUN_INTEGRATION_TESTS=true`

## Previous CRAN Submission

Last CRAN version: 1.16

## Maintainer Notes

* Package has been used in production for several years
* Major version bump due to API changes (backward compatible with deprecation warnings)
* No compiled code
* No native code
