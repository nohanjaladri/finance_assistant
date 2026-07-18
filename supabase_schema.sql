  -- ============================================
  -- SUPABASE SCHEMA - Dompetku AI v2.0 (Public Schema)
  -- Jalankan di Supabase Dashboard → SQL Editor
  -- ============================================

  -- ============================================
  -- 1. TABEL PROFILES
  -- ============================================
  CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    display_name TEXT,
    room_code TEXT UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );

  -- Trigger: auto-buat profile saat user baru register
  CREATE OR REPLACE FUNCTION public.handle_new_user()
  RETURNS TRIGGER AS $$
  DECLARE
    new_code TEXT;
    code_exists BOOLEAN;
  BEGIN
    -- Generate kode ruangan unik 6 karakter
    LOOP
      new_code := upper(substring(md5(random()::text), 1, 6));
      SELECT EXISTS (SELECT 1 FROM public.profiles WHERE room_code = new_code) INTO code_exists;
      EXIT WHEN NOT code_exists;
    END LOOP;

    INSERT INTO public.profiles (id, email, room_code)
    VALUES (new.id, new.email, new_code);
    RETURN new;
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  -- Pastikan trigger bersih dari duplikasi
  DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
  CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

  -- ============================================
  -- 2. TABEL ROOMS (Dompet Bersama)
  -- ============================================
  CREATE TABLE IF NOT EXISTS public.rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    room_code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL DEFAULT 'Dompet Bersama',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );

  -- ============================================
  -- 3. TABEL ROOM MEMBERS
  -- ============================================
  CREATE TABLE IF NOT EXISTS public.room_members (
    id BIGSERIAL PRIMARY KEY,
    room_id UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'member')),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(room_id, user_id)
  );

  -- ============================================
  -- 4. TABEL TRANSACTIONS (Transaksi Utama)
  -- ============================================
  CREATE TABLE IF NOT EXISTS public.transactions (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    room_id UUID REFERENCES public.rooms(id) ON DELETE SET NULL,  -- NULL = personal
    amount INTEGER NOT NULL CHECK (amount > 0),
    note TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('IN', 'OUT')),
    category TEXT NOT NULL DEFAULT 'Other',
    payment_method TEXT NOT NULL DEFAULT 'tunai' CHECK (payment_method IN ('tunai', 'non_tunai')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );

  -- ============================================
  -- 5. TABEL PENDING REQUESTS
  -- ============================================
  CREATE TABLE IF NOT EXISTS public.pending_requests (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    room_id UUID REFERENCES public.rooms(id) ON DELETE SET NULL,
    original_input TEXT NOT NULL,
    nama TEXT,
    nominal INTEGER,
    quantity INTEGER NOT NULL DEFAULT 1,
    missing_fields JSONB NOT NULL DEFAULT '[]',
    partial_data JSONB NOT NULL DEFAULT '{}',
    ai_question TEXT NOT NULL DEFAULT '',
    reason TEXT NOT NULL DEFAULT '',
    category TEXT NOT NULL DEFAULT 'Other',
    type TEXT NOT NULL DEFAULT 'OUT' CHECK (type IN ('IN', 'OUT')),
    payment_method TEXT NOT NULL DEFAULT 'tunai' CHECK (payment_method IN ('tunai', 'non_tunai')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'done', 'cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );

  -- ============================================
  -- 6. TABEL CHAT MESSAGES
  -- ============================================
  CREATE TABLE IF NOT EXISTS public.chat_messages (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    room_id UUID REFERENCES public.rooms(id) ON DELETE SET NULL,
    chat_type TEXT NOT NULL DEFAULT 'tunai' CHECK (chat_type IN ('tunai', 'non_tunai')),
    text TEXT NOT NULL,
    is_ai BOOLEAN NOT NULL DEFAULT FALSE,
    confirm_msg TEXT,
    confirm_cmd TEXT,
    receipt_data JSONB,
    query_result JSONB,
    viz_type TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );

  -- ============================================
  -- 7. HELPER FUNCTIONS & ROW LEVEL SECURITY (RLS)
  -- ============================================

  -- Fungsi helper SECURITY DEFINER untuk memutus rekursi tak terbatas (infinite recursion) pada RLS
  CREATE OR REPLACE FUNCTION public.is_room_member(r_id UUID, u_id UUID)
  RETURNS BOOLEAN AS $$
  BEGIN
    RETURN EXISTS (
      SELECT 1 FROM public.room_members
      WHERE room_id = r_id AND user_id = u_id
    );
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  CREATE OR REPLACE FUNCTION public.is_room_owner(r_id UUID, u_id UUID)
  RETURNS BOOLEAN AS $$
  BEGIN
    RETURN EXISTS (
      SELECT 1 FROM public.rooms
      WHERE id = r_id AND owner_id = u_id
    );
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  -- Enable RLS on semua tabel
  ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.room_members ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.pending_requests ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

  -- PROFILES: user hanya bisa lihat & edit profil sendiri
  DROP POLICY IF EXISTS profiles_self_access ON public.profiles;
  CREATE POLICY profiles_self_access ON public.profiles
    FOR ALL USING (auth.uid() = id);

  -- ROOMS: owner bisa kelola, member bisa lihat
  DROP POLICY IF EXISTS rooms_owner_access ON public.rooms;
  CREATE POLICY rooms_owner_access ON public.rooms
    FOR ALL USING (auth.uid() = owner_id);

  DROP POLICY IF EXISTS rooms_member_read ON public.rooms;
  CREATE POLICY rooms_member_read ON public.rooms
    FOR SELECT USING (
      public.is_room_member(id, auth.uid())
    );

  -- ROOM_MEMBERS: akses untuk member dan owner room
  DROP POLICY IF EXISTS room_members_access ON public.room_members;
  CREATE POLICY room_members_access ON public.room_members
    FOR ALL USING (
      user_id = auth.uid() OR
      public.is_room_owner(room_id, auth.uid())
    );

  -- TRANSACTIONS: personal (room_id IS NULL) → hanya diri sendiri
  DROP POLICY IF EXISTS transactions_personal ON public.transactions;
  CREATE POLICY transactions_personal ON public.transactions
    FOR ALL USING (
      user_id = auth.uid() AND room_id IS NULL
    );

  DROP POLICY IF EXISTS transactions_shared_read ON public.transactions;
  CREATE POLICY transactions_shared_read ON public.transactions
    FOR SELECT USING (
      room_id IS NOT NULL AND
      public.is_room_member(room_id, auth.uid())
    );

  DROP POLICY IF EXISTS transactions_shared_insert ON public.transactions;
  CREATE POLICY transactions_shared_insert ON public.transactions
    FOR INSERT WITH CHECK (
      user_id = auth.uid() AND (
        room_id IS NULL OR
        public.is_room_member(room_id, auth.uid())
      )
    );

  DROP POLICY IF EXISTS transactions_shared_update_delete ON public.transactions;
  CREATE POLICY transactions_shared_update_delete ON public.transactions
    FOR UPDATE USING (user_id = auth.uid());

  DROP POLICY IF EXISTS transactions_shared_delete ON public.transactions;
  CREATE POLICY transactions_shared_delete ON public.transactions
    FOR DELETE USING (user_id = auth.uid());

  -- PENDING REQUESTS
  DROP POLICY IF EXISTS pending_personal ON public.pending_requests;
  CREATE POLICY pending_personal ON public.pending_requests
    FOR ALL USING (user_id = auth.uid());

  -- CHAT MESSAGES
  DROP POLICY IF EXISTS chat_personal ON public.chat_messages;
  CREATE POLICY chat_personal ON public.chat_messages
    FOR ALL USING (user_id = auth.uid());

  DROP POLICY IF EXISTS chat_shared_read ON public.chat_messages;
  CREATE POLICY chat_shared_read ON public.chat_messages
    FOR SELECT USING (
      room_id IS NOT NULL AND
      public.is_room_member(room_id, auth.uid())
    );

  -- ============================================
  -- 8. INDEXES UNTUK PERFORMA
  -- ============================================
  CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON public.transactions(user_id);
  CREATE INDEX IF NOT EXISTS idx_transactions_room_id ON public.transactions(room_id);
  CREATE INDEX IF NOT EXISTS idx_transactions_payment_method ON public.transactions(payment_method);
  CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON public.transactions(created_at DESC);
  CREATE INDEX IF NOT EXISTS idx_transactions_type ON public.transactions(type);
  CREATE INDEX IF NOT EXISTS idx_pending_user_status ON public.pending_requests(user_id, status);
  CREATE INDEX IF NOT EXISTS idx_chat_user_created ON public.chat_messages(user_id, created_at DESC);
  CREATE INDEX IF NOT EXISTS idx_room_members_user ON public.room_members(user_id);
