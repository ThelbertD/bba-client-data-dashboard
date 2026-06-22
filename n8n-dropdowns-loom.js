// === n8n Code node ===  DROPDOWNS (LOOM)  →  Supabase: dropdowns_loom  (WIDE: one row per sheet row)
// Mode: "Run Once for All Items"  |  Language: JavaScript
// Chain: [Google Sheets: read DROPDOWNS (LOOM) tab] → [this Code node] → [Supabase insert into dropdowns_loom]
//
// Mirrors the sheet column-for-column: every header is a column, every sheet row
// is a record — exactly like the loom_outreach node. ALL fields go to Supabase.
// Outputs batches shaped { rows: [ ...up to 500... ] }  → map the next node to {{$json.rows}}
//
// Re-run safe: there's no natural unique key, so do a full refresh —
//   truncate table dropdowns_loom;   (run before the insert, or in a prior node)

const N = s => String(s).toUpperCase().replace(/[^A-Z0-9]/g, "");   // normalize header
const T = v => (v === "" || v == null) ? null : String(v).trim();

const rows = [];
for (const i of $input.all()) {
  const j = i.json, m = {};
  for (const k in j) m[N(k)] = j[k];            // normalized lookup
  const g = k => m[N(k)];                        // g("LOOM SENT DATE TIME") matches "Loom_Sent_Date_Time"

  const rec = {
    lead:                   T(g("LEAD")),
    coach:                  T(g("COACH")),
    loom_sent_date_time:    T(g("LOOM SENT DATE TIME")),
    email:                  T(g("EMAIL")),
    gender:                 T(g("GENDER")),
    lead_origin:            T(g("LEAD ORIGIN")),
    ig:                     T(g("IG")),
    fbtt:                   T(g("FBTT")),
    loom_offer:             T(g("LOOM OFFER")),
    loom_status:            T(g("LOOM STATUS")),
    closed:                 T(g("CLOSED")),
    sale_type:              T(g("SALE TYPE")),
    notes:                  T(g("NOTES")),
    week_start:             T(g("WEEK START")),
    appointment_before_now: T(g("APPOINTMENT BEFORE NOW")),
    follow_up:              T(g("FOLLOW UP"))
  };

  // skip fully-blank rows (every column null)
  if (Object.values(rec).every(v => v == null)) continue;
  rows.push(rec);
}

const CHUNK = 500, out = [];
for (let k = 0; k < rows.length; k += CHUNK) out.push({ json: { rows: rows.slice(k, k + CHUNK) } });
return out;
