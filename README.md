# Roxy Missed Connections

> A venue-based social app for The Roxy Encinitas — post missed connections, find your people, and keep the night going.

---

## What It Is

Roxy Missed Connections is a mobile-first web app built exclusively for The Roxy Encinitas. It lets patrons post anonymous-ish "missed connections," find event buddies, connect with music lovers, and browse who's out tonight — all without leaving the venue vibe.

---

## Tech Stack

| Layer | Tech |
|-------|------|
| Frontend | Vanilla HTML/CSS/JS — single `index.html`, no framework |
| Auth | Supabase Auth (email + password) |
| Database | Supabase (PostgreSQL + REST API) |
| Storage | Supabase Storage (avatar uploads) |
| Fonts | Google Fonts — DM Serif Display, Plus Jakarta Sans |
| Dev Server | Python `http.server` on port 3000 |

---

## Running Locally

1. Clone this repo
2. Double-click `start-app.command` in Finder — it starts a local Python server and opens Chrome at `http://localhost:3000`

> **Note:** The server runs while the terminal window is open. Close the terminal to stop it.

### Manual start

```bash
python3 -m http.server 3000
```

Then open [http://localhost:3000](http://localhost:3000) in your browser.

---

## Project Structure

```
roxy-missed-connections/
├── index.html          # The entire app — HTML, CSS, and JS in one file
├── start-app.command   # macOS double-click launcher (starts Python server)
├── schema-fix.sql      # Supabase schema (idempotent — safe to re-run)
├── schema-new.sql      # Full schema with comments (reference)
├── CLAUDE.md           # AI assistant context for this project
└── README.md           # This file
```

---

## Supabase Setup

1. Go to [supabase.com](https://supabase.com) and create a project
2. In the SQL Editor, run `schema-fix.sql` to create all tables, triggers, and RLS policies
3. In **Auth > Providers**, disable **"Confirm email"** for development
4. Update the credentials at the top of `index.html`:

```javascript
const SUPABASE_URL = 'https://YOUR_PROJECT_ID.supabase.co';
const SUPABASE_KEY = 'your-anon-public-key';
```

---

## Features (Current)

- **The Lounge** — ambient home page with venue branding and tonight's vibe
- **Feed** — scrollable post feed with category filters (Missed Connection, Looking to Meet, Event Buddy, Music Lover, Just Saying Hi)
- **Discover** — full-text search across all posts and profiles
- **Waves** — send a private wave to another user (connection request)
- **Profiles** — set your username, display name, bio, vibe tags, and avatar
- **Comments & Likes** — on every post
- **Notifications** — waves and connection updates
- **Report & Block** — safety controls on posts, comments, and users

---

## Venue

**The Roxy Encinitas**
1021 N. Vulcan Ave #3
Encinitas, CA 92024

---

## Development Notes

- All state lives in a global `state` object — no framework, no build step
- Supabase JS client is used for auth; direct `fetch()` calls are used for most DB queries (more reliable on initial page load)
- RLS (Row Level Security) is fully enabled — all data access is scoped per user
- The app is designed mobile-first; desktop gets a centered max-width layout

---

*Built by Media Wave SD for The Roxy Encinitas.*
