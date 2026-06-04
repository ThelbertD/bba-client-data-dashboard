"""
BBA Client Data — Dashboard data processor.

Reads the TRACKER - CLIENT SUCCESS Google Sheet (RAW tab) as CSV and writes
data.json in the exact shape the dashboard expects.

Usage:
    python build_data.py [--sheet-id <ID>] [--gid <GID>] [--out data.json]

Defaults to the sheet ID + RAW gid hardcoded below. Requires the sheet to be
shared "anyone with link → viewer" (or use a service account / authenticated
download instead).

When n8n is wired up later, it should produce the same JSON shape as the
output of this script and either:
  (a) POST it to a backend that writes data.json, or
  (b) expose it at a webhook URL the dashboard fetches directly.
"""
import csv, io, json, sys, argparse, urllib.request
from collections import Counter, defaultdict
from datetime import datetime, timezone

SHEET_ID = "1wBlcdRKzT_MPf5ktldZbfvMn3eX7TjzmtIgtDo591IY"
RAW_GID  = "754418002"

# All tabs in the TRACKER - CLIENT SUCCESS sheet (extracted from htmlview)
TABS = [
    ("RAW",                       "754418002"),
    ("CLIENT_NOTES",              "182322117"),
    ("DATA VALIDATION DROPDOWNS", "801848151"),
    ("OFFBOARDED",                "775534642"),
    ("ONBOARDING",                "986032430"),
    ("MOMENTUM",                  "1462666945"),   # was CLIENT 121
    ("CELEBRATION",               "847524447"),    # new
    ("CHALLENGE UPGRADE",         "596452103"),    # gid changed
    ("CATCHUP CALL",              "1059913481"),   # new
    ("KICKOFF",                   "686328974"),    # was KICKOFF CALLS
    ("PROGRAMS",                  "340082301"),
    ("RETREAT",                   "2102321023"),
]

# --- helpers ----------------------------------------------------------------

def fetch_csv(sheet_id, gid):
    url = f"https://docs.google.com/spreadsheets/d/{sheet_id}/export?format=csv&gid={gid}"
    with urllib.request.urlopen(url) as r:
        return r.read().decode("utf-8")

def load_rows(csv_text):
    reader = csv.reader(io.StringIO(csv_text))
    rows = list(reader)
    headers = [h.strip() for h in rows[0]]
    data = [dict(zip(headers, r)) for r in rows[1:] if any(c.strip() for c in r)]
    return data

def parse_date(s):
    if not s: return None
    s = s.strip()
    for fmt in ("%d-%b-%Y", "%Y-%m-%d", "%d/%m/%Y"):
        try: return datetime.strptime(s, fmt)
        except ValueError: pass
    return None

def to_float(s):
    if not s: return None
    s = s.replace("$", "").replace(",", "").replace(" ", "").strip()
    try: return float(s)
    except ValueError: return None

# Column key shortcuts (the CSV has multi-line headers — strip newlines)
KEY = {
    "id": "",  # first unlabeled column
    "name": "NAME_PTD",
    "email": "EMAIL",
    "country": "COUNTRY",
    "gender": "GENDER",
    "head_coach": "HEAD_COACH",
    "program": "CURRENT_PROGRAM",
    "length_weeks": "LENGTH_WEEKS",
    "start": "CURRENT_PROGRAM_START_DATE",
    "end": "CURRENT_PROGRAM_END_DATE",
    "days_to_end": "DAYS_TO_END",
    "closer": "CLOSER",
    "support_coach": "SUPPORT COACH",
    "status": "CURRENT_STATUS",
    "status_date": "STATUS_DATE",
    "last_event": "LAST_EVENT_TYPE",
    "last_event_date": "LAST_EVENT_DATE",
    "payment_status": "PAYMENT STATUS",
    "payment_cadence": "PAYMENT CADENCE",
    "currency": "CURRENCY",
    # Sheet sometimes ships these as multi-line headers, sometimes flat —
    # the loader tries multiple shapes via g(). Keep canonical flat name here.
    "contract_value": "CONTRACT VALUE (Home Currency)",
    "cash_collected": "CASH COLLECTED (Home Currency",
    "periodic_payments": "PERIODIC PAYMENTS (Home Currency)",
    "origin_date": "ORIGIN_DATE",
    "extra_weeks": "EXTRA_WEEKS",
    "length_type": "LENGTH_TYPE",
    "stripe_link": "STRIPE LINK",
}
def g(row, k):
    v = row.get(KEY[k], "")
    return v.strip() if isinstance(v, str) else v

# --- build dashboard payload ------------------------------------------------

def build(data, now=None):
    now = now or datetime.now()
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    total = len(data)
    by_status = Counter(g(r, "status") for r in data if g(r, "status"))
    by_program = Counter(g(r, "program") for r in data if g(r, "program"))
    by_coach = Counter(g(r, "head_coach") for r in data if g(r, "head_coach"))
    by_closer = Counter(g(r, "closer") for r in data if g(r, "closer"))
    by_country = Counter(g(r, "country") for r in data if g(r, "country"))
    by_gender = Counter(g(r, "gender") for r in data if g(r, "gender"))
    by_pay = Counter(g(r, "payment_status") for r in data if g(r, "payment_status"))
    by_cadence = Counter(g(r, "payment_cadence") for r in data if g(r, "payment_cadence"))

    active_statuses = {"ACTIVE_COACHING", "ACTIVE_ONBOARDING", "ACTIVE_LIFE"}
    active_count = sum(v for k, v in by_status.items() if k in active_statuses)
    cancelled_count = by_status.get("CANCELLED", 0)
    onboarding_count = by_status.get("ACTIVE_ONBOARDING", 0)
    coaching_count = by_status.get("ACTIVE_COACHING", 0)

    # New this month
    new_mtd = sum(
        1 for r in data
        if (d := parse_date(g(r, "origin_date"))) and d >= month_start
    )

    # Contract value + cash collected
    contract_total = sum(v for r in data if (v := to_float(g(r, "contract_value"))))
    contract_n = sum(1 for r in data if to_float(g(r, "contract_value")) is not None)
    cash_total = sum(v for r in data if (v := to_float(g(r, "cash_collected"))))
    avg_contract = (contract_total / contract_n) if contract_n else 0

    # Days to end (ending soon / past due)
    def parse_days(s):
        try: return int(float(s))
        except (TypeError, ValueError): return None
    days = [parse_days(g(r, "days_to_end")) for r in data]
    ending_30 = sum(1 for d in days if d is not None and 0 <= d <= 30)
    past_due  = sum(1 for d in days if d is not None and d < 0)

    active_rate = (active_count / total * 100) if total else 0

    # Closer leaderboard
    closers = []
    for name, count in by_closer.most_common(8):
        if name == "" or count < 5: continue
        clients = [r for r in data if g(r, "closer") == name]
        cv = sum(v for r in clients if (v := to_float(g(r, "contract_value"))))
        active_for = sum(1 for r in clients if g(r, "status") in active_statuses)
        closers.append({
            "name": name.title(),
            "clients": count,
            "active": active_for,
            "cancelled": count - active_for,
            "retention": round(active_for / count * 100, 1) if count else 0,
            "contractValue": round(cv),
        })

    # Recent additions (latest origin_date, top 8)
    dated = [
        (d, r) for r in data
        if (d := parse_date(g(r, "origin_date")))
    ]
    dated.sort(key=lambda x: x[0], reverse=True)
    recent = []
    for d, r in dated[:8]:
        recent.append({
            "date": d.strftime("%d %b %Y"),
            "name": g(r, "name").title(),
            "country": g(r, "country").title(),
            "program": g(r, "program").title(),
            "headCoach": g(r, "head_coach").title(),
            "status": g(r, "status"),
            "cadence": g(r, "payment_cadence"),
        })

    # Ending soon (top 8 by smallest non-negative days_to_end)
    ending_soon_list = []
    for r in data:
        days_v = parse_days(g(r, "days_to_end"))
        end_d = parse_date(g(r, "end"))
        if days_v is None or end_d is None or days_v < 0 or days_v > 60: continue
        if g(r, "status") not in active_statuses: continue
        ending_soon_list.append((days_v, end_d, r))
    ending_soon_list.sort(key=lambda x: x[0])
    ending_soon = []
    for days_v, end_d, r in ending_soon_list[:8]:
        ending_soon.append({
            "name": g(r, "name").title(),
            "program": g(r, "program").title(),
            "headCoach": g(r, "head_coach").title(),
            "endDate": end_d.strftime("%d %b %Y"),
            "daysToEnd": days_v,
        })

    # --- KPI grid (3 rows × 6 = 18 tiles, mirroring the Looker layout)
    kpis = [
        {"key":"total_clients",  "label":"Total Clients",    "value": total,          "format":"int"},
        {"key":"active",         "label":"Active",           "value": active_count,   "format":"int", "highlight":"hero"},
        {"key":"new_mtd",        "label":"New (MTD)",        "value": new_mtd,        "format":"int"},
        {"key":"onboarding",     "label":"Onboarding",       "value": onboarding_count,"format":"int"},
        {"key":"coaching",       "label":"Active Coaching",  "value": coaching_count, "format":"int"},
        {"key":"active_rate",    "label":"Active Rate",      "value": round(active_rate,1), "format":"pct", "highlight":"rate"},

        {"key":"paying",         "label":"Paying",           "value": by_pay.get("PAYING",0),       "format":"int"},
        {"key":"not_paying",     "label":"Not Paying",       "value": by_pay.get("NOT PAYING",0),   "format":"int"},
        {"key":"pif",            "label":"Paid In Full",     "value": by_pay.get("PAID IN FULL",0), "format":"int"},
        {"key":"contract_value", "label":"Contract Value",   "value": round(contract_total), "format":"money"},
        {"key":"cash_collected", "label":"Cash Collected",   "value": round(cash_total),     "format":"money"},
        {"key":"avg_contract",   "label":"Avg Contract",     "value": round(avg_contract),   "format":"money"},

        {"key":"ignition",       "label":"Ignition",         "value": by_program.get("IGNITION",0), "format":"int"},
        {"key":"challenge",      "label":"Challenge",        "value": by_program.get("CHALLENGE",0),"format":"int"},
        {"key":"elite",          "label":"Elite",            "value": by_program.get("ELITE",0),    "format":"int"},
        {"key":"basecamp",       "label":"Basecamp",         "value": by_program.get("BASECAMP",0), "format":"int"},
        {"key":"ending_30",      "label":"Ending ≤ 30 Days", "value": ending_30,      "format":"int"},
        {"key":"cancelled",      "label":"Cancelled (All Time)", "value": cancelled_count, "format":"int"},
    ]

    def topn(counter, n=5):
        out = [{"name": k.title() if k else "Unknown", "value": v}
               for k, v in counter.most_common(n) if k]
        return out

    # Full client list (compact) for drill-down panels
    clients = []
    for r in data:
        end_d = parse_date(g(r, "end"))
        origin_d = parse_date(g(r, "origin_date"))
        status_d = parse_date(g(r, "status_date"))
        event_d = parse_date(g(r, "last_event_date"))
        try:    extra_weeks = int(float(g(r, "extra_weeks"))) if g(r, "extra_weeks") else 0
        except (TypeError, ValueError): extra_weeks = 0
        try:    length_type = int(float(g(r, "length_type"))) if g(r, "length_type") and g(r, "length_type") != "N/A" else None
        except (TypeError, ValueError): length_type = None
        clients.append({
            "id": g(r, "id"),
            "name": g(r, "name").title(),
            "email": g(r, "email"),
            "country": g(r, "country").title(),
            "gender": g(r, "gender").title(),
            "program": g(r, "program"),
            "headCoach": g(r, "head_coach").title(),
            "closer": g(r, "closer").title(),
            "supportCoach": g(r, "support_coach").title(),
            "status": g(r, "status"),
            "statusDate": status_d.strftime("%d %b %Y") if status_d else None,
            "statusDateISO": status_d.strftime("%Y-%m-%d") if status_d else None,
            "lastEvent": g(r, "last_event") or None,
            "lastEventDate": event_d.strftime("%d %b %Y") if event_d else None,
            "lastEventDateISO": event_d.strftime("%Y-%m-%d") if event_d else None,
            "extraWeeks": extra_weeks,
            "lengthType": length_type,
            "paymentStatus": g(r, "payment_status"),
            "paymentCadence": g(r, "payment_cadence"),
            "daysToEnd": parse_days(g(r, "days_to_end")),
            "endDate": end_d.strftime("%d %b %Y") if end_d else None,
            "endDateISO": end_d.strftime("%Y-%m-%d") if end_d else None,
            "originDate": origin_d.strftime("%d %b %Y") if origin_d else None,
            "originDateISO": origin_d.strftime("%Y-%m-%d") if origin_d else None,
            "contractValue": to_float(g(r, "contract_value")) or 0,
            "cashCollected": to_float(g(r, "cash_collected")) or 0,
            "price": to_float(g(r, "periodic_payments")) or 0,
            "stripeLink": g(r, "stripe_link") or None,
        })

    return {
        "source": "TRACKER - CLIENT SUCCESS (RAW)",
        "syncedAt": now.replace(tzinfo=timezone.utc).isoformat(),
        "range": {"label": "All-time + MTD", "from": month_start.strftime("%Y-%m-%d"), "to": now.strftime("%Y-%m-%d")},
        "totals": {
            "total": total,
            "active": active_count,
            "onboarding": onboarding_count,
            "coaching": coaching_count,
            "cancelled": cancelled_count,
            "newMtd": new_mtd,
            "activeRate": round(active_rate, 1),
            "endingIn30": ending_30,
            "pastDue": past_due,
            "contractValueTotal": round(contract_total),
            "cashCollectedTotal": round(cash_total),
            "avgContract": round(avg_contract),
        },
        "kpis": kpis,
        "charts": {
            "byProgram":  topn(by_program, 6),
            "byHeadCoach": topn(by_coach, 6),
            "byCountry":  topn(by_country, 6),
            "byCadence":  topn(by_cadence, 6),
            "byGender":   topn(by_gender, 4),
        },
        "closers": closers,
        "recent": recent,
        "endingSoon": ending_soon,
        "clients": clients,
    }

def fetch_all_tabs(sheet_id, local_dir=None):
    """Fetch every tab as a generic { headers, rows } table.
    If local_dir is given, cache each tab's CSV there to avoid refetching."""
    import os
    out = {}
    for name, gid in TABS:
        cache = os.path.join(local_dir, f"{gid}.csv") if local_dir else None
        if cache and os.path.exists(cache):
            with open(cache, "r", encoding="utf-8") as f:
                csv_text = f.read()
            print(f"[build_data] cached {name} (gid={gid})")
        else:
            print(f"[build_data] fetching {name} (gid={gid})…")
            csv_text = fetch_csv(sheet_id, gid)
            if cache:
                os.makedirs(local_dir, exist_ok=True)
                with open(cache, "w", encoding="utf-8") as f:
                    f.write(csv_text)
        reader = csv.reader(io.StringIO(csv_text))
        rows = list(reader)
        if not rows:
            out[name] = {"headers": [], "rows": [], "rowCount": 0}
            continue
        headers = [h.strip() or f"col_{i}" for i, h in enumerate(rows[0])]
        # Skip the first cell if it's a leading blank "ID" column header
        body = [r for r in rows[1:] if any(c.strip() for c in r)]
        out[name] = {
            "headers": headers,
            "rows": body,
            "rowCount": len(body),
        }
    return out

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sheet-id", default=SHEET_ID)
    ap.add_argument("--gid", default=RAW_GID)
    ap.add_argument("--csv-file", help="read CSV from local file instead of fetching (RAW only)")
    ap.add_argument("--cache-dir", default=None, help="cache fetched CSVs here so re-runs are fast")
    ap.add_argument("--skip-tabs", action="store_true", help="don't fetch the other 13 tabs")
    ap.add_argument("--out", default="data.json")
    args = ap.parse_args()

    if args.csv_file:
        with open(args.csv_file, "r", encoding="utf-8") as f:
            csv_text = f.read()
    else:
        print(f"[build_data] fetching RAW gid={args.gid}…")
        csv_text = fetch_csv(args.sheet_id, args.gid)

    data = load_rows(csv_text)
    print(f"[build_data] RAW: {len(data)} rows loaded")

    payload = build(data)

    if not args.skip_tabs:
        payload["tabs"] = fetch_all_tabs(args.sheet_id, local_dir=args.cache_dir)
        for name, t in payload["tabs"].items():
            print(f"[build_data]   {name}: {t['rowCount']} rows × {len(t['headers'])} cols")

    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2, ensure_ascii=False)
    print(f"[build_data] wrote {args.out}: "
          f"{payload['totals']['total']} clients, "
          f"{payload['totals']['active']} active, "
          f"${payload['totals']['contractValueTotal']:,} contract value")

if __name__ == "__main__":
    main()
