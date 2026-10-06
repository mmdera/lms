-- EduIQ LMS — 10_reset_application_demo_data.sql
-- OPTIONAL / FRESH-DEMO DATABASE ONLY.
-- Run this ONLY if this Supabase project already contains the OLD EduIQ demo/sample records.
-- It removes application data but intentionally keeps Auth users / profiles so your admin account remains available.
-- DO NOT RUN THIS ON A LIVE INSTITUTION DATABASE CONTAINING REAL STUDENT DATA.

begin;

truncate table
  public.audit_logs,
  public.notifications,
  public.documents,
  public.attendance,
  public.results,
  public.fee_deposits,
  public.fee_accounts,
  public.student_classes,
  public.students,
  public.timetables,
  public.assignments,
  public.homework,
  public.materials,
  public.exams,
  public.announcements,
  public.events,
  public.class_subjects,
  public.subjects,
  public.classes,
  public.courses
restart identity cascade;

commit;
