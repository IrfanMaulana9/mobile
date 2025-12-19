-- ============================================
-- SQL Script untuk Membuat Tabel payments
-- Supabase Database - Xendit Payment Integration
-- ============================================

-- 1. Buat tabel payments
CREATE TABLE IF NOT EXISTS public.payments (
    id TEXT PRIMARY KEY,
    booking_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method TEXT NOT NULL, -- 'BANK_TRANSFER', 'QRIS', 'OVO', 'DANA', 'LINKAJA', 'SHOPEEPAY'
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'paid', 'expired', 'failed', 'cancelled'
    xendit_invoice_id TEXT,
    xendit_payment_id TEXT,
    payment_url TEXT,
    qr_code TEXT,
    expiry_date TIMESTAMPTZ,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB,
    CONSTRAINT valid_status CHECK (status IN ('pending', 'paid', 'expired', 'failed', 'cancelled')),
    CONSTRAINT valid_payment_method CHECK (payment_method IN ('BANK_TRANSFER', 'QRIS', 'OVO', 'DANA', 'LINKAJA', 'SHOPEEPAY'))
);

-- 2. Buat index untuk performa query
CREATE INDEX IF NOT EXISTS idx_payments_booking_id ON public.payments(booking_id);
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON public.payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON public.payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON public.payments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payments_xendit_invoice_id ON public.payments(xendit_invoice_id) WHERE xendit_invoice_id IS NOT NULL;

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- 4. Buat policy untuk SELECT (user hanya bisa lihat payment mereka sendiri)
CREATE POLICY "Users can read own payments" ON public.payments
    FOR SELECT
    USING (auth.uid()::text = user_id);

-- 5. Buat policy untuk INSERT (hanya authenticated user)
CREATE POLICY "Users can insert own payments" ON public.payments
    FOR INSERT
    WITH CHECK (auth.uid()::text = user_id);

-- 6. Buat policy untuk UPDATE (hanya user yang membuat payment atau system)
CREATE POLICY "Users can update own payments" ON public.payments
    FOR UPDATE
    USING (auth.uid()::text = user_id)
    WITH CHECK (auth.uid()::text = user_id);

-- 7. Buat trigger untuk auto-update updated_at
CREATE OR REPLACE FUNCTION update_payments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_payments_updated_at
    BEFORE UPDATE ON public.payments
    FOR EACH ROW
    EXECUTE FUNCTION update_payments_updated_at();

-- 8. Buat function untuk update booking status setelah payment paid
CREATE OR REPLACE FUNCTION update_booking_after_payment()
RETURNS TRIGGER AS $$
BEGIN
    -- Update booking status menjadi 'confirmed' jika payment status menjadi 'paid'
    IF NEW.status = 'paid' AND OLD.status != 'paid' THEN
        UPDATE public.bookings
        SET status = 'confirmed',
            updated_at = NOW()
        WHERE id = NEW.booking_id;
        
        RAISE NOTICE 'Booking % status updated to confirmed', NEW.booking_id;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_update_booking_after_payment
    AFTER UPDATE OF status ON public.payments
    FOR EACH ROW
    WHEN (NEW.status = 'paid' AND OLD.status != 'paid')
    EXECUTE FUNCTION update_booking_after_payment();

-- 9. Buat view untuk payment dengan booking info
CREATE OR REPLACE VIEW public.payments_with_booking AS
SELECT 
    p.*,
    b.customer_name,
    b.service_name,
    b.address,
    b.booking_date,
    b.booking_time
FROM public.payments p
LEFT JOIN public.bookings b ON p.booking_id = b.id;

-- 10. Buat function untuk mendapatkan total revenue
CREATE OR REPLACE FUNCTION get_total_revenue(p_user_id TEXT DEFAULT NULL)
RETURNS DECIMAL AS $$
BEGIN
    IF p_user_id IS NULL THEN
        RETURN (
            SELECT COALESCE(SUM(amount), 0)
            FROM public.payments
            WHERE status = 'paid'
        );
    ELSE
        RETURN (
            SELECT COALESCE(SUM(amount), 0)
            FROM public.payments
            WHERE status = 'paid' AND user_id = p_user_id
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- CATATAN PENTING:
-- ============================================
-- 1. Tabel payments akan menyimpan semua data pembayaran
-- 2. RLS diaktifkan untuk keamanan - user hanya bisa akses payment mereka sendiri
-- 3. Trigger otomatis update booking status menjadi 'confirmed' saat payment paid
-- 4. Index dibuat untuk performa query yang optimal
-- 5. View payments_with_booking untuk kemudahan query dengan info booking
-- 6. Function get_total_revenue untuk menghitung total revenue
--
-- CARA MENGGUNAKAN:
-- 1. Buka Supabase Dashboard
-- 2. Pilih project Anda
-- 3. Buka SQL Editor
-- 4. Copy-paste script ini
-- 5. Klik Run atau Execute
-- 6. Pastikan tidak ada error
-- 7. Cek Table Editor untuk memastikan tabel payments sudah ada
-- ============================================

