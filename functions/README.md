# Admin user-existence API

This Firebase HTTP Function checks Firebase Authentication for an existing user. Calls require a valid Firebase ID token whose custom claims contain `admin: true`.

## Endpoint

After deployment, use the exact function URL printed by the Firebase CLI and append `/api/admin/users/exists`. For this project's configured region, it will have this shape:

```text
https://asia-south1-healthsathi-c7ec6.cloudfunctions.net/adminApi/api/admin/users/exists
```

Send exactly one identifier:

```json
{"email":"user@example.com"}
```

or:

```json
{"uid":"firebase-user-id"}
```

## Admin-panel example

```js
import {getAuth} from "firebase/auth";

export async function userExists(identifier) {
  const admin = getAuth().currentUser;
  if (!admin) throw new Error("Admin is not signed in");

  // Pass true so a newly granted admin claim is picked up immediately.
  const idToken = await admin.getIdToken(true);
  const response = await fetch(
    "https://asia-south1-healthsathi-c7ec6.cloudfunctions.net/adminApi/api/admin/users/exists",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${idToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(identifier),
    },
  );

  const result = await response.json();
  if (!response.ok) {
    throw new Error(result.error ?? "User lookup failed");
  }

  return result;
}

const result = await userExists({email: "user@example.com"});
console.log(result.exists);
```

Responses are either:

```json
{"exists":true,"uid":"firebase-user-id","disabled":false}
```

or:

```json
{"exists":false}
```

## Verify and deploy

From the repository root:

```powershell
Set-Location functions
npm install
npm test
npm run build
Set-Location ..
npx firebase-tools deploy --only functions:adminApi --project healthsathi-c7ec6
```

Deployment requires Firebase CLI authentication and a Firebase project plan that supports Cloud Functions. The CLI prints the authoritative function URL after a successful deployment.
