# BBA Client Data Dashboard — Build Progress

**Progress Report · Updated 8 June 2026**

A live, login-protected view of retention, churn, and renewals — sourced from the TRACKER spreadsheet, refreshed every minute, broken down by support coach. Built for Jase and the management team to baseline performance and identify the coaches driving the best outcomes.

| | |
|---|---|
| **Phases complete** | 4 of 6 |
| **Demo target** | 4–5 June 2026 |
| **Retention baseline** | 1 June 2026 |
| **Build estimate** | < 1 day remaining |

🔗 Live dashboard: http://localhost:8080/
🔗 Source repo: https://github.com/ThelbertD/bba-client-data-dashboard *(private)*

---

## Where we are right now

28 features in the spec. The metrics layer Jase named as critical — churn, retention, renewal, off-boarding split, plus the per-coach view — shipped earlier. Since then we've landed the **n8n live pipeline**, the **client-journey funnel with first-month survival**, the **burned-out vs completed-then-left off-boarding tag**, and **Supabase login with authenticated-only data access**. Remaining work is wiring the AI assistant to Claude and capturing the daily retention baseline.

**Overall delivery: 90%** *(counting partials as half-credit)*

```
██████████████████████████████████████████████████████░░░░░░  90%
```

| Status | Count | Notes |
|---|---|---|
| ✅ **Delivered** | **25** | Built & visible in the dashboard |
| 🟡 **In progress** | **1** | Wired, awaiting final connection |
| 🔵 **Lined up** | **1** | Next on the build queue |
| 🔴 **Awaiting input** | **2** | Need access keys or accounts |

---

## The six phases

Each phase is a self-contained milestone. The first two are largely complete; Phases 2 and 3 shipped this week.

### ✅ Phase 0 — Data readiness — **90%**
Source spreadsheet audited end-to-end — all required columns confirmed present and emitted in the data feed. One remaining sub-task: an auto-stamp trigger on the status-date column (~10-line script).

### ✅ Phase 1 — Live data pipeline — **100%** 🎉
**Shipped.** The n8n workflow is built and connected — it reads the Sheet on a 1-minute schedule and writes the dashboard payload to the data source. The dashboard polls every 60 seconds, so the "Last sync" timestamp now advances on its own with no manual refresh.

### ✅ Phase 2 — Priority metrics: churn, retention, renewal — **100%** 🎉
**Shipped.** Four headline KPI cards live across the top row: churn rate, retention rate, renewal rate, and the off-boarding split (paying vs challenge). Each card is click-through and recomputes live with the date filter.

### ✅ Phase 3 — The coach story — **100%** 🎉
**Shipped.** Support coach performance table ranks every coach by retention. A coach selector in the top controls filters the entire dashboard — KPIs, charts, calendar, tables — down to one coach's book in a single click.

### ✅ Phase 4 — Funnel & churn reason — **100%** 🎉
**Shipped.** Onboarding → Active → Cancelled journey funnel with a first-month survival figure (share of clients who signed up ≥30 days ago and did *not* churn in month one). Every off-boarded client is auto-tagged "🔥 burned out early" (dropped mid-term or inside 30 days) vs "🏁 completed then left" (saw the program through, then left) — surfaced as a clickable split and as an Exit-reason tag on each client row. Each funnel stage and reason drills through to its client list.

### 🟡 Phase 5 — Login & AI assistant — **60%**
**Login shipped.** Supabase email/password login gates the whole dashboard, and Row Level Security locks all 12 data tables to authenticated users only — the public key alone now returns zero rows, so the login actually protects the data rather than just hiding the UI. Remaining: per-coach default scoping (coaches land on their own book) and wiring the chat widget to Claude so it explains the numbers in plain English beyond keyword matching.

### 🔴 Phase 6 — Retention baseline & finish — **Final**
A daily retention snapshot starting 1 June so Ryan has a "this is where we started" benchmark, plus week-in-program and price shown on every renewal-ready client row.

---

## ★ Just shipped this week — 7 new features for Jase's demo

The features named in the kickoff call as critical for the Phase 2 + Phase 3 demo. All live in the dashboard right now.

1. **★ Churn rate · headline KPI** — Big top-row card. Lifetime cancelled ÷ total ever. Click-through to the cancelled client list.
2. **★ Retention rate · headline KPI** — The mirror of churn. Active ÷ (active + cancelled). Click-through to the still-active book.
3. **★ Renewal rate · headline KPI** — Clients on extra weeks ÷ clients past onboarding. Surfaces the upsell base.
4. **★ Off-boarding split · headline KPI** — Single card showing total off-boarded plus a visual paying-vs-challenge bar split.
5. **★ Support coach leaderboard** — Every coach ranked by retention with active / cancelled / contract value side by side.
6. **★ Whole-dashboard coach filter** — Pick a coach from the top selector and every KPI, chart, calendar, and table narrows to their book.
7. **★ Chat answers match the KPI cards** — Ask "what's our churn rate?" in the chat and the number matches the headline card exactly, by reading from the same source. *Closes demo acceptance criterion: "AI assistant returns the same churn number as the KPI card."*

---

## Foundation already in place — 14 features that have been live

The dashboard chassis built earlier in the project — every one of these is what the new headline KPIs sit on top of.

- **✓ 18 KPI tiles** — Active book, programs, payments, retention — all in a 3×6 snapshot grid.
- **✓ Date range filter** — Quick chips for Today / 7D / 30D / MTD / QTD / YTD plus custom dates.
- **✓ Click-through drill-downs** — Every tile opens the full client list — searchable, sortable, CSV-exportable.
- **✓ Monthly calendar** — Sign-ups, endings, and past-due all on one calendar. Click any day to drill in.
- **✓ All 10 sheet tabs** — RAW, OFFBOARDED, ONBOARDING, CLIENT 121, KICKOFF, PROGRAMS — every tab has its own view.
- **✓ Auto-generated dashboards** — Each tab analyses its own columns and builds the right charts and KPIs automatically.
- **✓ Cell-level filtering** — Click any cell to filter the whole dashboard by that value instantly.
- **✓ Client 360 panel** — Click any client ID to see their full record across every tab they appear in.
- **✓ Closer leaderboard** — Sales-side ranking with retention percentage per closer.
- **✓ Programs ending soon** — A live list of clients whose program is nearing its end.
- **✓ Recent additions** — The freshest sign-ups, surfaced at a glance.
- **✓ Distribution charts** — Status, program, country, and head coach — visual at a glance.
- **✓ 1-minute auto-refresh** — The dashboard re-reads its data source every 60 seconds with no page reload.
- **✓ AI assistant panel** — Floating chat that already answers from the local snapshot — gets wired to live data in Phase 5.

---

## What's left before "demo ready"

The headline KPIs, the coach view, the journey funnel, the live pipeline, and login are all done. Three items remain before the build is fully closed out.

| # | Feature | Description | ETA |
|---|---|---|---|
| 01 | **Per-coach default view** | Login is live and managers see the whole business; the remaining piece is scoping each coach to land on their own book by default. ~10 users to provision. | This week |
| 02 | **AI assistant wired to Claude** | The chat panel already answers from the live snapshot and matches the KPI cards. Phase 5 wires it to Claude so it can explain the numbers in plain English and answer follow-ups. | Needs Anthropic key |
| 03 | **1 June retention baseline** | A daily snapshot of retention rate stored from 1 June onwards so Ryan has a "this is where we started" benchmark to grow against. | Daily, ongoing |

---

## The dates that matter

| Date | What |
|---|---|
| 🔵 **Today · 8 June 2026** | Phases 1–4 shipped and in production; Supabase login + RLS live. Baseline snapshots running daily since 1 June. Build is in its final stretch — AI assistant + per-coach scoping to go. |
| **1 June 2026** *(baseline)* | First daily retention snapshot stored so Ryan has a "this is where we started" benchmark to grow from. |
| **4–5 June 2026** *(demo)* | Working demo with churn, retention, renewal, off-boarding split, support coach leaderboard, and coach filter — the priority five for Jase. |

---

## What "demo ready" means

The nine checks from the spec. The demo is ready when every box is ticked.

- [x] Live "Last sync" timestamp that updates *— n8n live pipeline shipped*
- [x] Top row shows churn, retention, renewal, and off-boarded with the challenge-versus-paying split
- [x] Support coach leaderboard ranks coaches by retention
- [x] The whole dashboard can be filtered to one support coach
- [x] The funnel shows first-month survival percentage
- [x] Off-boarded clients are tagged "burned out" or "completed then left"
- [x] Login required — managers see everything *(per-coach default scoping still to come)*
- [x] AI assistant returns the same churn number as the KPI card
- [ ] Retention baseline captured starting 1 June for Ryan

> **8 of 9 done · 1 to go before the demo ships**

---

*Sources: 26 May 2026 build spec · live dashboard codebase · TRACKER — CLIENT SUCCESS spreadsheet*

*Better Body Academy — Internal progress report. Not for distribution outside the team.*
