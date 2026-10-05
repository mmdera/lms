-- EduIQ LMS — 02_functions_triggers.sql
-- Run second.

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at();

drop trigger if exists students_updated_at on public.students;
create trigger students_updated_at before update on public.students for each row execute function public.set_updated_at();

drop trigger if exists classes_updated_at on public.classes;
create trigger classes_updated_at before update on public.classes for each row execute function public.set_updated_at();

drop trigger if exists fee_accounts_updated_at on public.fee_accounts;
create trigger fee_accounts_updated_at before update on public.fee_accounts for each row execute function public.set_updated_at();

create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id, full_name, email, role)
  values(new.id, coalesce(new.raw_user_meta_data->>'full_name', split_part(coalesce(new.email,''),'@',1)), new.email, coalesce((new.raw_user_meta_data->>'role')::public.app_role,'student'::public.app_role))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_auth_user();

-- Maps the student's Admission No. to the synthetic Supabase Auth email used by the app.
-- This lets the UI accept Admission No. while Supabase Auth still uses email/password internally.
create or replace function public.get_login_email(p_admission_no text)
returns text language sql security definer set search_path = public as $$
  select lower(trim(p_admission_no)) || '@login.eduiq.local'
  where exists (
    select 1 from public.students s
    where lower(s.admission_no)=lower(trim(p_admission_no)) and s.status='active'
  );
$$;

grant execute on function public.get_login_email(text) to anon, authenticated;

-- Useful fee summary for the student dashboard/admin portal.
create or replace view public.student_fee_summary as
select
  fa.student_id,
  fa.total_fee,
  fa.scholarship_discount,
  fa.late_fee,
  coalesce(sum(fd.amount),0) as paid_amount,
  greatest(fa.total_fee - fa.scholarship_discount + fa.late_fee - coalesce(sum(fd.amount),0),0) as remaining_amount,
  case when fa.total_fee - fa.scholarship_discount + fa.late_fee <= 0 then 100
       else round((coalesce(sum(fd.amount),0) / (fa.total_fee - fa.scholarship_discount + fa.late_fee))*100,2)
  end as paid_percent
from public.fee_accounts fa
left join public.fee_deposits fd on fd.fee_account_id=fa.id
group by fa.id;

-- Prevent a public client from bypassing fee RLS through the view.
alter view public.student_fee_summary set (security_invoker = true);
