-- EduIQ LMS — 08_fee_management.sql
-- Run after 01_schema.sql through 07_storage_and_attachments.sql.
-- Adds production-safe course-fee assignment and fee-balance helpers.

-- Ensure every student can have exactly one fee account.
create or replace function public.ensure_student_fee_account()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.fee_accounts (student_id, total_fee)
  values (new.id, 0)
  on conflict (student_id) do nothing;
  return new;
end;
$$;

drop trigger if exists trg_ensure_student_fee_account on public.students;
create trigger trg_ensure_student_fee_account
after insert on public.students
for each row execute function public.ensure_student_fee_account();

-- Admin-only helper for assigning/updating a student's course fee.
create or replace function public.set_student_course_fee(
  p_student_id uuid,
  p_total_fee numeric
)
returns public.fee_accounts
language plpgsql
security definer
set search_path = public
as $$
declare
  v_account public.fee_accounts;
begin
  if not public.is_admin() then
    raise exception 'Only administrators can assign course fees';
  end if;

  if p_total_fee < 0 then
    raise exception 'Course fee cannot be negative';
  end if;

  insert into public.fee_accounts (student_id, total_fee)
  values (p_student_id, p_total_fee)
  on conflict (student_id)
  do update set
    total_fee = excluded.total_fee,
    updated_at = now()
  returning * into v_account;

  return v_account;
end;
$$;

revoke all on function public.set_student_course_fee(uuid, numeric) from public;
grant execute on function public.set_student_course_fee(uuid, numeric) to authenticated;

-- Convenient read model for the admin portal and future student dashboard.
-- Paid amount is derived from actual offline deposits; it is never typed manually.
create or replace view public.student_fee_balances
with (security_invoker = true)
as
select
  s.id as student_id,
  s.admission_no,
  s.profile_id,
  fa.id as fee_account_id,
  coalesce(fa.total_fee, 0) as total_fee,
  coalesce(fa.scholarship_discount, 0) as scholarship_discount,
  coalesce(fa.late_fee, 0) as late_fee,
  coalesce(sum(fd.amount), 0) as deposited_amount,
  greatest(
    coalesce(fa.total_fee, 0)
    - coalesce(fa.scholarship_discount, 0)
    + coalesce(fa.late_fee, 0)
    - coalesce(sum(fd.amount), 0),
    0
  ) as outstanding_amount,
  case
    when coalesce(fa.total_fee, 0) <= 0 then 0
    else round(
      least(
        greatest(
          coalesce(sum(fd.amount), 0)
          / nullif(
              coalesce(fa.total_fee, 0)
              - coalesce(fa.scholarship_discount, 0)
              + coalesce(fa.late_fee, 0),
              0
            ) * 100,
          0
        ),
        100
      ),
      2
    )
  end as deposited_percent
from public.students s
left join public.fee_accounts fa on fa.student_id = s.id
left join public.fee_deposits fd on fd.fee_account_id = fa.id
group by
  s.id,
  s.admission_no,
  s.profile_id,
  fa.id,
  fa.total_fee,
  fa.scholarship_discount,
  fa.late_fee;

-- Helpful indexes for admin fee management.
create index if not exists idx_fee_accounts_student_id
on public.fee_accounts(student_id);

create index if not exists idx_fee_deposits_account_date
on public.fee_deposits(fee_account_id, deposited_on desc);

-- IMPORTANT:
-- RLS on fee_accounts / fee_deposits from 03_rls.sql remains in force.
-- Students therefore only see their own fee balance/deposits;
-- administrators can manage all fee accounts and offline deposits.
