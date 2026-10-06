# EduIQ LMS — V16

GitHub Pages-ready EduIQ LMS build.

## V16 fix
- Fixed the blank **My Profile** page caused by missing profile renderer functions.
- Student profile now shows institution-issued identity, course/class/roll details and editable phone, email, DOB and address.
- Student password change is available directly from **My Profile**.
- First-login **Change password** button now redirects to the profile and opens the password-change dialog automatically.
- Administrator profile is also fully rendered with editable display name/email and password change.
- Existing academic, timetable, history, fee, attendance and student-management functionality from V15 is retained.

## Local demo
```bash
npm install
npm run dev
```

## GitHub Pages
Push the contents of this ZIP to your repository. The included GitHub Actions workflow builds and deploys the Vite app to GitHub Pages.

## Important
This GitHub Pages demo currently stores demo-state data in browser `localStorage`. For production multi-user access, connect the supplied Supabase schema/RLS/storage setup and replace the local data adapter with Supabase calls.


## V20 login fix
The default administrator login is `admin` / `1111111`. Existing custom admin passwords stored in the browser remain valid.


## V21 mobile note
The frontend uses browser-local storage until Supabase is connected. Admin login is intentionally portable with the institution default `admin / 1111111`. Student accounts created on another device require the Supabase-backed authentication/data layer for cross-device login; localStorage cannot synchronize student accounts between phones and desktops.
