-- ==========================================================
-- SEED DATA FOR TESTING (3 Months back: 2026-04-22 s/d 2026-07-21)
-- ==========================================================

DO $$
DECLARE
    -- GANTI UUID DI BAWAH INI DENGAN USER ID ANDA DARI TABLE auth.users
    v_user_id UUID := '0c732da4-39e4-45f1-8a64-984d66baadf0';
    v_tx_id BIGINT;
BEGIN
    RAISE NOTICE 'Memulai seeding data...';

    -- Transaksi: Perlengkapan Mandi Bulanan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 55400, 'Perlengkapan Mandi Bulanan', 'OUT', 'Groceries', 'tunai', '2026-04-22 11:31:39+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sabun Cair', 21500, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Shampoo 170ml', 23100, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Pasta Gigi', 10800, 1);

    -- Transaksi: Sarapan Bubur Ayam
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 21700, 'Sarapan Bubur Ayam', 'OUT', 'Food', 'tunai', '2026-04-22 21:38:29+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Bubur Ayam Komplit', 15700, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sate Usus', 3000, 2);

    -- Transaksi: Makan siang Bakso & Es Teh
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 21500, 'Makan siang Bakso & Es Teh', 'OUT', 'Food', 'non_tunai', '2026-04-23 12:50:03+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Bakso Urat', 17000, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Es Teh Manis', 4500, 1);

    -- Transaksi: Aksesoris Handphone
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 108600, 'Aksesoris Handphone', 'OUT', 'Shopping', 'non_tunai', '2026-04-23 12:00:27+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Casing HP', 44500, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kabel Charger', 64100, 1);

    -- Transaksi: Bensin Mobil
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 180800, 'Bensin Mobil', 'OUT', 'Transport', 'non_tunai', '2026-04-24 12:16:29+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Pertalite Mobil', 180800, 1);

    -- Transaksi: Camilan Siang Minimarket
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 32800, 'Camilan Siang Minimarket', 'OUT', 'Food', 'tunai', '2026-04-24 15:05:11+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Keripik Kentang', 12700, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Cokelat Bar', 7400, 1);

    -- Transaksi: Gaji Bulanan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 7500000, 'Gaji Bulanan', 'IN', 'Salary', 'non_tunai', '2026-04-25 08:00:00+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Gaji Bulanan', 7500000, 1);

    -- Transaksi: Skin Care Bulanan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 107800, 'Skin Care Bulanan', 'OUT', 'Shopping', 'tunai', '2026-04-25 10:56:10+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Face Wash', 42100, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sunscreen', 65700, 1);

    -- Transaksi: Pulsa & Paket Internet
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 122900, 'Pulsa & Paket Internet', 'OUT', 'Other', 'tunai', '2026-04-26 20:25:24+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Paket Data 50GB', 122900, 1);

    -- Transaksi: Kopi Susu Senja
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 37000, 'Kopi Susu Senja', 'OUT', 'Food', 'tunai', '2026-04-26 15:42:25+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Es Kopi Susu', 18500, 2);

    -- Transaksi: Sarapan Bubur Ayam
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 20700, 'Sarapan Bubur Ayam', 'OUT', 'Food', 'tunai', '2026-04-26 18:07:32+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Bubur Ayam Komplit', 14300, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sate Usus', 3200, 2);

    -- Transaksi: Beli Obat di Apotek
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 69600, 'Beli Obat di Apotek', 'OUT', 'Other', 'tunai', '2026-04-27 10:07:29+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Vitamin C', 53800, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Obat Flu', 15800, 1);

    -- Transaksi: Beli Buku Bacaan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 98100, 'Beli Buku Bacaan', 'OUT', 'Shopping', 'tunai', '2026-04-27 21:58:49+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Buku Novel', 98100, 1);

    -- Transaksi: Bayar Listrik Bulanan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 238200, 'Bayar Listrik Bulanan', 'OUT', 'Other', 'non_tunai', '2026-04-27 12:49:17+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Tagihan Listrik PLN', 238200, 1);

    -- Transaksi: Nonton Bioskop Weekend
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 125700, 'Nonton Bioskop Weekend', 'OUT', 'Other', 'tunai', '2026-04-28 21:21:47+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Tiket Bioskop', 46900, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Popcorn Large', 31900, 1);

    -- Transaksi: Isi Saldo e-Money
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 104000, 'Isi Saldo e-Money', 'OUT', 'Transport', 'non_tunai', '2026-04-28 12:47:59+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Top up e-Money', 104000, 1);

    -- Transaksi: Beli Buku Bacaan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 93800, 'Beli Buku Bacaan', 'OUT', 'Shopping', 'tunai', '2026-04-29 10:10:37+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Buku Novel', 93800, 1);

    -- Transaksi: Camilan Siang Minimarket
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 30500, 'Camilan Siang Minimarket', 'OUT', 'Food', 'tunai', '2026-04-29 11:33:34+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Keripik Kentang', 10900, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Cokelat Bar', 8700, 1);

    -- Transaksi: Bensin Mobil
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 207400, 'Bensin Mobil', 'OUT', 'Transport', 'tunai', '2026-04-29 18:26:01+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Pertalite Mobil', 207400, 1);

    -- Transaksi: Camilan Siang Minimarket
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 30900, 'Camilan Siang Minimarket', 'OUT', 'Food', 'non_tunai', '2026-04-30 20:35:29+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Keripik Kentang', 11300, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Cokelat Bar', 8300, 1);

    -- Transaksi: Kopi Susu Senja
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 33800, 'Kopi Susu Senja', 'OUT', 'Food', 'non_tunai', '2026-04-30 12:54:20+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Es Kopi Susu', 16900, 2);

    -- Transaksi: Makan siang Bakso & Es Teh
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 22400, 'Makan siang Bakso & Es Teh', 'OUT', 'Food', 'non_tunai', '2026-05-01 09:44:21+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Bakso Urat', 17700, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Es Teh Manis', 4700, 1);

    -- Transaksi: Belanja Mingguan Sayur & Buah
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 41700, 'Belanja Mingguan Sayur & Buah', 'OUT', 'Groceries', 'non_tunai', '2026-05-01 12:33:05+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Apel Merah', 23400, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sayur Bayam', 5100, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Wortel', 8100, 1);

    -- Transaksi: Kebutuhan Dapur Indomaret
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 117300, 'Kebutuhan Dapur Indomaret', 'OUT', 'Groceries', 'tunai', '2026-05-01 09:15:26+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Minyak Goreng 2L', 36300, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Beras 5kg', 63700, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Gula Pasir 1kg', 17300, 1);

    -- Transaksi: Kebutuhan Dapur Indomaret
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 116800, 'Kebutuhan Dapur Indomaret', 'OUT', 'Groceries', 'non_tunai', '2026-05-02 12:41:31+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Minyak Goreng 2L', 32600, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Beras 5kg', 69400, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Gula Pasir 1kg', 14800, 1);

    -- Transaksi: Bonus Kinerja
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 1000000, 'Bonus Kinerja', 'IN', 'Salary', 'non_tunai', '2026-05-03 13:00:00+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Bonus Kinerja', 1000000, 1);

    -- Transaksi: Pulsa & Paket Internet
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 120700, 'Pulsa & Paket Internet', 'OUT', 'Other', 'tunai', '2026-05-03 16:00:23+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Paket Data 50GB', 120700, 1);

    -- Transaksi: Sarapan Bubur Ayam
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 19500, 'Sarapan Bubur Ayam', 'OUT', 'Food', 'non_tunai', '2026-05-04 21:23:56+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Bubur Ayam Komplit', 14100, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sate Usus', 2700, 2);

    -- Transaksi: Nonton Bioskop Weekend
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 123700, 'Nonton Bioskop Weekend', 'OUT', 'Other', 'tunai', '2026-05-05 16:56:24+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Tiket Bioskop', 44400, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Popcorn Large', 34900, 1);

    -- Transaksi: Gojek ke Kantor
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 14800, 'Gojek ke Kantor', 'OUT', 'Transport', 'tunai', '2026-05-05 11:19:18+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'GoRide', 14800, 1);

    -- Transaksi: Camilan Siang Minimarket
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 33000, 'Camilan Siang Minimarket', 'OUT', 'Food', 'tunai', '2026-05-05 17:57:40+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Keripik Kentang', 12300, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Cokelat Bar', 8400, 1);

    -- Transaksi: Belanja Mingguan Sayur & Buah
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 43000, 'Belanja Mingguan Sayur & Buah', 'OUT', 'Groceries', 'tunai', '2026-05-06 17:53:24+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Apel Merah', 26200, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sayur Bayam', 4800, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Wortel', 7200, 1);

    -- Transaksi: Isi Saldo e-Money
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 100300, 'Isi Saldo e-Money', 'OUT', 'Transport', 'non_tunai', '2026-05-07 10:23:28+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Top up e-Money', 100300, 1);

    -- Transaksi: Isi Saldo e-Money
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 97600, 'Isi Saldo e-Money', 'OUT', 'Transport', 'tunai', '2026-05-08 14:16:35+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Top up e-Money', 97600, 1);

    -- Transaksi: Bensin Mobil
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 212100, 'Bensin Mobil', 'OUT', 'Transport', 'tunai', '2026-05-08 20:49:43+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Pertalite Mobil', 212100, 1);

    -- Transaksi: Makan Malam Nasi Goreng
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 20300, 'Makan Malam Nasi Goreng', 'OUT', 'Food', 'tunai', '2026-05-09 20:22:11+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Nasi Goreng Spesial', 20300, 1);

    -- Transaksi: Beli Buku Bacaan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 93300, 'Beli Buku Bacaan', 'OUT', 'Shopping', 'non_tunai', '2026-05-09 15:34:23+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Buku Novel', 93300, 1);

    -- Transaksi: Nasi Padang Lauk Rendang
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 27700, 'Nasi Padang Lauk Rendang', 'OUT', 'Food', 'non_tunai', '2026-05-09 16:38:30+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Nasi Padang Rendang', 22700, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kerupuk Kulit', 5000, 1);

    -- Transaksi: Bensin Mobil
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 206800, 'Bensin Mobil', 'OUT', 'Transport', 'tunai', '2026-05-10 12:24:05+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Pertalite Mobil', 206800, 1);

    -- Transaksi: Nasi Padang Lauk Rendang
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 28200, 'Nasi Padang Lauk Rendang', 'OUT', 'Food', 'tunai', '2026-05-10 18:29:33+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Nasi Padang Rendang', 23500, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kerupuk Kulit', 4700, 1);

    -- Transaksi: Stok Mie Instan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 47000, 'Stok Mie Instan', 'OUT', 'Groceries', 'tunai', '2026-05-10 09:29:55+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Goreng', 3200, 10);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Kuah Kari', 3000, 5);

    -- Transaksi: Makan siang Bakso & Es Teh
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 22400, 'Makan siang Bakso & Es Teh', 'OUT', 'Food', 'non_tunai', '2026-05-11 21:21:38+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Bakso Urat', 17000, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Es Teh Manis', 5400, 1);

    -- Transaksi: Belanja Mingguan Sayur & Buah
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 40700, 'Belanja Mingguan Sayur & Buah', 'OUT', 'Groceries', 'non_tunai', '2026-05-11 09:00:52+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Apel Merah', 24200, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sayur Bayam', 4500, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Wortel', 7500, 1);

    -- Transaksi: Bayar Listrik Bulanan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 269100, 'Bayar Listrik Bulanan', 'OUT', 'Other', 'non_tunai', '2026-05-11 10:20:05+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Tagihan Listrik PLN', 269100, 1);

    -- Transaksi: Stok Mie Instan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 45500, 'Stok Mie Instan', 'OUT', 'Groceries', 'tunai', '2026-05-12 11:21:46+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Goreng', 3000, 10);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Kuah Kari', 3100, 5);

    -- Transaksi: Kebutuhan Dapur Indomaret
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 118300, 'Kebutuhan Dapur Indomaret', 'OUT', 'Groceries', 'non_tunai', '2026-05-12 17:16:48+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Minyak Goreng 2L', 32400, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Beras 5kg', 71300, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Gula Pasir 1kg', 14600, 1);

    -- Transaksi: Perlengkapan Mandi Bulanan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 58400, 'Perlengkapan Mandi Bulanan', 'OUT', 'Groceries', 'non_tunai', '2026-05-13 15:51:36+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sabun Cair', 21000, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Shampoo 170ml', 25200, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Pasta Gigi', 12200, 1);

    -- Transaksi: Stok Mie Instan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 41500, 'Stok Mie Instan', 'OUT', 'Groceries', 'non_tunai', '2026-05-13 12:26:22+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Goreng', 2700, 10);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Kuah Kari', 2900, 5);

    -- Transaksi: Beli Kaos Polos
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 80100, 'Beli Kaos Polos', 'OUT', 'Shopping', 'non_tunai', '2026-05-14 13:12:46+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kaos Cotton Combed', 80100, 1);

    -- Transaksi: Beli Obat di Apotek
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 64200, 'Beli Obat di Apotek', 'OUT', 'Other', 'non_tunai', '2026-05-14 15:38:43+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Vitamin C', 49900, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Obat Flu', 14300, 1);

    -- Transaksi: Belanja Mingguan Sayur & Buah
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 41700, 'Belanja Mingguan Sayur & Buah', 'OUT', 'Groceries', 'non_tunai', '2026-05-14 18:02:33+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Apel Merah', 23700, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sayur Bayam', 5000, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Wortel', 8000, 1);

    -- Transaksi: Isi Saldo e-Money
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 95500, 'Isi Saldo e-Money', 'OUT', 'Transport', 'non_tunai', '2026-05-15 21:31:28+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Top up e-Money', 95500, 1);

    -- Transaksi: Beli Buku Bacaan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 103600, 'Beli Buku Bacaan', 'OUT', 'Shopping', 'tunai', '2026-05-15 11:47:54+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Buku Novel', 103600, 1);

    -- Transaksi: Stok Mie Instan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 46000, 'Stok Mie Instan', 'OUT', 'Groceries', 'non_tunai', '2026-05-15 09:45:08+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Goreng', 3100, 10);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Kuah Kari', 3000, 5);

    -- Transaksi: Isi Saldo e-Money
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 91400, 'Isi Saldo e-Money', 'OUT', 'Transport', 'tunai', '2026-05-16 13:04:04+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Top up e-Money', 91400, 1);

    -- Transaksi: Makan siang Bakso & Es Teh
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 21500, 'Makan siang Bakso & Es Teh', 'OUT', 'Food', 'tunai', '2026-05-16 13:01:25+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Bakso Urat', 16700, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Es Teh Manis', 4800, 1);

    -- Transaksi: Kopi Susu Senja
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 35200, 'Kopi Susu Senja', 'OUT', 'Food', 'non_tunai', '2026-05-17 17:51:44+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Es Kopi Susu', 17600, 2);

    -- Transaksi: Nonton Bioskop Weekend
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 121800, 'Nonton Bioskop Weekend', 'OUT', 'Other', 'tunai', '2026-05-18 21:23:37+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Tiket Bioskop', 44900, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Popcorn Large', 32000, 1);

    -- Transaksi: Stok Mie Instan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 44500, 'Stok Mie Instan', 'OUT', 'Groceries', 'tunai', '2026-05-19 16:59:56+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Goreng', 2800, 10);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Kuah Kari', 3300, 5);

    -- Transaksi: Beli Obat di Apotek
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 62300, 'Beli Obat di Apotek', 'OUT', 'Other', 'tunai', '2026-05-19 16:41:45+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Vitamin C', 46100, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Obat Flu', 16200, 1);

    -- Transaksi: Gojek ke Kantor
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 14500, 'Gojek ke Kantor', 'OUT', 'Transport', 'non_tunai', '2026-05-19 09:38:00+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'GoRide', 14500, 1);

    -- Transaksi: Perlengkapan Mandi Bulanan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 62200, 'Perlengkapan Mandi Bulanan', 'OUT', 'Groceries', 'non_tunai', '2026-05-20 11:50:24+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sabun Cair', 23800, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Shampoo 170ml', 25400, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Pasta Gigi', 13000, 1);

    -- Transaksi: Perlengkapan Mandi Bulanan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 58200, 'Perlengkapan Mandi Bulanan', 'OUT', 'Groceries', 'non_tunai', '2026-05-21 09:28:20+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sabun Cair', 21000, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Shampoo 170ml', 24900, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Pasta Gigi', 12300, 1);

    -- Transaksi: Nonton Bioskop Weekend
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 121300, 'Nonton Bioskop Weekend', 'OUT', 'Other', 'tunai', '2026-05-21 18:33:13+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Tiket Bioskop', 42700, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Popcorn Large', 35900, 1);

    -- Transaksi: Nonton Bioskop Weekend
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 124100, 'Nonton Bioskop Weekend', 'OUT', 'Other', 'non_tunai', '2026-05-21 09:13:39+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Tiket Bioskop', 43500, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Popcorn Large', 37100, 1);

    -- Transaksi: Aksesoris Handphone
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 106500, 'Aksesoris Handphone', 'OUT', 'Shopping', 'tunai', '2026-05-22 12:33:12+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Casing HP', 45000, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kabel Charger', 61500, 1);

    -- Transaksi: Isi Saldo e-Money
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 97900, 'Isi Saldo e-Money', 'OUT', 'Transport', 'non_tunai', '2026-05-22 16:29:35+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Top up e-Money', 97900, 1);

    -- Transaksi: Gojek ke Kantor
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 14700, 'Gojek ke Kantor', 'OUT', 'Transport', 'non_tunai', '2026-05-23 20:01:14+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'GoRide', 14700, 1);

    -- Transaksi: Aksesoris Handphone
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 104900, 'Aksesoris Handphone', 'OUT', 'Shopping', 'non_tunai', '2026-05-24 20:14:07+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Casing HP', 42600, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kabel Charger', 62300, 1);

    -- Transaksi: Gaji Bulanan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 7500000, 'Gaji Bulanan', 'IN', 'Salary', 'non_tunai', '2026-05-25 08:00:00+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Gaji Bulanan', 7500000, 1);

    -- Transaksi: Sarapan Bubur Ayam
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 20000, 'Sarapan Bubur Ayam', 'OUT', 'Food', 'non_tunai', '2026-05-25 18:29:14+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Bubur Ayam Komplit', 14000, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sate Usus', 3000, 2);

    -- Transaksi: Aksesoris Handphone
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 102400, 'Aksesoris Handphone', 'OUT', 'Shopping', 'tunai', '2026-05-25 21:10:30+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Casing HP', 42800, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kabel Charger', 59600, 1);

    -- Transaksi: Beli Obat di Apotek
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 66100, 'Beli Obat di Apotek', 'OUT', 'Other', 'non_tunai', '2026-05-25 20:24:04+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Vitamin C', 50000, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Obat Flu', 16100, 1);

    -- Transaksi: Bensin Motor Pertamax
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 36200, 'Bensin Motor Pertamax', 'OUT', 'Transport', 'non_tunai', '2026-05-26 09:47:55+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Pertamax', 36200, 1);

    -- Transaksi: Belanja Mingguan Sayur & Buah
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 43900, 'Belanja Mingguan Sayur & Buah', 'OUT', 'Groceries', 'tunai', '2026-05-26 18:06:30+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Apel Merah', 25800, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sayur Bayam', 5300, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Wortel', 7500, 1);

    -- Transaksi: Beli Buku Bacaan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 99800, 'Beli Buku Bacaan', 'OUT', 'Shopping', 'non_tunai', '2026-05-26 17:20:16+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Buku Novel', 99800, 1);

    -- Transaksi: Pulsa & Paket Internet
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 119800, 'Pulsa & Paket Internet', 'OUT', 'Other', 'non_tunai', '2026-05-27 14:43:42+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Paket Data 50GB', 119800, 1);

    -- Transaksi: Perlengkapan Mandi Bulanan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 59300, 'Perlengkapan Mandi Bulanan', 'OUT', 'Groceries', 'tunai', '2026-05-27 19:02:01+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sabun Cair', 21700, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Shampoo 170ml', 25700, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Pasta Gigi', 11900, 1);

    -- Transaksi: Gojek ke Kantor
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 14900, 'Gojek ke Kantor', 'OUT', 'Transport', 'non_tunai', '2026-05-27 11:50:56+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'GoRide', 14900, 1);

    -- Transaksi: Kebutuhan Dapur Indomaret
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 123400, 'Kebutuhan Dapur Indomaret', 'OUT', 'Groceries', 'tunai', '2026-05-28 17:35:20+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Minyak Goreng 2L', 35600, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Beras 5kg', 73100, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Gula Pasir 1kg', 14700, 1);

    -- Transaksi: Belanja Mingguan Sayur & Buah
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 44700, 'Belanja Mingguan Sayur & Buah', 'OUT', 'Groceries', 'tunai', '2026-05-29 14:48:16+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Apel Merah', 25400, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sayur Bayam', 5400, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Wortel', 8500, 1);

    -- Transaksi: Beli Obat di Apotek
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 69600, 'Beli Obat di Apotek', 'OUT', 'Other', 'tunai', '2026-05-29 14:09:15+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Vitamin C', 54100, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Obat Flu', 15500, 1);

    -- Transaksi: Isi Saldo e-Money
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 93000, 'Isi Saldo e-Money', 'OUT', 'Transport', 'non_tunai', '2026-05-29 20:05:58+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Top up e-Money', 93000, 1);

    -- Transaksi: Perlengkapan Mandi Bulanan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 57700, 'Perlengkapan Mandi Bulanan', 'OUT', 'Groceries', 'non_tunai', '2026-05-30 12:54:58+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sabun Cair', 21500, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Shampoo 170ml', 24700, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Pasta Gigi', 11500, 1);

    -- Transaksi: Kopi Susu Senja
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 32600, 'Kopi Susu Senja', 'OUT', 'Food', 'non_tunai', '2026-05-30 11:19:47+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Es Kopi Susu', 16300, 2);

    -- Transaksi: Camilan Siang Minimarket
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 31200, 'Camilan Siang Minimarket', 'OUT', 'Food', 'tunai', '2026-05-30 15:25:57+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Keripik Kentang', 11700, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Cokelat Bar', 7800, 1);

    -- Transaksi: Kopi Susu Senja
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 33200, 'Kopi Susu Senja', 'OUT', 'Food', 'non_tunai', '2026-05-31 19:50:17+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Es Kopi Susu', 16600, 2);

    -- Transaksi: Camilan Siang Minimarket
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 32700, 'Camilan Siang Minimarket', 'OUT', 'Food', 'tunai', '2026-05-31 15:17:20+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Keripik Kentang', 12700, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Cokelat Bar', 7300, 1);

    -- Transaksi: Nonton Bioskop Weekend
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 122100, 'Nonton Bioskop Weekend', 'OUT', 'Other', 'tunai', '2026-05-31 09:50:21+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Tiket Bioskop', 42800, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Popcorn Large', 36500, 1);

    -- Transaksi: Pulsa & Paket Internet
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 128600, 'Pulsa & Paket Internet', 'OUT', 'Other', 'tunai', '2026-06-01 11:24:24+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Paket Data 50GB', 128600, 1);

    -- Transaksi: Bensin Mobil
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 180600, 'Bensin Mobil', 'OUT', 'Transport', 'non_tunai', '2026-06-01 20:51:02+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Pertalite Mobil', 180600, 1);

    -- Transaksi: Beli Kaos Polos
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 74000, 'Beli Kaos Polos', 'OUT', 'Shopping', 'tunai', '2026-06-02 20:48:17+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kaos Cotton Combed', 74000, 1);

    -- Transaksi: Stok Mie Instan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 45000, 'Stok Mie Instan', 'OUT', 'Groceries', 'non_tunai', '2026-06-02 12:57:11+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Goreng', 2900, 10);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Kuah Kari', 3200, 5);

    -- Transaksi: Camilan Siang Minimarket
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 31000, 'Camilan Siang Minimarket', 'OUT', 'Food', 'non_tunai', '2026-06-03 09:05:29+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Keripik Kentang', 11800, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Cokelat Bar', 7400, 1);

    -- Transaksi: Stok Mie Instan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 43500, 'Stok Mie Instan', 'OUT', 'Groceries', 'non_tunai', '2026-06-03 15:37:20+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Goreng', 2900, 10);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Kuah Kari', 2900, 5);

    -- Transaksi: Aksesoris Handphone
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 102800, 'Aksesoris Handphone', 'OUT', 'Shopping', 'tunai', '2026-06-04 10:51:11+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Casing HP', 42500, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kabel Charger', 60300, 1);

    -- Transaksi: Beli Kaos Polos
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 81600, 'Beli Kaos Polos', 'OUT', 'Shopping', 'non_tunai', '2026-06-04 19:54:42+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kaos Cotton Combed', 81600, 1);

    -- Transaksi: Sarapan Bubur Ayam
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 21300, 'Sarapan Bubur Ayam', 'OUT', 'Food', 'tunai', '2026-06-05 10:47:24+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Bubur Ayam Komplit', 15100, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sate Usus', 3100, 2);

    -- Transaksi: Beli Buku Bacaan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 92400, 'Beli Buku Bacaan', 'OUT', 'Shopping', 'non_tunai', '2026-06-06 12:32:00+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Buku Novel', 92400, 1);

    -- Transaksi: Nasi Padang Lauk Rendang
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 30200, 'Nasi Padang Lauk Rendang', 'OUT', 'Food', 'non_tunai', '2026-06-07 16:27:50+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Nasi Padang Rendang', 25500, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kerupuk Kulit', 4700, 1);

    -- Transaksi: Stok Mie Instan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 49500, 'Stok Mie Instan', 'OUT', 'Groceries', 'tunai', '2026-06-07 10:08:55+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Goreng', 3300, 10);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Kuah Kari', 3300, 5);

    -- Transaksi: Pulsa & Paket Internet
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 116900, 'Pulsa & Paket Internet', 'OUT', 'Other', 'tunai', '2026-06-07 15:34:20+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Paket Data 50GB', 116900, 1);

    -- Transaksi: Nonton Bioskop Weekend
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 124500, 'Nonton Bioskop Weekend', 'OUT', 'Other', 'tunai', '2026-06-08 12:19:15+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Tiket Bioskop', 44700, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Popcorn Large', 35100, 1);

    -- Transaksi: Makan Malam Nasi Goreng
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 18500, 'Makan Malam Nasi Goreng', 'OUT', 'Food', 'non_tunai', '2026-06-08 09:35:29+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Nasi Goreng Spesial', 18500, 1);

    -- Transaksi: Perlengkapan Mandi Bulanan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 56600, 'Perlengkapan Mandi Bulanan', 'OUT', 'Groceries', 'non_tunai', '2026-06-08 10:49:03+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sabun Cair', 19900, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Shampoo 170ml', 23700, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Pasta Gigi', 13000, 1);

    -- Transaksi: Beli Kaos Polos
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 73800, 'Beli Kaos Polos', 'OUT', 'Shopping', 'non_tunai', '2026-06-09 21:17:21+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kaos Cotton Combed', 73800, 1);

    -- Transaksi: Camilan Siang Minimarket
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 32200, 'Camilan Siang Minimarket', 'OUT', 'Food', 'tunai', '2026-06-09 11:59:02+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Keripik Kentang', 12200, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Cokelat Bar', 7800, 1);

    -- Transaksi: Nonton Bioskop Weekend
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 127500, 'Nonton Bioskop Weekend', 'OUT', 'Other', 'non_tunai', '2026-06-09 17:16:36+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Tiket Bioskop', 46200, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Popcorn Large', 35100, 1);

    -- Transaksi: Makan Malam Nasi Goreng
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 21700, 'Makan Malam Nasi Goreng', 'OUT', 'Food', 'non_tunai', '2026-06-10 15:17:13+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Nasi Goreng Spesial', 21700, 1);

    -- Transaksi: Beli Kaos Polos
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 72300, 'Beli Kaos Polos', 'OUT', 'Shopping', 'non_tunai', '2026-06-10 10:27:59+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kaos Cotton Combed', 72300, 1);

    -- Transaksi: Bensin Mobil
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 215700, 'Bensin Mobil', 'OUT', 'Transport', 'tunai', '2026-06-11 17:52:56+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Pertalite Mobil', 215700, 1);

    -- Transaksi: Kopi Susu Senja
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 36000, 'Kopi Susu Senja', 'OUT', 'Food', 'non_tunai', '2026-06-11 16:08:53+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Es Kopi Susu', 18000, 2);

    -- Transaksi: Pulsa & Paket Internet
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 135600, 'Pulsa & Paket Internet', 'OUT', 'Other', 'non_tunai', '2026-06-12 21:57:26+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Paket Data 50GB', 135600, 1);

    -- Transaksi: Beli Buku Bacaan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 88600, 'Beli Buku Bacaan', 'OUT', 'Shopping', 'non_tunai', '2026-06-12 16:40:37+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Buku Novel', 88600, 1);

    -- Transaksi: Gojek ke Kantor
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 14200, 'Gojek ke Kantor', 'OUT', 'Transport', 'tunai', '2026-06-12 14:23:56+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'GoRide', 14200, 1);

    -- Transaksi: Beli Obat di Apotek
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 65200, 'Beli Obat di Apotek', 'OUT', 'Other', 'non_tunai', '2026-06-13 20:36:37+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Vitamin C', 51300, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Obat Flu', 13900, 1);

    -- Transaksi: Grab Car Bandara
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 156100, 'Grab Car Bandara', 'OUT', 'Transport', 'tunai', '2026-06-14 20:00:18+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'GrabCar Bandara', 156100, 1);

    -- Transaksi: Stok Mie Instan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 49000, 'Stok Mie Instan', 'OUT', 'Groceries', 'non_tunai', '2026-06-14 21:53:10+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Goreng', 3300, 10);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Kuah Kari', 3200, 5);

    -- Transaksi: Bayar Listrik Bulanan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 234200, 'Bayar Listrik Bulanan', 'OUT', 'Other', 'non_tunai', '2026-06-14 09:56:23+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Tagihan Listrik PLN', 234200, 1);

    -- Transaksi: Bayar Listrik Bulanan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 225300, 'Bayar Listrik Bulanan', 'OUT', 'Other', 'non_tunai', '2026-06-15 11:23:25+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Tagihan Listrik PLN', 225300, 1);

    -- Transaksi: Aksesoris Handphone
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 98600, 'Aksesoris Handphone', 'OUT', 'Shopping', 'tunai', '2026-06-15 19:06:17+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Casing HP', 42900, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kabel Charger', 55700, 1);

    -- Transaksi: Belanja Mingguan Sayur & Buah
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 43500, 'Belanja Mingguan Sayur & Buah', 'OUT', 'Groceries', 'tunai', '2026-06-16 19:18:18+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Apel Merah', 27100, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sayur Bayam', 4600, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Wortel', 7200, 1);

    -- Transaksi: Kebutuhan Dapur Indomaret
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 115300, 'Kebutuhan Dapur Indomaret', 'OUT', 'Groceries', 'non_tunai', '2026-06-16 17:30:51+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Minyak Goreng 2L', 34200, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Beras 5kg', 64800, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Gula Pasir 1kg', 16300, 1);

    -- Transaksi: Makan siang Bakso & Es Teh
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 24700, 'Makan siang Bakso & Es Teh', 'OUT', 'Food', 'tunai', '2026-06-16 21:45:39+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Bakso Urat', 19600, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Es Teh Manis', 5100, 1);

    -- Transaksi: Makan Malam Nasi Goreng
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 20900, 'Makan Malam Nasi Goreng', 'OUT', 'Food', 'non_tunai', '2026-06-17 21:31:19+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Nasi Goreng Spesial', 20900, 1);

    -- Transaksi: Stok Mie Instan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 43500, 'Stok Mie Instan', 'OUT', 'Groceries', 'tunai', '2026-06-17 15:38:26+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Goreng', 2900, 10);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Kuah Kari', 2900, 5);

    -- Transaksi: Kopi Susu Senja
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 36200, 'Kopi Susu Senja', 'OUT', 'Food', 'tunai', '2026-06-18 09:30:58+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Es Kopi Susu', 18100, 2);

    -- Transaksi: Makan Malam Nasi Goreng
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 19200, 'Makan Malam Nasi Goreng', 'OUT', 'Food', 'tunai', '2026-06-18 13:09:46+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Nasi Goreng Spesial', 19200, 1);

    -- Transaksi: Bensin Motor Pertamax
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 36800, 'Bensin Motor Pertamax', 'OUT', 'Transport', 'tunai', '2026-06-19 17:36:17+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Pertamax', 36800, 1);

    -- Transaksi: Bensin Mobil
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 204900, 'Bensin Mobil', 'OUT', 'Transport', 'non_tunai', '2026-06-20 10:48:00+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Pertalite Mobil', 204900, 1);

    -- Transaksi: Bensin Motor Pertamax
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 37300, 'Bensin Motor Pertamax', 'OUT', 'Transport', 'non_tunai', '2026-06-20 09:14:28+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Pertamax', 37300, 1);

    -- Transaksi: Belanja Mingguan Sayur & Buah
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 43800, 'Belanja Mingguan Sayur & Buah', 'OUT', 'Groceries', 'tunai', '2026-06-21 10:33:15+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Apel Merah', 24800, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sayur Bayam', 5200, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Wortel', 8600, 1);

    -- Transaksi: Bayar Listrik Bulanan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 265800, 'Bayar Listrik Bulanan', 'OUT', 'Other', 'non_tunai', '2026-06-21 09:33:30+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Tagihan Listrik PLN', 265800, 1);

    -- Transaksi: Beli Obat di Apotek
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 64300, 'Beli Obat di Apotek', 'OUT', 'Other', 'tunai', '2026-06-21 12:40:13+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Vitamin C', 48300, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Obat Flu', 16000, 1);

    -- Transaksi: Belanja Mingguan Sayur & Buah
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 42000, 'Belanja Mingguan Sayur & Buah', 'OUT', 'Groceries', 'non_tunai', '2026-06-22 15:57:10+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Apel Merah', 23700, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sayur Bayam', 5100, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Wortel', 8100, 1);

    -- Transaksi: Grab Car Bandara
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 158100, 'Grab Car Bandara', 'OUT', 'Transport', 'tunai', '2026-06-23 12:05:51+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'GrabCar Bandara', 158100, 1);

    -- Transaksi: Bayar Listrik Bulanan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 273900, 'Bayar Listrik Bulanan', 'OUT', 'Other', 'non_tunai', '2026-06-24 21:08:04+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Tagihan Listrik PLN', 273900, 1);

    -- Transaksi: Isi Saldo e-Money
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 98200, 'Isi Saldo e-Money', 'OUT', 'Transport', 'non_tunai', '2026-06-24 12:12:26+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Top up e-Money', 98200, 1);

    -- Transaksi: Gaji Bulanan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 7500000, 'Gaji Bulanan', 'IN', 'Salary', 'non_tunai', '2026-06-25 08:00:00+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Gaji Bulanan', 7500000, 1);

    -- Transaksi: Nonton Bioskop Weekend
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 118100, 'Nonton Bioskop Weekend', 'OUT', 'Other', 'tunai', '2026-06-25 12:49:52+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Tiket Bioskop', 41300, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Popcorn Large', 35500, 1);

    -- Transaksi: Nasi Padang Lauk Rendang
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 29500, 'Nasi Padang Lauk Rendang', 'OUT', 'Food', 'non_tunai', '2026-06-26 14:31:52+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Nasi Padang Rendang', 24900, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kerupuk Kulit', 4600, 1);

    -- Transaksi: Nonton Bioskop Weekend
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 126200, 'Nonton Bioskop Weekend', 'OUT', 'Other', 'non_tunai', '2026-06-26 16:28:40+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Tiket Bioskop', 46900, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Popcorn Large', 32400, 1);

    -- Transaksi: Project Freelance
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 1500000, 'Project Freelance', 'IN', 'Salary', 'non_tunai', '2026-06-27 13:00:00+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Project Freelance', 1500000, 1);

    -- Transaksi: Beli Buku Bacaan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 88600, 'Beli Buku Bacaan', 'OUT', 'Shopping', 'tunai', '2026-06-27 11:53:16+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Buku Novel', 88600, 1);

    -- Transaksi: Pulsa & Paket Internet
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 114600, 'Pulsa & Paket Internet', 'OUT', 'Other', 'tunai', '2026-06-28 12:20:38+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Paket Data 50GB', 114600, 1);

    -- Transaksi: Bensin Mobil
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 203400, 'Bensin Mobil', 'OUT', 'Transport', 'non_tunai', '2026-06-29 15:51:18+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Pertalite Mobil', 203400, 1);

    -- Transaksi: Beli Buku Bacaan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 87200, 'Beli Buku Bacaan', 'OUT', 'Shopping', 'tunai', '2026-06-29 20:59:30+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Buku Novel', 87200, 1);

    -- Transaksi: Aksesoris Handphone
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 108300, 'Aksesoris Handphone', 'OUT', 'Shopping', 'non_tunai', '2026-06-30 12:03:38+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Casing HP', 44600, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kabel Charger', 63700, 1);

    -- Transaksi: Beli Buku Bacaan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 87100, 'Beli Buku Bacaan', 'OUT', 'Shopping', 'non_tunai', '2026-06-30 09:16:42+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Buku Novel', 87100, 1);

    -- Transaksi: Aksesoris Handphone
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 96100, 'Aksesoris Handphone', 'OUT', 'Shopping', 'non_tunai', '2026-07-01 18:23:26+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Casing HP', 41600, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kabel Charger', 54500, 1);

    -- Transaksi: Beli Buku Bacaan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 100600, 'Beli Buku Bacaan', 'OUT', 'Shopping', 'non_tunai', '2026-07-02 20:29:13+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Buku Novel', 100600, 1);

    -- Transaksi: Nasi Padang Lauk Rendang
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 28400, 'Nasi Padang Lauk Rendang', 'OUT', 'Food', 'tunai', '2026-07-02 09:01:37+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Nasi Padang Rendang', 23200, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kerupuk Kulit', 5200, 1);

    -- Transaksi: Stok Mie Instan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 45000, 'Stok Mie Instan', 'OUT', 'Groceries', 'tunai', '2026-07-03 14:49:43+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Goreng', 3000, 10);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Kuah Kari', 3000, 5);

    -- Transaksi: Nasi Padang Lauk Rendang
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 28800, 'Nasi Padang Lauk Rendang', 'OUT', 'Food', 'non_tunai', '2026-07-04 16:24:52+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Nasi Padang Rendang', 23500, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kerupuk Kulit', 5300, 1);

    -- Transaksi: Bensin Mobil
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 207900, 'Bensin Mobil', 'OUT', 'Transport', 'tunai', '2026-07-04 12:20:30+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Pertalite Mobil', 207900, 1);

    -- Transaksi: Beli Buku Bacaan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 95600, 'Beli Buku Bacaan', 'OUT', 'Shopping', 'non_tunai', '2026-07-04 16:24:36+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Buku Novel', 95600, 1);

    -- Transaksi: Grab Car Bandara
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 159300, 'Grab Car Bandara', 'OUT', 'Transport', 'non_tunai', '2026-07-05 20:31:57+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'GrabCar Bandara', 159300, 1);

    -- Transaksi: Stok Mie Instan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 46500, 'Stok Mie Instan', 'OUT', 'Groceries', 'tunai', '2026-07-06 20:18:02+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Goreng', 3000, 10);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Mie Kuah Kari', 3300, 5);

    -- Transaksi: Beli Kaos Polos
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 77500, 'Beli Kaos Polos', 'OUT', 'Shopping', 'non_tunai', '2026-07-06 13:33:16+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kaos Cotton Combed', 77500, 1);

    -- Transaksi: Camilan Siang Minimarket
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 32100, 'Camilan Siang Minimarket', 'OUT', 'Food', 'tunai', '2026-07-07 12:04:23+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Keripik Kentang', 12100, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Cokelat Bar', 7900, 1);

    -- Transaksi: Bayar Listrik Bulanan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 236900, 'Bayar Listrik Bulanan', 'OUT', 'Other', 'non_tunai', '2026-07-07 19:34:55+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Tagihan Listrik PLN', 236900, 1);

    -- Transaksi: Bensin Motor Pertamax
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 33900, 'Bensin Motor Pertamax', 'OUT', 'Transport', 'tunai', '2026-07-07 10:27:13+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Pertamax', 33900, 1);

    -- Transaksi: Skin Care Bulanan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 112100, 'Skin Care Bulanan', 'OUT', 'Shopping', 'non_tunai', '2026-07-08 15:32:50+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Face Wash', 45800, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sunscreen', 66300, 1);

    -- Transaksi: Isi Saldo e-Money
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 105700, 'Isi Saldo e-Money', 'OUT', 'Transport', 'non_tunai', '2026-07-09 20:49:09+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Top up e-Money', 105700, 1);

    -- Transaksi: Belanja Mingguan Sayur & Buah
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 44500, 'Belanja Mingguan Sayur & Buah', 'OUT', 'Groceries', 'tunai', '2026-07-09 14:51:02+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Apel Merah', 26100, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sayur Bayam', 5000, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Wortel', 8400, 1);

    -- Transaksi: Aksesoris Handphone
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 109900, 'Aksesoris Handphone', 'OUT', 'Shopping', 'non_tunai', '2026-07-09 16:34:46+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Casing HP', 47100, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kabel Charger', 62800, 1);

    -- Transaksi: Perlengkapan Mandi Bulanan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 58300, 'Perlengkapan Mandi Bulanan', 'OUT', 'Groceries', 'tunai', '2026-07-10 14:56:02+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sabun Cair', 20800, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Shampoo 170ml', 25200, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Pasta Gigi', 12300, 1);

    -- Transaksi: Pulsa & Paket Internet
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 129200, 'Pulsa & Paket Internet', 'OUT', 'Other', 'tunai', '2026-07-11 15:10:28+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Paket Data 50GB', 129200, 1);

    -- Transaksi: Camilan Siang Minimarket
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 32600, 'Camilan Siang Minimarket', 'OUT', 'Food', 'non_tunai', '2026-07-11 13:16:33+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Keripik Kentang', 12700, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Cokelat Bar', 7200, 1);

    -- Transaksi: Bayar Listrik Bulanan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 246700, 'Bayar Listrik Bulanan', 'OUT', 'Other', 'tunai', '2026-07-11 18:26:11+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Tagihan Listrik PLN', 246700, 1);

    -- Transaksi: Beli Buku Bacaan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 89300, 'Beli Buku Bacaan', 'OUT', 'Shopping', 'non_tunai', '2026-07-12 19:55:27+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Buku Novel', 89300, 1);

    -- Transaksi: Makan Malam Nasi Goreng
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 19600, 'Makan Malam Nasi Goreng', 'OUT', 'Food', 'tunai', '2026-07-13 16:26:30+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Nasi Goreng Spesial', 19600, 1);

    -- Transaksi: Belanja Mingguan Sayur & Buah
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 44200, 'Belanja Mingguan Sayur & Buah', 'OUT', 'Groceries', 'tunai', '2026-07-14 15:01:43+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Apel Merah', 27100, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sayur Bayam', 4900, 2);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Wortel', 7300, 1);

    -- Transaksi: Beli Obat di Apotek
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 64800, 'Beli Obat di Apotek', 'OUT', 'Other', 'tunai', '2026-07-14 16:14:01+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Vitamin C', 50800, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Obat Flu', 14000, 1);

    -- Transaksi: Pulsa & Paket Internet
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 137000, 'Pulsa & Paket Internet', 'OUT', 'Other', 'non_tunai', '2026-07-15 11:15:37+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Paket Data 50GB', 137000, 1);

    -- Transaksi: Sarapan Bubur Ayam
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 21600, 'Sarapan Bubur Ayam', 'OUT', 'Food', 'tunai', '2026-07-15 14:12:20+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Bubur Ayam Komplit', 15200, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Sate Usus', 3200, 2);

    -- Transaksi: Kopi Susu Senja
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 36400, 'Kopi Susu Senja', 'OUT', 'Food', 'non_tunai', '2026-07-16 09:49:40+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Es Kopi Susu', 18200, 2);

    -- Transaksi: Aksesoris Handphone
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 100900, 'Aksesoris Handphone', 'OUT', 'Shopping', 'non_tunai', '2026-07-17 21:12:41+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Casing HP', 43300, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kabel Charger', 57600, 1);

    -- Transaksi: Bensin Mobil
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 182500, 'Bensin Mobil', 'OUT', 'Transport', 'non_tunai', '2026-07-17 19:16:12+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Pertalite Mobil', 182500, 1);

    -- Transaksi: Kopi Susu Senja
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 38400, 'Kopi Susu Senja', 'OUT', 'Food', 'non_tunai', '2026-07-17 17:33:11+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Es Kopi Susu', 19200, 2);

    -- Transaksi: Makan Malam Nasi Goreng
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 19100, 'Makan Malam Nasi Goreng', 'OUT', 'Food', 'non_tunai', '2026-07-18 20:02:53+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Nasi Goreng Spesial', 19100, 1);

    -- Transaksi: Beli Buku Bacaan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 86600, 'Beli Buku Bacaan', 'OUT', 'Shopping', 'non_tunai', '2026-07-19 18:52:50+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Buku Novel', 86600, 1);

    -- Transaksi: Gojek ke Kantor
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 15300, 'Gojek ke Kantor', 'OUT', 'Transport', 'non_tunai', '2026-07-19 10:02:29+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'GoRide', 15300, 1);

    -- Transaksi: Beli Buku Bacaan
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 86100, 'Beli Buku Bacaan', 'OUT', 'Shopping', 'non_tunai', '2026-07-19 10:36:14+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Buku Novel', 86100, 1);

    -- Transaksi: Kebutuhan Dapur Indomaret
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 119100, 'Kebutuhan Dapur Indomaret', 'OUT', 'Groceries', 'tunai', '2026-07-20 11:21:23+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Minyak Goreng 2L', 32600, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Beras 5kg', 71400, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Gula Pasir 1kg', 15100, 1);

    -- Transaksi: Kebutuhan Dapur Indomaret
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 110700, 'Kebutuhan Dapur Indomaret', 'OUT', 'Groceries', 'tunai', '2026-07-20 15:52:27+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Minyak Goreng 2L', 33100, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Beras 5kg', 62500, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Gula Pasir 1kg', 15100, 1);

    -- Transaksi: Nasi Padang Lauk Rendang
    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)
    VALUES (v_user_id, 30700, 'Nasi Padang Lauk Rendang', 'OUT', 'Food', 'non_tunai', '2026-07-21 20:23:05+07')
    RETURNING id INTO v_tx_id;

    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Nasi Padang Rendang', 26200, 1);
    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
    VALUES (v_tx_id, 'Kerupuk Kulit', 4500, 1);

    RAISE NOTICE 'Seeding selesai!';
END $$;
