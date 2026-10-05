-- EduIQ LMS — 09_courses.sql
-- Run after 08_fee_management.sql. Creates the master course layer.

create table if not exists public.courses (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text unique,
  description text,
  duration text,
  academic_session text,
  total_fee numeric(12,2) not null default 0 check (total_fee >= 0),
  status public.record_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.classes add column if not exists course_id uuid references public.courses(id) on delete set null;
alter table public.students add column if not exists course_id uuid references public.courses(id) on delete set null;
alter table public.fee_accounts add column if not exists course_id uuid references public.courses(id) on delete set null;

create index if not exists idx_classes_course_id on public.classes(course_id);
create index if not exists idx_students_course_id on public.students(course_id);
create index if not exists idx_fee_accounts_course_id on public.fee_accounts(course_id);

alter table public.courses enable row level security;

drop policy if exists courses_authenticated_read on public.courses;
drop policy if exists courses_admin_write on public.courses;

create policy courses_authenticated_read on public.courses
for select to authenticated
using (
  (select public.is_admin())
  or exists (select 1 from public.students s where s.profile_id=(select auth.uid()) and s.course_id=courses.id)
);

create policy courses_admin_write on public.courses
for all to authenticated
using ((select public.is_admin()))
with check ((select public.is_admin()));

create or replace view public.course_attendance_summary as
select
  c.id as course_id,
  c.name as course_name,
  count(distinct s.id) as student_count,
  count(distinct cl.id) as class_count,
  coalesce(round(avg(a.present_ratio)::numeric, 2), 0) as overall_attendance
from public.courses c
left join public.students s on s.course_id=c.id and s.status='active'
left join public.classes cl on cl.course_id=c.id and cl.status='active'
left join (
  select student_id,
         case when count(*)=0 then 0
              else (count(*) filter (where status='present')::numeric / count(*)::numeric)*100 end as present_ratio
  from public.attendance
  group by student_id
) a on a.student_id=s.id
group by c.id,c.name;

-- When a student is assigned to a course, the course fee becomes the default fee account.
create or replace function public.assign_student_course_fee(p_student_id uuid, p_course_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare v_fee numeric(12,2);
begin
  if not public.is_admin() then raise exception 'Only administrators can assign courses.'; end if;
  select total_fee into v_fee from public.courses where id=p_course_id;
  if not found then raise exception 'Course not found.'; end if;
  update public.students set course_id=p_course_id, course=(select name from public.courses where id=p_course_id), updated_at=now() where id=p_student_id;
  insert into public.fee_accounts(student_id,course_id,total_fee) values(p_student_id,p_course_id,v_fee)
  on conflict(student_id) do update set course_id=excluded.course_id,total_fee=excluded.total_fee,updated_at=now();
end;
$$;

revoke all on function public.assign_student_course_fee(uuid,uuid) from public;
grant execute on function public.assign_student_course_fee(uuid,uuid) to authenticated;
