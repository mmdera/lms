-- EduIQ institution-wide reset (V26)
-- Run ONCE in the Supabase SQL Editor for the configured project.
-- DESTRUCTIVE: permanently clears the shared EduIQ LMS snapshot (students,
-- credentials, courses, classes, attendance, results, fees, notices, schedules,
-- academic content and all other app-state data). Export a backup first if needed.
-- This does not delete Supabase Auth users or records in the separate normalized
-- tables created by 01_schema.sql; this V26 frontend uses eduiq_app_state.

begin;

insert into public.eduiq_app_state (id, payload, updated_at)
values (
  'eduiq-main',
  jsonb_build_object(
    'adminPassword', 'EduIQ#2026',
    'mustChangeAdminPassword', true,
    'student', null,
    'fees', jsonb_build_object('total', 0, 'paid', 0, 'entries', '[]'::jsonb),
    'courses', '[]'::jsonb,
    'classes', '[]'::jsonb,
    'students', '[]'::jsonb,
    'attendanceRecords', '[]'::jsonb,
    'academic', '[]'::jsonb,
    'results', '[]'::jsonb,
    'studentFees', '{}'::jsonb,
    'schedule', '[]'::jsonb,
    'classSchedules', '{}'::jsonb,
    'notifications', '[]'::jsonb,
    'events', '[]'::jsonb,
    'announcements', '[]'::jsonb,
    'attendance', jsonb_build_object('overall', 0, 'subjects', '[]'::jsonb)
  ),
  now()
)
on conflict (id) do update
set payload = excluded.payload,
    updated_at = excluded.updated_at;

commit;
