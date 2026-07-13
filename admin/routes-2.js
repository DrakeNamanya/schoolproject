/* Additional Timbitwire web routes. Registered on window.__extraRoutes;
   router.js merges them in. Keep each string tight. */

window.__extraRoutes = {

/* ==================== STUDENTS ==================== */
students: {
  crumb: 'Operations · Students',
  title: 'Students',
  html: `
  <div class="page-head">
    <div>
      <div class="eyebrow">812 learners · Term 2, 2026</div>
      <h1>Students <em>directory</em></h1>
      <div class="desc">Enrolled learners across S1–S6, with fees status, boarding assignment, and guardian contact.</div>
    </div>
    <div class="actions">
      <button class="btn o"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>Import roster</button>
      <button class="btn p"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>Enrol student</button>
    </div>
  </div>

  <div class="kpis">
    <div class="kpi"><div class="k">Enrolment</div><div class="v">812<small>learners</small></div><div class="bar"><div class="fill" style="width:78%"></div></div><div class="bar-l"><span>78% of 1,040 capacity</span><span>+18 this term</span></div></div>
    <div class="kpi"><div class="k">Boarding</div><div class="v">648</div><div class="trend"><svg viewBox="0 0 24 24"><path d="m6 15 6-6 6 6"/></svg>80% of enrolment</div></div>
    <div class="kpi"><div class="k">Day scholars</div><div class="v">164</div><div class="trend down"><svg viewBox="0 0 24 24"><path d="m6 9 6 6 6-6"/></svg>−4 vs Term 1</div></div>
    <div class="kpi"><div class="k">S6 candidates</div><div class="v">148<small>UNEB</small></div><div class="bar"><div class="fill maroon" style="width:92%"></div></div><div class="bar-l"><span>92% registered</span><span>12 pending</span></div></div>
  </div>

  <div class="student-grid">
    <div class="card">
      <div class="tab-hd">
        <h3>Roster</h3>
        <div style="display:flex;gap:6px;align-items:center">
          <button class="btn o sm"><svg viewBox="0 0 24 24"><path d="M4 6h16M6 12h12M8 18h8"/></svg>Filters</button>
          <button class="btn g sm">Export CSV</button>
        </div>
      </div>
      <div class="tabs"><div class="t on">All (812)</div><div class="t">S1 (168)</div><div class="t">S2 (162)</div><div class="t">S3 (152)</div><div class="t">S4 (148)</div><div class="t">S5 (98)</div><div class="t">S6 (84)</div></div>
      <div style="overflow-x:auto">
      <table class="tbl">
        <thead><tr><th>Student</th><th>Class</th><th>House</th><th>Boarding</th><th>Guardian</th><th>Fees</th></tr></thead>
        <tbody>
          <tr><td><div style="display:flex;align-items:center;gap:10px"><div class="avatar">NA</div><div><div style="font-weight:600">Nakato Aisha</div><div style="font-size:11px;color:var(--fg-3);font-family:var(--font-mono)">TGS/2024/00478</div></div></div></td><td>S2 East</td><td>Green</td><td>Boarder</td><td>Mukisa J.</td><td><span class="tag due"><span class="dot"></span>Arrears</span></td></tr>
          <tr><td><div style="display:flex;align-items:center;gap:10px"><div class="avatar m">AK</div><div><div style="font-weight:600">Akello Prossy</div><div style="font-size:11px;color:var(--fg-3);font-family:var(--font-mono)">TGS/2024/00512</div></div></div></td><td>S2 West</td><td>Blue</td><td>Boarder</td><td>Akello S.</td><td><span class="tag ok"><span class="dot"></span>Cleared</span></td></tr>
          <tr><td><div style="display:flex;align-items:center;gap:10px"><div class="avatar n">BW</div><div><div style="font-weight:600">Byaruhanga W.</div><div style="font-size:11px;color:var(--fg-3);font-family:var(--font-mono)">TGS/2021/00013</div></div></div></td><td>S6 A</td><td>White</td><td>Day</td><td>Byaruhanga E.</td><td><span class="tag part"><span class="dot"></span>Partial</span></td></tr>
          <tr><td><div style="display:flex;align-items:center;gap:10px"><div class="avatar">KE</div><div><div style="font-weight:600">Kembabazi Esther</div><div style="font-size:11px;color:var(--fg-3);font-family:var(--font-mono)">TGS/2023/00301</div></div></div></td><td>S3 North</td><td>Red</td><td>Boarder</td><td>Kembabazi P.</td><td><span class="tag ok"><span class="dot"></span>Cleared</span></td></tr>
          <tr><td><div style="display:flex;align-items:center;gap:10px"><div class="avatar m">NA</div><div><div style="font-weight:600">Namuli Angel</div><div style="font-size:11px;color:var(--fg-3);font-family:var(--font-mono)">TGS/2024/00521</div></div></div></td><td>S2 South</td><td>Green</td><td>Boarder</td><td>Namuli S.</td><td><span class="tag due"><span class="dot"></span>Arrears</span></td></tr>
          <tr><td><div style="display:flex;align-items:center;gap:10px"><div class="avatar">TB</div><div><div style="font-weight:600">Tumusiime Brenda</div><div style="font-size:11px;color:var(--fg-3);font-family:var(--font-mono)">TGS/2025/00612</div></div></div></td><td>S1 North</td><td>Blue</td><td>Boarder</td><td>Kabahenda R.</td><td><span class="tag part"><span class="dot"></span>Partial</span></td></tr>
          <tr><td><div style="display:flex;align-items:center;gap:10px"><div class="avatar n">LM</div><div><div style="font-weight:600">Lamunu Mercy</div><div style="font-size:11px;color:var(--fg-3);font-family:var(--font-mono)">TGS/2022/00159</div></div></div></td><td>S5 B</td><td>Red</td><td>Boarder</td><td>Lamunu O.</td><td><span class="tag ok"><span class="dot"></span>Cleared</span></td></tr>
          <tr><td><div style="display:flex;align-items:center;gap:10px"><div class="avatar m">SP</div><div><div style="font-weight:600">Ssenoga Patience</div><div style="font-size:11px;color:var(--fg-3);font-family:var(--font-mono)">TGS/2023/00218</div></div></div></td><td>S3 East</td><td>White</td><td>Day</td><td>Ssenoga E.</td><td><span class="tag ok"><span class="dot"></span>Cleared</span></td></tr>
        </tbody>
      </table>
      </div>
    </div>

    <div class="card st-profile">
      <div class="hero">
        <div class="av-lg">NA</div>
        <div>
          <div class="eyebrow">TGS/2024/00478 · S2 East</div>
          <h3>Nakato Aisha</h3>
          <div class="meta">Born 14 Mar 2011 · admitted 03 Feb 2024</div>
        </div>
      </div>
      <div class="attrs">
        <div><div class="k">House</div><div class="v">Green House</div></div>
        <div><div class="k">Boarding</div><div class="v">Kwagala dormitory, bed 14</div></div>
        <div><div class="k">Guardian</div><div class="v">Mukisa Josephine</div></div>
        <div><div class="k">Phone (SMS)</div><div class="v mono">+256 772 894 001</div></div>
        <div><div class="k">Position</div><div class="v">12 of 78</div></div>
        <div><div class="k">Attendance</div><div class="v">96%</div></div>
        <div><div class="k">Clinic visits</div><div class="v">2 · Term 2</div></div>
        <div><div class="k">Fees balance</div><div class="v" style="color:var(--brick-600)">UGX 450,000</div></div>
      </div>
      <div class="btn-row">
        <button class="btn p sm"><svg viewBox="0 0 24 24"><path d="M6 9V3h12v6"/><rect x="6" y="14" width="12" height="7"/></svg>Print report card</button>
        <button class="btn o sm"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>Post invoice</button>
        <button class="btn g sm">Guardian log</button>
      </div>
    </div>
  </div>
  `
},


/* ==================== ACADEMICS ==================== */
academics: {
  crumb: 'Operations · Academics',
  title: 'Academics',
  html: `
  <div class="page-head">
    <div>
      <div class="eyebrow">Marks entry · Term 2 · 2026</div>
      <h1>Marks <em>grid</em> · Physics S3 East</h1>
      <div class="desc">Mid-term Continuous Assessment (CAT) marks. Cells lock automatically 7 days after the assessment date.</div>
    </div>
    <div class="actions">
      <button class="btn o"><svg viewBox="0 0 24 24"><path d="M5 12h14M12 5v14"/></svg>Add assessment</button>
      <button class="btn s"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>Import CSV</button>
      <button class="btn p"><svg viewBox="0 0 24 24"><path d="M5 12l5 5L20 7"/></svg>Submit for review</button>
    </div>
  </div>

  <div class="card">
    <div class="marks-tools">
      <span class="sel"><small>Subject</small> Physics <svg viewBox="0 0 24 24" width="12" height="12" stroke="var(--fg-3)" fill="none"><path d="m6 9 6 6 6-6"/></svg></span>
      <span class="sel"><small>Class</small> S3 East · 32 girls <svg viewBox="0 0 24 24" width="12" height="12" stroke="var(--fg-3)" fill="none"><path d="m6 9 6 6 6-6"/></svg></span>
      <span class="sel"><small>Assessment</small> CAT 2 · 08 Jul <svg viewBox="0 0 24 24" width="12" height="12" stroke="var(--fg-3)" fill="none"><path d="m6 9 6 6 6-6"/></svg></span>
      <span class="sel"><small>Out of</small> 40</span>
      <span class="lock"><svg viewBox="0 0 24 24"><rect x="4" y="10" width="16" height="10" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/></svg>Locks in 5 days · 15 Jul 2026</span>
    </div>
    <div style="overflow-x:auto">
    <table class="tbl marks-tbl">
      <thead>
        <tr>
          <th style="width:36%">Student</th>
          <th class="num">CAT 1 (30)</th>
          <th class="num">CAT 2 (40)</th>
          <th class="num">Assign (20)</th>
          <th class="num">Mid-term (60)</th>
          <th class="num">Total (150)</th>
          <th style="text-align:center">Grade</th>
          <th>Comment</th>
        </tr>
      </thead>
      <tbody>
        ${[
          ['NA','Nakato Aisha',25,32,17,54,'D1','Strong grasp of mechanics'],
          ['AK','Akello Prossy',22,30,15,52,'D1','Very good work'],
          ['KE','Kembabazi Esther',20,28,14,50,'D2','Improving steadily'],
          ['LM','Lamunu Mercy',26,35,18,55,'D1','Excellent'],
          ['NM','Namara Miriam',18,24,13,45,'C3','Needs more practice'],
          ['SB','Ssebugwawo B.',16,22,11,40,'C4','Attend consultation'],
          ['TN','Tumwesigye N.',24,30,16,52,'D2','Neat presentation'],
        ].map(r => `
        <tr>
          <td><div style="display:flex;align-items:center;gap:10px"><div class="avatar">${r[0]}</div><div style="font-weight:600">${r[1]}</div></div></td>
          <td class="num"><input value="${r[2]}"></td>
          <td class="num"><input value="${r[3]}"></td>
          <td class="num"><input value="${r[4]}"></td>
          <td class="num"><input value="${r[5]}"></td>
          <td class="num" style="font-weight:700">${r[2]+r[3]+r[4]+r[5]}</td>
          <td class="grade">${r[6]}</td>
          <td style="font-size:12px;color:var(--fg-2)">${r[7]}</td>
        </tr>
        `).join('')}
      </tbody>
    </table>
    </div>
  </div>
  `
},


/* ==================== ATTENDANCE ==================== */
attendance: {
  crumb: 'Operations · Attendance',
  title: 'Attendance & GPS',
  html: `
  <div class="page-head">
    <div>
      <div class="eyebrow">Staff GPS attendance · 09 Jul 2026</div>
      <h1>Staff <em>geofence</em></h1>
      <div class="desc">Live positions of all 61 staff members. Anyone crossing the campus geofence is automatically checked in; anyone leaving during class hours raises an alert to the DOS.</div>
    </div>
    <div class="actions">
      <button class="btn o"><svg viewBox="0 0 24 24"><path d="M6 9V3h12v6"/><rect x="6" y="14" width="12" height="7"/></svg>Print daybook</button>
      <button class="btn p"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>Edit geofence</button>
    </div>
  </div>

  <div class="kpis">
    <div class="kpi"><div class="k">On-campus now</div><div class="v" style="color:var(--success)">54<small>/ 61</small></div><div class="bar"><div class="fill" style="width:88%;background:var(--success)"></div></div><div class="bar-l"><span>88%</span><span>7 off duty</span></div></div>
    <div class="kpi"><div class="k">Auto check-ins today</div><div class="v">57<small>events</small></div><div class="trend"><svg viewBox="0 0 24 24"><path d="M5 12l5 5L20 7"/></svg>Avg. entry 07:34</div></div>
    <div class="kpi"><div class="k">Late arrivals</div><div class="v" style="color:#7a5111">4</div><div class="bar-l"><span>&gt;15 min past 07:30</span><span>Grace applied</span></div></div>
    <div class="kpi"><div class="k">Off-campus alerts</div><div class="v" style="color:var(--brick-600)">1</div><div class="bar-l"><span>Ms. Nabbosa · 420 m</span><span>Escalated · DOS</span></div></div>
  </div>

  <div class="gps-grid">
    <div class="map-card">
      <div class="hd" style="border:none;padding:0 0 12px"><h3 style="margin:0">Campus geofence · live</h3></div>
      <div class="map-canvas">
        <div class="map-legend">
          <div class="row"><span class="dot" style="background:var(--success)"></span>Inside · 54</div>
          <div class="row"><span class="dot" style="background:var(--brick-500)"></span>Off-campus · 1</div>
          <div class="row" style="color:var(--fg-3)"><span class="dot" style="background:rgba(165,53,44,.55);outline:2px dashed rgba(165,53,44,.55);outline-offset:2px;width:6px;height:6px;"></span>Boundary</div>
        </div>
        <div class="map-scale">±6 m · GPS + cell</div>
        <!-- Pins (positioned via percentage) -->
        <div class="map-pin in" style="left:26%;top:36%"></div>
        <div class="map-pin in" style="left:32%;top:42%"></div>
        <div class="map-pin in" style="left:24%;top:48%"></div>
        <div class="map-pin in" style="left:30%;top:52%"></div>
        <div class="map-pin in" style="left:38%;top:38%"></div>
        <div class="map-pin in" style="left:36%;top:46%"></div>
        <div class="map-pin in" style="left:28%;top:58%"></div>
        <div class="map-pin in" style="left:34%;top:56%"></div>
        <div class="map-pin out" style="left:76%;top:24%"></div>
      </div>
    </div>

    <div class="card">
      <div class="hd"><h3>Staff · today</h3><div class="m"><a>All staff →</a></div></div>
      <div class="body body-tight">
        <div class="staff-list">
          <div class="st-row"><div class="puck in"><svg viewBox="0 0 24 24"><path d="M5 12l5 5L20 7"/></svg></div><div><div class="n">Mr. Ssekandi B.</div><div class="m">Physics · Day duty</div></div><div class="t"><b>07:38</b>Auto-in · ±6 m</div></div>
          <div class="st-row"><div class="puck in"><svg viewBox="0 0 24 24"><path d="M5 12l5 5L20 7"/></svg></div><div><div class="n">Ms. Nakku M.</div><div class="m">Head cook</div></div><div class="t"><b>05:52</b>Auto-in · ±8 m</div></div>
          <div class="st-row"><div class="puck in"><svg viewBox="0 0 24 24"><path d="M5 12l5 5L20 7"/></svg></div><div><div class="n">Nurse Alice N.</div><div class="m">Clinic</div></div><div class="t"><b>07:14</b>Auto-in · ±5 m</div></div>
          <div class="st-row"><div class="puck out"><svg viewBox="0 0 24 24"><path d="M12 3 2 20h20L12 3z"/></svg></div><div><div class="n">Ms. Nabbosa J.</div><div class="m">English · S4</div></div><div class="t"><b>420 m</b>Off · escalated</div></div>
          <div class="st-row"><div class="puck in"><svg viewBox="0 0 24 24"><path d="M5 12l5 5L20 7"/></svg></div><div><div class="n">Mr. Ochieng L.</div><div class="m">Chemistry · DOS</div></div><div class="t"><b>07:22</b>Auto-in · ±7 m</div></div>
          <div class="st-row"><div class="puck in"><svg viewBox="0 0 24 24"><path d="M5 12l5 5L20 7"/></svg></div><div><div class="n">Ms. Kabuye R.</div><div class="m">Mathematics · S6</div></div><div class="t"><b>07:41</b>Auto-in · ±6 m</div></div>
          <div class="st-row"><div class="puck off"><svg viewBox="0 0 24 24"><path d="M12 3v18M3 12h18"/></svg></div><div><div class="n">Mr. Walusansa P.</div><div class="m">Transport · Off duty</div></div><div class="t"><b>—</b>Roster-off</div></div>
          <div class="st-row"><div class="puck in"><svg viewBox="0 0 24 24"><path d="M5 12l5 5L20 7"/></svg></div><div><div class="n">Ms. Nakato F.</div><div class="m">Matron · Kwagala</div></div><div class="t"><b>06:44</b>Auto-in · ±5 m</div></div>
        </div>
      </div>
    </div>
  </div>

  <div class="card">
    <div class="hd"><h3>Auto check-in rule</h3><div class="m">Configuration · least-privilege</div></div>
    <div class="body">
      <p style="margin:0 0 12px;font-size:13px;color:var(--fg-2);max-width:640px;">When a staff member's device enters the campus geofence during their scheduled duty window, the system automatically posts a check-in event to their timesheet — no manual button-tap needed. GPS is only sampled inside the duty window to protect privacy under the Uganda Data Protection and Privacy Act, 2019.</p>
      <div class="two-col-eq">
        <div>
          <div class="k" style="font-size:10px;text-transform:uppercase;color:var(--fg-3);font-weight:700;letter-spacing:.08em">Geofence radius</div>
          <div style="font-family:var(--font-mono);font-size:18px;font-weight:600;color:var(--fg-1);margin-top:2px">120 m</div>
        </div>
        <div>
          <div class="k" style="font-size:10px;text-transform:uppercase;color:var(--fg-3);font-weight:700;letter-spacing:.08em">Grace period</div>
          <div style="font-family:var(--font-mono);font-size:18px;font-weight:600;color:var(--fg-1);margin-top:2px">15 minutes</div>
        </div>
      </div>
    </div>
  </div>
  `
},


/* ==================== CLINIC ==================== */
clinic: {
  crumb: 'Services · Clinic',
  title: 'Clinic',
  html: `
  <div class="page-head">
    <div>
      <div class="eyebrow">School clinic · 09 Jul 2026</div>
      <h1>Clinic <em>daybook</em></h1>
      <div class="desc">Visits, vitals, medicine issuance and referrals. Records are visible only to clinic staff, class teachers, and guardians under least-privilege.</div>
    </div>
    <div class="actions">
      <button class="btn o"><svg viewBox="0 0 24 24"><path d="M6 9V3h12v6"/><rect x="6" y="14" width="12" height="7"/></svg>Print daybook</button>
      <button class="btn p"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>Record a visit</button>
    </div>
  </div>

  <div class="kpis">
    <div class="kpi"><div class="k">Visits today</div><div class="v">12</div><div class="trend down"><svg viewBox="0 0 24 24"><path d="m6 9 6 6 6-6"/></svg>−3 vs yesterday</div></div>
    <div class="kpi"><div class="k">Under observation</div><div class="v" style="color:#7a5111">3</div><div class="bar-l"><span>Fever, headache, cough</span><span>Rest in sanitorium</span></div></div>
    <div class="kpi"><div class="k">Referrals</div><div class="v">1<small>UMC</small></div><div class="bar-l"><span>Ophthalmology follow-up</span><span>S4 candidate</span></div></div>
    <div class="kpi"><div class="k">Medicine stock alerts</div><div class="v" style="color:var(--brick-600)">2</div><div class="bar-l"><span>Paracetamol · low</span><span>ORS sachets · low</span></div></div>
  </div>

  <div class="clinic-cards">
    <div class="card"><div class="hd"><h3>Today's visits</h3><div class="m">14:02 EAT</div></div><div class="body body-tight">
      <div class="req"><div class="ic" style="background:var(--brick-50);color:var(--brick-600)"><svg viewBox="0 0 24 24"><path d="M12 3v18M3 12h18"/></svg></div><div><div class="t">Nakato Aisha · S2 East</div><div class="s">Headache · paracetamol · rest until lunch</div></div><div class="a"><span class="amt">10:24</span><span class="pill approved">Discharged</span></div></div>
      <div class="req"><div class="ic" style="background:var(--warning-bg);color:#7a5111"><svg viewBox="0 0 24 24"><path d="M12 3v18M3 12h18"/></svg></div><div><div class="t">Akello Prossy · S2 West</div><div class="s">Mild fever · 38.1°C · under observation</div></div><div class="a"><span class="amt">11:02</span><span class="pill pending">Observing</span></div></div>
      <div class="req"><div class="ic" style="background:var(--info-bg);color:var(--navy-600)"><svg viewBox="0 0 24 24"><path d="M12 3v18M3 12h18"/></svg></div><div><div class="t">Kembabazi Esther · S3 North</div><div class="s">Minor scrape · dressed · returned to class</div></div><div class="a"><span class="amt">11:44</span><span class="pill approved">Discharged</span></div></div>
      <div class="req"><div class="ic" style="background:var(--brick-50);color:var(--brick-600)"><svg viewBox="0 0 24 24"><path d="M12 3v18M3 12h18"/></svg></div><div><div class="t">Lamunu Mercy · S5 B</div><div class="s">Cramps · analgesic · sanitary kit issued</div></div><div class="a"><span class="amt">12:20</span><span class="pill approved">Discharged</span></div></div>
      <div class="req"><div class="ic" style="background:var(--danger-bg);color:var(--brick-700)"><svg viewBox="0 0 24 24"><path d="M12 3v18M3 12h18"/></svg></div><div><div class="t">Byaruhanga W. · S6 A</div><div class="s">Ophthalmology follow-up · referred UMC</div></div><div class="a"><span class="amt">13:05</span><span class="pill rejected">Referred</span></div></div>
    </div></div>

    <div class="card"><div class="hd"><h3>Medicine stock</h3><div class="m"><a>Issue voucher →</a></div></div><div class="body body-tight">
      <div class="stock-row"><div><div class="n">Paracetamol 500 mg</div><div class="s">BATCH-2026-041 · exp 07/2027</div></div><div class="bar-mini"><div class="low" style="width:22%"></div></div><div class="qty low">48 tab</div></div>
      <div class="stock-row"><div><div class="n">ORS sachets</div><div class="s">BATCH-2026-018 · exp 12/2027</div></div><div class="bar-mini"><div class="low" style="width:18%"></div></div><div class="qty low">9 pk</div></div>
      <div class="stock-row"><div><div class="n">Amoxicillin 250 mg</div><div class="s">BATCH-2026-033 · exp 03/2028</div></div><div class="bar-mini"><div class="mid" style="width:56%"></div></div><div class="qty">120 cap</div></div>
      <div class="stock-row"><div><div class="n">Cetirizine 10 mg</div><div class="s">BATCH-2026-021 · exp 06/2028</div></div><div class="bar-mini"><div style="width:78%"></div></div><div class="qty">78 tab</div></div>
      <div class="stock-row"><div><div class="n">Sanitary pads (regular)</div><div class="s">Welfare programme · replenished monthly</div></div><div class="bar-mini"><div style="width:88%"></div></div><div class="qty">124 pk</div></div>
      <div class="stock-row"><div><div class="n">Bandage · elastic</div><div class="s">BATCH-2026-009 · exp 11/2029</div></div><div class="bar-mini"><div style="width:64%"></div></div><div class="qty">18 rolls</div></div>
    </div></div>

    <div class="card"><div class="hd"><h3>Referrals · this term</h3><div class="m">All 3 with parent consent</div></div><div class="body body-tight">
      <div class="req"><div class="ic" style="background:var(--info-bg);color:var(--navy-600)"><svg viewBox="0 0 24 24"><path d="M12 3v18M8 6h4a3 3 0 1 1 0 6H8"/></svg></div><div><div class="t">Uganda Medical Centre · Ophthalmology</div><div class="s">Byaruhanga W. · S6 A · 09 Jul 2026</div></div><div class="a"><span class="pill pending">In progress</span></div></div>
      <div class="req"><div class="ic" style="background:var(--info-bg);color:var(--navy-600)"><svg viewBox="0 0 24 24"><path d="M12 3v18M8 6h4a3 3 0 1 1 0 6H8"/></svg></div><div><div class="t">Nsambya Hospital · Dentistry</div><div class="s">Namuli Angel · S2 South · 24 Jun 2026</div></div><div class="a"><span class="pill approved">Complete</span></div></div>
      <div class="req"><div class="ic" style="background:var(--info-bg);color:var(--navy-600)"><svg viewBox="0 0 24 24"><path d="M12 3v18M8 6h4a3 3 0 1 1 0 6H8"/></svg></div><div><div class="t">Case Hospital · Orthopaedic</div><div class="s">Tumusiime Brenda · S1 North · 12 May 2026</div></div><div class="a"><span class="pill approved">Complete</span></div></div>
    </div></div>
  </div>
  `
},


/* ==================== KITCHEN ==================== */
kitchen: {
  crumb: 'Services · Kitchen',
  title: 'Kitchen',
  html: `
  <div class="page-head">
    <div>
      <div class="eyebrow">Kitchen · Week 5 · Term 2</div>
      <h1>Feeding <em>plan</em></h1>
      <div class="desc">Weekly menu published to parents on Sundays. Consumption is tracked against roll count to spot waste or unfed learners.</div>
    </div>
    <div class="actions">
      <button class="btn o"><svg viewBox="0 0 24 24"><path d="M6 9V3h12v6"/><rect x="6" y="14" width="12" height="7"/></svg>Print menu</button>
      <button class="btn p"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>Log consumption</button>
    </div>
  </div>

  <div class="two-col">
    <div class="card"><div class="hd"><h3>Weekly menu</h3><div class="m">Published 07 Jul 2026</div></div><div class="body">
      <div class="menu-grid">
        <div class="menu-cell day">Mon <span>07 Jul</span></div>
        <div class="menu-cell meal"><div class="h">Breakfast</div><div class="n">Porridge · millet</div><div class="sub">Milk tea, bread</div></div>
        <div class="menu-cell meal"><div class="h">Lunch</div><div class="n">Posho & beans</div><div class="sub">Steamed cabbage</div></div>
        <div class="menu-cell meal"><div class="h">Supper</div><div class="n">Rice & meat stew</div><div class="sub">Greens, fruit</div></div>

        <div class="menu-cell day">Tue <span>08 Jul</span></div>
        <div class="menu-cell meal"><div class="h">Breakfast</div><div class="n">Porridge · maize</div><div class="sub">Milk tea, bread</div></div>
        <div class="menu-cell meal"><div class="h">Lunch</div><div class="n">Matoke & groundnut</div><div class="sub">Boiled greens</div></div>
        <div class="menu-cell meal"><div class="h">Supper</div><div class="n">Posho & beans</div><div class="sub">Fruit</div></div>

        <div class="menu-cell day">Wed <span>09 Jul</span></div>
        <div class="menu-cell meal"><div class="h">Breakfast</div><div class="n">Porridge · millet</div><div class="sub">Milk tea, bread</div></div>
        <div class="menu-cell meal"><div class="h">Lunch</div><div class="n">Posho & beans</div><div class="sub">Steamed cabbage</div></div>
        <div class="menu-cell meal"><div class="h">Supper</div><div class="n">Rice & fish stew</div><div class="sub">Sukuma wiki</div></div>

        <div class="menu-cell day">Thu <span>10 Jul</span></div>
        <div class="menu-cell meal"><div class="h">Breakfast</div><div class="n">Porridge · maize</div><div class="sub">Milk tea, bread</div></div>
        <div class="menu-cell meal"><div class="h">Lunch</div><div class="n">Matoke & beef stew</div><div class="sub">Boiled greens</div></div>
        <div class="menu-cell meal"><div class="h">Supper</div><div class="n">Posho & silverfish</div><div class="sub">Fruit</div></div>

        <div class="menu-cell day">Fri <span>11 Jul</span></div>
        <div class="menu-cell meal"><div class="h">Breakfast</div><div class="n">Porridge · millet</div><div class="sub">Milk tea, bread</div></div>
        <div class="menu-cell meal"><div class="h">Lunch</div><div class="n">Rice & bean stew</div><div class="sub">Cabbage salad</div></div>
        <div class="menu-cell meal"><div class="h">Supper</div><div class="n">Matoke & meat</div><div class="sub">Watermelon</div></div>
      </div>
    </div></div>

    <div class="card"><div class="hd"><h3>Kitchen inventory</h3><div class="m"><a>Request stock →</a></div></div><div class="body body-tight">
      <div class="stock-row"><div><div class="n">Maize flour</div><div class="s">Posho supply · 8 sacks in store</div></div><div class="bar-mini"><div style="width:74%"></div></div><div class="qty">400 kg</div></div>
      <div class="stock-row"><div><div class="n">Rice</div><div class="s">Long grain · Kayunga</div></div><div class="bar-mini"><div class="mid" style="width:44%"></div></div><div class="qty">180 kg</div></div>
      <div class="stock-row"><div><div class="n">Beans</div><div class="s">K132 · assorted</div></div><div class="bar-mini"><div style="width:68%"></div></div><div class="qty">240 kg</div></div>
      <div class="stock-row"><div><div class="n">Cooking oil</div><div class="s">Fortune · 20 L jerricans</div></div><div class="bar-mini"><div class="mid" style="width:38%"></div></div><div class="qty">6 jc</div></div>
      <div class="stock-row"><div><div class="n">Charcoal</div><div class="s">Sacks · replenished weekly</div></div><div class="bar-mini"><div class="low" style="width:22%"></div></div><div class="qty low">4 sacks</div></div>
      <div class="stock-row"><div><div class="n">Salt · iodised</div><div class="s">1 kg packs</div></div><div class="bar-mini"><div style="width:82%"></div></div><div class="qty">42 kg</div></div>
    </div></div>
  </div>
  `
},


/* ==================== EVENTS ==================== */
events: {
  crumb: 'Services · Events',
  title: 'Events calendar',
  html: `
  <div class="page-head">
    <div>
      <div class="eyebrow">School calendar · July 2026</div>
      <h1>Events <em>calendar</em></h1>
      <div class="desc">Academic diary, MDD, sports, PTA, and Visitation days. Push notification and SMS reminders go out to parents 48 h before every event.</div>
    </div>
    <div class="actions">
      <button class="btn o"><svg viewBox="0 0 24 24"><path d="M6 9V3h12v6"/><rect x="6" y="14" width="12" height="7"/></svg>Export ICS</button>
      <button class="btn p"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>Add event</button>
    </div>
  </div>

  <div class="card">
    <div class="hd"><h3>July 2026</h3><div class="m"><a>‹ June</a><a>August ›</a></div></div>
    <div class="body">
      <div class="cal">
        <div class="h">Mon</div><div class="h">Tue</div><div class="h">Wed</div><div class="h">Thu</div><div class="h">Fri</div><div class="h">Sat</div><div class="h">Sun</div>

        <div class="d mut"><div class="n">30</div></div>
        <div class="d"><div class="n">01</div></div>
        <div class="d"><div class="n">02</div></div>
        <div class="d"><div class="n">03</div><span class="pip navy">PTA exec</span></div>
        <div class="d"><div class="n">04</div></div>
        <div class="d"><div class="n">05</div><span class="pip maroon">Chapel</span></div>
        <div class="d"><div class="n">06</div></div>

        <div class="d"><div class="n">07</div><span class="pip brand">CAT week</span></div>
        <div class="d"><div class="n">08</div></div>
        <div class="d today"><div class="n">09</div><span class="pip brand">Marks due</span></div>
        <div class="d"><div class="n">10</div><span class="pip navy">S4 mock 1</span></div>
        <div class="d"><div class="n">11</div><span class="pip navy">S4 mock 2</span></div>
        <div class="d"><div class="n">12</div><span class="pip maroon">MDD final</span></div>
        <div class="d"><div class="n">13</div></div>

        <div class="d"><div class="n">14</div></div>
        <div class="d"><div class="n">15</div><span class="pip brand">Marks lock</span></div>
        <div class="d"><div class="n">16</div></div>
        <div class="d"><div class="n">17</div><span class="pip maroon">House meet</span></div>
        <div class="d"><div class="n">18</div><span class="pip navy">Inter-school</span></div>
        <div class="d"><div class="n">19</div><span class="pip navy">Sports · N Ug</span></div>
        <div class="d"><div class="n">20</div></div>

        <div class="d"><div class="n">21</div></div>
        <div class="d"><div class="n">22</div><span class="pip navy">Career day</span></div>
        <div class="d"><div class="n">23</div></div>
        <div class="d"><div class="n">24</div><span class="pip brand">Fees deadline</span></div>
        <div class="d"><div class="n">25</div></div>
        <div class="d"><div class="n">26</div></div>
        <div class="d"><div class="n">27</div><span class="pip maroon">Visitation Day</span></div>

        <div class="d"><div class="n">28</div><span class="pip navy">Reports out</span></div>
        <div class="d"><div class="n">29</div></div>
        <div class="d"><div class="n">30</div><span class="pip brand">Half-term brief</span></div>
        <div class="d"><div class="n">31</div></div>
        <div class="d mut"><div class="n">01</div></div>
        <div class="d mut"><div class="n">02</div></div>
        <div class="d mut"><div class="n">03</div></div>
      </div>
      <div class="legend" style="margin-top:14px">
        <span><span class="dot" style="background:var(--brick-500)"></span>Academic</span>
        <span><span class="dot" style="background:var(--navy-500)"></span>Co-curricular</span>
        <span><span class="dot" style="background:var(--maroon-500)"></span>Community & spiritual</span>
      </div>
    </div>
  </div>
  `
},


/* ==================== PROCUREMENT ==================== */
procurement: {
  crumb: 'Services · Procurement',
  title: 'Procurement',
  html: `
  <div class="page-head">
    <div>
      <div class="eyebrow">Term 2 · procurement pipeline</div>
      <h1>Requisitions & <em>purchase orders</em></h1>
      <div class="desc">Requisitions flow from department → bursar → director. POs raised only against approved requisitions.</div>
    </div>
    <div class="actions">
      <button class="btn o"><svg viewBox="0 0 24 24"><path d="M6 9V3h12v6"/><rect x="6" y="14" width="12" height="7"/></svg>Export</button>
      <button class="btn p"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>New requisition</button>
    </div>
  </div>

  <div class="kpis">
    <div class="kpi"><div class="k">Awaiting bursar</div><div class="v" style="color:#7a5111">3</div></div>
    <div class="kpi"><div class="k">Awaiting director</div><div class="v">1</div></div>
    <div class="kpi"><div class="k">Approved this term</div><div class="v" style="color:var(--success)">27</div></div>
    <div class="kpi"><div class="k">Total committed</div><div class="v">UGX 42.8M</div></div>
  </div>

  <div class="card">
    <div class="tab-hd"><h3>Pipeline</h3>
      <div style="display:flex;gap:6px"><button class="btn o sm">Filters</button><button class="btn p sm">Compare quotations</button></div>
    </div>
    <div class="tabs"><div class="t on">Pending (4)</div><div class="t">Approved (27)</div><div class="t">POs raised (19)</div><div class="t">Delivered (12)</div><div class="t">Rejected (3)</div></div>
    <div style="overflow-x:auto">
    <table class="tbl">
      <thead><tr><th>Requisition</th><th>Dept</th><th>Requester</th><th>Date</th><th class="num">Amount</th><th>Status</th><th>Action</th></tr></thead>
      <tbody>
        <tr><td><div style="font-weight:600">Lab reagents · Chemistry</div><div style="font-size:11px;color:var(--fg-3);font-family:var(--font-mono)">REQ-0347 · 3 line items</div></td><td>Academics</td><td>L. Ochieng (DOS)</td><td>08 Jul 2026</td><td class="num" style="font-weight:600;color:var(--brick-600)">1,240,000</td><td><span class="tag part"><span class="dot"></span>Bursar</span></td><td><button class="btn p sm">Review</button></td></tr>
        <tr><td><div style="font-weight:600">Kitchen · 200 kg maize flour</div><div style="font-size:11px;color:var(--fg-3);font-family:var(--font-mono)">REQ-0346 · 1 line item</div></td><td>Kitchen</td><td>M. Nakku (Cook)</td><td>08 Jul 2026</td><td class="num" style="font-weight:600">480,000</td><td><span class="tag ok"><span class="dot"></span>Approved</span></td><td><button class="btn o sm">Raise PO</button></td></tr>
        <tr><td><div style="font-weight:600">Exercise books · 12 dozen</div><div style="font-size:11px;color:var(--fg-3);font-family:var(--font-mono)">REQ-0345 · 2 line items</div></td><td>Stores</td><td>Stores officer</td><td>07 Jul 2026</td><td class="num" style="font-weight:600">216,000</td><td><span class="tag ok"><span class="dot"></span>Approved</span></td><td><button class="btn o sm">Raise PO</button></td></tr>
        <tr><td><div style="font-weight:600">Sports uniform batch</div><div style="font-size:11px;color:var(--fg-3);font-family:var(--font-mono)">REQ-0343 · 4 line items</div></td><td>MDD</td><td>MDD dept</td><td>07 Jul 2026</td><td class="num" style="font-weight:600;color:var(--brick-600)">2,860,000</td><td><span class="tag due"><span class="dot"></span>Over budget</span></td><td><button class="btn g sm">Revise</button></td></tr>
        <tr><td><div style="font-weight:600">Diesel · school van</div><div style="font-size:11px;color:var(--fg-3);font-family:var(--font-mono)">REQ-0342 · fuel top-up</div></td><td>Transport</td><td>Mr. Walusansa P.</td><td>06 Jul 2026</td><td class="num" style="font-weight:600">320,000</td><td><span class="tag part"><span class="dot"></span>Director</span></td><td><button class="btn p sm">Sign off</button></td></tr>
      </tbody>
    </table>
    </div>
  </div>
  `
},


/* ==================== STORES ==================== */
stores: {
  crumb: 'Services · Stores',
  title: 'Stores',
  html: `
  <div class="page-head">
    <div>
      <div class="eyebrow">Stores · Term 2 · 2026</div>
      <h1>Inventory & <em>issue vouchers</em></h1>
      <div class="desc">Physical goods held on-site: stationery, uniforms, cleaning, kitchen supplies. Reorder alerts fire when quantity dips below the reorder point.</div>
    </div>
    <div class="actions">
      <button class="btn o"><svg viewBox="0 0 24 24"><path d="M6 9V3h12v6"/><rect x="6" y="14" width="12" height="7"/></svg>Print stock take</button>
      <button class="btn p"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>Issue voucher</button>
    </div>
  </div>

  <div class="kpis">
    <div class="kpi"><div class="k">SKUs tracked</div><div class="v">142</div></div>
    <div class="kpi"><div class="k">Reorder alerts</div><div class="v" style="color:var(--brick-600)">6</div></div>
    <div class="kpi"><div class="k">Voucher this week</div><div class="v">23</div></div>
    <div class="kpi"><div class="k">Stock value</div><div class="v">UGX 118M</div></div>
  </div>

  <div class="card">
    <div class="tab-hd"><h3>Stock items</h3>
      <div style="display:flex;gap:6px"><button class="btn o sm">Filters</button><button class="btn g sm">Stock take</button></div>
    </div>
    <div class="tabs"><div class="t on">All (142)</div><div class="t">Stationery (32)</div><div class="t">Kitchen (28)</div><div class="t">Uniforms (18)</div><div class="t">Cleaning (16)</div><div class="t">Low stock (6)</div></div>
    <div style="overflow-x:auto">
    <table class="tbl">
      <thead><tr><th>Item</th><th>Category</th><th class="num">On hand</th><th class="num">Reorder point</th><th>Last issued</th><th>Status</th></tr></thead>
      <tbody>
        <tr><td><div style="font-weight:600">Exercise books · 96 pg</div><div style="font-size:11px;color:var(--fg-3);font-family:var(--font-mono)">STA-EB-096</div></td><td>Stationery</td><td class="num" style="color:var(--brick-600);font-weight:600">12 doz</td><td class="num">20 doz</td><td>08 Jul · S3E</td><td><span class="tag due"><span class="dot"></span>Reorder</span></td></tr>
        <tr><td><div style="font-weight:600">Chalk · white</div><div style="font-size:11px;color:var(--fg-3);font-family:var(--font-mono)">STA-CHK-WHT</div></td><td>Stationery</td><td class="num">84 box</td><td class="num">40 box</td><td>05 Jul · Blk A</td><td><span class="tag ok"><span class="dot"></span>OK</span></td></tr>
        <tr><td><div style="font-weight:600">Uniform · blouse S3</div><div style="font-size:11px;color:var(--fg-3);font-family:var(--font-mono)">UNI-BLZ-S3</div></td><td>Uniforms</td><td class="num">28 pc</td><td class="num">25 pc</td><td>03 Jul · Kwagala</td><td><span class="tag part"><span class="dot"></span>Watch</span></td></tr>
        <tr><td><div style="font-weight:600">Toilet paper · rolls</div><div style="font-size:11px;color:var(--fg-3);font-family:var(--font-mono)">CLN-TP-ROLL</div></td><td>Cleaning</td><td class="num" style="color:var(--brick-600);font-weight:600">42 roll</td><td class="num">80 roll</td><td>09 Jul · Sanitation</td><td><span class="tag due"><span class="dot"></span>Reorder</span></td></tr>
        <tr><td><div style="font-weight:600">Detergent · bar 800g</div><div style="font-size:11px;color:var(--fg-3);font-family:var(--font-mono)">CLN-DET-800</div></td><td>Cleaning</td><td class="num">64 pc</td><td class="num">50 pc</td><td>07 Jul · Laundry</td><td><span class="tag ok"><span class="dot"></span>OK</span></td></tr>
        <tr><td><div style="font-weight:600">Maize flour · sacks 50 kg</div><div style="font-size:11px;color:var(--fg-3);font-family:var(--font-mono)">KIT-MAZ-50K</div></td><td>Kitchen</td><td class="num">8 sk</td><td class="num">6 sk</td><td>09 Jul · Kitchen</td><td><span class="tag ok"><span class="dot"></span>OK</span></td></tr>
        <tr><td><div style="font-weight:600">Charcoal · sacks</div><div style="font-size:11px;color:var(--fg-3);font-family:var(--font-mono)">KIT-CHR-SAC</div></td><td>Kitchen</td><td class="num" style="color:var(--brick-600);font-weight:600">4 sk</td><td class="num">10 sk</td><td>09 Jul · Kitchen</td><td><span class="tag due"><span class="dot"></span>Reorder</span></td></tr>
      </tbody>
    </table>
    </div>
  </div>
  `
},


/* ==================== REPORTS ==================== */
reports: {
  crumb: 'Insight · Reports',
  title: 'Reports & exports',
  html: `
  <div class="page-head">
    <div>
      <div class="eyebrow">Printable outputs · Term 2 · 2026</div>
      <h1>Reports & <em>exports</em></h1>
      <div class="desc">Branded PDFs and regulator exports. All bear the school header, stamp, signatures, and — where relevant — the Uganda flag colour strip.</div>
    </div>
  </div>

  <div class="rep-grid">
    ${[
      { ic:'<path d="M4 4h16v16H4z"/><path d="M4 9h16"/>', h:'Report card', p:'Per-learner Term 2 report with grades, attendance, class-teacher comment and headteacher stamp.', btn:'Generate 812'},
      { ic:'<rect x="3" y="6" width="18" height="12" rx="2"/><path d="M3 10h18"/>', h:'Fees statement', p:'Individual fees statement by student, term, or class. Emits to PDF and SMS one-line summary.', btn:'Batch export'},
      { ic:'<path d="M12 3v18M8 6h4a3 3 0 1 1 0 6H8"/>', h:'Clinic term summary', p:'Aggregated clinic visits with confidentiality-preserving initials; issued to headteacher and nurse.', btn:'Export PDF'},
      { ic:'<path d="M12 2 4 5v6c0 5 3.5 8 8 9 4.5-1 8-4 8-9V5z"/>', h:'UNEB · S6 candidate list', p:'CSV export in UNEB registration format for the 148 S6 candidates. Signed off by DOS.', btn:'Export CSV'},
      { ic:'<path d="M3 3v18h18"/><path d="M7 15l4-4 3 3 5-6"/>', h:'EMIS · statutory return', p:'Termly EMIS submission: enrolment, teachers, infrastructure. Compliant with MoES schema.', btn:'Prepare submission'},
      { ic:'<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/>', h:'Payroll timesheet', p:'Hours per staff per week, feeds into monthly payroll. Locked once approved.', btn:'Prepare payroll'},
    ].map(x => `
    <div class="rep-card">
      <div class="strip"></div>
      <div class="ic"><svg viewBox="0 0 24 24">${x.ic}</svg></div>
      <h4>${x.h}</h4>
      <p>${x.p}</p>
      <div style="display:flex;gap:8px"><button class="btn p sm">${x.btn}</button><button class="btn g sm">Preview</button></div>
    </div>`).join('')}
  </div>
  `
},


/* ==================== AUDIT ==================== */
audit: {
  crumb: 'Insight · Audit log',
  title: 'Audit log',
  html: `
  <div class="page-head">
    <div>
      <div class="eyebrow">Compliance · Uganda Data Protection Act, 2019</div>
      <h1>Audit <em>log</em></h1>
      <div class="desc">Immutable trail of every sensitive action: fee posting, marks entry, clinic edit, geofence tracking. Only Director and administrator roles may export.</div>
    </div>
    <div class="actions">
      <button class="btn o"><svg viewBox="0 0 24 24"><path d="M6 9V3h12v6"/><rect x="6" y="14" width="12" height="7"/></svg>Export CSV</button>
      <button class="btn g">Filters</button>
    </div>
  </div>

  <div class="card">
    <div class="tab-hd" style="padding-bottom:12px"><h3>Recent activity</h3><div style="font-size:11px;color:var(--fg-3);font-family:var(--font-mono)">Last 24 h · 187 events</div></div>
    <div style="padding:8px 0 4px">
      ${[
        ['13:58:41','J. Nsubuga','Bursar','Posted','payment UGX 350,000 for','TGS/2024/00478','i'],
        ['13:22:12','L. Ochieng','DOS','Approved','requisition','REQ-0346','i'],
        ['12:11:04','Nurse Alice N.','Clinic','Added','clinic visit for','TGS/2022/00087','i'],
        ['11:42:18','Ms. Kabuye R.','Teacher','Edited','Physics marks · CAT 2','S3 East','i'],
        ['10:24:00','Nurse Alice N.','Clinic','Added','clinic visit for','TGS/2024/00478','i'],
        ['09:45:22','SYSTEM','Geofence','Flagged','off-campus during class hours','Ms. Nabbosa J.','d'],
        ['09:12:44','Ms. Nabbosa J.','Teacher','Failed','attempt to edit locked marks','S4 East · Eng','w'],
        ['07:41:03','Ms. Kabuye R.','Teacher','Auto check-in','via geofence','±6 m · 07:41','i'],
        ['07:38:47','Mr. Ssekandi B.','Teacher','Auto check-in','via geofence','±6 m · 07:38','i'],
        ['05:52:12','Ms. Nakku M.','Cook','Auto check-in','via geofence','±8 m · 05:52','i'],
        ['22:58:19','SYSTEM','Backup','Completed','full DB backup','tgs-prod-2026-07-08','i'],
        ['21:14:03','Admin (root)','IT','Rotated','API key','fcm-server-key','w'],
      ].map(r => `
        <div class="audit-row">
          <div class="ts">${r[0]}</div>
          <div>
            <div class="who">${r[1]} <span class="r">· ${r[2]}</span></div>
            <div class="act"><b>${r[3]}</b> ${r[4]}</div>
          </div>
          <div class="obj">${r[5]}</div>
          <div class="lvl ${r[6]}">${r[6]==='i'?'INFO':r[6]==='w'?'WARN':'ALERT'}</div>
        </div>
      `).join('')}
    </div>
  </div>
  `
},

};
