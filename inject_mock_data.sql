-- ============================================================
-- STATIC INSERT MOCK DATA TRANSAKSI (5 BULAN TERAKHIR)
-- ============================================================
-- Menggunakan subquery otomatis (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
-- untuk mendeteksi user ID pertama di database secara dinamis.
-- Menggunakan Common Table Expressions (CTE) agar pengisian rincian item
-- tidak bergantung pada valseq / lastval() yang rentan error saat multi-row insert.

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 150567, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-02-22 12:56:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 23557, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 42629, 2 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 20876, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 293608, 'Belanja Kebutuhan Mingguan', 'OUT', 'Groceries', 'tunai', '2026-02-22 09:32:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Gula Pasir Rose Brand 1kg', 21254, 1 FROM ins UNION ALL
SELECT id, 'Beras Ramos 5kg', 45279, 2 FROM ins UNION ALL
SELECT id, 'Sabun Cuci Piring', 43298, 1 FROM ins UNION ALL
SELECT id, 'Indomie Goreng 1 Dus', 40104, 2 FROM ins UNION ALL
SELECT id, 'Indomie Goreng 1 Dus', 29145, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 44786, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-02-23 12:04:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 44786, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 78579, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-02-24 12:11:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 15675, 1 FROM ins UNION ALL
SELECT id, 'Sate Madura 10 Tusuk', 31452, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 74101, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-02-24 20:43:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 22252, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 16199, 1 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 35650, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 8536466, 'Gaji Bulanan Utama', 'IN', 'Salary', 'non_tunai', '2026-02-25 08:00:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Gaji Bersih Bulanan (Corporate)', 8536466, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 103338, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-02-25 12:29:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Mie Goreng Telur', 25001, 2 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 21824, 1 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 31512, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 79376, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-02-26 12:20:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Teh Manis Dingin', 18365, 1 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 36328, 1 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 24683, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 37314, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-02-27 12:37:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 37314, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 21501, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-02-27 07:03:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 21501, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 166325, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-02-28 12:42:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Mie Goreng Telur', 23951, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 38470, 2 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 32717, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 121648, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-01 12:44:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 39557, 2 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 42534, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 189148, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-01 20:09:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 31537, 2 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 38726, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 43674, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 341525, 'Belanja Kebutuhan Mingguan', 'OUT', 'Groceries', 'tunai', '2026-03-01 11:13:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Susu UHT Full Cream 1L', 28655, 2 FROM ins UNION ALL
SELECT id, 'Telur Ayam 1kg', 48146, 1 FROM ins UNION ALL
SELECT id, 'Telur Ayam 1kg', 52655, 1 FROM ins UNION ALL
SELECT id, 'Pasta Gigi Herbal', 62590, 2 FROM ins UNION ALL
SELECT id, 'Pasta Gigi Herbal', 58234, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 102317, 'Refreshing & Hiburan Weekend', 'OUT', 'Entertainment', 'non_tunai', '2026-03-01 17:30:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Game PC Steam', 102317, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 168680, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-02 12:49:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Ayam Penyet Sambal Ijo', 33803, 2 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 22322, 2 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 28215, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 52298, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-02 19:07:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 26149, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 23232, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-03-02 08:00:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 23232, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 100017, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-03 12:39:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 27091, 2 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 21202, 1 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 24633, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 87580, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-03 18:49:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 43790, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 45678, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-03-03 08:53:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 45678, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 14035, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-04 12:48:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 14035, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 25889, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-03-04 07:41:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 25889, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 96910, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-05 12:07:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 15943, 2 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 29846, 1 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 17589, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 21563, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-03-05 07:24:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 21563, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 1700661, 'Pendapatan Freelance', 'IN', 'Transfer_In', 'non_tunai', '2026-03-06 17:47:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Pembayaran Jasa Pembuatan Website / Desain', 1700661, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 22243, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-06 12:27:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 22243, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 43781, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-03-06 08:04:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 43781, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 163632, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-07 12:13:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Mie Goreng Telur', 40910, 2 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 40906, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 29260, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-07 18:25:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 29260, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 135917, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-08 12:39:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 42324, 2 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 16940, 2 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 17389, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 102042, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-08 21:27:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 29638, 2 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 21383, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 514966, 'Belanja Kebutuhan Mingguan', 'OUT', 'Groceries', 'tunai', '2026-03-08 10:12:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Telur Ayam 1kg', 20437, 2 FROM ins UNION ALL
SELECT id, 'Beras Ramos 5kg', 33157, 2 FROM ins UNION ALL
SELECT id, 'Beras Ramos 5kg', 69918, 2 FROM ins UNION ALL
SELECT id, 'Pasta Gigi Herbal', 61918, 2 FROM ins UNION ALL
SELECT id, 'Minyak Goreng 2L', 61673, 2 FROM ins UNION ALL
SELECT id, 'Telur Ayam 1kg', 20760, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 568086, 'Belanja Fashion & Kebutuhan Hobi', 'OUT', 'Shopping', 'non_tunai', '2026-03-08 16:53:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Dompet Kulit Asli', 257265, 1 FROM ins UNION ALL
SELECT id, 'Celana Chino Slim Fit', 310821, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 142174, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-09 12:17:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 31807, 2 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 39280, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 74519, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-10 12:06:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 44597, 1 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 29922, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 112553, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-10 21:45:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Teh Manis Dingin', 23161, 2 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 32871, 1 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 16680, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 34013, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-03-10 07:59:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 34013, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 28036, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-11 12:19:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 14018, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 204662, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-11 20:13:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Mie Goreng Telur', 33114, 2 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 26847, 2 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 42370, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 39056, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-03-11 07:36:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 39056, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 95237, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-12 12:05:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 42903, 1 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 12087, 2 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 14080, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 42929, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-12 19:01:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 42929, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 20565, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-03-12 08:51:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 20565, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 88561, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-13 12:41:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Mie Goreng Telur', 30931, 1 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 28815, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 72869, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-15 12:48:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 28698, 1 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 44171, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 376544, 'Belanja Kebutuhan Mingguan', 'OUT', 'Groceries', 'tunai', '2026-03-15 10:35:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Susu UHT Full Cream 1L', 50664, 2 FROM ins UNION ALL
SELECT id, 'Beras Ramos 5kg', 56887, 2 FROM ins UNION ALL
SELECT id, 'Pasta Gigi Herbal', 28374, 1 FROM ins UNION ALL
SELECT id, 'Beras Ramos 5kg', 27403, 1 FROM ins UNION ALL
SELECT id, 'Pasta Gigi Herbal', 60011, 1 FROM ins UNION ALL
SELECT id, 'Sabun Cuci Piring', 45654, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 496043, 'Belanja Fashion & Kebutuhan Hobi', 'OUT', 'Shopping', 'non_tunai', '2026-03-15 13:34:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Jam Tangan Sporty', 163400, 1 FROM ins UNION ALL
SELECT id, 'Kaos Polos Cotton Combed', 332643, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 226222, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-16 12:41:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 31442, 2 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 37463, 2 FROM ins UNION ALL
SELECT id, 'Sate Madura 10 Tusuk', 44206, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 54820, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-16 19:31:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 23672, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 31148, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 31765, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-03-16 07:37:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 31765, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 78654, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-17 12:57:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bakso Aci Kuah Pedas', 31919, 1 FROM ins UNION ALL
SELECT id, 'Sate Madura 10 Tusuk', 30271, 1 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 16464, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 139266, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-17 21:19:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 24471, 2 FROM ins UNION ALL
SELECT id, 'Sate Madura 10 Tusuk', 28445, 2 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 16717, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 33253, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-03-17 08:55:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 33253, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 58056, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-18 12:47:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Teh Manis Dingin', 35058, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 22998, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 105246, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-18 18:52:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 43111, 2 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 19024, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 48012, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-03-18 08:11:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 48012, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 114582, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-19 12:48:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 16935, 2 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 40356, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 44356, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-19 18:21:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bakso Aci Kuah Pedas', 44356, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 2587371, 'Pendapatan Freelance', 'IN', 'Transfer_In', 'non_tunai', '2026-03-20 14:37:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Pembayaran Jasa Pembuatan Website / Desain', 2587371, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 73167, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-21 12:48:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Ayam Penyet Sambal Ijo', 34131, 1 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 19518, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 132478, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-21 18:42:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bakso Aci Kuah Pedas', 22426, 2 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 43813, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 337687, 'Belanja Fashion & Kebutuhan Hobi', 'OUT', 'Shopping', 'non_tunai', '2026-03-21 16:21:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Dompet Kulit Asli', 115504, 1 FROM ins UNION ALL
SELECT id, 'Kaos Polos Cotton Combed', 222183, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 101733, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-22 12:06:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 41018, 1 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 24217, 1 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 36498, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 266077, 'Belanja Kebutuhan Mingguan', 'OUT', 'Groceries', 'tunai', '2026-03-22 11:58:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Minyak Goreng 2L', 19118, 2 FROM ins UNION ALL
SELECT id, 'Beras Ramos 5kg', 65587, 1 FROM ins UNION ALL
SELECT id, 'Sabun Cuci Piring', 22367, 1 FROM ins UNION ALL
SELECT id, 'Minyak Goreng 2L', 62506, 1 FROM ins UNION ALL
SELECT id, 'Sabun Cuci Piring', 18555, 1 FROM ins UNION ALL
SELECT id, 'Sabun Cuci Piring', 29413, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 118915, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-23 12:18:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Teh Manis Dingin', 22042, 1 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 27162, 2 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 42549, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 15100, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-23 18:50:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 15100, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 26036, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-03-23 07:41:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 26036, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 36664, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-24 12:26:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 18672, 1 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 17992, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 41424, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-03-24 07:37:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 41424, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 9155031, 'Gaji Bulanan Utama', 'IN', 'Salary', 'non_tunai', '2026-03-25 08:00:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Gaji Bersih Bulanan (Corporate)', 9155031, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 139806, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-25 12:30:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bakso Aci Kuah Pedas', 41781, 2 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 28122, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 22610, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-03-25 07:36:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 22610, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 121643, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-26 12:10:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Mie Goreng Telur', 42579, 1 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 39532, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 29586, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-03-26 08:00:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 29586, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 2434949, 'Pendapatan Freelance', 'IN', 'Transfer_In', 'non_tunai', '2026-03-27 15:55:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Pembayaran Jasa Pembuatan Website / Desain', 2434949, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 51580, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-27 12:49:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 25790, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 106500, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-27 20:58:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 32212, 1 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 37144, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 67176, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-28 12:57:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bakso Aci Kuah Pedas', 33588, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 56407, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-29 12:38:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 36678, 1 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 19729, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 304860, 'Belanja Kebutuhan Mingguan', 'OUT', 'Groceries', 'tunai', '2026-03-29 11:59:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sabun Cuci Piring', 36134, 2 FROM ins UNION ALL
SELECT id, 'Pasta Gigi Herbal', 63493, 2 FROM ins UNION ALL
SELECT id, 'Susu UHT Full Cream 1L', 23820, 1 FROM ins UNION ALL
SELECT id, 'Pasta Gigi Herbal', 18024, 1 FROM ins UNION ALL
SELECT id, 'Telur Ayam 1kg', 31881, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 101029, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-30 12:47:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 18972, 2 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 28836, 1 FROM ins UNION ALL
SELECT id, 'Sate Madura 10 Tusuk', 34249, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 209868, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-30 21:13:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 39709, 2 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 28317, 2 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 36908, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 35806, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-03-30 08:22:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 35806, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 84776, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-31 12:12:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 42388, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 118540, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-03-31 21:34:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 33515, 2 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 25755, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 27875, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-03-31 08:16:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 27875, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 49507, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-04-01 07:37:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 49507, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 79508, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-02 12:38:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 15492, 1 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 32008, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 22376, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-04-02 08:41:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 22376, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 2731496, 'Pendapatan Freelance', 'IN', 'Transfer_In', 'non_tunai', '2026-04-03 16:33:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Pembayaran Jasa Pembuatan Website / Desain', 2731496, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 162032, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-03 12:14:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 19130, 2 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 44903, 2 FROM ins UNION ALL
SELECT id, 'Sate Madura 10 Tusuk', 33966, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 28347, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-04-03 07:54:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 28347, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 128464, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-04 12:07:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Teh Manis Dingin', 22382, 2 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 41850, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 84020, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-05 12:53:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Mie Goreng Telur', 42010, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 489012, 'Belanja Kebutuhan Mingguan', 'OUT', 'Groceries', 'tunai', '2026-04-05 09:02:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Susu UHT Full Cream 1L', 39736, 2 FROM ins UNION ALL
SELECT id, 'Susu UHT Full Cream 1L', 60638, 1 FROM ins UNION ALL
SELECT id, 'Telur Ayam 1kg', 29972, 2 FROM ins UNION ALL
SELECT id, 'Gula Pasir Rose Brand 1kg', 60369, 2 FROM ins UNION ALL
SELECT id, 'Pasta Gigi Herbal', 30321, 2 FROM ins UNION ALL
SELECT id, 'Minyak Goreng 2L', 53789, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 36088, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-06 12:51:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 36088, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 23075, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-04-06 07:32:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 23075, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 82415, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-07 12:57:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 17397, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 32509, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 92267, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-07 21:55:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Ayam Penyet Sambal Ijo', 17146, 2 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 43521, 1 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 14454, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 30591, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-04-07 07:46:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 30591, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 125874, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-08 12:20:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 41393, 2 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 43088, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 36647, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-04-08 08:27:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 36647, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 121326, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-09 12:53:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bakso Aci Kuah Pedas', 39242, 2 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 42842, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 41729, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-04-09 07:52:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 41729, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 2216468, 'Pendapatan Freelance', 'IN', 'Transfer_In', 'non_tunai', '2026-04-10 14:39:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Pembayaran Jasa Pembuatan Website / Desain', 2216468, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 24451, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-10 12:23:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 24451, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 392142, 'Tagihan internet rumah (IndiHome/Biznet)', 'OUT', 'Bills', 'non_tunai', '2026-04-10 10:00:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Paket internet WiFi unlimited', 392142, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 423855, 'Tagihan Listrik PLN', 'OUT', 'Bills', 'non_tunai', '2026-04-10 13:00:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Token / Tagihan pascabayar PLN', 423855, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 43273, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-04-10 08:06:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 43273, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 87666, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-11 12:33:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Ayam Penyet Sambal Ijo', 14720, 1 FROM ins UNION ALL
SELECT id, 'Sate Madura 10 Tusuk', 36473, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 107218, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-11 20:11:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bakso Aci Kuah Pedas', 32282, 1 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 19076, 1 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 27930, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 100722, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-12 12:24:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Mie Goreng Telur', 29656, 2 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 41410, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 86662, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-12 19:25:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 43331, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 180451, 'Belanja Kebutuhan Mingguan', 'OUT', 'Groceries', 'tunai', '2026-04-12 09:38:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Telur Ayam 1kg', 47890, 1 FROM ins UNION ALL
SELECT id, 'Minyak Goreng 2L', 30344, 1 FROM ins UNION ALL
SELECT id, 'Sabun Cuci Piring', 32995, 1 FROM ins UNION ALL
SELECT id, 'Susu UHT Full Cream 1L', 69222, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 119497, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-13 12:59:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 39595, 1 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 39951, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 218606, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-13 21:43:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 39869, 2 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 44769, 2 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 24665, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 27142, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-04-13 07:52:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 27142, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 70824, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-14 12:52:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 35412, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 96144, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-14 19:07:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 19208, 2 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 21420, 1 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 36308, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 111479, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-15 12:31:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Ayam Penyet Sambal Ijo', 21422, 2 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 25644, 2 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 17347, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 136459, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-16 12:28:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 28911, 2 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 20537, 1 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 29050, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 112870, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-16 19:08:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 24836, 1 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 44017, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 24370, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-04-16 08:54:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 24370, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 2493399, 'Pendapatan Freelance', 'IN', 'Transfer_In', 'non_tunai', '2026-04-17 16:38:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Pembayaran Jasa Pembuatan Website / Desain', 2493399, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 37542, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-04-17 08:38:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 37542, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 79168, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-18 12:38:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 39584, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 134920, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-18 20:13:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 37611, 2 FROM ins UNION ALL
SELECT id, 'Sate Madura 10 Tusuk', 43818, 1 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 15880, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 83281, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-19 12:02:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bakso Aci Kuah Pedas', 22710, 2 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 37861, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 134460, 'Belanja Kebutuhan Mingguan', 'OUT', 'Groceries', 'tunai', '2026-04-19 09:40:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sabun Cuci Piring', 67086, 1 FROM ins UNION ALL
SELECT id, 'Sabun Cuci Piring', 19702, 2 FROM ins UNION ALL
SELECT id, 'Telur Ayam 1kg', 27970, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 89159, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-20 12:55:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Teh Manis Dingin', 30673, 1 FROM ins UNION ALL
SELECT id, 'Sate Madura 10 Tusuk', 29243, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 31861, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-04-20 08:53:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 31861, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 85347, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-21 12:48:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 32102, 2 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 21143, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 118078, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-22 12:18:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 16033, 2 FROM ins UNION ALL
SELECT id, 'Sate Madura 10 Tusuk', 21798, 2 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 42416, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 35571, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-22 21:18:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bakso Aci Kuah Pedas', 35571, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 38195, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-04-22 08:13:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 38195, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 84961, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-23 12:58:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 29959, 2 FROM ins UNION ALL
SELECT id, 'Sate Madura 10 Tusuk', 25043, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 72235, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-23 20:41:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Mie Goreng Telur', 34748, 1 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 17300, 1 FROM ins UNION ALL
SELECT id, 'Sate Madura 10 Tusuk', 20187, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 29916, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-24 12:11:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bakso Aci Kuah Pedas', 29916, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 33132, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-24 18:31:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 16566, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 31351, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-04-24 08:12:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 31351, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 11908661, 'Gaji Bulanan Utama', 'IN', 'Salary', 'non_tunai', '2026-04-25 08:00:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Gaji Bersih Bulanan (Corporate)', 11908661, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 128127, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-25 12:25:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Mie Goreng Telur', 42518, 2 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 28167, 1 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 14924, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 152329, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-25 20:51:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bakso Aci Kuah Pedas', 32720, 2 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 22102, 2 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 42685, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 199208, 'Refreshing & Hiburan Weekend', 'OUT', 'Entertainment', 'non_tunai', '2026-04-25 15:44:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Tiket Konser Musik', 199208, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 104419, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-26 12:28:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Mie Goreng Telur', 37471, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 12071, 2 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 21403, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 276579, 'Belanja Kebutuhan Mingguan', 'OUT', 'Groceries', 'tunai', '2026-04-26 09:40:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Telur Ayam 1kg', 27455, 1 FROM ins UNION ALL
SELECT id, 'Minyak Goreng 2L', 48374, 2 FROM ins UNION ALL
SELECT id, 'Minyak Goreng 2L', 55510, 1 FROM ins UNION ALL
SELECT id, 'Minyak Goreng 2L', 50744, 1 FROM ins UNION ALL
SELECT id, 'Sabun Cuci Piring', 46122, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 461907, 'Belanja Fashion & Kebutuhan Hobi', 'OUT', 'Shopping', 'non_tunai', '2026-04-26 19:58:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sepatu Sneakers Kasual', 361358, 1 FROM ins UNION ALL
SELECT id, 'Celana Chino Slim Fit', 100549, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 88082, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-27 12:37:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 33954, 1 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 23946, 1 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 15091, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 44812, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-04-27 07:49:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 44812, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 60099, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-28 12:23:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 15947, 2 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 28205, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 36883, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-28 21:26:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bakso Aci Kuah Pedas', 36883, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 27141, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-04-28 07:55:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 27141, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 25200, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-29 12:18:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Ayam Penyet Sambal Ijo', 25200, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 35254, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-29 18:27:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 17627, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 36280, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-04-29 08:05:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 36280, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 141684, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-30 12:17:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 44581, 2 FROM ins UNION ALL
SELECT id, 'Sate Madura 10 Tusuk', 26261, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 41149, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-04-30 20:02:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 41149, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 35534, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-04-30 07:32:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 35534, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 2018429, 'Pendapatan Freelance', 'IN', 'Transfer_In', 'non_tunai', '2026-05-01 16:16:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Pembayaran Jasa Pembuatan Website / Desain', 2018429, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 70816, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-01 12:52:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Teh Manis Dingin', 12974, 1 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 20103, 2 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 17636, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 58624, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-01 18:51:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 29312, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 20112, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-05-01 08:13:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 20112, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 55452, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-03 12:50:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 15049, 1 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 40403, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 131884, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-04 12:49:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Ayam Penyet Sambal Ijo', 33025, 2 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 32917, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 127232, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-04 20:30:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 29142, 1 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 15796, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 41147, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 47922, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-05-04 07:52:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 47922, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 99783, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-05 12:56:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 15075, 2 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 27244, 1 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 42389, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 136215, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-06 12:44:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 29920, 1 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 41212, 2 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 23871, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 398595, 'Tagihan internet rumah (IndiHome/Biznet)', 'OUT', 'Bills', 'non_tunai', '2026-05-06 10:00:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Paket internet WiFi unlimited', 398595, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 360625, 'Tagihan Listrik PLN', 'OUT', 'Bills', 'non_tunai', '2026-05-06 13:00:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Token / Tagihan pascabayar PLN', 360625, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 40862, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-05-06 07:08:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 40862, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 121174, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-07 12:17:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 25013, 1 FROM ins UNION ALL
SELECT id, 'Sate Madura 10 Tusuk', 22747, 1 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 36707, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 121344, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-07 19:18:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Teh Manis Dingin', 40017, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 16779, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 32274, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 41845, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-05-07 08:00:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 41845, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 67774, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-08 12:40:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Ayam Penyet Sambal Ijo', 37504, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 15135, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 46860, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-05-08 08:33:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 46860, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 71032, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-09 12:17:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 35516, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 130867, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-09 19:12:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bakso Aci Kuah Pedas', 38496, 1 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 37436, 2 FROM ins UNION ALL
SELECT id, 'Sate Madura 10 Tusuk', 17499, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 175309, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-10 12:15:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 30227, 1 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 30129, 2 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 42412, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 153674, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-10 21:58:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Teh Manis Dingin', 33145, 2 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 43692, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 408530, 'Tagihan internet rumah (IndiHome/Biznet)', 'OUT', 'Bills', 'non_tunai', '2026-05-10 10:00:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Paket internet WiFi unlimited', 408530, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 570514, 'Tagihan Listrik PLN', 'OUT', 'Bills', 'non_tunai', '2026-05-10 13:00:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Token / Tagihan pascabayar PLN', 570514, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 150635, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-11 12:13:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Ayam Penyet Sambal Ijo', 25452, 2 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 34909, 2 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 29913, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 88810, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-11 18:38:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 44405, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 47258, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-05-11 08:22:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 47258, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 77620, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-12 12:42:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 17748, 2 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 42124, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 61632, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-12 20:29:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Ayam Penyet Sambal Ijo', 23364, 1 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 22302, 1 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 15966, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 41319, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-05-12 07:19:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 41319, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 21632, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-05-13 08:50:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 21632, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 118554, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-14 12:38:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 40700, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 38927, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 27844, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-14 19:28:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 27844, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 48878, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-05-14 08:04:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 48878, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 130410, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-15 12:29:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 26515, 2 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 38690, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 47609, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-05-15 07:35:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 47609, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 174601, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-16 12:15:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 40986, 2 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 32284, 2 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 28061, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 51552, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-17 12:41:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 14549, 2 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 22454, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 94322, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-18 12:21:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 36593, 1 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 18765, 2 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 20199, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 22290, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-05-18 07:55:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 22290, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 120348, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-19 12:25:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Ayam Penyet Sambal Ijo', 35448, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 29660, 1 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 27620, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 105586, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-19 18:26:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Ayam Penyet Sambal Ijo', 27052, 1 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 39267, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 29949, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-05-19 07:35:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 29949, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 29560, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-05-20 08:59:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 29560, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 64252, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-21 12:04:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 43883, 1 FROM ins UNION ALL
SELECT id, 'Sate Madura 10 Tusuk', 20369, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 102274, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-21 20:00:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Ayam Penyet Sambal Ijo', 19011, 2 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 32126, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 25699, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-05-21 08:17:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 25699, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 2623308, 'Pendapatan Freelance', 'IN', 'Transfer_In', 'non_tunai', '2026-05-22 14:50:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Pembayaran Jasa Pembuatan Website / Desain', 2623308, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 69872, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-22 12:53:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Mie Goreng Telur', 26089, 1 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 43783, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 66125, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-22 20:50:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 41417, 1 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 24708, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 24935, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-23 12:52:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 24935, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 253706, 'Belanja Fashion & Kebutuhan Hobi', 'OUT', 'Shopping', 'non_tunai', '2026-05-23 17:24:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Jam Tangan Sporty', 253706, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 123692, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-24 12:56:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 36174, 2 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 25672, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 252900, 'Belanja Kebutuhan Mingguan', 'OUT', 'Groceries', 'tunai', '2026-05-24 09:19:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Pasta Gigi Herbal', 27143, 1 FROM ins UNION ALL
SELECT id, 'Pasta Gigi Herbal', 30089, 2 FROM ins UNION ALL
SELECT id, 'Gula Pasir Rose Brand 1kg', 27650, 1 FROM ins UNION ALL
SELECT id, 'Indomie Goreng 1 Dus', 55603, 2 FROM ins UNION ALL
SELECT id, 'Pasta Gigi Herbal', 26723, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 118674, 'Refreshing & Hiburan Weekend', 'OUT', 'Entertainment', 'non_tunai', '2026-05-24 18:36:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Tiket Bioskop XXI', 118674, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 11833020, 'Gaji Bulanan Utama', 'IN', 'Salary', 'non_tunai', '2026-05-25 08:00:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Gaji Bersih Bulanan (Corporate)', 11833020, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 29789, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-25 12:22:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Teh Manis Dingin', 29789, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 150593, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-25 18:49:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bakso Aci Kuah Pedas', 42472, 1 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 44502, 2 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 19117, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 23825, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-05-26 07:43:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 23825, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 75590, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-27 12:30:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 19669, 2 FROM ins UNION ALL
SELECT id, 'Sate Madura 10 Tusuk', 36252, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 22096, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-05-27 08:04:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 22096, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 90464, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-28 12:41:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 28576, 2 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 33312, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 93845, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-28 21:15:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Teh Manis Dingin', 28726, 2 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 36393, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 48717, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-05-28 07:51:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 48717, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 1305923, 'Pendapatan Freelance', 'IN', 'Transfer_In', 'non_tunai', '2026-05-29 15:02:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Pembayaran Jasa Pembuatan Website / Desain', 1305923, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 61848, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-29 12:20:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 33440, 1 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 14204, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 26498, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-05-29 08:33:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 26498, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 224186, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-30 12:30:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 37234, 2 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 35092, 2 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 39767, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 126475, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-30 21:28:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Mie Goreng Telur', 36499, 1 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 44988, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 111564, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-31 12:29:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Ayam Penyet Sambal Ijo', 33086, 1 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 39239, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 130829, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-05-31 20:55:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 23369, 1 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 40764, 2 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 12966, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 42721, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-01 12:48:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Ayam Penyet Sambal Ijo', 25973, 1 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 16748, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 160808, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-01 19:52:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 23234, 2 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 43776, 2 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 26788, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 23373, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-06-01 08:47:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 23373, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 44474, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-02 12:01:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 44474, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 124092, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-02 19:01:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 28419, 2 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 20747, 2 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 12880, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 41159, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-06-02 07:38:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 41159, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 21150, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-03 12:48:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Ayam Penyet Sambal Ijo', 21150, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 34995, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-06-03 07:59:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 34995, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 56725, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-04 12:08:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 37184, 1 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 19541, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 122482, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-05 12:30:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Teh Manis Dingin', 30564, 2 FROM ins UNION ALL
SELECT id, 'Sate Madura 10 Tusuk', 41615, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 19739, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 382246, 'Tagihan internet rumah (IndiHome/Biznet)', 'OUT', 'Bills', 'non_tunai', '2026-06-05 10:00:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Paket internet WiFi unlimited', 382246, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 419556, 'Tagihan Listrik PLN', 'OUT', 'Bills', 'non_tunai', '2026-06-05 13:00:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Token / Tagihan pascabayar PLN', 419556, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 26588, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-06-05 08:25:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 26588, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 287878, 'Belanja Kebutuhan Mingguan', 'OUT', 'Groceries', 'tunai', '2026-06-07 10:38:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Gula Pasir Rose Brand 1kg', 70766, 1 FROM ins UNION ALL
SELECT id, 'Susu UHT Full Cream 1L', 27022, 1 FROM ins UNION ALL
SELECT id, 'Sabun Cuci Piring', 53276, 1 FROM ins UNION ALL
SELECT id, 'Minyak Goreng 2L', 18979, 2 FROM ins UNION ALL
SELECT id, 'Pasta Gigi Herbal', 67041, 1 FROM ins UNION ALL
SELECT id, 'Telur Ayam 1kg', 31815, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 86336, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-08 12:48:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 17162, 2 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 31145, 1 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 20867, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 33057, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-06-08 07:14:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 33057, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 88514, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-09 12:09:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 33514, 2 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 21486, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 395961, 'Tagihan internet rumah (IndiHome/Biznet)', 'OUT', 'Bills', 'non_tunai', '2026-06-09 10:00:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Paket internet WiFi unlimited', 395961, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 497209, 'Tagihan Listrik PLN', 'OUT', 'Bills', 'non_tunai', '2026-06-09 13:00:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Token / Tagihan pascabayar PLN', 497209, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 43729, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-06-09 08:17:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 43729, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 100812, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-10 12:59:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 30397, 2 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 20009, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 103329, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-10 19:16:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 33915, 2 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 35499, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 32918, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-06-10 07:55:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 32918, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 25630, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-11 12:44:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 12815, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 23131, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-11 21:27:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Ayam Penyet Sambal Ijo', 23131, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 29550, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-06-11 08:24:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 29550, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 66550, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-12 12:17:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 33013, 1 FROM ins UNION ALL
SELECT id, 'Sate Madura 10 Tusuk', 33537, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 25565, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-06-12 07:57:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 25565, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 54520, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-13 12:54:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 27260, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 41711, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-14 12:01:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 41711, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 100863, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-14 21:55:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 28271, 2 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 44321, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 221737, 'Belanja Kebutuhan Mingguan', 'OUT', 'Groceries', 'tunai', '2026-06-14 11:25:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Pasta Gigi Herbal', 24511, 2 FROM ins UNION ALL
SELECT id, 'Gula Pasir Rose Brand 1kg', 19120, 2 FROM ins UNION ALL
SELECT id, 'Indomie Goreng 1 Dus', 39045, 2 FROM ins UNION ALL
SELECT id, 'Susu UHT Full Cream 1L', 56385, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 28434, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-15 12:22:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 14217, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 35792, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-15 18:24:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Ayam Penyet Sambal Ijo', 35792, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 119592, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-16 12:14:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Mie Goreng Telur', 25334, 2 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 34462, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 27753, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-16 19:47:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 27753, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 171514, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-18 12:20:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 40525, 2 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 24516, 1 FROM ins UNION ALL
SELECT id, 'Sate Madura 10 Tusuk', 32974, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 25308, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-06-18 08:11:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 25308, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 16498, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-19 12:07:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Mie Goreng Telur', 16498, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 138170, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-19 20:31:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Mie Goreng Telur', 36209, 2 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 32876, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 161934, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-20 12:15:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 16662, 1 FROM ins UNION ALL
SELECT id, 'Sate Madura 10 Tusuk', 33670, 2 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 38966, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 76122, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-20 18:29:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 38061, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 291394, 'Belanja Fashion & Kebutuhan Hobi', 'OUT', 'Shopping', 'non_tunai', '2026-06-20 13:42:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Kaos Polos Cotton Combed', 291394, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 79486, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-21 12:27:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 21749, 2 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 17994, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 96300, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-21 18:43:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bakso Aci Kuah Pedas', 25535, 1 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 34594, 1 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 36171, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 196396, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-22 12:55:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 43489, 2 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 44108, 2 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 21202, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 67204, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-22 19:08:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 33602, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 32100, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-06-22 08:15:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 32100, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 63290, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-23 12:58:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 41524, 1 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 21766, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 30584, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-06-23 07:24:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 30584, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 49676, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-24 12:16:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 13777, 1 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 35899, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 45108, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-24 20:14:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Teh Manis Dingin', 22554, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 9616756, 'Gaji Bulanan Utama', 'IN', 'Salary', 'non_tunai', '2026-06-25 08:00:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Gaji Bersih Bulanan (Corporate)', 9616756, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 28264, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-25 12:09:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Teh Manis Dingin', 28264, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 78951, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-25 19:36:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Ayam Penyet Sambal Ijo', 18516, 1 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 38874, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 21561, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 31871, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-06-25 07:43:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 31871, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 1801935, 'Pendapatan Freelance', 'IN', 'Transfer_In', 'non_tunai', '2026-06-26 16:25:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Pembayaran Jasa Pembuatan Website / Desain', 1801935, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 22202, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-06-26 08:01:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 22202, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 123225, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-27 12:48:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Mie Goreng Telur', 33423, 1 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 44901, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 164211, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-27 21:33:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 27322, 2 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 40867, 2 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 27833, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 15744, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-28 12:21:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 15744, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 287792, 'Belanja Kebutuhan Mingguan', 'OUT', 'Groceries', 'tunai', '2026-06-28 10:09:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Gula Pasir Rose Brand 1kg', 64098, 1 FROM ins UNION ALL
SELECT id, 'Sabun Cuci Piring', 29691, 1 FROM ins UNION ALL
SELECT id, 'Minyak Goreng 2L', 70320, 2 FROM ins UNION ALL
SELECT id, 'Susu UHT Full Cream 1L', 53363, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 106410, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-29 12:07:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 40498, 1 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 43294, 1 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 22618, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 37595, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-29 20:31:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 37595, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 39890, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-06-29 08:51:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 39890, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 131791, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-06-30 12:12:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Mie Goreng Telur', 27965, 2 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 15669, 1 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 30096, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 32191, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-06-30 08:51:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 32191, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 156914, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-01 12:12:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 36282, 2 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 21382, 2 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 41586, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 123575, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-02 12:26:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 24868, 1 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 40273, 1 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 29217, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 143628, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-02 19:15:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Teh Manis Dingin', 35278, 2 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 36536, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 22872, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-07-02 07:40:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 22872, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 137823, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-03 12:15:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 39901, 2 FROM ins UNION ALL
SELECT id, 'Sate Madura 10 Tusuk', 23611, 1 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 17205, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 62598, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-04 12:43:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 40386, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 22212, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 55962, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-05 12:22:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Teh Manis Dingin', 23093, 1 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 20507, 1 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 12362, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 292239, 'Belanja Kebutuhan Mingguan', 'OUT', 'Groceries', 'tunai', '2026-07-05 11:03:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Beras Ramos 5kg', 22112, 1 FROM ins UNION ALL
SELECT id, 'Sabun Cuci Piring', 41697, 2 FROM ins UNION ALL
SELECT id, 'Sabun Cuci Piring', 64558, 1 FROM ins UNION ALL
SELECT id, 'Pasta Gigi Herbal', 25454, 1 FROM ins UNION ALL
SELECT id, 'Pasta Gigi Herbal', 40955, 1 FROM ins UNION ALL
SELECT id, 'Susu UHT Full Cream 1L', 27883, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 247362, 'Belanja Fashion & Kebutuhan Hobi', 'OUT', 'Shopping', 'non_tunai', '2026-07-05 19:50:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Jaket Bomber Windbreaker', 141997, 1 FROM ins UNION ALL
SELECT id, 'Jaket Bomber Windbreaker', 105365, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 65187, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-06 12:55:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 29753, 1 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 35434, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 135505, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-06 19:18:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 13413, 2 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 42653, 1 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 33013, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 24737, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-07-06 08:03:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 24737, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 192626, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-07 12:46:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Mie Goreng Telur', 19558, 1 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 41845, 2 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 44689, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 60736, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-07 19:27:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 30368, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 25456, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-08 12:08:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Ayam Penyet Sambal Ijo', 25456, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 21704, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-07-08 07:56:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 21704, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 165816, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-09 12:13:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 42109, 2 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 16410, 1 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 32594, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 27784, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-09 19:49:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 13892, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 132400, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-10 12:54:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 30585, 1 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 17815, 1 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 42000, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 20112, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-10 18:48:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 20112, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 29259, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-07-10 08:16:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 29259, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 40446, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-11 12:57:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Teh Manis Dingin', 40446, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 193826, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-12 12:48:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 37904, 2 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 38527, 2 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 20482, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 61733, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-13 12:25:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 18242, 1 FROM ins UNION ALL
SELECT id, 'Teh Manis Dingin', 43491, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 84016, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-14 12:08:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 42008, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 29011, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-14 19:27:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 29011, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 20772, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-07-14 07:32:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 20772, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 116260, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-15 12:03:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Ayam Penyet Sambal Ijo', 24837, 2 FROM ins UNION ALL
SELECT id, 'Ayam Penyet Sambal Ijo', 32797, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 33789, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 33134, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-07-15 08:24:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 33134, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 67002, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-16 12:16:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Mie Goreng Telur', 34327, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 32675, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 87619, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-16 20:25:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 14637, 2 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 33531, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 24814, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 1602646, 'Pendapatan Freelance', 'IN', 'Transfer_In', 'non_tunai', '2026-07-17 14:59:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Pembayaran Jasa Pembuatan Website / Desain', 1602646, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 25189, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-17 12:53:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 25189, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 45011, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-18 12:09:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Es Kopi Susu Aren', 12754, 1 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 18173, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 14084, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 92592, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-18 21:57:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bakso Aci Kuah Pedas', 12920, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 27880, 1 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 25896, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 68087, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-19 12:46:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Nasi Goreng Spesial', 28670, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 39417, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 126820, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-19 18:33:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Roti Bakar Cokelat', 25462, 2 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 21523, 2 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 16425, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 284638, 'Belanja Kebutuhan Mingguan', 'OUT', 'Groceries', 'tunai', '2026-07-19 10:35:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sabun Cuci Piring', 32845, 2 FROM ins UNION ALL
SELECT id, 'Gula Pasir Rose Brand 1kg', 31711, 1 FROM ins UNION ALL
SELECT id, 'Minyak Goreng 2L', 60097, 1 FROM ins UNION ALL
SELECT id, 'Indomie Goreng 1 Dus', 63570, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 151186, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-20 12:30:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Ayam Penyet Sambal Ijo', 22157, 2 FROM ins UNION ALL
SELECT id, 'Nasi Goreng Spesial', 40969, 2 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 24934, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 87109, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-20 18:21:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 38617, 1 FROM ins UNION ALL
SELECT id, 'Roti Bakar Cokelat', 24246, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 31738, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-07-20 07:58:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 31738, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 51273, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-21 12:59:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Sate Madura 10 Tusuk', 16099, 1 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 17587, 2 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 107923, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-21 21:33:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Mie Goreng Telur', 44072, 2 FROM ins UNION ALL
SELECT id, 'Bakso Aci Kuah Pedas', 19779, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 42099, 'Operasional Transport Harian', 'OUT', 'Transport', 'tunai', '2026-07-21 08:18:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bensin kendaraan / Saldo e-money KRL-MRT', 42099, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 30864, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-22 12:57:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Bakso Aci Kuah Pedas', 30864, 1 FROM ins;

WITH ins AS (
  INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at) VALUES ((SELECT id FROM auth.users ORDER BY created_at LIMIT 1), 145892, 'Konsumsi Makanan Harian', 'OUT', 'Food', 'tunai', '2026-07-22 19:23:00+07')
  RETURNING id
)
INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)
SELECT id, 'Mie Goreng Telur', 18974, 2 FROM ins UNION ALL
SELECT id, 'Mie Goreng Telur', 26333, 2 FROM ins UNION ALL
SELECT id, 'Es Kopi Susu Aren', 27639, 2 FROM ins;
