-- EduIQ LMS — 05_seed_reference_data.sql
-- Run fifth after creating at least one admin Auth user.
-- This seeds the academic structure only. Student Auth accounts should be created through Supabase Auth or an Edge Function.

insert into public.classes(name,course,academic_year,section)
select * from (values
  ('D.Pharm — First Year','D.Pharm','2026–27','A'),
  ('D.Pharm — Second Year','D.Pharm','2026–27','A'),
  ('B.Pharm — First Year','B.Pharm','2026–27','A'),
  ('B.Sc. Zoology — Final Year','B.Sc. Zoology','2026–27','A')
) as v(name,course,academic_year,section)
where not exists (select 1 from public.classes c where c.name=v.name);

insert into public.subjects(name,code,course,year,credits)
select * from (values
 ('Pharmaceutics','DP101','D.Pharm','First Year',4),
 ('Pharmacology','DP102','D.Pharm','First Year',4),
 ('Human Anatomy','DP103','D.Pharm','First Year',4),
 ('Human Physiology','DP104','D.Pharm','First Year',4),
 ('Biochemistry','DP105','D.Pharm','First Year',3)
) as v(name,code,course,year,credits)
where not exists (select 1 from public.subjects s where s.code=v.code);
