# The Roxy Encinitas — Missed Connections
## Claude Code Project Brief

**Client:** Roxy Encinitas (roxyencinitas.com)  
**Built by:** Media Wave SD (brett@mediawavesd.com)  
**Project type:** Standalone web app — zero dependencies, no backend  
**Status:** V1 complete and functional. Ready for deploy or Supabase upgrade.

---

## What This Is

A "missed connections" social app for The Roxy bar in Encinitas, CA. Users can:
- Browse missed connection posts from other Roxy patrons
- Create a lightweight profile (name + emoji avatar) OR post as a guest
- Post their own missed connection (night, vibe, message, contact info)
- Heart posts (deduplicated via localStorage)
- View their own post history on their profile tab

**Tone:** Warm, funny, coastal. Think Craigslist Missed Connections meets a Encinitas beach bar.

---

## File Structure

```
roxy-v3/
├── index.html          ← The entire app. Self-contained, no build step.
├── Roxy-logo-white.png ← Original logo asset (PNG, white on black)
├── CLAUDE.md           ← This file
└── supabase-schema.sql ← (optional) DB schema if upgrading to Supabase
```

---

## Tech Stack

- **Pure HTML/CSS/JS** — no framework, no bundler, no npm
- **localStorage** for all persistence (posts, user profile, hearts)
- **Google Fonts** (Playfair Display + DM Sans) via CDN link
- Logo embedded as base64 data URI directly in the HTML

---

## Brand & Design

**Colors:**
- `--gold: #d4a050` — primary accent
- `--bg: #0d0d0d` — near-black background
- `--bg2: #161616` — card surface
- `--bg3: #1e1e1e` — input/button surface
- `--txt: #f0ece4` — warm white text
- `--red: #c45566` — error / "New" badge

**Fonts:**
- `Playfair Display` — headings, card body text (italic for post messages)
- `DM Sans` — all UI, labels, buttons

**Logo:** The Roxy wordmark (white, "THE ROXY / ENCINITAS·CA EST. 1978")
- Currently embedded as base64 in `<img class="roxy-logo">`
- If serving from a real server, swap the `src` to `./Roxy-logo-white.png`

---

## Key JS Functions

| Function | What it does |
|---|---|
| `openAuth()` | Shows the auth modal |
| `createProfile()` | Saves user to localStorage, shows success step |
| `continueGuest()` | Saves guest alias to localStorage |
| `switchTab(name)` | Switches between browse/post/wins/profile tabs |
| `renderBrowse(filter)` | Renders filtered post cards |
| `submitPost()` | Validates and saves a new post to localStorage |
| `heartPost(id)` | Increments heart count (deduped) |
| `renderProfile()` | Shows user's own posts + stats |
| `showToast(msg)` | Bottom toast notification |

---

## Data Model (localStorage)

### `roxy_mc_v3` key
```json
{
  "posts": [
    {
      "id": "p_1234567890",
      "name": "The one in the linen shirt",
      "avatar": "🌊",
      "night": "Last Friday",
      "nk": "fri",
      "vibe": "Eye contact across the bar",
      "msg": "Full message text here...",
      "contact": "@instagram or email",
      "hearts": 0,
      "ts": 1712000000000
    }
  ],
  "user": {
    "name": "Display Name",
    "avatar": "🌊",
    "created": 1712000000000
  },
  "guest": { "name": "Alias" },
  "visited": true
}
```

### `roxy_hearts_v3` key
```json
["seed1", "p_1234567890"]
```
Array of post IDs this device has hearted. Prevents double-hearting.

---

## Seed Posts

Five hardcoded posts are always shown (`SEED` array in the JS). They render below any user-submitted posts. Hearts on seed posts update in-memory only (not persisted). This ensures the wall never looks empty on first visit.

---

## Deployment

### Option A: Netlify Drop (30 seconds, free)
1. Go to [netlify.com/drop](https://app.netlify.com/drop)
2. Drag `index.html` into the browser window
3. Done — live URL instantly

### Option B: Webflow Embed
- Create a new page at `/missed-connections`
- Add a **Custom Code** section → paste the full `index.html` content
- Or: host on Netlify and embed via `<iframe src="https://your-netlify-url.netlify.app" />`

### Option C: GitHub Pages
```bash
git init
git add index.html
git commit -m "roxy missed connections v1"
# push to GitHub → Settings → Pages → Deploy from main branch
```

---

## Planned Upgrades (Phase 2)

When ready to add a real backend so posts are shared across all devices:

### Supabase Integration
- Schema: `supabase-schema.sql` (already written)
- Tables: `profiles`, `connections`, `hearts`
- Replace `localStorage` reads/writes with `supabase.from('...').select/insert`
- Add email capture to profile creation
- Add email notifications via Supabase Edge Functions → Resend/SendGrid

### Email List
- Currently: no email capture (intentional for MVP)
- Phase 2: Add optional email field to profile creation
- All captured emails go to `profiles.email` in Supabase
- Export CSV or connect to Mailchimp/Klaviyo via Zapier

### Moderation
- Add `is_approved` flag to connections table (already in schema)
- Build simple `/admin` page with password protection
- Or use Supabase Dashboard → Table Editor for manual review

---

## Notes for Claude Code

- The logo is embedded as a base64 data URI. If you swap to a real file path, update `<img src="...">` in the hero section.
- The `SEED` array in JS is the hardcoded sample posts. Edit freely to match real Roxy stories.
- All CSS custom properties are in `:root` — change colors there only.
- The `--ease` cubic-bezier is intentional — do not change to `ease-in-out`.
- No external JS libraries. Keep it that way unless adding Supabase.
- localStorage key is `roxy_mc_v3` — bump to `v4` if you change the data schema to avoid breaking existing users' state.
