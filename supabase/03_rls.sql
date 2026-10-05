-- EduIQ LMS — 03_rls.sql
-- Run third. RLS is essential before connecting the public GitHub Pages frontend.

alter table public.profiles enable row level security;
alter table public.students enable row level security;
alter table public.classes enable row level security;
alter table public.student_classes enable row level security;
alter table public.subjects enable row level security;
alter table public.class_subjects enable row level security;
alter table public.timetables enable row level security;
alter table public.assignments enable row level security;
alter table public.homework enable row level security;
alter table public.materials enable row level security;
alter table public.exams enable row level security;
alter table public.results enable row level security;
alter table public.attendance enable row level security;
alter table public.fee_accounts enable row level security;
alter table public.fee_deposits enable row level security;
alter table public.announcements enable row level security;
alter table public.events enable row level security;
alter table public.notifications enable row level security;
alter table public.documents enable row level security;
alter table public.audit_logs enable row level security;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.profiles where id=auth.uid() and role='admin');
$$;

create or replace function public.is_faculty()
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.profiles where id=auth.uid() and role in ('faculty','admin'));
$$;

create or replace function public.current_student_id()
returns uuid language sql stable security definer set search_path=public as $$
  select id from public.students where profile_id=auth.uid() limit 1;
$$;

-- Profiles
create policy profiles_self_select on public.profiles for select using (id=auth.uid() or public.is_admin());
create policy profiles_self_update on public.profiles for update using (id=auth.uid() or public.is_admin());
create policy profiles_admin_all on public.profiles for all using (public.is_admin()) with check (public.is_admin());

-- Students
create policy students_self_select on public.students for select using (profile_id=auth.uid() or public.is_admin());
create policy students_self_update on public.students for update using (profile_id=auth.uid() or public.is_admin()) with check (profile_id=auth.uid() or public.is_admin());
create policy students_admin_all on public.students for all using (public.is_admin()) with check (public.is_admin());

-- Class / academic data: students can read their current class; faculty/admin manage.
create policy classes_student_read on public.classes for select using (exists(select 1 from public.student_classes sc join public.students s on s.id=sc.student_id where sc.class_id=classes.id and s.profile_id=auth.uid() and sc.is_current) or public.is_faculty());
create policy classes_admin_write on public.classes for all using (public.is_admin()) with check (public.is_admin());

create policy student_classes_self_read on public.student_classes for select using (student_id=public.current_student_id() or public.is_faculty());
create policy student_classes_admin_write on public.student_classes for all using (public.is_admin()) with check (public.is_admin());

create policy subjects_authenticated_read on public.subjects for select using (auth.uid() is not null);
create policy subjects_admin_write on public.subjects for all using (public.is_faculty()) with check (public.is_faculty());

create policy class_subjects_authenticated_read on public.class_subjects for select using (auth.uid() is not null);
create policy class_subjects_faculty_write on public.class_subjects for all using (public.is_faculty()) with check (public.is_faculty());

create policy timetable_class_read on public.timetables for select using (exists(select 1 from public.student_classes sc where sc.class_id=timetables.class_id and sc.student_id=public.current_student_id() and sc.is_current) or public.is_faculty());
create policy timetable_faculty_write on public.timetables for all using (public.is_faculty()) with check (public.is_faculty());

create policy assignments_class_read on public.assignments for select using (exists(select 1 from public.student_classes sc where sc.class_id=assignments.class_id and sc.student_id=public.current_student_id() and sc.is_current) or public.is_faculty());
create policy assignments_faculty_write on public.assignments for all using (public.is_faculty()) with check (public.is_faculty());

create policy homework_class_read on public.homework for select using (exists(select 1 from public.student_classes sc where sc.class_id=homework.class_id and sc.student_id=public.current_student_id() and sc.is_current) or public.is_faculty());
create policy homework_faculty_write on public.homework for all using (public.is_faculty()) with check (public.is_faculty());

create policy materials_class_read on public.materials for select using (exists(select 1 from public.student_classes sc where sc.class_id=materials.class_id and sc.student_id=public.current_student_id() and sc.is_current) or public.is_faculty());
create policy materials_faculty_write on public.materials for all using (public.is_faculty()) with check (public.is_faculty());

create policy exams_class_read on public.exams for select using (exists(select 1 from public.student_classes sc where sc.class_id=exams.class_id and sc.student_id=public.current_student_id() and sc.is_current) or public.is_faculty());
create policy exams_faculty_write on public.exams for all using (public.is_faculty()) with check (public.is_faculty());

create policy results_self_read on public.results for select using (student_id=public.current_student_id() or public.is_faculty());
create policy results_faculty_write on public.results for all using (public.is_faculty()) with check (public.is_faculty());

create policy attendance_self_read on public.attendance for select using (student_id=public.current_student_id() or public.is_faculty());
create policy attendance_faculty_write on public.attendance for all using (public.is_faculty()) with check (public.is_faculty());

create policy fee_accounts_self_read on public.fee_accounts for select using (student_id=public.current_student_id() or public.is_admin());
create policy fee_accounts_admin_write on public.fee_accounts for all using (public.is_admin()) with check (public.is_admin());
create policy fee_deposits_self_read on public.fee_deposits for select using (exists(select 1 from public.fee_accounts fa where fa.id=fee_deposits.fee_account_id and fa.student_id=public.current_student_id()) or public.is_admin());
create policy fee_deposits_admin_write on public.fee_deposits for all using (public.is_admin()) with check (public.is_admin());

create policy announcements_class_read on public.announcements for select using (class_id is null or exists(select 1 from public.student_classes sc where sc.class_id=announcements.class_id and sc.student_id=public.current_student_id() and sc.is_current) or public.is_faculty());
create policy announcements_faculty_write on public.announcements for all using (public.is_faculty()) with check (public.is_faculty());

create policy events_class_read on public.events for select using (class_id is null or exists(select 1 from public.student_classes sc where sc.class_id=events.class_id and sc.student_id=public.current_student_id() and sc.is_current) or public.is_faculty());
create policy events_faculty_write on public.events for all using (public.is_faculty()) with check (public.is_faculty());

create policy notifications_self on public.notifications for select using (profile_id=auth.uid() or public.is_admin());
create policy notifications_self_update on public.notifications for update using (profile_id=auth.uid() or public.is_admin()) with check (profile_id=auth.uid() or public.is_admin());
create policy notifications_admin_write on public.notifications for insert using (public.is_admin()) with check (public.is_admin());

create policy documents_self_read on public.documents for select using (profile_id=auth.uid() or student_id=public.current_student_id() or public.is_admin());
create policy documents_admin_write on public.documents for all using (public.is_admin()) with check (public.is_admin());

create policy audit_admin_read on public.audit_logs for select using (public.is_admin());
create policy audit_admin_write on public.audit_logs for insert with check (public.is_admin());
