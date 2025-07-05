# Sistem Pesanan - Flutter Auth App

## Overview

Sistem pesanan yang lengkap dengan sinkronisasi real-time antara admin dan pengguna, termasuk notifikasi untuk pesanan yang belum dibayar dan menunggu konfirmasi.

## Fitur Utama

### 1. Status Pesanan

- **Unpaid**: Pesanan belum dibayar
- **Paid**: Sudah dibayar, menunggu konfirmasi admin
- **Confirmed**: Dikonfirmasi admin, sedang diproses
- **Shipped**: Dikirim
- **Delivered**: Selesai/diterima
- **Cancelled**: Dibatalkan

### 2. Notifikasi Real-time

- Badge notifikasi di menu pesanan user
- Update otomatis saat status berubah
- Sinkronisasi antara admin dan user

### 3. Halaman User

- **MyOrdersScreen**: Halaman utama dengan tab untuk setiap status
- **UnpaidOrdersScreen**: Pesanan yang belum dibayar
- **PendingConfirmationScreen**: Pesanan menunggu konfirmasi admin
- **CompletedOrdersScreen**: Pesanan yang sudah selesai

### 4. Halaman Admin

- **IncomingOrdersScreen**: Pesanan yang menunggu konfirmasi
- **OrderManagementScreen**: Manajemen semua pesanan dengan filter status

## Struktur File

### Models

```
lib/models/
├── order_model.dart          # Model Order dengan enum status
└── user_model.dart           # Model User (existing)
```

### Services

```
lib/services/
├── order_service.dart        # Service untuk operasi CRUD pesanan
├── auth_service.dart         # Service autentikasi (existing)
└── payment_service.dart      # Service pembayaran (existing)
```

### Screens

```
lib/screens/
├── my_orders_screen.dart     # Halaman utama pesanan user
├── unpaid_orders_screen.dart # Pesanan belum bayar
├── pending_confirmation_screen.dart # Pesanan menunggu konfirmasi
├── completed_orders_screen.dart     # Pesanan selesai
└── admin/
    ├── incoming_orders_screen.dart  # Pesanan masuk admin
    └── order_management_screen.dart # Manajemen pesanan admin
```

## Cara Kerja

### 1. Pembuatan Pesanan

1. User checkout dari keranjang
2. OrderService.createOrder() membuat pesanan dengan status 'unpaid'
3. Payment URL dibuat dan disimpan
4. User diarahkan ke halaman pembayaran

### 2. Pembayaran

1. User melakukan pembayaran via Midtrans
2. PaymentWebViewScreen mendeteksi pembayaran berhasil
3. OrderService.updateOrderPaymentDetails() mengupdate status ke 'paid'
4. Pesanan muncul di halaman admin untuk konfirmasi

### 3. Konfirmasi Admin

1. Admin melihat pesanan di IncomingOrdersScreen
2. Admin klik "Konfirmasi Pesanan"
3. OrderService.confirmOrder() mengupdate status ke 'confirmed'
4. User melihat update di PendingConfirmationScreen

### 4. Update Status

1. Admin dapat update status di OrderManagementScreen
2. Setiap update menggunakan OrderService.updateOrderStatus()
3. Perubahan terlihat real-time di semua halaman

## Notifikasi

### User Side

- Badge merah untuk pesanan belum bayar
- Badge orange untuk pesanan menunggu konfirmasi
- Badge hijau untuk pesanan selesai
- Update otomatis menggunakan StreamBuilder

### Admin Side

- Badge di setiap tab menunjukkan jumlah pesanan
- Real-time update menggunakan StreamBuilder
- Statistik pesanan di dashboard

## Database Schema

### Collection: orders

```json
{
  "orderId": "ORD1234567890",
  "userId": "user_uid",
  "items": [
    {
      "id": "product_id",
      "name": "Product Name",
      "price": 100000,
      "quantity": 2,
      "imageUrl": "url",
      "size": "M"
    }
  ],
  "totalAmount": 200000,
  "status": "paid",
  "orderDate": "timestamp",
  "paymentDate": "timestamp",
  "confirmedDate": "timestamp",
  "shippedDate": "timestamp",
  "deliveredDate": "timestamp",
  "paymentDetails": {},
  "paymentUrl": "url",
  "shippingAddress": "address",
  "customerName": "name",
  "customerPhone": "phone",
  "adminNotes": "notes"
}
```

## Firestore Rules

```javascript
match /orders/{orderId} {
  // User dapat membuat pesanan sendiri
  allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;

  // User dapat membaca pesanan sendiri, admin dapat membaca semua
  allow read: if request.auth != null && (
    resource.data.userId == request.auth.uid ||
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'
  );

  // User dapat update pesanan sendiri
  allow update: if request.auth != null && resource.data.userId == request.auth.uid;

  // User dapat hapus pesanan sendiri
  allow delete: if request.auth != null && resource.data.userId == request.auth.uid;
}
```

## Integrasi dengan Sistem Existing

### 1. Bag Screen

- Menggunakan OrderService.createOrder() saat checkout
- Menghapus item dari keranjang setelah checkout

### 2. Payment WebView

- Menggunakan OrderService.updateOrderPaymentDetails() saat pembayaran berhasil
- Update status otomatis ke 'paid'

### 3. Profile Screen

- Menampilkan menu pesanan dengan notifikasi real-time
- Navigasi ke MyOrdersScreen

### 4. Admin Home

- Menambahkan menu "Manajemen Pesanan"
- Statistik pesanan di dashboard

## Keunggulan Sistem

1. **Real-time Sync**: Menggunakan StreamBuilder untuk update otomatis
2. **Scalable**: Struktur modular dan terpisah
3. **User-friendly**: UI yang intuitif dengan notifikasi
4. **Admin Control**: Kontrol penuh atas status pesanan
5. **Error Handling**: Penanganan error yang baik
6. **Performance**: Optimized queries dan caching

## Testing

### User Flow

1. Login sebagai user
2. Tambahkan item ke keranjang
3. Checkout dan buat pesanan
4. Lakukan pembayaran
5. Lihat status di menu pesanan
6. Tunggu konfirmasi admin

### Admin Flow

1. Login sebagai admin
2. Lihat pesanan masuk di IncomingOrdersScreen
3. Konfirmasi pesanan
4. Update status di OrderManagementScreen
5. Monitor statistik pesanan

## Troubleshooting

### Common Issues

1. **Stream tidak update**: Pastikan Firestore rules benar
2. **Notifikasi tidak muncul**: Cek OrderService.getOrderCountsByStatus()
3. **Status tidak berubah**: Verifikasi OrderService.updateOrderStatus()
4. **Permission denied**: Periksa Firestore rules

### Debug Tips

- Gunakan print statements di OrderService
- Monitor Firestore console untuk queries
- Cek network tab untuk API calls
- Verifikasi user role untuk admin functions

# Sistem Order dan Stok - FirjeStore

## Overview

Sistem order dan stok yang terintegrasi untuk aplikasi e-commerce FirjeStore dengan fitur sinkronisasi real-time antara admin dan pengguna.

## Fitur Utama

### 1. Sistem Order Terintegrasi

- **Status Order**: unpaid → paid → confirmed → shipped → delivered/cancelled
- **Real-time Updates**: Menggunakan Firestore streams untuk update otomatis
- **Notification Badges**: Badge pada menu untuk unpaid dan pending confirmation orders
- **Order History**: Riwayat lengkap semua pesanan user

### 2. Sistem Stok Terintegrasi

- **Stok Real-time**: Stok produk terupdate secara real-time
- **Validasi Stok**: Mencegah pembelian melebihi stok yang tersedia
- **Pengurangan Otomatis**: Stok berkurang otomatis saat order dibuat
- **Indikator Visual**: Status stok ditampilkan dengan warna dan badge

### 3. Admin Management

- **Order Management**: Kelola semua pesanan dengan filter status
- **Stock Management**: Update stok produk dengan validasi
- **Order Confirmation**: Konfirmasi dan update status pesanan
- **Payment Reports**: Laporan pembayaran dan statistik

## Arsitektur Sistem

### Database Schema

#### Collection: `products`

```javascript
{
  id: "product_id",
  name: "Nama Produk",
  price: 150000,
  stock: 10,           // Stok tersedia
  description: "Deskripsi produk",
  category: "Pakaian",
  imageUrl: "https://...",
  discount: 10         // Opsional, dalam persen
}
```

#### Collection: `carts/{userId}/items`

```javascript
{
  id: "cart_item_id",
  productId: "product_id",
  name: "Nama Produk",
  price: 150000,
  quantity: 2,
  stock: 10,           // Stok saat ditambahkan ke cart
  imageUrl: "https://...",
  size: "L",
  category: "Pakaian"
}
```

#### Collection: `orders`

```javascript
{
  id: "order_id",
  orderId: "ORD1234567890",
  userId: "user_id",
  items: [
    {
      id: "product_id",
      productId: "product_id",
      name: "Nama Produk",
      price: 150000,
      quantity: 2,
      imageUrl: "https://...",
      size: "L"
    }
  ],
  totalAmount: 300000,
  status: "unpaid",    // unpaid, paid, confirmed, shipped, delivered, cancelled
  orderDate: Timestamp,
  paymentUrl: "https://...",
  paymentDetails: {...},
  shippingAddress: "Alamat pengiriman",
  customerName: "Nama Customer",
  customerPhone: "08123456789"
}
```

## Implementasi Stok

### 1. Validasi Stok Saat Menambah ke Cart

- **Product Detail**: Cek stok sebelum menambah ke cart
- **Cart Update**: Validasi stok saat mengubah quantity
- **Real-time Check**: Ambil stok terbaru dari database

### 2. Pengurangan Stok Otomatis

- **Order Creation**: Stok berkurang saat order dibuat
- **Batch Operation**: Menggunakan Firestore batch untuk konsistensi
- **Error Handling**: Rollback jika ada error

### 3. Indikator Visual Stok

- **Product Cards**: Badge stok di pojok kanan atas
- **Cart Items**: Info stok di setiap item cart
- **Admin Panel**: Status stok dengan warna berbeda

## File yang Diupdate

### User Side

1. **`lib/screens/bag_screen.dart`**

   - Tambah validasi stok pada quantity controls
   - Tampilkan info stok di setiap item
   - Update fungsi `_updateQuantity` untuk cek stok real-time

2. **`lib/screens/product_detail.dart`**

   - Validasi stok sebelum menambah ke cart
   - Cek stok saat update quantity existing item

3. **`lib/widgets/product_item.dart`**

   - Tambah parameter `stock`
   - Tampilkan badge stok di product card

4. **`lib/screens/home_screen.dart`**

   - Update ProductItem calls dengan parameter stock

5. **`lib/screens/search_screen.dart`**
   - Update ProductItem calls dengan parameter stock

### Admin Side

1. **`lib/screens/admin/product_management_screen.dart`**

   - Update ProductCard untuk tampilkan status stok dengan warna
   - Indikator visual stok habis vs tersedia

2. **`lib/screens/admin/product_form_screen.dart`**
   - Tambah validasi stok tidak boleh negatif
   - Helper text untuk field stok

### Services

1. **`lib/services/order_service.dart`**
   - Update `createOrder` untuk kurangi stok otomatis
   - Gunakan Firestore batch untuk konsistensi
   - Validasi stok sebelum membuat order

## Cara Kerja Sistem Stok

### 1. Saat User Menambah ke Cart

```dart
// Di product_detail.dart
if (widget.product.stock <= 0) {
  // Tampilkan error: stok habis
  return;
}

// Cek quantity tidak melebihi stok
if (newQuantity > widget.product.stock) {
  // Tampilkan error: stok tidak mencukupi
  return;
}
```

### 2. Saat User Update Quantity di Cart

```dart
// Di bag_screen.dart
final productDoc = await FirebaseFirestore.instance
    .collection('products')
    .doc(productId)
    .get();

final availableStock = productDoc.data()['stock'] ?? 0;

if (newQuantity > availableStock) {
  // Tampilkan error dan batalkan update
  return;
}
```

### 3. Saat Order Dibuat

```dart
// Di order_service.dart
for (var item in items) {
  final productDoc = await _firestore.collection('products').doc(productId).get();
  final currentStock = productDoc.data()['stock'] ?? 0;

  if (currentStock < quantity) {
    throw Exception('Stok tidak mencukupi');
  }

  // Kurangi stok
  final newStock = currentStock - quantity;
  batch.update(productRef, {'stock': newStock});
}
```

## Keuntungan Sistem Ini

1. **Konsistensi Data**: Stok selalu akurat dan sinkron
2. **User Experience**: User tidak bisa membeli melebihi stok
3. **Admin Control**: Admin bisa monitor dan update stok dengan mudah
4. **Real-time Updates**: Perubahan stok terlihat langsung
5. **Error Prevention**: Mencegah overselling dan konflik data

## Testing

### Test Cases untuk Stok

1. **Stok Habis**: User tidak bisa menambah produk dengan stok 0
2. **Stok Terbatas**: User tidak bisa membeli melebihi stok yang tersedia
3. **Update Stok**: Admin update stok, user langsung melihat perubahan
4. **Order Creation**: Stok berkurang otomatis saat order dibuat
5. **Concurrent Orders**: Sistem handle multiple orders dengan benar

## Maintenance

### Monitoring Stok

- Admin bisa monitor stok rendah melalui dashboard
- Notifikasi otomatis untuk stok yang hampir habis
- Backup dan restore data stok secara berkala

### Performance

- Gunakan Firestore batch untuk operasi multiple
- Cache data produk untuk mengurangi read operations
- Optimize queries dengan proper indexing

## Alur Pengelolaan Stok (DIPERBAIKI)

### Sebelumnya (Masalah):

1. Stok dikurangi saat order dibuat (status: unpaid)
2. Jika pembayaran ditunda/dibatalkan, stok tidak dikembalikan
3. Menyebabkan stok berkurang meskipun pembayaran belum selesai

### Sekarang (Diperbaiki):

1. **Stok TIDAK dikurangi saat order dibuat** (status: unpaid)
2. **Stok hanya dikurangi saat pembayaran berhasil** (status: unpaid → paid)
3. **Stok dikembalikan jika pesanan dibatalkan setelah pembayaran**

### Logika Baru:

#### 1. Pembuatan Pesanan (`createOrder`)

```dart
// Hanya periksa stok tersedia (tanpa mengurangi)
// Buat order dengan status 'unpaid'
// Stok belum berkurang
```

#### 2. Pembayaran Berhasil (`updateOrderPaymentDetails`)

```dart
// Periksa stok masih tersedia
// Kurangi stok untuk setiap item
// Update status menjadi 'paid'
```

#### 3. Pembatalan Pesanan (`cancelOrderWithRestore`)

```dart
// Jika status 'paid', 'confirmed', atau 'shipped':
//   - Kembalikan stok ke produk
// Jika status 'unpaid':
//   - Tidak perlu mengembalikan stok (karena belum dikurangi)
// Kembalikan item ke keranjang
// Hapus pesanan
```

## Keuntungan Perbaikan:

1. **Stok akurat**: Stok hanya berkurang saat pembayaran benar-benar berhasil
2. **Tidak ada stok hilang**: Pesanan unpaid yang dibatalkan tidak mempengaruhi stok
3. **Konsistensi data**: Stok selalu sesuai dengan pesanan yang sudah dibayar
4. **User experience lebih baik**: User bisa menunda pembayaran tanpa mempengaruhi stok

## File yang Diperbarui:

- `lib/services/order_service.dart`: Logika pengelolaan stok
- `lib/screens/payment_webview_screen.dart`: Sudah menggunakan logika baru
- `lib/screens/unpaid_orders_screen.dart`: Sudah menggunakan logika baru

## Testing:

1. Buat pesanan baru → stok tidak berkurang
2. Lakukan pembayaran → stok berkurang
3. Batalkan pesanan unpaid → stok tidak berubah
4. Batalkan pesanan paid → stok dikembalikan
