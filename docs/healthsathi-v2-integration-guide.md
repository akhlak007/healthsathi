# `healthSathi-v2` Backend Integration Guide (QR Check-In + Firestore Report Delivery)

This guide matches the exact file layout of [`TOMJID/healthSathi-v2`](https://github.com/TOMJID/healthSathi-v2) (`apps/backend`) so it connects seamlessly to the Flutter mobile app's **Hospital QR Check-In** feature (`lib/features/hospital_checkin/`).

---

## 1. Install `firebase-admin` in `apps/backend`

```bash
pnpm --filter backend add firebase-admin
```

Add Firebase service account credentials (for Firebase project `healthsathi-c7ec6`) to `apps/backend/.env`:

```env
FIREBASE_PROJECT_ID="healthsathi-c7ec6"
FIREBASE_CLIENT_EMAIL="firebase-adminsdk-xxxx@healthsathi-c7ec6.iam.gserviceaccount.com"
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

---

## 2. Prisma Schema Updates (`apps/backend/prisma/schema.prisma`)

```prisma
enum VisitStatus {
  CHECKED_IN
  IN_PROGRESS
  COMPLETED
  CANCELLED
}

model User {
  id          String          @id @default(uuid())
  firebaseUid String?         @unique
  patientCode String?         @unique // e.g. HS-2026-000001
  email       String?         @unique
  phone       String?
  bloodGroup  String?
  fullName    String
  role        UserRole        @default(PATIENT)
  createdAt   DateTime        @default(now())
  updatedAt   DateTime        @updatedAt

  reports     Report[]
  visits      HospitalVisit[]

  @@map("users")
}

model HospitalVisit {
  id              String      @id @default(uuid())
  hospital        Hospital    @relation(fields: [hospitalId], references: [id])
  hospitalId      String
  user            User        @relation(fields: [userId], references: [id])
  userId          String
  patientCode     String
  familyProfileId String      @default("self")
  patientName     String
  status          VisitStatus @default(CHECKED_IN)
  checkedInAt     DateTime    @default(now())
  completedAt     DateTime?

  reports         Report[]

  @@map("hospital_visits")
}

model Report {
  id          String         @id @default(uuid())
  hospital    Hospital       @relation(fields: [hospitalId], references: [id])
  hospitalId  String
  staff       HospitalStaff  @relation(fields: [staffId], references: [id])
  staffId     String
  visit       HospitalVisit? @relation(fields: [visitId], references: [id])
  visitId     String?
  title       String         @default("Diagnostic Report")
  reportType  String         @default("lab_report")
  doctorName  String?
  notes       String?
  pdfUrl      String         // Cloudinary public_id
  secureUrl   String?        // Full HTTPS URL ending in .pdf
  status      ReportStatus   @default(PENDING)
  createdAt   DateTime       @default(now())
  user        User           @relation(fields: [userId], references: [id])
  userId      String

  @@map("reports")
}
```

*(Also add `visits HospitalVisit[]` to the `Hospital` model and run `pnpm prisma:migrate && pnpm prisma:generate`.)*

---

## 3. Firebase Service & Guard (`apps/backend/src/module/firebase/`)

- **`firebase.service.ts`**: Initializes `firebase-admin` once using `ConfigService` and exposes `auth()` and `firestore()`.
- **`firebase-auth.guard.ts`**: Reads `Authorization: Bearer <token>`, calls `this.firebase.auth().verifyIdToken(token)`, and sets `req.firebaseUser = { uid, email }`.

---

## 4. QR Payload & Check-In Endpoints

### A. Generate Hospital Reception QR (`GET /hospitals/qr-payload`)
Protected by `JwtAuthGuard` + `RolesGuard` (`HOSPITAL_ADMIN`, `HOSPITAL_STAFF`):

```ts
return {
  type: 'healthsathi_checkin',
  hospitalId: hospital.id,
  hospitalName: hospital.name,
  // Optional: include public backend URL so QR works without hardcoding in .env
  // apiBaseUrl: process.env.PUBLIC_API_URL,
};
```

Encode that JSON string as a QR code in `apps/frontend`.

### B. Patient Check-In (`POST /hospitals/:hospitalId/check-in`)
Protected by `FirebaseAuthGuard` (called by the Flutter mobile app):

1. Verify `hospital` exists and `hospital.status === 'APPROVED'`.
2. Read the authoritative `users/{firebaseUid}` document from Firestore using `firebase.firestore()` to fetch `patientId` (`HS-2026-XXXXXX`) and `name`/`bloodGroup`.
3. Upsert `prisma.user` by `firebaseUid` (storing `patientCode`, `fullName`, `email`, `bloodGroup`).
4. Create a `prisma.hospitalVisit` row with `status: 'CHECKED_IN'`, `familyProfileId`, and `patientName`.
5. Return HTTP 201:
   ```json
   {
     "visitId": "...",
     "hospitalName": "City General Hospital",
     "patientCode": "HS-2026-000001",
     "patientName": "...",
     "status": "CHECKED_IN"
   }
   ```

### C. Hospital Queue (`GET /hospitals/visits`)
Protected by `JwtAuthGuard` + `RolesGuard` (`HOSPITAL_ADMIN`, `HOSPITAL_STAFF`):
Returns `prisma.hospitalVisit.findMany({ where: { hospitalId }, orderBy: { checkedInAt: 'desc' } })`.

---

## 5. Deliver Report PDF Directly to Patient's Mobile App

1. **Preserve `.pdf` extension on Cloudinary upload (`apps/backend/src/module/cloudinary/cloudinary.service.ts`)**:
   In `uploadFile()`, pass `public_id: `${Date.now()}_${hospitalId.slice(0, 6)}.pdf`` (with `resource_type: 'raw'`), so `getFileUrl()` ends in `.pdf`.
2. **Update `ReportService.saveReport()`**:
   - Accept optional `visitId`, `title`, `reportType`, `doctorName`, `notes`.
   - Save `Report` in PostgreSQL and update `HospitalVisit.status = 'COMPLETED'`.
   - Resolve `patient.firebaseUid` and `familyProfileId` (default `'self'`).
   - Write the `OcrRecord` document into Firestore:
     - Path if `'self'`: `users/${firebaseUid}/records/${report.id}`
     - Path if family member: `users/${firebaseUid}/familyProfiles/${familyProfileId}/records/${report.id}`
   - Fields written to Firestore:
     ```ts
     const now = admin.firestore.Timestamp.now();
     await targetCollection.doc(report.id).set({
       recordType: dto.reportType ?? 'lab_report',
       recordLabel: dto.title ?? 'Hospital Diagnostic Report',
       doctorName: dto.doctorName ?? staff.fullName,
       hospitalName: hospital.name,
       date: now,
       ocrText: dto.notes ?? '',
       imageUrl: null,
       pdfUrl: viewUrl,
       medicines: [],
       notes: dto.notes ?? `Uploaded by ${hospital.name}`,
       createdAt: now,
       updatedAt: now,
       timelineVisible: true,
       userId: firebaseUid,
       source: 'hospital',
       hospitalId,
       verifiedByHospital: true,
     });
     ```

