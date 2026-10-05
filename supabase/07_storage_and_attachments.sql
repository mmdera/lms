-- EduIQ LMS — 07_storage_and_attachments.sql
-- Run after 01_schema.sql, 02_functions_triggers.sql and 03_rls.sql.
-- Adds attachment metadata to academic records and a private Supabase Storage bucket.
-- No online payments are introduced.

-- ============================================================
-- 1. ATTACHMENT METADATA
-- ============================================================

ALTER TABLE public.timetables
  ADD COLUMN IF NOT EXISTS attachment_path text,
  ADD COLUMN IF NOT EXISTS attachment_name text,
  ADD COLUMN IF NOT EXISTS attachment_mime text,
  ADD COLUMN IF NOT EXISTS attachment_size bigint;

ALTER TABLE public.assignments
  ADD COLUMN IF NOT EXISTS attachment_path text,
  ADD COLUMN IF NOT EXISTS attachment_name text,
  ADD COLUMN IF NOT EXISTS attachment_mime text,
  ADD COLUMN IF NOT EXISTS attachment_size bigint;

ALTER TABLE public.homework
  ADD COLUMN IF NOT EXISTS attachment_path text,
  ADD COLUMN IF NOT EXISTS attachment_name text,
  ADD COLUMN IF NOT EXISTS attachment_mime text,
  ADD COLUMN IF NOT EXISTS attachment_size bigint;

ALTER TABLE public.materials
  ADD COLUMN IF NOT EXISTS attachment_name text,
  ADD COLUMN IF NOT EXISTS attachment_mime text,
  ADD COLUMN IF NOT EXISTS attachment_size bigint;

ALTER TABLE public.exams
  ADD COLUMN IF NOT EXISTS attachment_path text,
  ADD COLUMN IF NOT EXISTS attachment_name text,
  ADD COLUMN IF NOT EXISTS attachment_mime text,
  ADD COLUMN IF NOT EXISTS attachment_size bigint;

ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS attachment_path text,
  ADD COLUMN IF NOT EXISTS attachment_name text,
  ADD COLUMN IF NOT EXISTS attachment_mime text,
  ADD COLUMN IF NOT EXISTS attachment_size bigint;

-- Helpful indexes for the individual attendance view.
CREATE INDEX IF NOT EXISTS idx_attendance_student_date
  ON public.attendance(student_id, attendance_date DESC);

CREATE INDEX IF NOT EXISTS idx_attendance_class_student
  ON public.attendance(class_id, student_id);

-- ============================================================
-- 2. PRIVATE STORAGE BUCKET
-- ============================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('eduiq-academic', 'eduiq-academic', false)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 3. STORAGE POLICIES
-- ============================================================
-- File path convention:
-- academic/<class_id>/<unique-file-name>
-- Students can read files belonging to their current class.
-- Admin/faculty can manage academic files.

DROP POLICY IF EXISTS eduiq_academic_read
ON storage.objects;

CREATE POLICY eduiq_academic_read
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'eduiq-academic'
  AND (
    public.is_admin()
    OR public.is_faculty()
    OR EXISTS (
      SELECT 1
      FROM public.student_classes sc
      WHERE sc.class_id::text = split_part(storage.objects.name, '/', 2)
        AND sc.student_id = public.current_student_id()
        AND sc.is_current = true
    )
  )
);

DROP POLICY IF EXISTS eduiq_academic_insert
ON storage.objects;

CREATE POLICY eduiq_academic_insert
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'eduiq-academic'
  AND (public.is_admin() OR public.is_faculty())
);

DROP POLICY IF EXISTS eduiq_academic_update
ON storage.objects;

CREATE POLICY eduiq_academic_update
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'eduiq-academic'
  AND (public.is_admin() OR public.is_faculty())
)
WITH CHECK (
  bucket_id = 'eduiq-academic'
  AND (public.is_admin() OR public.is_faculty())
);

DROP POLICY IF EXISTS eduiq_academic_delete
ON storage.objects;

CREATE POLICY eduiq_academic_delete
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'eduiq-academic'
  AND (public.is_admin() OR public.is_faculty())
);

-- ============================================================
-- END
-- ============================================================
