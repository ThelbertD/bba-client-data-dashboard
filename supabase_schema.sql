-- =============================================================
-- Supabase schema for: REPORT - SALES CALLS (Client Data Dashboard)
-- Source sheet tabs:
--   1. RAW
--   2. LOOM
--   3. DROPDOWNS (RAW)
--   4. DROPDOWNS (LOOM)
--   5. UNWANTED CANCELLATIONS
-- One table per tab. Run this whole file in the Supabase SQL Editor.
--
-- Note on types: text fields mirror the sheet's dropdown values exactly
-- (YES/NO, PAST/FUTURE, etc.) so importing the sheet is friction-free.
-- APPOINTMENT_TIME is kept as the display string; APPOINTMENT_SERIAL
-- holds the sortable timestamp used for ordering/filtering.
-- =============================================================


-- =============================================================
-- TAB 1: RAW  -- master appointment / sales-call records
-- =============================================================
create table if not exists raw_appointments (
  id                      uuid primary key default gen_random_uuid(),
  lead                    text,
  coach                   text,        -- DROPDOWNS (RAW).COACH
  closer                  text,        -- DROPDOWNS (RAW).CLOSER
  date_added              date,
  appointment_serial      timestamptz, -- sortable appointment datetime
  appointment_time        text,        -- display string: "Tue, Jan 27 - 6:45 p.m."
  email                   text,
  gender                  text,        -- FEMALE / MALE
  lead_origin             text,        -- FACEBOOK / INSTAGRAM / TIKTOK / ...
  ig                      text,        -- Instagram handle
  fbtt                    text,        -- Facebook name
  showed                  text,        -- YES / NO / THEY CANCELLED / WE CANCELLED
  closed                  text,        -- YES / NO
  sale_type               text,        -- 6 MONTHS - PP / 12 MONTHS - PIF / CHALLENGE / ...
  closers_notes           text,        -- "CLOSERS  NOTES"
  nurtures_notes          text,        -- "NURTURES  NOTES"
  job_title               text,
  source                  text,
  week_start              date,
  appointment_before_now  text,        -- PAST / FUTURE
  follow_up               text,        -- DROPDOWNS (RAW).FOLLOW UP
  created_at              timestamptz default now(),
  updated_at              timestamptz default now()
);
create index if not exists idx_raw_serial   on raw_appointments (appointment_serial);
create index if not exists idx_raw_coach     on raw_appointments (coach);
create index if not exists idx_raw_closer    on raw_appointments (closer);
create index if not exists idx_raw_week      on raw_appointments (week_start);
create index if not exists idx_raw_showed    on raw_appointments (showed);
create index if not exists idx_raw_closed    on raw_appointments (closed);


-- =============================================================
-- TAB 2: LOOM  -- loom outreach / high-ticket nurture records
-- =============================================================
create table if not exists loom_outreach (
  id                              uuid primary key default gen_random_uuid(),
  lead                            text,
  coach                           text,
  email                           text,
  loom_sent_date_time             timestamptz,
  gender                          text,
  lead_origin                     text,        -- includes META (loom dropdown)
  ig                              text,
  fbtt                            text,
  loom_offer                      text,        -- HIGH_TICKET / CHALLENGE
  loom_status                     text,        -- SENT / WATCHED / RESPONDED / NO RESPONSE
  closed_ht                       text,        -- YES / NO  (closed high-ticket)
  sale_type                       text,
  week_start                      date,
  loom_sent_date_time_before_now  text,        -- PAST / FUTURE
  follow_up                       text,        -- DROPDOWNS (LOOM).FOLLOW UP
  created_at                      timestamptz default now(),
  updated_at                      timestamptz default now()
);
create index if not exists idx_loom_sent    on loom_outreach (loom_sent_date_time);
create index if not exists idx_loom_coach    on loom_outreach (coach);
create index if not exists idx_loom_status   on loom_outreach (loom_status);
create index if not exists idx_loom_closedht on loom_outreach (closed_ht);


-- =============================================================
-- TAB 5: UNWANTED CANCELLATIONS  -- cancellations log + investigation
-- =============================================================
create table if not exists unwanted_cancellations (
  id                      uuid primary key default gen_random_uuid(),
  lead                    text,
  coach                   text,
  closer                  text,
  date_added              date,
  appointment_serial      timestamptz,
  appointment_time        text,        -- "TIME" column display string
  email                   text,
  gender                  text,
  lead_origin             text,
  ig                      text,
  fbtt                    text,
  showed                  text,        -- usually WE CANCELLED / THEY CANCELLED
  closed                  text,        -- YES / NO
  sale_type               text,
  notes                   text,
  week_start              date,
  appointment_before_now  text,        -- PAST / FUTURE
  investigation           text,        -- OFFERED RESCHEDULE / RESCHEDULED / DONE / ...
  reschedule_closer       text,        -- when rebooked (optional)
  reschedule_serial       timestamptz, -- rebooked datetime (optional)
  created_at              timestamptz default now(),
  updated_at              timestamptz default now()
);
create index if not exists idx_unw_serial on unwanted_cancellations (appointment_serial);
create index if not exists idx_unw_coach   on unwanted_cancellations (coach);
create index if not exists idx_unw_closer  on unwanted_cancellations (closer);


-- =============================================================
-- TAB 3 + 4: DROPDOWNS (RAW) and DROPDOWNS (LOOM)
-- These tabs are validation/option lists, not transactional data.
-- Stored in long format: one row per (field, option) so the app can
-- populate dropdowns and validate inputs. (One table per source tab.)
-- =============================================================
create table if not exists dropdowns_raw (
  id          uuid primary key default gen_random_uuid(),
  field_name  text not null,   -- e.g. COACH, CLOSER, SHOWED, SALE_TYPE, FOLLOW UP
  option_value text not null,
  sort_order  int default 0,
  unique (field_name, option_value)
);

create table if not exists dropdowns_loom (
  id          uuid primary key default gen_random_uuid(),
  field_name  text not null,   -- e.g. COACH, LOOM_OFFER, LOOM_STATUS, SALE_TYPE, FOLLOW UP
  option_value text not null,
  sort_order  int default 0,
  unique (field_name, option_value)
);

-- ---- Seed: DROPDOWNS (RAW) ----------------------------------
insert into dropdowns_raw (field_name, option_value, sort_order) values
  ('COACH','DOM FISCHER',1),('COACH','CARLY STUART',2),('COACH','CORDIA CHAN',3),
  ('COACH','ERIN PREECE',4),('COACH','JASE STUART',5),('COACH','TROY MCLELLAN',6),
  ('CLOSER','CARLY STUART',1),('CLOSER','CORDIA CHAN',2),('CLOSER','DOM FISCHER',3),
  ('CLOSER','ERIN PREECE',4),('CLOSER','TROY MCLELLAN',5),('CLOSER','JASE STUART',6),
  ('CLOSER','JACK HOLT',7),('CLOSER','STUART MCDERMID',8),
  ('GENDER','FEMALE',1),('GENDER','MALE',2),
  ('LEAD_ORIGIN','FACEBOOK',1),('LEAD_ORIGIN','INSTAGRAM',2),('LEAD_ORIGIN','TIKTOK',3),
  ('LEAD_ORIGIN','YOUTUBE',4),('LEAD_ORIGIN','LINKEDIN',5),('LEAD_ORIGIN','BBA PODCAST',6),
  ('LEAD_ORIGIN','WEBSITE',7),('LEAD_ORIGIN','EMAIL',8),
  ('SHOWED','YES',1),('SHOWED','NO',2),('SHOWED','THEY CANCELLED',3),('SHOWED','WE CANCELLED',4),
  ('CLOSED','YES',1),('CLOSED','NO',2),
  ('SALE_TYPE','6 MONTHS - PP',1),('SALE_TYPE','6 MONTHS - PIF',2),
  ('SALE_TYPE','12 MONTHS - PP',3),('SALE_TYPE','12 MONTHS - PIF',4),('SALE_TYPE','CHALLENGE',5),
  ('APPOINTMENT_BEFORE_NOW','PAST',1),('APPOINTMENT_BEFORE_NOW','FUTURE',2),
  ('FOLLOW UP','OFFERED MEAL PLAN',1),('FOLLOW UP','SENT MEAL PLAN',2),
  ('FOLLOW UP','FOLLOW UP MEAL PLAN',3),('FOLLOW UP','OFFERED CHALLENGE',4),
  ('FOLLOW UP','DONE',5),('FOLLOW UP','CLIENT',6),('FOLLOW UP','SENT LOOM VIDEO',7),
  ('FOLLOW UP','SENT RESCHEDULE LINK',8),('FOLLOW UP','1 FOLLOW UP - RESCHEDULE',9),
  ('FOLLOW UP','2 FOLLOW UP - RESCHEDULE',10),('FOLLOW UP','RESCHEDULED',11)
on conflict (field_name, option_value) do nothing;

-- ---- Seed: DROPDOWNS (LOOM) ---------------------------------
insert into dropdowns_loom (field_name, option_value, sort_order) values
  ('COACH','DOM FISCHER',1),('COACH','CARLY STUART',2),('COACH','CORDIA CHAN',3),
  ('COACH','ERIN PREECE',4),('COACH','JASE STUART',5),('COACH','TROY MCLELLAN',6),
  ('GENDER','FEMALE',1),('GENDER','MALE',2),
  ('LEAD_ORIGIN','FACEBOOK',1),('LEAD_ORIGIN','INSTAGRAM',2),('LEAD_ORIGIN','TIKTOK',3),
  ('LEAD_ORIGIN','YOUTUBE',4),('LEAD_ORIGIN','LINKEDIN',5),('LEAD_ORIGIN','BBA PODCAST',6),
  ('LEAD_ORIGIN','WEBSITE',7),('LEAD_ORIGIN','EMAIL',8),('LEAD_ORIGIN','META',9),
  ('LOOM_OFFER','HIGH_TICKET',1),('LOOM_OFFER','CHALLENGE',2),
  ('LOOM_STATUS','SENT',1),('LOOM_STATUS','WATCHED',2),('LOOM_STATUS','RESPONDED',3),
  ('LOOM_STATUS','NO RESPONSE',4),
  ('CLOSED','YES',1),('CLOSED','NO',2),
  ('SALE_TYPE','6 MONTHS - PP',1),('SALE_TYPE','6 MONTHS - PIF',2),
  ('SALE_TYPE','12 MONTHS - PP',3),('SALE_TYPE','12 MONTHS - PIF',4),('SALE_TYPE','CHALLENGE',5),
  ('APPOINTMENT_BEFORE_NOW','PAST',1),('APPOINTMENT_BEFORE_NOW','FUTURE',2),
  ('FOLLOW UP','OFFERED MEAL PLAN',1),('FOLLOW UP','SENT MEAL PLAN',2),
  ('FOLLOW UP','FOLLOW UP MEAL PLAN',3),('FOLLOW UP','SENT RESCHEDULE LINK',4),
  ('FOLLOW UP','RESCHEDULED',5),('FOLLOW UP','DONE',6),('FOLLOW UP','CLIENT',7),
  ('FOLLOW UP','OFFERED RESCHEDULE',8),('FOLLOW UP','SENT LOOM VIDEO',9),
  ('FOLLOW UP','OFFERED CHALLENGE',10),('FOLLOW UP','SENT CHALLENGE',11)
on conflict (field_name, option_value) do nothing;
