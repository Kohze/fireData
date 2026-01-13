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
* Note: Firebase Dynamic Links is deprecated and will shut down August 2025

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
