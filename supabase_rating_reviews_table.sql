-- ============================================
-- SQL Script untuk Membuat Tabel rating_reviews
-- Supabase Database
-- ============================================

-- 1. Buat tabel rating_reviews
CREATE TABLE IF NOT EXISTS public.rating_reviews (
    id TEXT PRIMARY KEY,
    booking_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    customer_name TEXT NOT NULL,
    service_name TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Buat index untuk performa query
CREATE INDEX IF NOT EXISTS idx_rating_reviews_booking_id ON public.rating_reviews(booking_id);
CREATE INDEX IF NOT EXISTS idx_rating_reviews_user_id ON public.rating_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_rating_reviews_created_at ON public.rating_reviews(created_at DESC);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.rating_reviews ENABLE ROW LEVEL SECURITY;

-- 4. Buat policy untuk SELECT (semua user bisa membaca)
CREATE POLICY "Allow public read access" ON public.rating_reviews
    FOR SELECT
    USING (true);

-- 5. Buat policy untuk INSERT (hanya authenticated user)
CREATE POLICY "Allow authenticated insert" ON public.rating_reviews
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- 6. Buat policy untuk UPDATE (hanya user yang membuat rating)
CREATE POLICY "Allow users to update own ratings" ON public.rating_reviews
    FOR UPDATE
    USING (auth.uid()::text = user_id)
    WITH CHECK (auth.uid()::text = user_id);

-- 7. Buat policy untuk DELETE (hanya user yang membuat rating)
CREATE POLICY "Allow users to delete own ratings" ON public.rating_reviews
    FOR DELETE
    USING (auth.uid()::text = user_id);

-- 8. Buat trigger untuk auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_rating_reviews_updated_at
    BEFORE UPDATE ON public.rating_reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 9. Buat constraint untuk memastikan satu user hanya bisa rating sekali per booking
CREATE UNIQUE INDEX IF NOT EXISTS idx_rating_reviews_unique_booking_user 
ON public.rating_reviews(booking_id, user_id);

-- ============================================
-- CATATAN PENTING:
-- ============================================
-- 1. Script ini akan membuat tabel rating_reviews dengan struktur yang sesuai
-- 2. RLS (Row Level Security) diaktifkan untuk keamanan
-- 3. Semua user bisa membaca rating (public read)
-- 4. Hanya authenticated user yang bisa insert
-- 5. User hanya bisa update/delete rating mereka sendiri
-- 6. Satu user hanya bisa memberikan 1 rating per booking (unique constraint)
-- 7. Rating harus antara 1-5 (check constraint)
-- 
-- CARA MENGGUNAKAN:
-- 1. Buka Supabase Dashboard
-- 2. Pilih project Anda
-- 3. Buka SQL Editor
-- 4. Copy-paste script ini
-- 5. Klik Run atau Execute
-- 6. Pastikan tidak ada error
-- ============================================

