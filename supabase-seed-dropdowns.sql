-- =====================================================================
-- Seed data_validation_dropdowns with the master rosters from the
-- TRACKER sheet's DATA VALIDATION DROPDOWNS tab.
--
-- Run this once in Supabase Dashboard → SQL Editor → New query.
-- Safe to re-run: TRUNCATE clears the table first.
--
-- Source: gid=801848151 of
--   https://docs.google.com/spreadsheets/d/1wBlcdRKzT_MPf5ktldZbfvMn3eX7TjzmtIgtDo591IY
-- =====================================================================

truncate table public.data_validation_dropdowns;

insert into public.data_validation_dropdowns (
  gender, country, head_coach, current_program, length_type,
  closer, support_coach, current_status, last_event_type,
  sales_closers
) values
  ('FEMALE', 'AUSTRALIA',     'DOM FISCHER',   'CHALLENGE', '4',   'CARLY STUART',     'OB TEAM',          'ACTIVE_ONBOARDING', 'ONBOARDING_STARTED',   'STUART MCDERMID'),
  ('MALE',   'NEW ZEALAND',   'CARLY STUART',  'IGNITION',  '26',  'CORDIA CHAN',      'IGGY DOMINGO',     'ACTIVE_COACHING',   'ONBOARDING_COMPLETED', 'JACK HOLT'),
  (NULL,     'UK + IRELAND',  'CORDIA CHAN',   'BASECAMP',  '52',  'DOM FISCHER',      'JEREMIAH BARREDO', 'CANCELLED',         'ONBOARDING_GRADUATED', 'DOM FISCHER'),
  (NULL,     'UNITED STATES', 'ERIN PREECE',   'ELITE',     'N/A', 'ERIN PREECE',      'JOHN PAUL APINES', 'ACTIVE_PAUSED',     'PROGRAM_BASE_EXTENSION', NULL),
  (NULL,     'CANADA',        'JASE STUART',   NULL,        NULL,  'TROY MCLELLAN',    'KERT ACOT',        'ACTIVE_LIFE',       'PROGRAM_BASE_UPGRADE', NULL),
  (NULL,     'OTHER',         'TROY MCLELLAN', NULL,        NULL,  'JASE STUART',      'LEANDRA REYES',    NULL,                'PROGRAM_ELITE_UPGRADE', NULL),
  (NULL,     NULL,            NULL,            NULL,        NULL,  'JACK HOLT',        'NICO ALBINES',     NULL,                'PAUSED',                NULL),
  (NULL,     NULL,            NULL,            NULL,        NULL,  'STUART MCDERMID',  'PATRICIA MALONZO', NULL,                'UNPAUSED',              NULL),
  (NULL,     NULL,            NULL,            NULL,        NULL,  'MARIELLE EUSUBIO', 'SAM FUENTES',      NULL,                'CANCELLED',             NULL),
  (NULL,     NULL,            NULL,            NULL,        NULL,  'DEL LAPID',        'UNASSIGNED',       NULL,                'REACTIVATED',           NULL),
  (NULL,     NULL,            NULL,            NULL,        NULL,  'JP APINES',        'N/A',              NULL,                'LIFE_GRANTED',          NULL),
  (NULL,     NULL,            NULL,            NULL,        NULL,  'SAM FUENTES',      'TONY DOLOR',       NULL,                'PAYMENT_FAILED',        NULL),
  (NULL,     NULL,            NULL,            NULL,        NULL,  'IGE DOMINGO',      'DAUN RAFAL',       NULL,                'PAYMENT_RECOVERED',     NULL),
  (NULL,     NULL,            NULL,            NULL,        NULL,  'ADA REYES',        'TERI QUIMBO',      NULL,                NULL,                    NULL),
  (NULL,     NULL,            NULL,            NULL,        NULL,  'JER BARREDO',      'FRAN FRANCISCO',   NULL,                NULL,                    NULL),
  (NULL,     NULL,            NULL,            NULL,        NULL,  'FRAN FRANCISCO',   NULL,               NULL,                NULL,                    NULL);

-- Sanity check
select 'data_validation_dropdowns' as table_name,
       count(*) as rows,
       count(distinct support_coach) filter (where support_coach not in ('OB TEAM','UNASSIGNED','N/A')) as real_coaches
from public.data_validation_dropdowns;
