// === n8n Code node ===  UNWANTED CANCELLATIONS  →  Supabase: unwanted_cancellations
// Mode: "Run Once for All Items"  |  Language: JavaScript
// Chain: [Google Sheets: read UNWANTED CANCELLATIONS tab] → [this Code node] → [Supabase insert]
// Outputs batches shaped { rows: [ ...up to 500... ] }  → map the next node to {{$json.rows}}

const N  = s => String(s).toUpperCase().replace(/[^A-Z0-9]/g, "");          // normalize header
const T  = v => (v === "" || v == null) ? null : String(v).trim();
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

const byKey = new Map();
for (const i of $input.all()) {
  const j = i.json, m = {};
  for (const k in j) m[N(k)] = j[k];          // build normalized lookup
  const g = k => m[N(k)];

  const email  = T(g("EMAIL"));
  const serial = DT(g("APPOINTMENT SERIAL"));
  if (!email && !g("LEAD")) continue;          // skip blank rows
  const key = `${(email||"").toLowerCase()}|${serial || g("APPOINTMENT TIME") || j.row_number || ""}`;

  byKey.set(key, {
    lead: T(g("LEAD")),
    coach: T(g("COACH")),
    closer: T(g("CLOSER")),
    date_added: D(g("DATE ADDED")),
    appointment_serial: serial,
    appointment_time: T(g("APPOINTMENT TIME")),
    email,
    gender: T(g("GENDER")),
    lead_origin: T(g("LEAD ORIGIN")),
    ig: T(g("IG")),
    fbtt: T(g("FBTT")),
    showed: T(g("SHOWED")),
    closed: T(g("CLOSED")),
    sale_type: T(g("SALE TYPE")),
    notes: T(g("NOTES")),
    week_start: D(g("WEEK START")),
    appointment_before_now: T(g("APPOINTMENT BEFORE NOW")),
    investigation: T(g("INVESTIGATION")),
    reschedule_closer: T(g("RESCHEDULE CLOSER")),
    reschedule_serial: DT(g("RESCHEDULE SERIAL"))
  });
}

const rows = Array.from(byKey.values());
const CHUNK = 500, out = [];
for (let k = 0; k < rows.length; k += CHUNK) out.push({ json: { rows: rows.slice(k, k + CHUNK) } });
return out;
