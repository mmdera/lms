# EduIQ LMS — GitHub Pages V4

Premium LMS / academic portal frontend for EduIQ.

## V4 fixes
- Corrected top-bar spacing between `STUDENT PORTAL` and page title.
- Student sidebar is now clearly bifurcated into **Workspace / Academics / Administration**.
- `Manage class` now opens a functional class manager with roster, subjects, timetable, assignments, exams, materials, announcements and events.
- `Create class` and `Edit class` work in the frontend demo and persist to localStorage.
- Academic `Configure` cards now open functional editors and save demo records locally instead of only showing a Supabase toast.
- Added Homework and Calendar student routes.
- Kept the offline fee model: **no Razorpay / no online payment processing**.
- Added ordered Supabase SQL scripts under `supabase/` for the production data layer.

## GitHub Pages
This version is intentionally deployable as a static site. The included GitHub Actions workflow uploads the repository root directly to GitHub Pages.

1. Create a GitHub repository.
2. Put the contents of this `lms-portal` folder in the repository root.
3. Push to `main`.
4. GitHub → Settings → Pages → Source: **GitHub Actions**.
5. The workflow deploys automatically.

## Supabase later
The frontend demo uses localStorage. For production, connect the UI to Supabase Auth + PostgreSQL + Storage + RLS.

Run the SQL files in this order:

1. `supabase/01_schema.sql`
2. `supabase/02_functions_triggers.sql`
3. `supabase/03_rls.sql`
4. `supabase/04_indexes.sql`
5. `supabase/05_seed_reference_data.sql`
6. Read `supabase/06_auth_setup_notes.sql` before creating student accounts.

### Authentication model
Students log in using their **Admission No. + password**. Supabase Auth internally uses a synthetic email such as:

`eduiq-2026-1042@login.eduiq.local`

The Admission No. is mapped to that Auth email by the `get_login_email()` RPC. Never store plaintext student passwords in the database.

### Fee model
There is deliberately **no Razorpay or online payment flow**. Admin records offline deposits such as Cash, Bank Deposit or Cheque. The student sees the resulting paid amount, balance and percentage.

## Demo credentials
Student:
- Admission No: `EDUIQ-2026-1042`
- Password: `EduIQ@1042`

Admin:
- Admin ID: `admin`
- Password: `EduIQ#Admin`

These are frontend demo credentials only. Replace them with Supabase Auth before production use.


## V5 changes
- Delete classes from Admin → Classes.
- Individual student attendance roster + editing.
- Fee deposit create/edit/delete with live totals.
- Result entry uses a student dropdown.
- Timetable, assignments, homework, exams/date sheets, study materials and events/calendar support PDF/image attachments in the demo; production attachments should use Supabase Storage.


## Course management
V8 adds a master Courses layer: create course, define fee/details, assign classes to a course, then assign students to those classes. Course attendance is calculated across enrolled students. Run `supabase/09_courses.sql` after the existing migrations.
