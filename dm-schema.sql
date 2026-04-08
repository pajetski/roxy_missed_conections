-- ============================================================
-- ROXY MISSED CONNECTIONS — Direct Messaging Schema
-- Safe to re-run in Supabase SQL editor
-- ============================================================

-- CONVERSATIONS (one per pair, created on wave acceptance)
CREATE TABLE IF NOT EXISTS public.conversations (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_one   uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  user_two   uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE (user_one, user_two)
);

-- MESSAGES
CREATE TABLE IF NOT EXISTS public.messages (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id       uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  body            text NOT NULL CHECK (char_length(body) <= 1000),
  created_at      timestamptz DEFAULT now(),
  is_deleted      boolean DEFAULT false
);

-- MESSAGE READS (for unread tracking — no read receipts exposed to other user)
CREATE TABLE IF NOT EXISTS public.message_reads (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id         uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  last_read_at    timestamptz DEFAULT now(),
  UNIQUE (conversation_id, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS conversations_user_one_idx        ON public.conversations (user_one);
CREATE INDEX IF NOT EXISTS conversations_user_two_idx        ON public.conversations (user_two);
CREATE INDEX IF NOT EXISTS messages_conv_created_at_idx      ON public.messages (conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS messages_sender_id_idx            ON public.messages (sender_id);
CREATE INDEX IF NOT EXISTS message_reads_user_id_idx         ON public.message_reads (user_id);

-- Enable RLS
ALTER TABLE public.conversations  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_reads  ENABLE ROW LEVEL SECURITY;

-- Drop existing policies (safe re-run)
DROP POLICY IF EXISTS "Users can see their own conversations"          ON public.conversations;
DROP POLICY IF EXISTS "Users can create conversations"                 ON public.conversations;
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON public.messages;
DROP POLICY IF EXISTS "Users can send messages in their conversations" ON public.messages;
DROP POLICY IF EXISTS "Users can view their own read markers"          ON public.message_reads;
DROP POLICY IF EXISTS "Users can upsert their own read markers"        ON public.message_reads;

-- Conversation policies
CREATE POLICY "Users can see their own conversations"
ON public.conversations FOR SELECT
USING (auth.uid() = user_one OR auth.uid() = user_two);

CREATE POLICY "Users can create conversations"
ON public.conversations FOR INSERT
WITH CHECK (auth.uid() = user_one OR auth.uid() = user_two);

-- Message policies
CREATE POLICY "Users can view messages in their conversations"
ON public.messages FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.conversations c
    WHERE c.id = conversation_id
      AND (c.user_one = auth.uid() OR c.user_two = auth.uid())
  )
);

CREATE POLICY "Users can send messages in their conversations"
ON public.messages FOR INSERT
WITH CHECK (
  auth.uid() = sender_id
  AND EXISTS (
    SELECT 1 FROM public.conversations c
    WHERE c.id = conversation_id
      AND (c.user_one = auth.uid() OR c.user_two = auth.uid())
  )
);

-- Message reads policies
CREATE POLICY "Users can view their own read markers"
ON public.message_reads FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can upsert their own read markers"
ON public.message_reads FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (
  auth.uid() = user_id
  AND EXISTS (
    SELECT 1 FROM public.conversations c
    WHERE c.id = conversation_id
      AND (c.user_one = auth.uid() OR c.user_two = auth.uid())
  )
);
