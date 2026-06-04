-- =====================================================================
-- BBA Client Data Dashboard — Supabase schema
-- Source: TRACKER - CLIENT SUCCESS Google Sheet
--   https://docs.google.com/spreadsheets/d/1wBlcdRKzT_MPf5ktldZbfvMn3eX7TjzmtIgtDo591IY
--
-- Sync pattern: full replace per minute (n8n truncates + reinserts each tab).
-- Wrap each tab's sync in a single transaction so the dashboard never reads
-- an empty table mid-sync. See the n8n recipe at the bottom of this file.
--
-- 10 data tabs become 10 tables. The DATA VALIDATION DROPDOWNS tab is config
-- and is intentionally NOT synced.
--
-- Run this whole file in: Supabase Dashboard -> SQL Editor -> New query.
-- It is idempotent — safe to re-run; existing tables are dropped first.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Drop existing (idempotent re-run)
-- ---------------------------------------------------------------------
drop table if exists public.tab_raw cascade;
drop table if exists public.tab_client_notes cascade;
drop table if exists public.tab_offboarded cascade;
drop table if exists public.tab_onboarding cascade;
drop table if exists public.tab_client_121 cascade;
drop table if exists public.tab_catchup_call cascade;
drop table if exists public.tab_challenge_upgrade_call cascade;
drop table if exists public.tab_kickoff_calls cascade;
drop table if exists public.tab_programs cascade;
drop table if exists public.tab_retreat cascade;
drop table if exists public.sync_status cascade;

-- ---------------------------------------------------------------------
-- 1. RAW — master client list (every client, every status)
-- ---------------------------------------------------------------------
create table public.tab_raw (
  id                              bigserial primary key,
  sheet_row                       integer,                -- 1-based row index in the sheet
  client_id                       text,                   -- sheet column "F" (mislabeled header — value is client id, e.g. "200626BS")
  name_ptd                        text,
  name_fb                         text,
  email                           text,
  phone                           text,
  origin_date                     text,
  gender                          text,
  country                         text,
  head_coach                      text,
  current_program                 text,
  length_type                     text,
  extra_weeks                     text,
  length_weeks                    text,
  current_program_start_date      text,
  current_program_end_date        text,
  days_to_end                     text,
  closer                          text,
  support_coach                   text,                   -- sheet header "SUPPORT COACH"
  current_status                  text,
  status_date                     text,
  last_event_type                 text,
  last_event_date                 text,
  payment_status                  text,
  payment_cadence                 text,
  currency                        text,
  contract_value_home_currency    text,
  cash_collected_home_currency    text,
  periodic_payments_home_currency text,
  current_agreement               text,
  net_after_stripe_cad            text,
  commission_cad                  text,
  stripe_link                     text,
  notes                           text,
  synced_at                       timestamptz not null default now()
);
create index tab_raw_client_id_idx       on public.tab_raw (client_id);
create index tab_raw_support_coach_idx   on public.tab_raw (support_coach);
create index tab_raw_current_status_idx  on public.tab_raw (current_status);
create index tab_raw_email_idx           on public.tab_raw (email);

-- ---------------------------------------------------------------------
-- 2. CLIENT_NOTES
-- ---------------------------------------------------------------------
create table public.tab_client_notes (
  id                bigserial primary key,
  sheet_row         integer,
  client_id         text,
  name_ptd          text,
  name_fb           text,
  head_coach        text,
  support_coach     text,
  program           text,
  current_status    text,
  program_end_date  text,
  last_contact      text,
  posts             text,
  ax                text,                                 -- present in sheet, purpose unclear
  synced_at         timestamptz not null default now()
);
create index tab_client_notes_client_id_idx on public.tab_client_notes (client_id);

-- ---------------------------------------------------------------------
-- 3. OFFBOARDED — cancelled clients
-- NOTE: sheet has #REF! errors in columns LENGTH_WEEKS, CURRENT_PROGRAM_END_DATE,
-- DAYS_TO_END and a blank header for ORIGIN_DATE. Names below mirror RAW; fix
-- the sheet headers/formulas so n8n can write them cleanly.
-- ---------------------------------------------------------------------
create table public.tab_offboarded (
  id                              bigserial primary key,
  sheet_row                       integer,
  date_offboarded                 text,
  client_id                       text,
  name_ptd                        text,
  name_fb                         text,
  email                           text,
  phone                           text,
  origin_date                     text,                   -- sheet header is blank
  gender                          text,
  country                         text,
  head_coach                      text,
  current_program                 text,
  length_type                     text,
  extra_weeks                     text,
  length_weeks                    text,                   -- sheet shows #REF!
  current_program_start_date      text,
  current_program_end_date        text,                   -- sheet shows #REF!
  days_to_end                     text,                   -- sheet shows #REF!
  closer                          text,
  support_coach                   text,
  current_status                  text,
  status_date                     text,
  last_event_type                 text,
  last_event_date                 text,
  payment_status                  text,
  payment_cadence                 text,
  currency                        text,
  contract_value_home_currency    text,
  cash_collected_home_currency    text,
  periodic_payments_home_currency text,
  current_agreement               text,
  net_after_stripe_cad            text,
  commission_cad                  text,
  stripe_link                     text,
  notes                           text,
  synced_at                       timestamptz not null default now()
);
create index tab_offboarded_client_id_idx       on public.tab_offboarded (client_id);
create index tab_offboarded_date_offboarded_idx on public.tab_offboarded (date_offboarded);
create index tab_offboarded_support_coach_idx   on public.tab_offboarded (support_coach);

-- ---------------------------------------------------------------------
-- 4. ONBOARDING
-- ---------------------------------------------------------------------
create table public.tab_onboarding (
  id                                  bigserial primary key,
  sheet_row                           integer,
  name                                text,
  email                               text,
  coach                               text,
  ptd_signup_date                     text,
  weeks_signed                        text,
  four_plus_week_date                 text,               -- sheet header "4+ WEEK DATE"
  week                                text,
  ob_success_team                     text,
  program_assigned                    text,
  start_weight_kg                     text,
  goal_weight_kg                      text,
  kick_off_call_attended_sent         text,               -- sheet header "KICK OFF CALL ATTENDED/SENT"
  fb_group                            text,
  intro                               text,
  triage_status                       text,
  triage_call_notes_momentum_or_closer text,
  last_contact_date                   text,
  client_notes                        text,
  community_posts                     text,
  synced_at                           timestamptz not null default now()
);
create index tab_onboarding_email_idx on public.tab_onboarding (email);
create index tab_onboarding_coach_idx on public.tab_onboarding (coach);

-- ---------------------------------------------------------------------
-- 5. CLIENT 121 — momentum coach 1-to-1 calls
-- ---------------------------------------------------------------------
create table public.tab_client_121 (
  id                          bigserial primary key,
  sheet_row                   integer,
  name_ptd                    text,
  name_fb                     text,
  support_coach               text,
  program                     text,
  call_type                   text,
  host_name                   text,
  date_appointment_pst        text,                       -- sheet header "DATE_APPOINTMENT (PST)"
  call_notes_momentum_coach   text,
  synced_at                   timestamptz not null default now()
);
create index tab_client_121_support_coach_idx on public.tab_client_121 (support_coach);

-- ---------------------------------------------------------------------
-- 6. CATCHUP CALL
-- ---------------------------------------------------------------------
create table public.tab_catchup_call (
  id                      bigserial primary key,
  sheet_row               integer,
  name_ptd                text,
  name_fb                 text,
  closer                  text,
  date_appointment_pst    text,
  referral                text,                           -- sheet header "REFERRAL?"
  call_notes_closer       text,
  synced_at               timestamptz not null default now()
);
create index tab_catchup_call_closer_idx on public.tab_catchup_call (closer);

-- ---------------------------------------------------------------------
-- 7. CHALLENGE UPGRADE CALL
-- ---------------------------------------------------------------------
create table public.tab_challenge_upgrade_call (
  id                      bigserial primary key,
  sheet_row               integer,
  name_ptd                text,
  name_fb                 text,
  closer                  text,
  date_appointment_pst    text,
  closed                  text,                           -- sheet header "CLOSED?"
  call_notes_closer       text,
  synced_at               timestamptz not null default now()
);
create index tab_challenge_upgrade_call_closer_idx on public.tab_challenge_upgrade_call (closer);

-- ---------------------------------------------------------------------
-- 8. KICKOFF CALLS
-- ---------------------------------------------------------------------
create table public.tab_kickoff_calls (
  id                          bigserial primary key,
  sheet_row                   integer,
  client                      text,
  appointment_time_vancouver  text,
  appointment_time_local      text,
  synced_at                   timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 9. PROGRAMS
-- ---------------------------------------------------------------------
create table public.tab_programs (
  id                      bigserial primary key,
  sheet_row               integer,
  name                    text,
  game_plan_date          text,
  which_program_assigned  text,
  video_troy              text,                           -- sheet header "VIDEO - TROY"
  start_weight_kg         text,
  goal_weight_kg          text,
  notes                   text,
  synced_at               timestamptz not null default now()
);
create index tab_programs_name_idx on public.tab_programs (name);

-- ---------------------------------------------------------------------
-- 10. RETREAT
-- ---------------------------------------------------------------------
create table public.tab_retreat (
  id                          bigserial primary key,
  sheet_row                   integer,
  num                         text,                       -- sheet header "#"
  retreat_1_hunter_valley     text,                       -- attendee name lives here
  frequency                   text,
  subscription_loaded         text,
  total_cost                  text,
  deposit_pif                 text,                       -- sheet header "DEPOSIT / PIF"
  periodic                    text,
  synced_at                   timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- sync_status — one row per tab, updated each time n8n finishes a sync
-- Drives the dashboard's "Last sync" timestamp.
-- ---------------------------------------------------------------------
create table public.sync_status (
  tab_name      text primary key,
  last_synced_at timestamptz not null default now(),
  row_count     integer,
  ok            boolean not null default true,
  error_message text
);

insert into public.sync_status (tab_name, ok) values
  ('RAW', true),
  ('CLIENT_NOTES', true),
  ('OFFBOARDED', true),
  ('ONBOARDING', true),
  ('CLIENT 121', true),
  ('CATCHUP CALL', true),
  ('CHALLENGE UPGRADE CALL', true),
  ('KICKOFF CALLS', true),
  ('PROGRAMS', true),
  ('RETREAT', true);

-- =====================================================================
-- Realtime — let the dashboard subscribe to live row changes
-- =====================================================================
alter publication supabase_realtime add table public.tab_raw;
alter publication supabase_realtime add table public.tab_client_notes;
alter publication supabase_realtime add table public.tab_offboarded;
alter publication supabase_realtime add table public.tab_onboarding;
alter publication supabase_realtime add table public.tab_client_121;
alter publication supabase_realtime add table public.tab_catchup_call;
alter publication supabase_realtime add table public.tab_challenge_upgrade_call;
alter publication supabase_realtime add table public.tab_kickoff_calls;
alter publication supabase_realtime add table public.tab_programs;
alter publication supabase_realtime add table public.tab_retreat;
alter publication supabase_realtime add table public.sync_status;

-- Full row image in realtime payloads (so the dashboard can diff easily)
alter table public.tab_raw                     replica identity full;
alter table public.tab_client_notes            replica identity full;
alter table public.tab_offboarded              replica identity full;
alter table public.tab_onboarding              replica identity full;
alter table public.tab_client_121              replica identity full;
alter table public.tab_catchup_call            replica identity full;
alter table public.tab_challenge_upgrade_call  replica identity full;
alter table public.tab_kickoff_calls           replica identity full;
alter table public.tab_programs                replica identity full;
alter table public.tab_retreat                 replica identity full;
alter table public.sync_status                 replica identity full;

-- =====================================================================
-- RLS — read-only for the dashboard's anon key; writes go via service_role
-- (service_role bypasses RLS, so n8n only needs the service_role key)
-- Tighten this in Phase 5 when login lands.
-- =====================================================================
alter table public.tab_raw                     enable row level security;
alter table public.tab_client_notes            enable row level security;
alter table public.tab_offboarded              enable row level security;
alter table public.tab_onboarding              enable row level security;
alter table public.tab_client_121              enable row level security;
alter table public.tab_catchup_call            enable row level security;
alter table public.tab_challenge_upgrade_call  enable row level security;
alter table public.tab_kickoff_calls           enable row level security;
alter table public.tab_programs                enable row level security;
alter table public.tab_retreat                 enable row level security;
alter table public.sync_status                 enable row level security;

create policy "anon read" on public.tab_raw                    for select to anon, authenticated using (true);
create policy "anon read" on public.tab_client_notes           for select to anon, authenticated using (true);
create policy "anon read" on public.tab_offboarded             for select to anon, authenticated using (true);
create policy "anon read" on public.tab_onboarding             for select to anon, authenticated using (true);
create policy "anon read" on public.tab_client_121             for select to anon, authenticated using (true);
create policy "anon read" on public.tab_catchup_call           for select to anon, authenticated using (true);
create policy "anon read" on public.tab_challenge_upgrade_call for select to anon, authenticated using (true);
create policy "anon read" on public.tab_kickoff_calls          for select to anon, authenticated using (true);
create policy "anon read" on public.tab_programs               for select to anon, authenticated using (true);
create policy "anon read" on public.tab_retreat                for select to anon, authenticated using (true);
create policy "anon read" on public.sync_status                for select to anon, authenticated using (true);

-- =====================================================================
-- n8n recipe — full replace per minute
-- =====================================================================
-- One workflow, one Cron trigger (every 1 min), one branch per tab.
-- Each branch is 3 nodes:
--
--   [Google Sheets: Read tab]  ->  [Code: shape rows]  ->  [Postgres: Execute Query]
--
-- The Postgres node runs a single multi-statement query (a transaction) so
-- the dashboard never sees an empty table mid-sync. Example for RAW:
--
--   begin;
--   delete from public.tab_raw;
--   insert into public.tab_raw
--     (sheet_row, client_id, name_ptd, name_fb, email, phone, origin_date, gender,
--      country, head_coach, current_program, length_type, extra_weeks, length_weeks,
--      current_program_start_date, current_program_end_date, days_to_end, closer,
--      support_coach, current_status, status_date, last_event_type, last_event_date,
--      payment_status, payment_cadence, currency, contract_value_home_currency,
--      cash_collected_home_currency, periodic_payments_home_currency,
--      current_agreement, net_after_stripe_cad, commission_cad, stripe_link, notes)
--   values
--     ($1, $2, $3, ...),  -- one tuple per sheet row
--     ...;
--   insert into public.sync_status (tab_name, last_synced_at, row_count, ok, error_message)
--   values ('RAW', now(), <rowcount>, true, null)
--   on conflict (tab_name) do update set
--     last_synced_at = excluded.last_synced_at,
--     row_count      = excluded.row_count,
--     ok             = excluded.ok,
--     error_message  = excluded.error_message;
--   commit;
--
-- Easier alternative without writing manual SQL: use the n8n Postgres node's
-- built-in "Insert" operation with "Mode: Insert" after running a separate
-- "Execute Query: delete from public.tab_raw" node — but keep them in the
-- same workflow run so a failure rolls forward at the next minute.
--
-- Credentials in n8n:
--   Host:     db.zkqtdjnffcnicsltttno.supabase.co
--   Port:     5432
--   Database: postgres
--   User:     postgres
--   Password: <from Supabase Dashboard -> Settings -> Database>
--   SSL:     require
-- =====================================================================
