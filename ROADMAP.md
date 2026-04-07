# Roxy Missed Connections — Development Roadmap

> A living plan for turning the MVP into a full venue-native app.

---

## Phase 1 — Foundation (Done ✅)

The app runs locally at `localhost:3000`, users can sign up and sign in, the feed displays posts, and all core interactions (likes, comments, waves, reports) work end-to-end.

- [x] Single-file SPA with Supabase Auth + DB
- [x] User onboarding (username, display name, vibe tags)
- [x] Post feed with category filters and sort
- [x] Post detail with comments and likes
- [x] Send a "wave" (connection request) to another user
- [x] Discover view with full-text search
- [x] My profile with edit and avatar upload
- [x] Notifications (waves received, connection status)
- [x] Report & block (posts, comments, users)
- [x] Row-level security on all Supabase tables
- [x] The Lounge home page with venue branding
- [x] README and project documentation

---

## Phase 2 — Polish & Real Use (Next Up 🔜)

These are the things needed before real patrons use it in-venue.

### 2a — UX Tightening
- [ ] Loading skeletons on feed, discover, and profile (replace spinners)
- [ ] Swipe-to-dismiss on modals (mobile gesture)
- [ ] Pull-to-refresh on the feed
- [ ] Infinite scroll / pagination on the feed (currently loads all at once)
- [ ] Empty state illustrations on feed, discover, notifications

### 2b — Profile Completion
- [ ] Avatar upload that actually previews before saving
- [ ] Profile completeness indicator (nudge users to fill in bio, vibe tags)
- [ ] View other users' full profiles from posts and discover

### 2c — The Lounge
- [ ] Venue admin panel to post "Tonight at The Roxy" events
- [ ] Pull live event data from Supabase `venue_events` table
- [ ] Live activity counter (posts in the last hour)
- [ ] Featured/pinned posts from venue staff

### 2d — Safety
- [ ] Rate limiting on post creation (max 5 posts/hour per user)
- [ ] Admin dashboard to review reported content
- [ ] Auto-deactivate posts older than 48 hours (optional)

---

## Phase 3 — Engagement Features 🎯

Features that make people want to come back.

- [ ] **"Match" system** — when two users wave at each other, they match and get a shared message thread
- [ ] **Direct messages** — simple 1:1 chat between matched users
- [ ] **Anonymous mode** — post without showing your username (venue staff see all)
- [ ] **Vibe poll** — "What's the vibe tonight?" quick tap survey in The Lounge
- [ ] **Post expiry** — posts auto-archive after 24 hours to keep the feed fresh
- [ ] **Venue check-in** — optional "I'm here tonight" status visible to others

---

## Phase 4 — Going Live 🚀

Steps to move from localhost to a real URL.

- [ ] Deploy to Vercel, Netlify, or Cloudflare Pages (free tier)
  - No build step needed — just upload `index.html`
  - Set custom domain e.g. `connections.theroxyen.com`
- [ ] Add PWA manifest so it installs to phone home screen like an app
  - `manifest.json` + service worker for offline shell
  - iOS splash screen and icon set
- [ ] QR code for in-venue promotion
  - Table cards, bathroom stickers, bar menu inserts
- [ ] Set up email SMTP in Supabase for auth emails (currently disabled)
- [ ] Enable Supabase Realtime for live feed updates

---

## Phase 5 — Monetization & Partnerships (Future)

- [ ] Venue-sponsored "featured" posts (promoted missed connections)
- [ ] Event ticket integration (link posts to ticketed events)
- [ ] Multi-venue support (expand beyond The Roxy to other Media Wave SD clients)
- [ ] White-label version for other venues

---

## Technical Debt to Address

| Item | Priority | Notes |
|------|----------|-------|
| Split `index.html` into modules | Medium | Over 2000 lines — manageable now, will need splitting around 3000+ |
| Replace direct `fetch()` with consistent client | Low | Current hybrid (Supabase JS for auth, fetch for queries) works fine |
| Add error boundaries | Medium | Some async functions swallow errors silently |
| Test on iOS Safari | High | Safe area insets, viewport units need real device testing |
| Rate limiting on waves | High | Currently one wave per user pair (enforced by DB unique constraint) |

---

## Immediate Next Session Priorities

1. Test the Lounge page in-browser and refine the feel
2. Wire venue events to the Supabase `venue_events` table
3. Build out the avatar upload flow (it's scaffolded but untested)
4. Deploy to Netlify or Vercel for a shareable URL
5. Create QR code and simple in-venue card

---

*Last updated: April 2026*
