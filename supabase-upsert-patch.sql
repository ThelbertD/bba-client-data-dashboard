-- =====================================================================
-- Upsert patch — run AFTER supabase-schema.sql.
-- Adds a UNIQUE constraint on sheet_row for every tab table so n8n's
-- Supabase "Upsert" operation can use sheet_row as the conflict column.
--
-- Pattern: n8n upserts each sheet row by its row index. Row N in the
-- sheet always maps to row N in Supabase.
--
-- CAVEAT: pure upsert never deletes. If you delete a row from the
-- middle of the sheet, the bottom-most row in Supabase will become
-- stale until you manually clean it up (or switch to truncate+insert).
-- =====================================================================

alter table public.tab_raw                     add constraint tab_raw_sheet_row_key                     unique (sheet_row);
alter table public.tab_client_notes            add constraint tab_client_notes_sheet_row_key            unique (sheet_row);
alter table public.tab_offboarded              add constraint tab_offboarded_sheet_row_key              unique (sheet_row);
alter table public.tab_onboarding              add constraint tab_onboarding_sheet_row_key              unique (sheet_row);
alter table public.tab_client_121              add constraint tab_client_121_sheet_row_key              unique (sheet_row);
alter table public.tab_catchup_call            add constraint tab_catchup_call_sheet_row_key            unique (sheet_row);
alter table public.tab_challenge_upgrade_call  add constraint tab_challenge_upgrade_call_sheet_row_key  unique (sheet_row);
alter table public.tab_kickoff_calls           add constraint tab_kickoff_calls_sheet_row_key           unique (sheet_row);
alter table public.tab_programs                add constraint tab_programs_sheet_row_key                unique (sheet_row);
alter table public.tab_retreat                 add constraint tab_retreat_sheet_row_key                 unique (sheet_row);

-- sync_status already has tab_name as primary key — upsert works out of the box.

-- =====================================================================
-- n8n setup — one branch per tab (delete the Merge + single Create node)
-- =====================================================================
-- For EACH of the 10 Google Sheets nodes, wire it to its own Supabase node:
--
--   Resource:         Row
--   Operation:        Upsert
--   Table:            tab_xxx  (see mapping below)
--   On Conflict:      sheet_row
--   Data to Send:     Define Below for Each Column
--   Fields to Send:   map every sheet column to the matching table column,
--                     and set sheet_row = {{$json["row_number"]}} from the
--                     Google Sheets node (or use an Item Index expression).
--
-- Tab -> Table mapping:
--   RAW                       -> tab_raw
--   CLIENT_NOTES              -> tab_client_notes
--   OFFBOARDED                -> tab_offboarded
--   ONBOARDING                -> tab_onboarding
--   CLIENT 121                -> tab_client_121
--   CATCHUP CALL              -> tab_catchup_call
--   CHALLENGE UPGRADE CALL    -> tab_challenge_upgrade_call
--   KICKOFF CALLS             -> tab_kickoff_calls
--   PROGRAMS                  -> tab_programs
--   RETREAT                   -> tab_retreat
--
-- Skip DATA VALIDATION DROPDOWNS — it's sheet config, not data.
--
-- After each tab's Upsert succeeds, optionally chain a second Supabase
-- node that upserts the heartbeat:
--   Table:        sync_status
--   Operation:    Upsert
--   On Conflict:  tab_name
--   Fields:       tab_name='RAW', last_synced_at=now(), row_count={{items count}}, ok=true
-- =====================================================================
