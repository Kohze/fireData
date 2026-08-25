# fireData 2.0.1

## Compatibility and release maintenance

* Updated the maintainer email and added the maintainer ORCID.
* Updated deprecated authentication wrappers to use the current Identity Toolkit
  v1 REST endpoints instead of the obsolete v3 endpoints.
* Updated the inferred Cloud Storage bucket for newly created Firebase projects
  to the current `PROJECT_ID.firebasestorage.app` format. Legacy projects can pass
  their existing `PROJECT_ID.appspot.com` bucket explicitly.
* Made Cloud Storage uploads compatible with uniform bucket-level access by
  applying object ACLs only when explicitly requested, and cached service-account
  access tokens separately for each OAuth scope set.
* Documented Realtime Database regional URLs and the package's supported Firebase
  feature scope.
* Marked Firebase Dynamic Links helpers as unavailable following the service's
  shutdown on August 25, 2025.
* Removed stale CRAN availability claims, broken external artwork, temporary
  repository files, and unused suggested dependencies.

# fireData 2.0.0

## Breaking Changes

* Minimum R version increased to 4.1.0
* Function naming convention changed to snake_case (old camelCase functions deprecated)
* Connection object pattern introduced - most functions now accept a `conn` parameter

## New Features

### Architecture
* **Modular design**: Package split from single 792-line file into 15 focused modules
* **Connection objects**: New `firebase_connect()` creates reusable connection with configuration
* **Configuration management**: Support for environment variables, config files, and interactive setup
* **Custom error classes**: Firebase-specific error types with detailed messages
* **Service account support**: Full support for server-side authentication via service accounts

### Authentication
* `auth_sign_in()` - Sign in with email/password (replaces `auth()`)
* `auth_anonymous()` - Anonymous sign in (replaces `anonymous_login()`)
* `auth_create_user()` - Create new user (replaces `createUser()`)
* `auth_reset_password()` - Send password reset email (replaces `resetPassword()`)
* `auth_google()` - Google OAuth sign in (replaces `google_login()`)
* `auth_refresh_token()` - Refresh expired tokens (NEW)
* `auth_get_user()` - Get current user info (NEW)
* `auth_update_profile()` - Update user profile (NEW)
* `auth_delete_user()` - Delete user account (NEW)

### Realtime Database
* `rtdb_get()` - Read data (replaces `download()`)
* `rtdb_set()` - Write/overwrite data (replaces `put()`)
* `rtdb_push()` - Add data with auto-key (replaces `upload()`)
* `rtdb_update()` - Partial update (replaces `patch()`)
* `rtdb_delete()` - Delete data (replaces `delete()`)
* `rtdb_backup()` - Full database backup (replaces `dataBackup()`)
* `rtdb_query()` - Query builder with filtering/sorting (NEW)

### Cloud Firestore (NEW)
* `firestore_get()` - Get a document from a collection
* `firestore_set()` - Create/overwrite a document
* `firestore_add()` - Add document with auto-generated ID
* `firestore_update()` - Update specific fields in a document
* `firestore_delete()` - Delete a document
* `firestore_list()` - List documents in a collection with pagination
* `firestore_query()` - Query builder for complex queries
* Query helpers: `fs_where()`, `fs_order_by()`, `fs_limit()`, `fs_offset()`, `fs_select()`, `fs_execute()`
* Support for common Firestore data types (strings, numbers, booleans, timestamps, arrays, maps)

### Cloud Storage
* `storage_upload()` - Upload files (replaces `upload_storage()`)
* `storage_download()` - Download files (NEW)
* `storage_delete()` - Delete files (replaces `delete_storage()`)
* `storage_list()` - List files (replaces `list_storage()`)
* `storage_get_metadata()` - Get file metadata (replaces `get_storage()`)
* `storage_get_url()` - Get download URL (replaces `get_url()`)
* `storage_upload_folder()` - Upload folder (replaces `upload_folder()`)

### Dynamic Links
* `dynlink_create()` - Create short links (replaces `get_dynamic_link()`)
* Legacy Dynamic Links helpers are retained for compatibility. Firebase Dynamic
  Links shut down on August 25, 2025, so these helpers no longer make API requests.

### Configuration
* `firebase_connect()` - Create connection object (NEW)
* `firebase_config_set()` - Set session configuration (NEW)
* `firebase_config_get()` - Get configuration value (NEW)
* `firebase_config_load()` - Load from YAML file (NEW)
* `firebase_config_wizard()` - Interactive setup (NEW)

### Utilities
* `path_sanitize()` - Clean Firebase paths (replaces `path_check()`)
* `FirebaseToken` - R6 class for token management with auto-refresh (NEW)
* `ServiceAccountCredentials` - R6 class for service account auth (NEW)

## Deprecated Functions

The following functions are deprecated but still work. They will show deprecation warnings:

| Deprecated | Use Instead |
|------------|-------------|
| `auth()` | `auth_sign_in()` |
| `anonymous_login()` | `auth_anonymous()` |
| `createUser()` | `auth_create_user()` |
| `resetPassword()` | `auth_reset_password()` |
| `google_login()` | `auth_google()` |
| `upload()` | `rtdb_push()` |
| `download()` | `rtdb_get()` |
| `put()` | `rtdb_set()` |
| `patch()` | `rtdb_update()` |
| `delete()` | `rtdb_delete()` |
| `dataBackup()` | `rtdb_backup()` |
| `upload_storage()` | `storage_upload()` |
| `delete_storage()` | `storage_delete()` |
| `list_storage()` | `storage_list()` |
| `get_storage()` | `storage_get_metadata()` |
| `get_url()` | `storage_get_url()` |
| `upload_folder()` | `storage_upload_folder()` |
| `get_dynamic_link()` | `dynlink_create()` |
| `path_check()` | `path_sanitize()` |

## Infrastructure

* CI migrated from Travis CI to GitHub Actions
* Test credentials removed from source code (now via environment variables)
* Added test helpers for safe credential handling
* Code coverage reporting via Codecov

## Dependencies

### Added
* R6 (>= 2.5.0) - For token and credential classes
* openssl (>= 2.0.0) - For JWT signing
* yaml (>= 2.3.0) - For config file support

### Updated
* httr (>= 1.4.0)
* jsonlite (>= 1.8.0)
* curl (>= 5.0.0)

### Removed
* Removed hardcoded test credentials
* Removed deprecated `.travis.yml`

---

# fireData 1.16

* Last release of v1.x series
* See GitHub releases for historical changes
