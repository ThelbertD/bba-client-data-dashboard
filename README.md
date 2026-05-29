# BBA Client Data Dashboard

Internal dashboard for **Better Body Academy** that visualises the `TRACKER - CLIENT SUCCESS` Google Sheet — active book of business, programs, payments, retention, churn, and renewals.

> ⚠️ **Private repo — contains real client data.** Do not change visibility to public without first removing `data.json`.

## What it does

- **Client Success dashboard** — 18 KPI tiles (3×6 grid), 4 distribution charts, monthly calendar of sign-ups + endings, closer leaderboard, programs ending soon, recent additions
- **Date range filter** — preset chips (Today / 7D / 30D / MTD / QTD / YTD / All) + custom date inputs
- **Click-through everything** — every KPI tile opens a slide-in drill-down with the filtered client list, sortable, searchable, exportable as CSV
- **Calendar widget** — month view, sign-ups (blue) + endings (orange) + past due (red), click any day to drill into that day's clients
- **Tab navigation** — left sidebar with all 10 sheet tabs (RAW, OFFBOARDED, ONBOARDING, etc.) — each gets an auto-generated dashboard
- **Auto-dashboards** — each tab's columns are analysed (numeric / date / categorical detection) and the dashboard generates KPIs + charts automatically
- **Cell-level interactions** — click any cell to add a filter chip, click a client ID to open a **Client 360** panel showing that client's record across every tab where they appear
- **AI chat widget** — floating bubble bottom-right, answers questions about the current snapshot from local data (stub mode; ready to wire to Claude/OpenAI)

## Source sheet

```
https://docs.google.com/spreadsheets/d/1wBlcdRKzT_MPf5ktldZbfvMn3eX7TjzmtIgtDo591IY/edit
```

Sharing must be set to **Anyone with link → Viewer** for `build_data.py` (and n8n) to read it without OAuth.

## Architecture

```
Google Sheet  →  build_data.py  →  data.json  →  index.html (browser)
       │              │                                    ↑
       │              └─ will be replaced by n8n          │
       │                                                   │
       └─────── n8n cron (every 1 min) ───────────────────┘
```

- `build_data.py` — fetches all 10 tabs from the Sheet as CSV, structures `RAW` into typed client objects, includes the other tabs as raw `{headers, rows}`. Outputs a single `data.json`.
- `index.html` — single-file dashboard. Loads `data.json` every **1 minute**. All aggregation runs client-side in JS so date filtering and drill-downs are instant.

## Run it locally

```bash
# 1. Generate the data file (fetches Google Sheet)
python build_data.py --out data.json

# 2. Serve the folder (file:// blocks fetch())
python -m http.server 8765

# 3. Open in browser
# http://localhost:8765/
```

To refresh the data manually: re-run `python build_data.py --out data.json` — the dashboard will pick up the new file on its next 1-minute poll.

## Wiring up n8n (the real auto-refresh path)

The dashboard already polls its data source every 1 minute. n8n just needs to refresh that source on the same cadence.

**n8n workflow (one node per box):**

1. **Schedule Trigger** — `every 1 minute`
2. **HTTP Request** (one per tab, or loop) — `GET https://docs.google.com/spreadsheets/d/1wBlcdRKzT_MPf5ktldZbfvMn3eX7TjzmtIgtDo591IY/export?format=csv&gid={GID}`
3. **Code node** (Python or JS) — replicate the aggregation logic in `build_data.py` (`Counter` on status / program / coach / closer, sums on contract / cash, ISO date filtering, top-N for closers / recent / ending). Emit JSON in the same shape `build_data.py` produces.
4. **Webhook Response** OR **Write Binary File** — either:
   - **Webhook**: expose at `https://your-n8n/webhook/bba-data.json`, then set in `index.html`:
     ```js
     const N8N_WEBHOOK_URL = 'https://your-n8n/webhook/bba-data.json';
     ```
   - **File**: write `data.json` directly to wherever the dashboard is hosted (S3, the same web server's static folder, etc.). The dashboard's existing fetch will see the new file on its next poll.

**Output shape contract:**

```jsonc
{
  "source": "TRACKER - CLIENT SUCCESS (RAW)",
  "syncedAt": "2026-05-29T17:50:00Z",       // ISO 8601
  "clients": [ { "id":"…", "name":"…", "originDateISO":"YYYY-MM-DD", "status":"…", … } ],
  "tabs": {
    "RAW":          { "headers": ["…"], "rows": [ ["…"], … ], "rowCount": 1647 },
    "OFFBOARDED":   { "headers": ["…"], "rows": [ ["…"], … ], "rowCount": 642 },
    /* … one entry per tab … */
  }
}
```

Don't include the pre-computed `totals` / `kpis` / `charts` / `closers` / `recent` / `endingSoon` — the browser re-derives them from `clients`. That keeps the n8n flow minimal.

**Sheet tab gids (for the HTTP nodes):**

| Tab | gid |
|---|---|
| RAW | 754418002 |
| CLIENT_NOTES | 182322117 |
| DATA VALIDATION DROPDOWNS | 801848151 |
| OFFBOARDED | 775534642 |
| CLIENT 121 | 1462666945 |
| CHALLENGE UPGRADE | 1853599286 |
| ONBOARDING | 986032430 |
| KICKOFF CALLS | 686328974 |
| PROGRAMS | 340082301 |
| RETREAT | 2102321023 |

## Tech

- Vanilla HTML/CSS/JS (no build step)
- Chart.js for charts
- Python 3 for `build_data.py` (stdlib only — `urllib`, `csv`, `json`)
- Fonts: Archivo Black + Inter (Google Fonts)

## Folder

```
.
├── Images/                  BBA logo assets
├── build_data.py            Sheet → data.json transformer
├── data.json                Generated snapshot (gitignored sample, real data tracked)
├── index.html               The dashboard
├── .gitignore
└── README.md
```
