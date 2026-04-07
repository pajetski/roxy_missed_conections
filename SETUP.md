# Roxy Missed Connections — Setup Guide

## Quick Start (5 minutes)

### 1. Create a Supabase Project
1. Go to https://supabase.com and create a free account
2. Click **New Project**, name it "roxy-missed-connections"
3. Choose a strong database password (save it!)
4. Select the region closest to you (US West for SoCal)
5. Wait ~2 minutes for provisioning

### 2. Run the Database Schema
1. In your Supabase dashboard, go to **SQL Editor** → **New Query**
2. Open `schema-new.sql` from this folder
3. Copy all content and paste into the SQL editor
4. Click **Run** — you should see "Success, no rows returned"

### 3. Configure Authentication
1. Go to **Authentication** → **Providers**
2. Make sure **Email** is enabled
3. Under **Email**, you can enable "Confirm email" (recommended for production)
   - For testing, disable it temporarily
4. For magic links: they work automatically with email provider

### 4. Connect Your App
1. Open `app.html` in a code editor
2. Find these two lines near the top of the `<script>` section:
   ```
   const SUPABASE_URL  = 'YOUR_SUPABASE_URL';
   const SUPABASE_KEY  = 'YOUR_SUPABASE_ANON_KEY';
   ```
3. In Supabase, go to **Settings** → **API**
4. Copy your **Project URL** → paste as `SUPABASE_URL`
5. Copy your **anon / public** key → paste as `SUPABASE_KEY`
   ⚠️ Use ONLY the **anon** key — never the service_role key in frontend code

### 5. Test Locally
Open `app.html` directly in Chrome or deploy to any static host.

**Test this flow:**
- [ ] Create an account (sign up)
- [ ] Complete profile onboarding
- [ ] Create a post
- [ ] Like a post
- [ ] Comment on a post
- [ ] Send a wave to another user
- [ ] Accept/decline a wave in Notifications

---

## Deployment Options

### Option A: Netlify Drop (Easiest)
1. Go to https://app.netlify.com/drop
2. Drag `app.html` into the browser window
3. Rename to `index.html` when prompted
4. Done — you get a live URL

### Option B: GitHub Pages
1. Create a GitHub repo
2. Upload `app.html` as `index.html`
3. Enable GitHub Pages under Settings
4. Free HTTPS hosting

### Option C: Embed in Roxy Website
If The Roxy website is on Squarespace/Wix/Webflow:
1. Host `app.html` on Netlify (free)
2. Add an iFrame embed block pointing to your Netlify URL
3. Or link directly from the navigation: "Missed Connections"

---

## Supabase Auth Settings for Production

In Supabase Dashboard → **Authentication** → **URL Configuration**:
- **Site URL**: Your production domain (e.g., `https://missed.theroxy.com`)
- **Redirect URLs**: Add your domain + `/**`

---

## Supabase Storage
The schema SQL creates the `avatars` bucket automatically.
If it doesn't appear, go to **Storage** and create a bucket named `avatars` with:
- Public: ON
- Max file size: 5MB
- Allowed types: image/jpeg, image/png, image/webp

---

## Row Level Security (RLS) — What's Enabled
- Users can only edit/delete their own posts, comments, profile
- Connection requests are only visible to sender and receiver
- Reports are write-only (users submit but can't read others' reports)
- All posts and profiles are publicly readable (for browsing)
- Storage: users can only upload to their own folder (avatars/{userId}/)

---

## Moderation Workflow
Reports go to the `reports` table. To review:
1. Go to Supabase Table Editor → `reports`
2. Filter by `status = pending`
3. Take action manually (ban user, delete post)
4. Update `status` to `resolved`

To ban a user:
```sql
UPDATE profiles SET is_banned = true WHERE id = 'user-uuid-here';
```

To delete a post:
```sql
UPDATE posts SET is_active = false WHERE id = 'post-uuid-here';
```

---

## Phase 2 Ideas (Next Steps)
- Real-time feed updates (Supabase Realtime subscriptions)
- Push notifications (Web Push API)
- Event-based matching (link posts to venue_events table)
- Admin dashboard for moderation
- Badges for regulars (post count milestones)
- Private messaging between connected users

---

## Environment Notes
- No build system required — pure HTML/CSS/JS
- Supabase SDK loaded via CDN (jsdelivr)
- Google Fonts loaded via @import
- Works offline for static UI, requires Supabase for data
- File size: ~100KB uncompressed (no images, all in one file)
