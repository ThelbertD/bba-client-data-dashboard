# BBA Client Data Dashboard

Internal dashboard for **Better Body Academy** that visualises the `TRACKER - CLIENT SUCCESS` Google Sheet — active book of business, programs, payments, retention, churn, and renewals.

> ⚠️ **Private repo — contains real client data.** Do not change visibility to public without first removing `data.json`.

## What it does

- **Client Success dashboard** — 18 KPI tiles (3×6 grid), 4 distribution charts, monthly calendar of sign-ups + endings, closer leaderboard, programs ending soon, recent additions
- **Date range filter** — preset chips (Today / 7D / 30D / MTD / QTD / YTD / All) + custom date inputs
- **Click-through everything** — every KPI tile opens a slide-in drill-down with the filtered client list, sortable, searchable, exportable as CSV
- **Calendar widget** — month view, sign-ups (blue) + endings (orange) + past due (red), click any day to drill into that day's clients
- **Tab navigation** — left sidebar with all 14 sheet tabs (RAW, OFFBOARDED, ONBOARDING, etc.) — each gets an auto-generated dashboard
- **Auto-dashboards** — each tab's columns are analysed (numeric / date / categorical detection) and the dashboard generates KPIs + charts automatically
- **Cell-level interactions** — click any cell to add a filter chip, click a client ID to open a **Client 360** panel showing that client's record across every tab where they appear
- **AI chat widget** — floating bubble bottom-right, answers questions about the current snapshot from local data (stub mode; ready to wire to Claude/OpenAI)

## Architecture

```
Google Sheet  →  build_data.py  →  data.json  →  index.html (browser)
                                                 ↑
                                       n8n will replace build_data.py
                                       once the pipeline is in place
```

- `build_data.py` — fetches all 14 tabs from the Sheet as CSV, structures `RAW` into typed client objects, includes the other 13 tabs as raw `{headers, rows}`. Outputs a single `data.json`.
- `index.html` — single-file dashboard. Loads `data.json`, all aggregation runs client-side in JS so date filtering and drill-downs are instant.

## Run it locally

```bash
# 1. Generate the data file (fetches Google Sheet)
python build_data.py --out data.json

# 2. Serve the folder (file:// blocks fetch())
python -m http.server 8765

# 3. Open in browser
# http://localhost:8765/
```

## Wiring up n8n (when ready)

`index.html` has a constant near the bottom of the script:

```js
const N8N_WEBHOOK_URL = '';  // <-- paste n8n GET endpoint here
```

When set, the dashboard fetches from there instead of `./data.json`. The endpoint must return JSON in the same shape `build_data.py` produces.

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
