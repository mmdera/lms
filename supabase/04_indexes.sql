-- EduIQ LMS — 04_indexes.sql
-- Run fourth.

create index if not exists idx_students_admission on public.students(lower(admission_no));
create index if not exists idx_students_profile on public.students(profile_id);
create index if not exists idx_student_classes_student on public.student_classes(student_id,is_current);
create index if not exists idx_student_classes_class on public.student_classes(class_id,is_current);
create index if not exists idx_timetable_class_day on public.timetables(class_id,day_of_week,start_time);
create index if not exists idx_assignments_class_due on public.assignments(class_id,due_at);
create index if not exists idx_homework_class_due on public.homework(class_id,due_at);
create index if not exists idx_materials_class on public.materials(class_id,created_at desc);
create index if not exists idx_exams_class_date on public.exams(class_id,exam_date);
create index if not exists idx_results_student on public.results(student_id);
create index if not exists idx_attendance_student_date on public.attendance(student_id,attendance_date desc);
create index if not exists idx_fee_deposits_account_date on public.fee_deposits(fee_account_id,deposited_on desc);
create index if not exists idx_announcements_class_date on public.announcements(class_id,published_at desc);
create index if not exists idx_notifications_profile on public.notifications(profile_id,created_at desc);
