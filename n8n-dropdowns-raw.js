// === n8n Code node ===  DROPDOWNS (RAW)  →  Supabase: dropdowns_raw  (WIDE: one row per sheet row)
// Mode: "Run Once for All Items"  |  Language: JavaScript
// Chain: [Google Sheets: read DROPDOWNS (RAW) tab] → [this Code node] → [Supabase insert into dropdowns_raw]
//
// Mirrors the sheet column-for-column: every header is a column, every sheet row
// is a record. ALL fields go to Supabase.
// Outputs batches shaped { rows: [ ...up to 500... ] }  → map the next node to {{$json.rows}}
//
// HTTP node: URL .../rest/v1/dropdowns_raw  (no on_conflict) | Prefer: return=minimal
// Re-run safe: no natural unique key, so full-refresh — truncate table dropdowns_raw; before insert.

const N = s => String(s).toUpperCase().replace(/[^A-Z0-9]/g, "");   // normalize header
const T = v => (v === "" || v == null) ? null : String(v).trim();

const rows = [];
for (const i of $input.all()) {
  const j = i.json, m = {};
  for (const k in j) m[N(k)] = j[k];            // normalized lookup
  const g = k => m[N(k)];                        // g("APPOINTMENT SERIAL") matches "Appointment_Serial"

  const rec = {
    lead:                   T(g("LEAD")),
    coach:                  T(g("COACH")),
    closer:                 T(g("CLOSER")),
    date_added:             T(g("DATE ADDED")),
    appointment_serial:     T(g("APPOINTMENT SERIAL")),
    appointment_time:       T(g("APPOINTMENT TIME")),
    email:                  T(g("EMAIL")),
    gender:                 T(g("GENDER")),
    lead_origin:            T(g("LEAD ORIGIN")),
    ig:                     T(g("IG")),
    fbtt:                   T(g("FBTT")),
    showed:                 T(g("SHOWED")),
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
