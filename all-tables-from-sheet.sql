-- =====================================================================
-- BBA Client Dashboard — ALL tables from the Google Sheet (1 per tab)
-- =====================================================================
-- Mirrors every tab + its headers from the source spreadsheet.
-- Each table has a PRIMARY KEY so the n8n sync can UPSERT
-- (Prefer: resolution=merge-duplicates) — new/changed sheet rows update,
-- existing rows are overwritten, so Supabase always matches the sheet.
--
-- RLS: every table gets enable+force + "authenticated read".
--      Only the service_role key (n8n) can write.
--
-- HOW TO RUN: Supabase -> SQL Editor -> paste -> Run.
--
-- ⚠️ DESTRUCTIVE: the "drop table" lines below DELETE existing tables so
--    the schema exactly matches the sheet. Your n8n sync will repopulate
--    them. If you want to KEEP current data, delete the drop lines and
--    note that existing tables won't be altered (create-if-not-exists).
-- =====================================================================

drop table if exists public.raw                       cascade;
drop table if exists public.client_notes              cascade;
drop table if exists public.onboarding                cascade;
drop table if exists public.offboarded                cascade;
drop table if exists public.momentum                  cascade;
drop table if exists public.celebration               cascade;
drop table if exists public.catchup_call              cascade;
drop table if exists public.challenge_upgrade         cascade;
drop table if exists public.kickoff                   cascade;
drop table if exists public.programs                  cascade;
drop table if exists public.retreat                   cascade;
drop table if exists public.data_validation_dropdowns cascade;

-- ---------------------------------------------------------------------
-- 1) RAW  (tab: RAW)
-- ---------------------------------------------------------------------
create table public.raw (
  email                              text primary key,
  row_index                          integer,
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

-- ---------------------------------------------------------------------
-- 2) CLIENT_NOTES  (tab: CLIENT_NOTES)
-- ---------------------------------------------------------------------
create table public.client_notes (
  client_id          text primary key,
  row_index          integer,
  name_ptd           text,
  name_fb            text,
  head_coach         text,
  support_coach      text,
  program            text,
  current_status     text,
  program_end_date   date,
  posting            text,
  attending          text,
  check_in           text,
  engaging           text,
  notes              text,
  synced_at          timestamptz default now()
);

-- ---------------------------------------------------------------------
-- 3) ONBOARDING  (tab: ONBOARDING)
-- ---------------------------------------------------------------------
create table public.onboarding (
  email                         text primary key,
  row_index                     integer,
  name                          text,
  coach                         text,
  ptd_signup_date               date,
  weeks_signed                  integer,
  four_plus_week_date           date,
  week                          integer,
  ob_success                    text,
  program_assigned              text,
  start_weight_kg               numeric(10,2),
  goal_weight_kg                numeric(10,2),
  kickoff_call_attended_sent    text,
  posting                       text,
  attending                     text,
  check_in                      text,
  engaging                      text,
  triage_status                 text,
  triage_call_notes             text,
  last_contact_date             date,
  client_notes                  text,
  synced_at                     timestamptz default now()
);

-- ---------------------------------------------------------------------
-- 4) OFFBOARDED  (tab: OFFBOARDED)
--    Sheet had #REF!/blank columns; mapped to the raw equivalents.
-- ---------------------------------------------------------------------
create table public.offboarded (
  email                              text primary key,
  row_index                          integer,
  date_offboarded                    date,
  client_id                          text,
  name_ptd                           text,
  name_fb                            text,
  phone                              text,
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

-- ---------------------------------------------------------------------
-- 5) MOMENTUM  (tab: MOMENTUM)  — call log, keyed by client + appt
-- ---------------------------------------------------------------------
create table public.momentum (
  name_ptd                   text not null,
  date_appointment_pst       text not null,
  row_index                  integer,
  name_fb                    text,
  support_coach              text,
  program                    text,
  host_name                  text,
  call_notes_momentum_coach  text,
  synced_at                  timestamptz default now(),
  primary key (name_ptd, date_appointment_pst)
);

-- ---------------------------------------------------------------------
-- 6) CELEBRATION  (tab: CELEBRATION)
-- ---------------------------------------------------------------------
create table public.celebration (
  name_ptd                   text not null,
  date_appointment_pst       text not null,
  row_index                  integer,
  name_fb                    text,
  support_coach              text,
  program                    text,
  host_name                  text,
  target_action_extension    text,
  call_notes_momentum_coach  text,
  synced_at                  timestamptz default now(),
  primary key (name_ptd, date_appointment_pst)
);

-- ---------------------------------------------------------------------
-- 7) CATCHUP_CALL  (tab: CATCHUP CALL)
-- ---------------------------------------------------------------------
create table public.catchup_call (
  name_ptd                 text not null,
  date_appointment_pst     text not null,
  row_index                integer,
  name_fb                  text,
  support_coach            text,
  host_name                text,
  target_action_referral   text,
  call_notes_closer        text,
  synced_at                timestamptz default now(),
  primary key (name_ptd, date_appointment_pst)
);

-- ---------------------------------------------------------------------
-- 8) CHALLENGE_UPGRADE  (tab: CHALLENGE UPGRADE)
-- ---------------------------------------------------------------------
create table public.challenge_upgrade (
  name_ptd                 text not null,
  date_appointment_pst     text not null,
  row_index                integer,
  name_fb                  text,
  host_name                text,
  target_action_upgrade    text,
  call_notes_closer        text,
  synced_at                timestamptz default now(),
  primary key (name_ptd, date_appointment_pst)
);

-- ---------------------------------------------------------------------
-- 9) KICKOFF  (tab: KICKOFF)
-- ---------------------------------------------------------------------
create table public.kickoff (
  client                       text not null,
  appointment_time_vancouver   text not null,
  row_index                    integer,
  appointment_time_local       text,
  synced_at                    timestamptz default now(),
  primary key (client, appointment_time_vancouver)
);

-- ---------------------------------------------------------------------
-- 10) PROGRAMS  (tab: PROGRAMS)
-- ---------------------------------------------------------------------
create table public.programs (
  name                     text not null,
  game_plan_date           date not null,
  row_index                integer,
  which_program_assigned   text,
  video_troy               text,
  start_weight_kg          numeric(10,2),
  goal_weight_kg           numeric(10,2),
  notes                    text,
  synced_at                timestamptz default now(),
  primary key (name, game_plan_date)
);

-- ---------------------------------------------------------------------
-- 11) RETREAT  (tab: RETREAT)  — keyed by the "#" sequence column
-- ---------------------------------------------------------------------
create table public.retreat (
  seq_num                  integer primary key,
  row_index                integer,
  retreat_1_hunter_valley  text,
  frequency                text,
  subscription_loaded      text,
  total_cost               numeric(14,2),
  deposit_pif              numeric(14,2),
  periodic                 numeric(14,2),
  synced_at                timestamptz default now()
);

-- ---------------------------------------------------------------------
-- 12) DATA_VALIDATION_DROPDOWNS  (tab: DATA VALIDATION DROPDOWNS)
--     Column-wise option lists; no natural key -> surrogate id.
--     Sync pattern: TRUNCATE + reload (not upsert).
-- ---------------------------------------------------------------------
create table public.data_validation_dropdowns (
  id                                bigint generated always as identity primary key,
  row_index                         integer,
  gender                            text,
  country                           text,
  head_coach                        text,
  current_program                   text,
  length_type                       text,
  closer                            text,
  support_coach                     text,
  current_status                    text,
  last_event_type                   text,
  payment_status                    text,
  payment_cadence                   text,
  currency                          text,
  contract_value_home_currency      text,
  cash_collected_home_currency      text,
  periodic_payments_home_currency   text,
  current_agreement                 text,
  net_after_stripe_cad              text,
  commission_cad                    text,
  stripe_link                       text,
  notes                             text,
  sales_closers                     text,
  synced_at                         timestamptz default now()
);

-- =====================================================================
-- ROW LEVEL SECURITY for every table above
-- =====================================================================
do $$
declare
  t   text;
  pol record;
  tables text[] := array[
    'raw','client_notes','onboarding','offboarded','momentum','celebration',
    'catchup_call','challenge_upgrade','kickoff','programs','retreat',
    'data_validation_dropdowns'
  ];
begin
  foreach t in array tables loop
    execute format('alter table public.%I enable row level security;', t);
    execute format('alter table public.%I force  row level security;', t);

    for pol in
      select policyname from pg_policies
      where schemaname = 'public' and tablename = t
    loop
      execute format('drop policy if exists %I on public.%I;', pol.policyname, t);
    end loop;

    execute format(
      'create policy "authenticated read" on public.%I for select to authenticated using (true);',
      t
    );
  end loop;
end $$;

-- =====================================================================
-- (Optional) Enable Supabase Realtime on every table so the dashboard
-- updates live when the sync writes new data.
-- =====================================================================
-- do $$
-- declare t text;
-- declare tables text[] := array[
--   'raw','client_notes','onboarding','offboarded','momentum','celebration',
--   'catchup_call','challenge_upgrade','kickoff','programs','retreat',
--   'data_validation_dropdowns'];
-- begin
--   foreach t in array tables loop
--     execute format('alter publication supabase_realtime add table public.%I;', t);
--   end loop;
-- end $$;
