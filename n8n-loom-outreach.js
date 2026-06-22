// === n8n Code node ===  LOOM  →  Supabase table: loom_outreach
// Mode: "Run Once for All Items"  |  Language: JavaScript
// Chain: [Google Sheets: read LOOM tab] → [this Code node] → [Supabase insert into loom_outreach]
// Outputs batches shaped { rows: [ ...up to 500... ] }  → map the next node to {{$json.rows}}

const N  = s => String(s).toUpperCase().replace(/[^A-Z0-9]/g, "");          // normalize header
const T  = v => (v === "" || v == null) ? null : String(v).trim();
const NAME = v => { const t = T(v); return t ? t.toUpperCase().replace(/\s+/g, " ") : t; };  // canonical name casing
const D  = v => {                                                           // date-only → YYYY-MM-DD
  if (v === "" || v == null) return null;
  const s = String(v).trim();
  for (const f of ["d LLLL, yyyy","LLLL d, yyyy","LLL d, yyyy","M/d/yyyy","yyyy-LL-dd"]) {
    const d = DateTime.fromFormat(s, f); if (d.isValid) return d.toISODate();
  }
  const iso = DateTime.fromISO(s); return iso.isValid ? iso.toISODate() : null;
};
const DT = v => {                                                           // datetime → ISO timestamp
  if (v === "" || v == null) return null;
  const s = String(v).trim();
  for (const f of ["LLL d, yyyy, h:mm:ss a","LLLL d, yyyy, h:mm:ss a","LLL d, yyyy, h:mm a","M/d/yyyy h:mm:ss a"]) {
    const d = DateTime.fromFormat(s, f); if (d.isValid) return d.toISO();
  }
  const iso = DateTime.fromISO(s); return iso.isValid ? iso.toISO() : null;
};

// Status values that sometimes get mis-entered into the LEAD column. A real
// person is never named one of these, so if LEAD matches one we skip the row
// (it's a bad source row, not a deal). Edit this list to match your sheet's
// LOOM STATUS values. Compared case-insensitively against normalized text.
const STATUS_WORDS = new Set(
  ["RESPONDED","NO RESPONSE","FOLLOWED UP","FOLLOW UP","PENDING","NOT INTERESTED","NOT SENT","SENT","BOOKED","CLOSED"]
    .map(w => w.toUpperCase().trim())
);

// One record per sheet row. This LOOM tab has NO email column, but it DOES have
// NOTES — so we key on lead + loom_sent_date_time (falling back to row number)
// and map NOTES instead of email.
const byKey = new Map();
let idx = 0;
for (const i of $input.all()) {
  idx++;
  const j = i.json, m = {};
  for (const k in j) m[N(k)] = j[k];          // build normalized lookup
  const g = k => m[N(k)];                      // g("LOOM SENT DATE TIME") matches "Loom_Sent_Date_Time" too

  const lead   = T(g("LEAD"));
  const status = T(g("LOOM STATUS"));
  const sent   = T(g("LOOM SENT DATE TIME"));  // keep RAW text — the dashboard parses it (DT nulled the no-year format)
  if (!lead && !sent) continue;                // skip blank rows

  // Drop rows where the LEAD cell holds a status instead of a name (mis-entry):
  // either it matches a known STATUS word, or it equals this row's own status.
  if (lead && (STATUS_WORDS.has(lead.toUpperCase().trim())
            || (status && lead.toUpperCase().trim() === status.toUpperCase().trim()))) continue;

  // Unique key per SOURCE ROW. Use lead+date when both exist; otherwise fall
  // back to the sheet row number so rows can never collapse onto one key.
  const key = (lead && sent)
    ? `${lead.toLowerCase()}|${sent}`
    : `__row_${j.row_number ?? idx}`;

  byKey.set(key, {
    lead,
    coach: NAME(g("COACH")),
    loom_sent_date_time: sent,
    gender: T(g("GENDER")),
    lead_origin: T(g("LEAD ORIGIN")),
    ig: T(g("IG")),
    fbtt: T(g("FBTT")),
    loom_offer: T(g("LOOM OFFER")),
    loom_status: status,
    closed_ht: T(g("CLOSED HT")),
    sale_type: T(g("SALE TYPE")),
    week_start: D(g("WEEK START")),
    loom_sent_date_time_before_now: T(g("LOOM SENT DATE TIME BEFORE NOW")),
    follow_up: T(g("FOLLOW UP")),
    notes: T(g("NOTES"))
  });
}

const rows = Array.from(byKey.values());
const CHUNK = 500, out = [];
for (let k = 0; k < rows.length; k += CHUNK) out.push({ json: { rows: rows.slice(k, k + CHUNK) } });
return out;
