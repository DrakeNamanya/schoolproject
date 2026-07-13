# Timbitwire Girls School — Interactive Demo

Self-contained static site — click **`index.html`** to start.

Structure:

```
deploy/
├── index.html                 ← Launcher: three apps + palette + deep links
├── parent/                    ← Parent mobile app (5 screens)
├── staff/                     ← Staff mobile app w/ auto GPS check-in
├── admin/                     ← Admin web console (12 dashboards)
├── assets/                    ← Logo, crest, pattern, flag strip
├── fonts/                     ← DM Serif Display, Plus Jakarta Sans, JetBrains Mono
├── timbitwire-tokens.css      ← Single source of truth for all design tokens
├── _headers                   ← Cloudflare Pages caching rules
└── README.md                  ← You are here
```

No build step — pure HTML/CSS/JS. Works from any static host, from a USB
stick, or from `file://`.

---

## Publish to Cloudflare Pages

You already have a repo at **[github.com/DrakeNamanya/schoolproject](https://github.com/DrakeNamanya/schoolproject)**. Two paths, pick either:

### A. Push this folder to your repo, connect Cloudflare Pages (recommended)

1. Download this project as a zip (top-right of the Genspark UI) and extract.
2. Copy the **`deploy/`** folder into your local clone of `schoolproject`.
3. From that folder:
   ```bash
   git add deploy
   git commit -m "Add Timbitwire demo"
   git push
   ```
4. Go to [dash.cloudflare.com](https://dash.cloudflare.com) → **Workers & Pages** → **Create** → **Pages** → **Connect to Git**.
5. Pick `schoolproject`. When it asks:
   - **Framework preset:** *None*
   - **Build command:** *(leave empty)*
   - **Build output directory:** `deploy`
6. Click **Save and Deploy**. In ~90 seconds you'll get a live URL like
   `https://schoolproject.pages.dev` (or a name you pick).

Any future `git push` re-deploys automatically.

### B. Drag-and-drop (no repo, no CLI)

1. Download this project, extract, open the `deploy/` folder.
2. [dash.cloudflare.com](https://dash.cloudflare.com) → **Workers & Pages** → **Create** → **Pages** → **Upload assets**.
3. Drag the `deploy` folder onto the drop zone.
4. Name the project `timbitwire-demo`, click **Deploy**.
5. Live URL appears in ~60 seconds.

Zero credentials shared with anyone. No CLI. Good for a one-off demo.

---

## What's in the demo

- **Launcher** (`index.html`) — brand hero, three app cards, deep-links to every admin route, palette proof.
- **Parent mobile app** (`parent/`) — Home · Fees · Academics · Clinic · More. Full report card. Mobile-money statement (MTN, Airtel, Stanbic).
- **Staff mobile app** (`staff/`) — Check-in · Schedule · Timesheet · Alerts. Includes an animated **auto-GPS demo** button that plays leaving-and-re-entering the campus geofence.
- **Admin console** (`admin/`) — Dashboard, Finance, Students, Academics (marks entry with 7-day lock), Attendance (live staff geofence), Clinic, Kitchen, Events, Procurement, Stores, Reports, Audit log. **All 12 sidebar tabs render real screens.**

State (last-visited tab) persists in the browser between visits.

---

## Rotating credentials

If any Cloudflare API tokens were ever shared during this demo prep,
please revoke them at
[dash.cloudflare.com/profile/api-tokens](https://dash.cloudflare.com/profile/api-tokens)
and issue fresh, narrowly-scoped ones for future work.
