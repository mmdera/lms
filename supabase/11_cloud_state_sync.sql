-- EduIQ LMS — 11_cloud_state_sync.sql
-- ONE-TIME SETUP for the current static GitHub Pages build.
-- This creates a single cloud snapshot so the existing EduIQ UI has the same
-- application data on PC and mobile.
--
-- IMPORTANT: this is a compatibility bridge for the current localStorage-based
-- UI. It is NOT the final production security model for real student PII.
-- For a production institution deployment, use the supplied normalized schema
-- + Supabase Auth/RLS instead of a public JSON snapshot.

create table if not exists public.eduiq_app_state (
  id text primary key,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.eduiq_app_state enable row level security;

drop policy if exists eduiq_app_state_read on public.eduiq_app_state;
drop policy if exists eduiq_app_state_write on public.eduiq_app_state;

-- Compatibility bridge: the static client uses the publishable key and does
-- not yet have a Supabase Auth session. These policies let the same institution
-- snapshot be read/written from each device.
create policy eduiq_app_state_read
on public.eduiq_app_state
for select
to anon, authenticated
using (true);

create policy eduiq_app_state_write
on public.eduiq_app_state
for all
to anon, authenticated
using (true)
with check (true);

grant select, insert, update, delete on public.eduiq_app_state to anon, authenticated;
