-- ============================================================
-- ROXY MISSED CONNECTIONS — Schema Fix (Safe to re-run)
-- Drop existing policies first, then recreate everything.
-- Run this in: Supabase Dashboard > SQL Editor > New Query > Run
-- ============================================================

-- ─── ENABLE EXTENSIONS ────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ─── TABLES (idempotent) ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id              uuid        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username        text        UNIQUE NOT NULL,
  display_name    text,
  avatar_url      text,
  bio             text        CHECK (char_length(bio) <= 300),
  age_range       text        CHECK (age_range IN ('21-25','26-30','31-35','36-40','41-45','46+', NULL)),
  interests       text[]      DEFAULT '{}',
  favorite_artist text,
  favorite_drink  text,
  here_for        text[]      DEFAULT '{}',
  vibe_tags       text[]      DEFAULT '{}',
  is_banned       boolean     DEFAULT false,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.posts (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title         text        NOT NULL CHECK (char_length(title) <= 100),
  body          text        NOT NULL CHECK (char_length(body) <= 800),
  category      text        NOT NULL DEFAULT 'just_saying_hi'
                            CHECK (category IN (
                              'missed_connection','looking_to_meet','event_buddy',
                              'music_lover','just_saying_hi'
                            )),
  venue_tag     text        CHECK (venue_tag IN (
                              'live_music','happy_hour','brunch',
                              'late_night','weekend','special_event', NULL
                            )),
  like_count    integer     NOT NULL DEFAULT 0,
  comment_count integer     NOT NULL DEFAULT 0,
  is_active     boolean     NOT NULL DEFAULT true,
  created_at    timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS posts_fts_idx ON public.posts
  USING gin((to_tsvector('english', title || ' ' || body)));

CREATE TABLE IF NOT EXISTS public.likes (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  post_id    uuid        NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE (user_id, post_id)
);

CREATE TABLE IF NOT EXISTS public.comments (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  post_id    uuid        NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  body       text        NOT NULL CHECK (char_length(body) <= 500),
  is_active  boolean     NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.connection_requests (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id   uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  receiver_id uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  post_id     uuid        REFERENCES public.posts(id) ON DELETE SET NULL,
  message     text        CHECK (char_length(message) <= 200),
  status      text        NOT NULL DEFAULT 'pending'
                          CHECK (status IN ('pending','accepted','declined')),
  created_at  timestamptz DEFAULT now(),
  UNIQUE (sender_id, receiver_id)
);

CREATE TABLE IF NOT EXISTS public.reports (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id      uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  reported_user_id uuid        REFERENCES public.profiles(id) ON DELETE SET NULL,
  post_id          uuid        REFERENCES public.posts(id) ON DELETE SET NULL,
  comment_id       uuid        REFERENCES public.comments(id) ON DELETE SET NULL,
  reason           text        NOT NULL,
  status           text        NOT NULL DEFAULT 'pending'
                               CHECK (status IN ('pending','reviewed','resolved')),
  created_at       timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.blocked_users (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  blocked_id uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE (blocker_id, blocked_id)
);

CREATE TABLE IF NOT EXISTS public.venue_events (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  title       text        NOT NULL,
  description text,
  event_date  date        NOT NULL,
  event_time  text,
  event_type  text        CHECK (event_type IN ('live_music','happy_hour','brunch','special_event','late_night')),
  is_active   boolean     NOT NULL DEFAULT true,
  created_at  timestamptz DEFAULT now()
);

-- ─── FUNCTIONS & TRIGGERS (idempotent) ───────────────────────────────────────

CREATE OR REPLACE FUNCTION update_post_like_count()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.posts SET like_count = like_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.posts SET like_count = GREATEST(like_count - 1, 0) WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$;

CREATE OR REPLACE TRIGGER on_like_change
  AFTER INSERT OR DELETE ON public.likes
  FOR EACH ROW EXECUTE FUNCTION update_post_like_count();

CREATE OR REPLACE FUNCTION update_post_comment_count()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' OR (TG_OP = 'UPDATE' AND NEW.is_active = false) THEN
    UPDATE public.posts SET comment_count = GREATEST(comment_count - 1, 0) WHERE id = COALESCE(OLD.post_id, NEW.post_id);
  END IF;
  RETURN NULL;
END;
$$;

CREATE OR REPLACE TRIGGER on_comment_change
  AFTER INSERT OR DELETE OR UPDATE ON public.comments
  FOR EACH ROW EXECUTE FUNCTION update_post_comment_count();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substring(NEW.id::text, 1, 8)),
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.raw_user_meta_data->>'username')
  );
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ─── ROW LEVEL SECURITY — ENABLE ─────────────────────────────────────────────

ALTER TABLE public.profiles            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.connection_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocked_users       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.venue_events        ENABLE ROW LEVEL SECURITY;

-- ─── DROP EXISTING POLICIES (so re-runs don't error) ─────────────────────────

DROP POLICY IF EXISTS "Public profiles are viewable by anyone"      ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile"           ON public.profiles;

DROP POLICY IF EXISTS "Active posts are viewable by anyone"          ON public.posts;
DROP POLICY IF EXISTS "Authenticated users can create posts"         ON public.posts;
DROP POLICY IF EXISTS "Users can update their own posts"             ON public.posts;
DROP POLICY IF EXISTS "Users can delete their own posts"             ON public.posts;

DROP POLICY IF EXISTS "Likes are viewable by anyone"                 ON public.likes;
DROP POLICY IF EXISTS "Authenticated users can like"                 ON public.likes;
DROP POLICY IF EXISTS "Users can unlike their own likes"             ON public.likes;

DROP POLICY IF EXISTS "Active comments are viewable by anyone"       ON public.comments;
DROP POLICY IF EXISTS "Authenticated users can comment"              ON public.comments;
DROP POLICY IF EXISTS "Users can update their own comments"          ON public.comments;
DROP POLICY IF EXISTS "Users can delete their own comments"          ON public.comments;

DROP POLICY IF EXISTS "Users can see their own requests"             ON public.connection_requests;
DROP POLICY IF EXISTS "Authenticated users can send requests"        ON public.connection_requests;
DROP POLICY IF EXISTS "Receivers can update request status"          ON public.connection_requests;

DROP POLICY IF EXISTS "Users can create reports"                     ON public.reports;
DROP POLICY IF EXISTS "Users can view their own reports"             ON public.reports;

DROP POLICY IF EXISTS "Users can view their own blocks"              ON public.blocked_users;
DROP POLICY IF EXISTS "Users can block others"                       ON public.blocked_users;
DROP POLICY IF EXISTS "Users can unblock"                            ON public.blocked_users;

DROP POLICY IF EXISTS "Venue events are public"                      ON public.venue_events;

DROP POLICY IF EXISTS "Avatar images are publicly accessible"        ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own avatar"            ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar"            ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatar"            ON storage.objects;

-- ─── RECREATE ALL POLICIES ────────────────────────────────────────────────────

-- PROFILES
CREATE POLICY "Public profiles are viewable by anyone" ON public.profiles
  FOR SELECT USING (true);
CREATE POLICY "Users can update their own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- POSTS
CREATE POLICY "Active posts are viewable by anyone" ON public.posts
  FOR SELECT USING (is_active = true);
CREATE POLICY "Authenticated users can create posts" ON public.posts
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own posts" ON public.posts
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own posts" ON public.posts
  FOR DELETE USING (auth.uid() = user_id);

-- LIKES
CREATE POLICY "Likes are viewable by anyone" ON public.likes
  FOR SELECT USING (true);
CREATE POLICY "Authenticated users can like" ON public.likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can unlike their own likes" ON public.likes
  FOR DELETE USING (auth.uid() = user_id);

-- COMMENTS
CREATE POLICY "Active comments are viewable by anyone" ON public.comments
  FOR SELECT USING (is_active = true);
CREATE POLICY "Authenticated users can comment" ON public.comments
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own comments" ON public.comments
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own comments" ON public.comments
  FOR DELETE USING (auth.uid() = user_id);

-- CONNECTION REQUESTS
CREATE POLICY "Users can see their own requests" ON public.connection_requests
  FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
CREATE POLICY "Authenticated users can send requests" ON public.connection_requests
  FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "Receivers can update request status" ON public.connection_requests
  FOR UPDATE USING (auth.uid() = receiver_id);

-- REPORTS
CREATE POLICY "Users can create reports" ON public.reports
  FOR INSERT WITH CHECK (auth.uid() = reporter_id);
CREATE POLICY "Users can view their own reports" ON public.reports
  FOR SELECT USING (auth.uid() = reporter_id);

-- BLOCKED USERS
CREATE POLICY "Users can view their own blocks" ON public.blocked_users
  FOR SELECT USING (auth.uid() = blocker_id);
CREATE POLICY "Users can block others" ON public.blocked_users
  FOR INSERT WITH CHECK (auth.uid() = blocker_id);
CREATE POLICY "Users can unblock" ON public.blocked_users
  FOR DELETE USING (auth.uid() = blocker_id);

-- VENUE EVENTS
CREATE POLICY "Venue events are public" ON public.venue_events
  FOR SELECT USING (is_active = true);

-- ─── STORAGE BUCKET ───────────────────────────────────────────────────────────

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars', 'avatars', true, 5242880,
  ARRAY['image/jpeg','image/png','image/webp','image/gif']
) ON CONFLICT DO NOTHING;

CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can update their own avatar" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete their own avatar" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
