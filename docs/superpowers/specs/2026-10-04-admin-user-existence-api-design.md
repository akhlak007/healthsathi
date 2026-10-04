# Admin User Existence API Design

## Goal

Add a small, authenticated HTTP API that lets the existing admin panel determine whether a user account exists in HealthSathi's Firebase Authentication tenant. The endpoint must not expose profile or credential data.

## API contract

The Firebase Function exposes an Express application with this endpoint:

```http
POST /api/admin/users/exists
Authorization: Bearer <firebase-id-token>
Content-Type: application/json

{"email":"user@example.com"}
```

The request must contain exactly one supported identifier:

- `email`: a non-empty email address, normalized by trimming whitespace and converting it to lowercase.
- `uid`: a non-empty Firebase Authentication user ID.

Successful lookups return HTTP 200. A found account returns:

```json
{"exists":true,"uid":"firebase-user-id","disabled":false}
```

A missing account also returns HTTP 200:

```json
{"exists":false}
```

Using the same status for found and missing accounts makes the endpoint simple for the admin panel while authorization prevents it from becoming a public account-enumeration service.

Invalid or ambiguous input returns HTTP 400. A missing or invalid ID token returns HTTP 401, and an authenticated user without the admin claim returns HTTP 403. Unexpected server errors return HTTP 500 without internal error details.

## Authentication and authorization

The route reads a Firebase ID token from the `Authorization: Bearer` header and verifies it with the Firebase Admin SDK. The decoded token must contain `admin: true`. This uses the existing admin identity model described by the user while enforcing authorization inside the API rather than trusting the caller.

The Express application will be exported separately from the Firebase Functions entry point. This keeps request behavior testable without deploying a function.

## User lookup

Firebase Authentication is the source of truth for account existence. The route uses `getUserByEmail` for email input and `getUser` for UID input. An `auth/user-not-found` Admin SDK error maps to `{ "exists": false }`; other Firebase errors are treated as server errors.

Firestore is deliberately not the source of truth. The current mobile signup flow permits authentication creation to succeed when its Firestore profile write fails, so a Firestore-only lookup can report a false negative.

## Project structure

A new `functions/` package will contain:

- the Firebase Functions entry point and Express application;
- admin-token authorization middleware;
- the user-existence route;
- focused endpoint tests;
- package and TypeScript configuration required to build and run the function.

The root Firebase configuration will declare the Functions source directory. Existing Flutter application files and unrelated working-tree changes will remain untouched.

## Security and privacy

- Every request requires a verified Firebase admin token.
- The response includes only existence, UID, and disabled state; it excludes email, display name, provider data, metadata, and profile fields.
- The endpoint accepts JSON only and applies a small request-body limit.
- Error responses do not expose stack traces or Firebase internals.
- The route does not log submitted email addresses or UIDs.

The repository's broad fallback Firestore rule is outside this endpoint's implementation scope, though it should be tightened separately because it currently permits any authenticated user to access unmatched documents.

## Testing

Automated tests will inject mocked Firebase Admin authentication services and verify:

- lookup by email finds a user;
- lookup by UID finds a user;
- a missing user returns `exists: false`;
- invalid and ambiguous bodies return HTTP 400;
- missing, invalid, and non-admin tokens are rejected;
- unexpected lookup failures return a generic HTTP 500 response.

The completed package must pass its type-check/build and test commands.

## Deployment and client usage

Deployment uses the Firebase CLI against the project's existing Firebase project. The handoff will include the exact deployment command and a JavaScript `fetch` example showing how the admin panel supplies its Firebase ID token and consumes the response.
