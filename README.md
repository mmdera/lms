# EduIQ LMS — V26

GitHub Pages-ready EduIQ LMS build. V26 establishes a single authoritative Supabase snapshot for all devices and includes an institution-wide cloud reset script.

## V26 changes
- Existing Supabase cloud snapshot is authoritative even when it contains an empty/reset payload. Old browser caches can no longer repopulate records after the reset.
- Administrator password is stored in the shared application snapshot, so an administrator password change is shared across devices.
- Fresh administrator credentials: **Admin ID `admin` / Password `EduIQ#2026`**. The first sign-in prompts the administrator to change this password.
- Admin Portal → Students → Add student continues to issue a unique admission number and initial password. The first new student after reset receives **`EDUIQ/2026/0001` / `Student@0001`**. Later students increment the serial.
- Student creation, edits, credentials, attendance, fee and academic data are synchronized through the same cloud snapshot.

## Required one-time Supabase setup
1. Open the Supabase project configured in `js/app.js`.
2. In **SQL Editor**, run `supabase/11_cloud_state_sync.sql` if the `eduiq_app_state` table and policies have not already been created.
3. Review the destructive warning in `supabase/12_reset_eduiq_cloud.sql`, then run it once to clear the shared EduIQ app data and reset the administrator password. This creates an authoritative empty snapshot so stale PCs cannot restore old data.
4. Deploy this V26 build to GitHub Pages / your hosting provider.
5. Open the deployed app on each device and sign in with the administrator credentials above. Add students from **Admin Portal → Students → Add student**; issue each student their generated admission number and password.

**Important:** The reset SQL clears the V26 frontend's shared `eduiq_app_state` snapshot. It does not delete Supabase Auth users or records in the separate normalized tables from `01_schema.sql`. Those are not used by this frontend data adapter.

## Local development
```bash
npm install
npm run dev
```

## Cross-device and security note
This version is a compatibility bridge for the existing static frontend. `11_cloud_state_sync.sql` grants anonymous read/write access to the shared JSON snapshot, and the current frontend stores student/admin passwords in that snapshot. It is suitable only for a controlled demo/test environment, **not production storage of real student personal information or credentials**. A production deployment needs Supabase Auth, server-side credential verification (for example an Edge Function), and per-role RLS policies; never expose a service-role key in frontend code.

The cross-device reset/login workflow requires the Supabase SQL setup above and a deployed build. Merely downloading the ZIP does not erase the live Supabase database.

## V27 — cross-device authentication and cloud sync fix
- Admin credential changes are now treated as shared institution data and queued for cloud sync even before students or academic records exist.
- Login waits for a successful cloud read; database/CDN errors are shown as cloud errors rather than misleading "Invalid credentials" messages.
- A clean first device can bootstrap the shared snapshot when the administrator signs in; a clean secondary device cannot overwrite the institution snapshot.
- After deployment, sign in on the main laptop once while online, then use the same credentials on other devices.

If cloud access reports a database/table error, run `supabase/11_cloud_state_sync.sql` in the configured Supabase project's SQL Editor and verify the project URL/key in `js/app.js`.

## V28 — persistent login across refresh

- Login state is now stored in browser `localStorage` instead of relying only on `sessionStorage`.
- On page reload, the app waits for the shared cloud snapshot to hydrate, then restores the signed-in admin or student workspace and last visited page.
- Student sessions are restored only if the matching admission number still exists in the current student list.
- The Sign out button explicitly clears the persistent session. Clearing site data or using a different browser/device still requires signing in again.
- This is a convenience session mechanism for the current demo architecture, not a substitute for server-side Supabase Auth. Anyone with access to the same unlocked browser profile may access its active session; use Sign out on shared computers.


## V29 update
- Serializes cloud writes to prevent concurrent autosaves from being dropped.
- Password changes now await a successful Supabase write and report sync failures clearly.
- Uses the existing V28 cloud state and schema; no database reset or SQL migration is required.


## V30 cloud connection fix

- Replaced the Supabase JavaScript SDK calls used by the LMS cloud-state layer with direct PostgREST `fetch` requests.
- Uses the verified publishable key in the `apikey` header, matching the successful browser diagnostic request.
- Reads and upserts `eduiq_app_state` directly; the existing table and RLS policies remain required.
- Removed the unused Supabase SDK CDN include to avoid duplicate GoTrue client initialization warnings.
- Added `?v=30` cache-busting to the app JS and stylesheet references.

After deploying, hard-refresh each device (Ctrl+Shift+R) once. No database reset is required.


## V31 publishable API key correction
- Corrected the frontend publishable API key to exactly match the key supplied and successfully tested by the user.
- V30 had an extra/misplaced character in the configured key, which caused the LMS to receive `Invalid API key` even though the direct diagnostic request succeeded.
- Updated asset query versions to force browsers to fetch the corrected JavaScript and CSS.
- No database reset or SQL changes are required for this key correction.
