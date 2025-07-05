# Duplicate Order ID Fix

## Masalah yang Ditemukan

Saat melakukan checkout, aplikasi membuat **2 order ID yang berbeda**:

1. **Order ID dari Flutter (OrderService.createOrder)**:

   - Format: `order-{timestamp}-{random}`
   - Contoh: `order-1750638180882-0882`
   - Dibuat di client side

2. **Order ID dari Server (server.js)**:
   - Format: `order-{timestamp}-{hex}`
   - Contoh: `order-1750638181123-49896ee9`
   - Dibuat di server side

## Alur yang Bermasalah

1. User melakukan checkout di `bag_screen.dart`
2. `OrderService.createOrder()` dipanggil → **membuat order ID #1**
3. `PaymentService.createTransaction()` dipanggil → **membuat order ID #2 di server**
4. Server menyimpan order dengan ID #2 ke Firestore
5. Akibatnya ada **2 order yang berbeda** dengan ID yang berbeda

## Solusi yang Diterapkan

### 1. Modifikasi Server (server.js)

- Server sekarang menerima `orderId` dari client
- Server tidak lagi membuat order ID baru
- Server hanya memverifikasi bahwa order sudah ada di Firestore
- Server menggunakan order ID yang sudah ada untuk Midtrans

### 2. Modifikasi PaymentService

- `createTransaction()` sekarang menerima parameter `orderId`
- Order ID dikirim ke server untuk konsistensi

### 3. Modifikasi BagScreen

- Order ID yang dibuat di Flutter dikirim ke PaymentService
- Logging ditambahkan untuk tracking

### 4. Cleanup Tools

- `cleanupLegacyDuplicateOrders()`: Membersihkan order duplikat yang sudah ada
- `cleanupSpecificDuplicateOrders()`: Membersihkan order duplikat spesifik
- Debug button di Profile Screen untuk menjalankan cleanup

## Langkah-langkah untuk Mengatasi Masalah Saat Ini

### 1. Restart Server

```bash
# Matikan server yang sedang berjalan
taskkill /f /im node.exe

# Jalankan server dengan kode yang sudah diperbaiki
cd server && npm start
```

### 2. Cleanup Order Duplikat yang Ada

1. Buka Profile Screen di aplikasi
2. Tekan tombol debug berwarna **deep orange** (🎯) untuk membersihkan order duplikat spesifik
3. Periksa console log untuk melihat proses cleanup
4. Verifikasi bahwa order `order-1750638181123-49896ee9` (unpaid) sudah dihapus
5. Pastikan order `order-1750638180882-0882` (paid) tetap ada

### 3. Test Checkout Baru

1. Lakukan checkout seperti biasa
2. Periksa console log untuk memastikan hanya 1 order ID yang dibuat
3. Verifikasi bahwa order muncul dengan benar di UI

### 4. Verifikasi Hasil

1. Buka My Orders
2. Periksa bahwa tidak ada lagi order duplikat
3. Periksa bahwa order yang sudah dibayar tidak muncul di "Belum Bayar"

## Log yang Diharapkan

### Checkout Berhasil (Setelah Fix)

```
🚀 [createOrder] Starting order creation process...
   - User ID: user123
   - Items count: 2
   - Total amount: 150000
   - Items: product1_1_M|product2_2_L
📦 [createOrder] Checking product availability...
✅ [createOrder] All products available, generating new order ID...
🆔 [createOrder] Generated order ID: order-1750638180882-0882
🆕 [createOrder] Creating new order: order-1750638180882-0882
   - Items: product1_1_M|product2_2_L
   - Total Amount: 150000
   - User ID: user123
✅ [createOrder] Order created successfully in Firestore: order-1750638180882-0882
✅ [bag_screen] Order created successfully: order-1750638180882-0882
🔄 [bag_screen] Proceeding to payment service...
📤 [bag_screen] Sending order to payment service with ID: order-1750638180882-0882
✨ Using existing order ID from client: order-1750638180882-0882
✅ Order order-1750638180882-0882 found in Firestore, proceeding with payment
✅ [bag_screen] Payment service response received
   - Order ID in response: order-1750638180882-0882
   - Redirect URL: https://app.midtrans.com/snap/v2/vtweb/...
```

### Cleanup Berhasil

```
🔍 [cleanupSpecificDuplicateOrders] Cleaning up specific duplicate orders...
🔍 [cleanupSpecificDuplicateOrders] Found order: order-1750638180882-0882
   - Status: paid
   - Payment Details: Yes
   - Total Amount: 150000
   - Items count: 2
   ✅ Keeping paid order with payment details: order-1750638180882-0882
🔍 [cleanupSpecificDuplicateOrders] Found order: order-1750638181123-49896ee9
   - Status: unpaid
   - Payment Details: No
   - Total Amount: 150000
   - Items count: 2
   🗑️ Deleting unpaid order without payment details: order-1750638181123-49896ee9
   ✅ Successfully deleted: order-1750638181123-49896ee9
🎉 [cleanupSpecificDuplicateOrders] Cleanup completed!
```

## Troubleshooting

### Jika Masih Ada Order Duplikat

1. Pastikan server sudah restart dengan kode yang baru
2. Jalankan `cleanupSpecificDuplicateOrders()`
3. Periksa console log untuk detail
4. Test checkout baru

### Jika Order Tidak Muncul

1. Periksa Firestore untuk memastikan order tersimpan
2. Jalankan `checkAndFixOrderStatuses()`
3. Periksa console log untuk error

### Jika Payment Gagal

1. Periksa koneksi ke server
2. Periksa konfigurasi Midtrans
3. Periksa console log server untuk error detail

## Pencegahan di Masa Depan

1. **Single Source of Truth**: Order ID hanya dibuat di satu tempat (Flutter)
2. **Validation**: Server memverifikasi order sudah ada sebelum membuat transaksi
3. **Logging**: Logging yang detail untuk tracking
4. **Cleanup Tools**: Tools untuk membersihkan data yang bermasalah
5. **Monitoring**: Monitor console log untuk mendeteksi duplikasi sejak awal
