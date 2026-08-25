[![GitHub tag](https://img.shields.io/github/v/tag/Kohze/fireData?label=version)](https://github.com/Kohze/fireData/tags)
[![R-CMD-check](https://github.com/Kohze/fireData/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Kohze/fireData/actions/workflows/R-CMD-check.yaml)
[![codecov](https://codecov.io/gh/Kohze/fireData/branch/master/graph/badge.svg)](https://codecov.io/gh/Kohze/fireData)
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

fireData supports multiple configuration methods:

```r
library(fireData)

# Option 1: Environment variables (recommended for production)
Sys.setenv(FIREBASE_PROJECT_ID = "your-project-id")
Sys.setenv(FIREBASE_API_KEY = "your-api-key")
Sys.setenv(FIREBASE_DATABASE_URL = "https://your-database-url")
Sys.setenv(FIREBASE_STORAGE_BUCKET = "your-project-id.firebasestorage.app")

# Option 2: Create a connection with explicit values
conn <- firebase_connect(
  project_id = "your-project-id",
  api_key = "your-api-key",
  database_url = "https://your-database-url",
  storage_bucket = "your-project-id.firebasestorage.app"
)

# Option 3: Interactive setup wizard
firebase_config_wizard()
```

---

## Quick Start

### Authentication

```r
# Anonymous login
result <- auth_anonymous(api_key = "your-api-key")

# Email/password login
result <- auth_sign_in(
  api_key = "your-api-key",
  email = "user@example.com",
  password = "password123"
)

# Create new user
result <- auth_create_user(
  api_key = "your-api-key",
  email = "newuser@example.com",
  password = "securepassword"
)

# Update connection with authentication
conn <- firebase_set_token(conn, result)
```

### Realtime Database Operations

```r
# Create connection
conn <- firebase_connect(
  api_key = "your-api-key",
  database_url = "https://your-database-url"
)

# Push data (auto-generated key)
path <- rtdb_push(conn, "messages", list(
  text = "Hello from R!",
  author = "R User",
  timestamp = Sys.time()
))

# Set data at specific path (overwrites)
rtdb_set(conn, "users/user123", list(
  name = "John Doe",
  email = "john@example.com"
))

# Update specific fields (merge)
rtdb_update(conn, "users/user123", list(
  lastLogin = Sys.time()
))

# Read data
user <- rtdb_get(conn, "users/user123")

# Query with filtering
results <- rtdb_query(conn, "users") |>
  query_order_by("name") |>
  query_limit_to_first(10) |>
  query_execute()

# Delete data
rtdb_delete(conn, "messages/-NxYz123")

# Backup entire database
rtdb_backup(conn, filename = "backup.json")
```

### Cloud Firestore

Cloud Firestore is a flexible, scalable NoSQL document database. It stores data in **documents** organized into **collections**, making it ideal for complex, structured data with powerful querying.

```r
# Authenticate (Firestore requires authentication)
result <- auth_sign_in(conn, "user@example.com", "password")
conn <- firebase_set_token(conn, result)

# Create/overwrite a document
firestore_set(conn, "users", "user123", list(
  name = "John Doe",
  email = "john@example.com",
  age = 30
))

# Add document with auto-generated ID
result <- firestore_add(conn, "messages", list(
  text = "Hello Firestore!",
  timestamp = Sys.time()
))

# Get a document
user <- firestore_get(conn, "users", "user123")

# Update specific fields
firestore_update(conn, "users", "user123", list(
  lastLogin = Sys.time()
))

# Query with filters
results <- firestore_query(conn, "products") |>
  fs_where("price", "<", 100) |>
  fs_where("inStock", "==", TRUE) |>
  fs_order_by("price", "asc") |>
  fs_limit(20) |>
  fs_execute()

# Delete a document
firestore_delete(conn, "users", "user123")
```

### Cloud Storage

```r
# Upload a file
result <- storage_upload(conn,
  file_path = "local/image.jpg",
  object_name = "images/photo.jpg"
)

# Download a file
storage_download(conn, "images/photo.jpg", "downloaded.jpg")

# Get download URL
url <- storage_get_url(conn, "images/photo.jpg")

# List files
files <- storage_list(conn, prefix = "images/")
```

### Data Frames

fireData seamlessly handles R data frames:

```r
# Upload data frame
rtdb_push(conn, "datasets", mtcars)

# Download returns a data frame
data <- rtdb_get(conn, "datasets/-KeyHere")
head(data)
```

---

## Migration from v1.x

Version 2.0 uses a new naming convention. The old functions still work but show deprecation warnings:

| v1.x (deprecated) | v2.0 (recommended) |
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
