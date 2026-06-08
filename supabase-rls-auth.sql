-- =====================================================================
-- BBA Client Dashboard — Row Level Security (authenticated-only access)
-- =====================================================================
-- WHAT THIS DOES
--   * Enables RLS on every table the dashboard reads.
--   * Removes any existing permissive policies (e.g. old "anon read").
--   * Grants SELECT to logged-in (authenticated) users only.
--
-- RESULT
--   Signed-in users see all dashboard data. The public anon key can no
--   longer read these tables on its own, so the login screen actually
--   protects the data instead of just hiding the UI.
--
-- HOW TO RUN
--   Supabase Dashboard → SQL Editor → paste this whole file → Run.
--   Safe to re-run (idempotent).
--
-- NOTE
--   The data sync (n8n / service-role writer) uses the service_role key,
--   which BYPASSES RLS — so writes/syncs keep working unchanged.
-- =====================================================================

do $$
declare
  t   text;
  pol record;
  tables text[] := array[
    'raw',
    'client_notes',
    'offboarded',
    'onboarding',
    'momentum',
    'celebration',
    'challenge_upgrade',
    'catchup_call',
    'kickoff',
    'programs',
    'retreat',
    'data_validation_dropdowns'
  ];
begin
  foreach t in array tables loop

    -- Skip gracefully if a table doesn't exist in this project
    if to_regclass(format('public.%I', t)) is null then
      raise notice 'Skipping missing table: %', t;
      continue;
    end if;

    -- 1) Turn RLS on (deny-by-default for any role without a matching policy)
    execute format('alter table public.%I enable row level security;', t);
    execute format('alter table public.%I force row level security;',  t);

    -- 2) Drop every existing policy (clears old anon-read grants)
    for pol in
      select policyname
      from pg_policies
      where schemaname = 'public' and tablename = t
    loop
      execute format('drop policy if exists %I on public.%I;', pol.policyname, t);
    end loop;

    -- 3) Allow SELECT for authenticated (logged-in) users only
    execute format(
      'create policy "authenticated read" on public.%I '
      || 'for select to authenticated using (true);',
      t
    );

    raise notice 'RLS configured: %', t;
  end loop;
end $$;

-- =====================================================================
-- VERIFY (optional) — list the policies now in place.
-- Expect exactly one "authenticated read" SELECT policy per table.
-- =====================================================================
-- select tablename, policyname, roles, cmd
-- from pg_policies
-- where schemaname = 'public'
--   and tablename in (
--     'raw','client_notes','offboarded','onboarding','momentum','celebration',
--     'challenge_upgrade','catchup_call','kickoff','programs','retreat',
--     'data_validation_dropdowns'
--   )
-- order by tablename;

-- =====================================================================
-- ROLLBACK (optional) — re-open read access to the anon key.
-- Only run if you need to revert to the previous open-read behaviour.
-- =====================================================================
-- do $$
-- declare t text;
-- declare tables text[] := array[
--   'raw','client_notes','offboarded','onboarding','momentum','celebration',
--   'challenge_upgrade','catchup_call','kickoff','programs','retreat',
--   'data_validation_dropdowns'];
-- begin
--   foreach t in array tables loop
--     if to_regclass(format('public.%I', t)) is null then continue; end if;
--     execute format('drop policy if exists "authenticated read" on public.%I;', t);
--     execute format('create policy "anon read" on public.%I for select to anon, authenticated using (true);', t);
--   end loop;
-- end $$;
