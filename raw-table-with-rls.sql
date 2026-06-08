-- =====================================================================
-- BBA Client Dashboard — public.raw table + Row Level Security
-- =====================================================================
-- WHAT THIS DOES
--   1. Creates the public.raw table (matches the dashboard schema).
--   2. Enables + forces RLS (deny-by-default).
--   3. Grants SELECT to logged-in (authenticated) users only.
--
-- WHO CAN DO WHAT AFTER RUNNING
--   anon (logged-out) ...... no read, no write   (blocked)
--   authenticated (login) .. read only           (SELECT)
--   service_role (n8n) ..... full read + write    (bypasses RLS)
--
-- HOW TO RUN
--   Supabase Dashboard -> SQL Editor -> paste this whole file -> Run.
--   Safe to re-run (idempotent).
--
-- NOTE
--   Your n8n sync must use the SERVICE_ROLE key (not anon) so its
--   inserts/upserts bypass RLS. The anon key cannot write.
-- =====================================================================

-- 1) TABLE -------------------------------------------------------------
create table if not exists public.raw (
  email                              text primary key,
  name_ptd                           text,
  name_fb                            text,
  phone                              text,
  origin_date                        date,
  gender                             text,
  country                            text,
  head_coach                         text,
  current_program                    text,
  length_type                        text,
  extra_weeks                        integer,
  length_weeks                       integer,
  current_program_start_date         date,
  current_program_end_date           date,
  days_to_end                        integer,
  closer                             text,
  support_coach                      text,
  current_status                     text,
  status_date                        date,
  last_event_type                    text,
  last_event_date                    date,
  payment_status                     text,
  payment_cadence                    text,
  currency                           text,
  contract_value_home_currency       numeric(14,2),
  cash_collected_home_currency       numeric(14,2),
  periodic_payments_home_currency    numeric(14,2),
  current_agreement                  text,
  net_after_stripe_cad               numeric(14,2),
  commission_cad                     numeric(14,2),
  stripe_link                        text,
  notes                              text,
  synced_at                          timestamptz default now()
);

-- 2) Helpful indexes for dashboard filters (optional but recommended)
create index if not exists raw_current_status_idx          on public.raw (current_status);
create index if not exists raw_head_coach_idx              on public.raw (head_coach);
create index if not exists raw_closer_idx                  on public.raw (closer);
create index if not exists raw_current_program_idx         on public.raw (current_program);
create index if not exists raw_current_program_end_dt_idx  on public.raw (current_program_end_date);

-- 3) ROW LEVEL SECURITY -----------------------------------------------
alter table public.raw enable row level security;
alter table public.raw force  row level security;

-- Drop any existing policies (clears old anon-read grants), then recreate
do $$
declare pol record;
begin
  for pol in
    select policyname from pg_policies
    where schemaname = 'public' and tablename = 'raw'
  loop
    execute format('drop policy if exists %I on public.raw;', pol.policyname);
  end loop;
end $$;

-- Logged-in users may read everything
create policy "authenticated read"
  on public.raw
  for select
  to authenticated
  using (true);

-- NOTE: no INSERT/UPDATE/DELETE policy on purpose.
-- service_role bypasses RLS, so n8n keeps writing. No other role can write.

-- =====================================================================
-- VERIFY (optional) — should show exactly one "authenticated read" row.
-- =====================================================================
-- select tablename, policyname, roles, cmd
-- from pg_policies
-- where schemaname = 'public' and tablename = 'raw';
