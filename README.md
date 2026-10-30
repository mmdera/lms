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
