[![GitHub tag](https://img.shields.io/github/v/tag/Kohze/fireData?label=version)](https://github.com/Kohze/fireData/tags)
[![R-CMD-check](https://github.com/Kohze/fireData/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Kohze/fireData/actions/workflows/R-CMD-check.yaml)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/Kohze/fireData/master/LICENSE)

# fireData: Connecting R to Google Firebase

fireData integrates R with selected Google Firebase services, enabling data exchange, user authentication, and cloud storage directly from R.

**Key Features:**
- **Realtime Database**: Store and sync data in real-time across clients
- **Cloud Firestore**: Flexible, scalable NoSQL document database with powerful queries
- **Authentication**: Email/password, Google OAuth, and anonymous sign-in
- **Cloud Storage**: Upload and download files to Firebase Storage
- **Shiny Integration**: Built-in authentication UI for Shiny applications
- **Service Accounts**: Server-side authentication and automation

> **Version 2.0.1** introduces a modern API with consistent naming, connection objects, and improved error handling. All v1.x functions remain available with deprecation warnings.

fireData covers the common REST operations for Realtime Database, Cloud Firestore,
Authentication, and Cloud Storage. It is not a client for every Firebase product or
every advanced endpoint. See [Firebase feature support](inst/FIREBASE-SUPPORT.md) for the
audited support matrix.

---

## Installation

```r
# Install from GitHub
# install.packages("pak")
pak::pak("Kohze/fireData")
```

## Firebase Project Setup

1. Visit [Firebase Console](https://console.firebase.google.com/)
2. Create a new project (or select existing)
3. Navigate to **Project Settings** (gear icon)
4. Find your **Web API Key** and **Project ID**
5. Enable the Firebase services you plan to use
6. Copy the exact **Realtime Database URL** and **Storage bucket** from the console
7. For OAuth features, configure credentials in [Google Cloud Console](https://console.developers.google.com/apis/credentials)

## Configuration

fireData supports multiple configuration methods. Choose one approach; each
example below produces a `firebase_conn` connection object.

```r
library(fireData)

# Option 1: Environment variables (recommended for production)
Sys.setenv(FIREBASE_PROJECT_ID = "your-project-id")
Sys.setenv(FIREBASE_API_KEY = "your-api-key")
Sys.setenv(FIREBASE_DATABASE_URL = "https://your-database-url")
Sys.setenv(FIREBASE_STORAGE_BUCKET = "your-project-id.firebasestorage.app")
firebase_conn <- firebase_connect()

# Option 2: Create a connection with explicit values
firebase_conn <- firebase_connect(
  project_id = "your-project-id",
  api_key = "your-api-key",
  database_url = "https://your-database-url",
  storage_bucket = "your-project-id.firebasestorage.app"
)

# Option 3: Interactive setup wizard
firebase_config_wizard()
firebase_conn <- firebase_connect()
```

---

## Quick Start

### Connect and authenticate a Firebase user

Create one connection, sign in, and then store the returned Firebase ID token in
that connection. The authenticated `firebase_conn` is reused by the Realtime
Database and Firestore examples below.

```r
firebase_conn <- firebase_connect(
  project_id = "your-project-id",
  api_key = "your-api-key",
  database_url = "https://your-database-url"
)

auth_response <- auth_sign_in(
  conn = firebase_conn,
  email = "user@example.com",
  password = "password123"
)

firebase_conn <- firebase_set_token(firebase_conn, auth_response)
user_id <- auth_response$localId
```

Account creation and anonymous sign-in are alternatives to email/password
sign-in. If you use one of them, pass its response to `firebase_set_token()` in
the same way:

```r
new_user_auth <- auth_create_user(
  conn = firebase_conn,
  email = "newuser@example.com",
  password = "securepassword"
)

anonymous_auth <- auth_anonymous(conn = firebase_conn)

# Each alternative response can create its own authenticated connection
new_user_conn <- firebase_set_token(firebase_conn, new_user_auth)
anonymous_conn <- firebase_set_token(firebase_conn, anonymous_auth)
```

### Realtime Database Operations

These examples use the authenticated `firebase_conn` created above. An
unauthenticated request works only when your Realtime Database Security Rules
explicitly allow public access.

```r
# Push data (auto-generated key)
message_path <- rtdb_push(firebase_conn, "messages", list(
  text = "Hello from R!",
  authorId = user_id,
  timestamp = Sys.time()
))

# Store data below the authenticated user's ID
user_path <- paste0("users/", user_id)
rtdb_set(firebase_conn, user_path, list(
  name = "John Doe",
  email = "john@example.com"
))

# Update specific fields (merge)
rtdb_update(firebase_conn, user_path, list(
  lastLogin = Sys.time()
))

# Read data
user_profile <- rtdb_get(firebase_conn, user_path)

# Query with filtering
user_query_results <- rtdb_query(firebase_conn, "users") |>
  query_order_by("name") |>
  query_limit_to_first(10) |>
  query_execute()

# Delete the message created above
rtdb_delete(firebase_conn, message_path)

# Backup requires permission to read the database root
rtdb_backup(firebase_conn, file_name = "backup.json")
```

### Cloud Firestore

Cloud Firestore is a flexible, scalable NoSQL document database. It stores data in **documents** organized into **collections**, making it ideal for complex, structured data with powerful querying.

The calls below reuse the authenticated `firebase_conn`. Firestore evaluates the
Firebase ID token against your Firestore Security Rules.

```r
# Create/overwrite a document
firestore_set(firebase_conn, "users", user_id, list(
  name = "John Doe",
  email = "john@example.com",
  age = 30
))

# Add document with auto-generated ID
created_message <- firestore_add(firebase_conn, "messages", list(
  text = "Hello Firestore!",
  authorId = user_id,
  timestamp = Sys.time()
))

# Get a document
firestore_user <- firestore_get(firebase_conn, "users", user_id)

# Update specific fields
firestore_update(firebase_conn, "users", user_id, list(
  lastLogin = Sys.time()
))

# Query with filters
product_matches <- firestore_query(firebase_conn, "products") |>
  fs_where("price", "<", 100) |>
  fs_where("inStock", "==", TRUE) |>
  fs_order_by("price", "asc") |>
  fs_limit(20) |>
  fs_execute()

# Delete a document
firestore_delete(firebase_conn, "users", user_id)
```

### Cloud Storage

fireData accesses Storage through the Google Cloud Storage JSON API. These
server-side calls use Google Cloud IAM credentials, not the Firebase user ID
token stored in `firebase_conn`. The following example uses a service account
whose IAM role permits access to the bucket.

```r
storage_conn <- firebase_connect(
  project_id = "your-project-id",
  storage_bucket = "your-project-id.firebasestorage.app",
  credentials = "path/to/service-account.json"
)

# Upload a file
uploaded_object <- storage_upload(
  storage_conn,
  file_path = "local/image.jpg",
  object_name = "images/photo.jpg"
)

# Download a file
downloaded_file <- storage_download(
  storage_conn,
  object_name = "images/photo.jpg",
  dest_file = "downloaded.jpg"
)

# Existing objects created by a Firebase SDK may have download-token metadata.
# Google Cloud Storage API uploads do not add that metadata automatically.
download_url <- storage_get_url(
  storage_conn,
  "images/existing-firebase-object.jpg"
)

# List files
stored_objects <- storage_list(storage_conn, prefix = "images/")
```

### Data Frames

fireData seamlessly handles R data frames:

```r
# Upload data frame
dataset_path <- rtdb_push(firebase_conn, "datasets", mtcars)

# Read the same data frame using the returned path
downloaded_data <- rtdb_get(firebase_conn, dataset_path)
head(downloaded_data)
```

---

## Migration from v1.x

Version 2.0.1 uses the modern naming convention introduced in the 2.x series.
The old functions still work but show deprecation warnings:

| v1.x (deprecated) | v2.0.1 (recommended) |
|-------------------|-------------------|
| `auth()` | `auth_sign_in()` |
| `anonymous_login()` | `auth_anonymous()` |
| `createUser()` | `auth_create_user()` |
| `upload()` | `rtdb_push()` |
| `download()` | `rtdb_get()` |
| `put()` | `rtdb_set()` |
| `patch()` | `rtdb_update()` |
| `delete()` | `rtdb_delete()` |
| `dataBackup()` | `rtdb_backup()` |

See `vignette("firedata")` for complete documentation.

---

## Projects Using fireData

- **SpatialMaps**: A spatial proteomics platform using Firebase as a cross-platform database
- **Cryptotrade-hq bot**: Data collector with Shiny using Firebase for secure API key storage
- **Various Shiny applications**: Authentication and persistent storage

---

## Documentation

- `vignette("firedata")` - Getting started guide
- [Firebase feature support](inst/FIREBASE-SUPPORT.md) - Audited support matrix
- [GitHub Issues](https://github.com/Kohze/fireData/issues) - Bug reports and feature requests
- [Firebase Documentation](https://firebase.google.com/docs) - Official Firebase docs

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgements

This package was created within the framework of Google Summer of Code 2017 and 2018.

Special thanks to GSOC mentors L. Pedraza, S. Schmidt, and especially L. Gatto for their insights and experience in making this package a reality.

---

## License

MIT License - see [LICENSE](LICENSE) for details.
