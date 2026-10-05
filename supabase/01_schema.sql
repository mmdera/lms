-- EduIQ LMS — 01_schema.sql
-- Run first in Supabase SQL Editor.
-- No online fee payments are used. Fee deposits are manually recorded by staff.

create extension if not exists pgcrypto;

create type public.app_role as enum ('student','faculty','admin');
create type public.record_status as enum ('active','inactive','draft','published');
create type public.attendance_status as enum ('present','absent','leave');
create type public.fee_method as enum ('cash','bank_deposit','cheque','other');

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.app_role not null default 'student',
  full_name text not null,
  phone text,
  email text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  course text not null,
  academic_year text not null,
  section text,
  class_teacher_id uuid references public.profiles(id) on delete set null,
  status public.record_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid unique references public.profiles(id) on delete cascade,
  admission_no text unique not null,
  roll_no text,
  course text not null,
  year text not null,
  date_of_birth date,
  guardian_name text,
  address text,
  admission_year int,
  session text,
  status public.record_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.student_classes (
  student_id uuid references public.students(id) on delete cascade,
  class_id uuid references public.classes(id) on delete cascade,
  is_current boolean not null default true,
  joined_on date default current_date,
  primary key (student_id, class_id)
);

create table if not exists public.subjects (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text unique,
  course text,
  year text,
  credits numeric(4,1),
  created_at timestamptz not null default now()
);

create table if not exists public.class_subjects (
  class_id uuid references public.classes(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete cascade,
  faculty_id uuid references public.profiles(id) on delete set null,
  primary key (class_id, subject_id)
);

create table if not exists public.timetables (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete set null,
  faculty_id uuid references public.profiles(id) on delete set null,
  day_of_week int not null check (day_of_week between 1 and 7),
  start_time time not null,
  end_time time not null,
  room text,
  class_type text default 'Lecture',
  section text,
  created_at timestamptz not null default now()
);

create table if not exists public.assignments (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete set null,
  faculty_id uuid references public.profiles(id) on delete set null,
  title text not null,
  description text,
  assigned_at timestamptz not null default now(),
  due_at timestamptz,
  max_marks numeric(8,2),
  status public.record_status not null default 'published'
);

create table if not exists public.homework (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete set null,
  faculty_id uuid references public.profiles(id) on delete set null,
  task text not null,
  due_at timestamptz,
  priority text default 'normal',
  created_at timestamptz not null default now()
);

create table if not exists public.materials (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete set null,
  uploaded_by uuid references public.profiles(id) on delete set null,
  title text not null,
  file_type text,
  storage_path text,
  description text,
  status public.record_status not null default 'published',
  created_at timestamptz not null default now()
);

create table if not exists public.exams (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete set null,
  name text not null,
  exam_date date not null,
  start_time time,
  duration_minutes int,
  room text,
  instructions text,
  status public.record_status not null default 'published'
);

create table if not exists public.results (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete set null,
  exam_id uuid references public.exams(id) on delete set null,
  max_marks numeric(8,2) not null,
  obtained_marks numeric(8,2) not null,
  grade text,
  grade_point numeric(4,2),
  credits numeric(4,1),
  result_status text default 'Pass',
  created_at timestamptz not null default now()
);

create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete set null,
  attendance_date date not null,
  status public.attendance_status not null,
  marked_by uuid references public.profiles(id) on delete set null,
  unique(student_id, subject_id, attendance_date)
);

create table if not exists public.fee_accounts (
  id uuid primary key default gen_random_uuid(),
  student_id uuid unique not null references public.students(id) on delete cascade,
  total_fee numeric(12,2) not null default 0,
  scholarship_discount numeric(12,2) not null default 0,
  late_fee numeric(12,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.fee_deposits (
  id uuid primary key default gen_random_uuid(),
  fee_account_id uuid not null references public.fee_accounts(id) on delete cascade,
  receipt_no text unique not null,
  amount numeric(12,2) not null check (amount > 0),
  method public.fee_method not null,
  deposited_on date not null default current_date,
  notes text,
  recorded_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  class_id uuid references public.classes(id) on delete cascade,
  title text not null,
  category text,
  message text not null,
  author_id uuid references public.profiles(id) on delete set null,
  pinned boolean not null default false,
  status public.record_status not null default 'published',
  published_at timestamptz default now()
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  class_id uuid references public.classes(id) on delete cascade,
  title text not null,
  event_date date not null,
  start_time time,
  venue text,
  description text,
  created_by uuid references public.profiles(id) on delete set null
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  message text not null,
  category text,
  priority text default 'normal',
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references public.profiles(id) on delete cascade,
  student_id uuid references public.students(id) on delete cascade,
  title text not null,
  document_type text,
  storage_path text,
  created_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity text,
  entity_id uuid,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now()
);
