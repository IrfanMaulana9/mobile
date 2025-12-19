-- ============================================
-- SQL Script Lengkap untuk Database Supabase
-- Cleaning Service Application
-- ============================================
-- Script ini akan membuat/memperbaiki semua tabel yang diperlukan
-- Jalankan script ini di Supabase SQL Editor
-- ============================================

-- ============================================
-- 1. TABEL PROMOTIONS (Jika belum ada)
-- ============================================
CREATE TABLE IF NOT EXISTS public.promotions (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    service_name TEXT NOT NULL,
    original_price DECIMAL(10, 2) NOT NULL,
    promo_price DECIMAL(10, 2) NOT NULL,
    discount_percentage INTEGER NOT NULL CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    badge TEXT,
    icon_name TEXT, -- Nama icon (untuk mapping ke IconData)
    color_hex TEXT, -- Hex color code
    terms JSONB, -- Array of strings untuk terms & conditions
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_date_range CHECK (end_date > start_date)
);

-- Index untuk promotions
CREATE INDEX IF NOT EXISTS idx_promotions_service_name ON public.promotions(service_name);
CREATE INDEX IF NOT EXISTS idx_promotions_dates ON public.promotions(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_promotions_active ON public.promotions(is_active) WHERE is_active = true;

-- RLS untuk promotions
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to promotions" ON public.promotions
    FOR SELECT
    USING (true);

CREATE POLICY "Allow admin insert promotions" ON public.promotions
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- ============================================
-- 2. PERBAIKAN TABEL BOOKINGS (Jika perlu)
-- ============================================
-- Pastikan tabel bookings memiliki semua kolom yang diperlukan
DO $$ 
BEGIN
    -- Tambah kolom photo_urls jika belum ada
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'bookings' 
        AND column_name = 'photo_urls'
    ) THEN
        ALTER TABLE public.bookings 
        ADD COLUMN photo_urls JSONB DEFAULT '[]'::jsonb;
    END IF;

    -- Tambah kolom notes jika belum ada
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'bookings' 
        AND column_name = 'notes'
    ) THEN
        ALTER TABLE public.bookings 
        ADD COLUMN notes TEXT;
    END IF;

    -- Tambah kolom user_id jika belum ada
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'bookings' 
        AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.bookings 
        ADD COLUMN user_id TEXT;
    END IF;

    -- Tambah kolom updated_at jika belum ada
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'bookings' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.bookings 
        ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
END $$;

-- Index untuk bookings
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON public.bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON public.bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_booking_date ON public.bookings(booking_date);
CREATE INDEX IF NOT EXISTS idx_bookings_created_at ON public.bookings(created_at DESC);

-- ============================================
-- 3. PERBAIKAN TABEL NOTES (Jika perlu)
-- ============================================
DO $$ 
BEGIN
    -- Tambah kolom image_urls jika belum ada
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'notes' 
        AND column_name = 'image_urls'
    ) THEN
        ALTER TABLE public.notes 
        ADD COLUMN image_urls JSONB DEFAULT '[]'::jsonb;
    END IF;

    -- Tambah kolom booking_id jika belum ada (nullable untuk standalone notes)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'notes' 
        AND column_name = 'booking_id'
    ) THEN
        ALTER TABLE public.notes 
        ADD COLUMN booking_id TEXT;
    END IF;

    -- Tambah kolom updated_at jika belum ada
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'notes' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.notes 
        ADD COLUMN updated_at TIMESTAMPTZ;
    END IF;
END $$;

-- Index untuk notes
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON public.notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_booking_id ON public.notes(booking_id) WHERE booking_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_notes_created_at ON public.notes(created_at DESC);

-- ============================================
-- 4. TABEL NOTIFICATIONS (History)
-- ============================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT, -- 'promo', 'booking', 'system', etc.
    payload JSONB, -- Additional data
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index untuk notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications(user_id, is_read) WHERE is_read = false;

-- RLS untuk notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own notifications" ON public.notifications
    FOR SELECT
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can update own notifications" ON public.notifications
    FOR UPDATE
    USING (auth.uid()::text = user_id);

CREATE POLICY "System can insert notifications" ON public.notifications
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- ============================================
-- 5. TABEL USER PROFILES (Extended user info)
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL UNIQUE, -- Link ke auth.users
    full_name TEXT,
    phone_number TEXT,
    address TEXT,
    avatar_url TEXT,
    preferred_language TEXT DEFAULT 'id',
    notification_preferences JSONB DEFAULT '{"promo": true, "booking": true, "system": true}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index untuk user_profiles
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);

-- RLS untuk user_profiles
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile" ON public.user_profiles
    FOR SELECT
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE
    USING (auth.uid()::text = user_id)
    WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT
    WITH CHECK (auth.uid()::text = user_id);

-- ============================================
-- 6. TABEL BOOKING STATUS HISTORY (Tracking)
-- ============================================
CREATE TABLE IF NOT EXISTS public.booking_status_history (
    id TEXT PRIMARY KEY,
    booking_id TEXT NOT NULL,
    status TEXT NOT NULL, -- 'pending', 'confirmed', 'in_progress', 'completed', 'cancelled'
    changed_by TEXT, -- user_id yang mengubah status
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index untuk booking_status_history
CREATE INDEX IF NOT EXISTS idx_booking_status_history_booking_id ON public.booking_status_history(booking_id);
CREATE INDEX IF NOT EXISTS idx_booking_status_history_created_at ON public.booking_status_history(created_at DESC);

-- RLS untuk booking_status_history
ALTER TABLE public.booking_status_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read booking status history" ON public.booking_status_history
    FOR SELECT
    USING (true); -- Bisa dibaca semua user yang authenticated

-- ============================================
-- 7. TRIGGERS untuk auto-update updated_at
-- ============================================

-- Function untuk update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger untuk bookings
DROP TRIGGER IF EXISTS update_bookings_updated_at ON public.bookings;
CREATE TRIGGER update_bookings_updated_at
    BEFORE UPDATE ON public.bookings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger untuk notes
DROP TRIGGER IF EXISTS update_notes_updated_at ON public.notes;
CREATE TRIGGER update_notes_updated_at
    BEFORE UPDATE ON public.notes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger untuk promotions
DROP TRIGGER IF EXISTS update_promotions_updated_at ON public.promotions;
CREATE TRIGGER update_promotions_updated_at
    BEFORE UPDATE ON public.promotions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger untuk user_profiles
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 8. VIEWS untuk kemudahan query
-- ============================================

-- View untuk active promotions
CREATE OR REPLACE VIEW public.active_promotions AS
SELECT * FROM public.promotions
WHERE is_active = true 
  AND start_date <= NOW() 
  AND end_date >= NOW();

-- View untuk booking dengan status
CREATE OR REPLACE VIEW public.bookings_with_status AS
SELECT 
    b.*,
    COUNT(bsh.id) as status_change_count,
    MAX(bsh.created_at) as last_status_change
FROM public.bookings b
LEFT JOIN public.booking_status_history bsh ON b.id = bsh.booking_id
GROUP BY b.id;

-- ============================================
-- 9. FUNCTIONS untuk business logic
-- ============================================

-- Function untuk mendapatkan unread notification count
CREATE OR REPLACE FUNCTION get_unread_notification_count(p_user_id TEXT)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)::INTEGER
        FROM public.notifications
        WHERE user_id = p_user_id AND is_read = false
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function untuk mark all notifications as read
CREATE OR REPLACE FUNCTION mark_all_notifications_read(p_user_id TEXT)
RETURNS INTEGER AS $$
BEGIN
    UPDATE public.notifications
    SET is_read = true
    WHERE user_id = p_user_id AND is_read = false;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 10. INSERT SAMPLE DATA (Optional)
-- ============================================

-- Insert sample promotions (jika tabel kosong)
INSERT INTO public.promotions (
    id, title, description, service_name, 
    original_price, promo_price, discount_percentage,
    start_date, end_date, badge, icon_name, color_hex, terms
) VALUES
(
    '1',
    'Deep Cleaning Hemat 40%',
    'Dapatkan layanan pembersihan mendalam dengan harga spesial',
    'Deep Cleaning',
    500000.00,
    300000.00,
    40,
    NOW() - INTERVAL '2 days',
    NOW() + INTERVAL '5 days',
    'Flash Sale',
    'spa',
    '#6C5FE8',
    '["Berlaku untuk area maksimal 200m²", "Minimal pemesanan 2 jam", "Garansi kepuasan 100%"]'::jsonb
),
(
    '2',
    'Indoor Cleaning Diskon 35%',
    'Bersihkan rumah Anda dengan tim profesional kami',
    'Indoor Cleaning',
    350000.00,
    227500.00,
    35,
    NOW() - INTERVAL '5 days',
    NOW() + INTERVAL '10 days',
    'Limited Time',
    'home',
    '#1AA5D4',
    '["Berlaku untuk area maksimal 150m²", "Gratis konsultasi sebelum pembersihan", "Produk ramah lingkungan digunakan"]'::jsonb
)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- CATATAN PENTING:
-- ============================================
-- 1. Script ini akan:
--    - Membuat tabel baru jika belum ada
--    - Menambahkan kolom yang kurang pada tabel yang sudah ada
--    - Membuat index untuk performa
--    - Setup RLS (Row Level Security)
--    - Membuat triggers untuk auto-update
--    - Membuat views dan functions
--
-- 2. Tabel yang dibuat/diperbaiki:
--    - promotions (baru)
--    - bookings (diperbaiki)
--    - notes (diperbaiki)
--    - notifications (baru)
--    - user_profiles (baru)
--    - booking_status_history (baru)
--    - rating_reviews (sudah ada script terpisah)
--
-- 3. Pastikan rating_reviews sudah dibuat dengan script terpisah
--
-- 4. Setelah menjalankan script ini:
--    - Cek apakah semua tabel berhasil dibuat
--    - Test RLS policies
--    - Verify indexes sudah dibuat
--
-- CARA MENGGUNAKAN:
-- 1. Buka Supabase Dashboard
-- 2. Pilih project Anda
-- 3. Buka SQL Editor
-- 4. Copy-paste script ini
-- 5. Klik Run atau Execute
-- 6. Pastikan tidak ada error
-- 7. Cek Table Editor untuk memastikan semua tabel sudah ada
-- ============================================

