// === n8n Code node ===  RAW  →  Supabase table: raw_appointments
// Mode: "Run Once for All Items"  |  Language: JavaScript
// Chain: [Google Sheets: read RAW tab] → [this Code node] → [Supabase insert into raw_appointments]
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
// Canonical name: UPPERCASE + single spaces. Keeps "Stuart McDermid" and
// "STUART MCDERMID" from ever splitting into two people downstream.
const NAME = v => { const t = T(v); return t ? t.toUpperCase().replace(/\s+/g, " ") : t; };
// Year-less datetime (e.g. "Thursday, Jun 11 - 08:30 AM") → real ISO timestamp.
// The source has no year, so pick the year (last/this/next) that lands the
// date CLOSEST to now — correct for recent-past and near-future appointments.
const DTNOYEAR = v => {
  const withYear = DT(v); if (withYear) return withYear;                    // already dated? use it
  if (v === "" || v == null) return null;
  const s = String(v).trim();
  for (const f of ["EEEE, LLL d - hh:mm a","EEEE, LLL d - h:mm a","EEEE, LLLL d - h:mm a","LLL d - hh:mm a"]) {
    const base = DateTime.fromFormat(s, f);
    if (base.isValid) {
      const now = DateTime.now();
      let best = null, bestDiff = Infinity;
      for (const y of [now.year - 1, now.year, now.year + 1]) {
        const cand = base.set({ year: y }), diff = Math.abs(cand.toMillis() - now.toMillis());
        if (diff < bestDiff) { bestDiff = diff; best = cand; }
      }
      return best.toISO();
    }
  }
  return null;
};

// dedupe by email + appointment (one row per appointment) and map every field
const byKey = new Map();
for (const i of $input.all()) {
  const j = i.json, m = {};
  for (const k in j) m[N(k)] = j[k];          // build normalized lookup
  const g = k => m[N(k)];                      // g("APPOINTMENT SERIAL") matches "Appointment_Serial" too

  const email  = T(g("EMAIL"));
  // Real ISO timestamp: use a dated serial if present, else derive one from the
  // year-less APPOINTMENT TIME so the dashboard never has to guess the year.
  const serial = DT(g("APPOINTMENT SERIAL")) || DTNOYEAR(g("APPOINTMENT TIME"));
  if (!email && !g("LEAD")) continue;          // skip blank rows
  const key = `${(email||"").toLowerCase()}|${serial || g("APPOINTMENT TIME") || j.row_number || ""}`;

  byKey.set(key, {
    lead: T(g("LEAD")),
    coach: NAME(g("COACH")),                    // canonical casing — no split bars
    closer: NAME(g("CLOSER")),                  // canonical casing — no split bars
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
    closers_notes: T(g("CLOSERS NOTES")),
    nurtures_notes: T(g("NURTURES NOTES")),
    job_title: T(g("JOB TITLE")),
    source: T(g("SOURCE")),
    week_start: D(g("WEEK START")),
    appointment_before_now: T(g("APPOINTMENT BEFORE NOW")),
    follow_up: T(g("FOLLOW UP"))
  });
}

const rows = Array.from(byKey.values());
const CHUNK = 500, out = [];
for (let k = 0; k < rows.length; k += CHUNK) out.push({ json: { rows: rows.slice(k, k + CHUNK) } });
return out;
