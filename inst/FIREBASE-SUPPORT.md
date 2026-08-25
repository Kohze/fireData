# Firebase feature support

This matrix was audited against the official Firebase REST documentation on
August 24, 2026. fireData is an R client for common operations in four Firebase
services; it is not intended to expose every Firebase product.

| Service | Supported | Important gaps |
|---|---|---|
| Realtime Database | Read, shallow read, set, push, update, delete, backup, and basic ordered/range/limit queries | Streaming listeners, ETags and conditional writes, priorities, query timeouts, and database administration |
| Cloud Firestore | Document create/get/set/update/delete, collection listing and pagination, structured filters, ordering, projection, offset, and limit | Transactions, batched reads/writes, aggregation and pipeline queries, collection-group queries, cursors, listeners, query explain, named databases, and administrative APIs |
| Authentication | Email/password and anonymous sign-in, account creation, password reset, token refresh, user lookup/profile update/delete, Google and generic identity-provider exchange | Custom-token sign-in, email verification/link sign-in, email/password changes, phone authentication, multi-factor authentication, provider linking/unlinking, and administrative user management |
| Cloud Storage | Media upload/download/delete, object listing, metadata lookup, download URLs, and folder upload | Resumable/multipart uploads, metadata update, pagination, copy/move/rewrite, signed URLs, bucket administration, and Firebase Security Rules client flows |

## Compatibility notes

- Realtime Database URLs are location-specific. Use the exact URL shown in the
  Firebase console. US Central databases use `DATABASE_NAME.firebaseio.com`;
  other regions use `DATABASE_NAME.REGION.firebasedatabase.app`.
- Default Storage buckets created since September 2024 use
  `PROJECT_ID.firebasestorage.app`. Older default buckets retain
  `PROJECT_ID.appspot.com`. Pass `storage_bucket` explicitly for legacy projects.
- Cloud Storage for Firebase now requires the Blaze pricing plan.
- Firebase Dynamic Links shut down on August 25, 2025. The legacy exported
  helpers remain only to provide a clear migration error.
- Storage operations use the Google Cloud Storage JSON API and OAuth. These calls
  follow Google Cloud IAM and access controls rather than Firebase client SDK
  Security Rules.
- Storage uploads use bucket IAM by default. A predefined object ACL can be
  requested explicitly for buckets that still use fine-grained access control.

## Out of scope

The wider Firebase platform also includes App Check, App Hosting, Cloud Functions,
Extensions, Hosting, Phone Number Verification, SQL Connect, Firebase AI Logic,
Analytics, Crashlytics, Cloud Messaging, Remote Config, Performance Monitoring,
Test Lab, and other products. fireData does not currently implement these services.

## Audit references

- [Firebase products](https://firebase.google.com/products-build)
- [Realtime Database REST setup](https://firebase.google.com/docs/database/rest/start)
- [Realtime Database REST reference](https://firebase.google.com/docs/reference/rest/database)
- [Cloud Firestore REST reference](https://firebase.google.com/docs/firestore/reference/rest)
- [Firebase Authentication REST reference](https://firebase.google.com/docs/reference/rest/auth)
- [Cloud Storage and Google Cloud integration](https://firebase.google.com/docs/storage/gcp-integration)
- [Cloud Storage default bucket and billing changes](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024)
- [Dynamic Links shutdown FAQ](https://firebase.google.com/support/dynamic-links-faq)
