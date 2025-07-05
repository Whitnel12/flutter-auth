# Perbaikan Pengelolaan Stok - Stock Management Fix

## Masalah yang Ditemukan

Pada sistem sebelumnya, stok produk berkurang saat pesanan dibuat dengan status `unpaid`, meskipun pembayaran belum selesai. Ini menyebabkan:

- Stok tidak akurat
- Stok berkurang meskipun pembayaran ditunda/dibatalkan
- Ketidaksesuaian antara stok dan pesanan yang benar-benar dibayar
- Produk dengan stok 0 masih ditampilkan di katalog

## Solusi yang Diterapkan

### 1. Perubahan Logika `createOrder`

**Sebelum:**

```dart
// Stok dikurangi saat order dibuat
final batch = _firestore.batch();
for (var item in items) {
  // Kurangi stok
  final newStock = currentStock - quantity;
  batch.update(productRef, {'stock': newStock});
}
await batch.commit();
```

**Sesudah:**

```dart
// Hanya periksa stok tersedia (tanpa mengurangi)
for (var item in items) {
  // Periksa apakah stok mencukupi
  if (currentStock < quantity) {
    throw Exception('Stok tidak mencukupi');
  }
}
// Buat order tanpa mengurangi stok
await _firestore.collection('orders').doc(orderId).set(order.toMap());
```

### 2. Perubahan Logika `updateOrderPaymentDetails`

**Sebelum:**

```dart
// Hanya update status dan payment details
await _firestore.collection('orders').doc(orderId).update({
  'paymentDetails': paymentDetails,
  'status': OrderStatus.paid.name,
  'paymentDate': Timestamp.now(),
});
```

**Sesudah:**

```dart
// Periksa dan kurangi stok saat pembayaran berhasil
if (status == OrderStatus.unpaid.name) {
  final batch = _firestore.batch();
  for (var item in items) {
    // Periksa stok masih tersedia
    if (currentStock < quantity) {
      throw Exception('Stok tidak mencukupi');
    }
    // Kurangi stok
    final newStock = currentStock - quantity;

    // Update stok dan status produk
    final productUpdates = <String, dynamic>{
      'stock': newStock,
    };

    // Jika stok menjadi 0, update status produk menjadi tidak tersedia
    if (newStock <= 0) {
      productUpdates['isAvailable'] = false;
      productUpdates['status'] = 'out_of_stock';
    }

    batch.update(productRef, productUpdates);
  }
  await batch.commit();
}
// Update status pesanan
await _firestore.collection('orders').doc(orderId).update({
  'paymentDetails': paymentDetails,
  'status': OrderStatus.paid.name,
  'paymentDate': Timestamp.now(),
});
```

### 3. Penambahan Field Ketersediaan Produk

**Model Product yang Diperbarui:**

```dart
class Product {
  // ... existing fields ...
  final bool isAvailable; // Tambahan field untuk status ketersediaan
  final String status; // Tambahan field untuk status produk

  // Getter untuk mengecek apakah produk tersedia untuk dibeli
  bool get canBePurchased {
    return isAvailable && stock > 0 && status == 'available';
  }

  // Getter untuk status ketersediaan yang user-friendly
  String get availabilityStatus {
    if (!isAvailable || status != 'available') {
      return 'Tidak Tersedia';
    }
    if (stock <= 0) {
      return 'Stok Habis';
    }
    if (stock <= 5) {
      return 'Stok Terbatas';
    }
    return 'Tersedia';
  }
}
```

### 4. Filter Produk di UI

**Home Screen:**

```dart
final snapshot = await FirebaseFirestore.instance
    .collection('products')
    .where('isAvailable', isEqualTo: true) // Hanya produk yang tersedia
    .orderBy('name')
    .get();

_cachedProducts = snapshot.docs
    .map((doc) => Product.fromMap(doc.id, doc.data()))
    .where((product) => product.canBePurchased) // Filter tambahan
    .toList();
```

**Search Screen:**

```dart
final snapshot = await FirebaseFirestore.instance
    .collection('products')
    .where('isAvailable', isEqualTo: true) // Hanya produk yang tersedia
    .orderBy('name')
    .get();

_allProducts = snapshot.docs
    .map((doc) => Product.fromMap(doc.id, doc.data()))
    .where((product) => product.canBePurchased) // Filter tambahan
    .toList();
```

### 5. Pengecekan Ketersediaan di Product Detail

**Sebelum Menambahkan ke Keranjang:**

```dart
// Periksa ketersediaan produk
if (!widget.product.canBePurchased) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Maaf, produk ${widget.product.availabilityStatus.toLowerCase()}'),
      backgroundColor: Colors.red,
    ),
  );
  return;
}
```

### 6. Pengecekan Ketersediaan saat Checkout

**Bag Screen:**

```dart
// Periksa ketersediaan semua produk sebelum checkout
for (var item in items) {
  final productData = productDoc.data() as Map<String, dynamic>;
  final currentStock = productData['stock'] ?? 0;
  final isAvailable = productData['isAvailable'] ?? true;
  final status = productData['status'] ?? 'available';

  // Periksa apakah produk masih tersedia
  if (!isAvailable || status != 'available') {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Produk ${itemData['name']} tidak tersedia lagi'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Periksa apakah stok mencukupi
  if (currentStock < quantity) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Stok ${itemData['name']} tidak mencukupi. Stok tersedia: $currentStock'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
}
```

### 7. UI yang Diperbarui

**Product Detail:**

- Status ketersediaan yang informatif
- Tombol "Add to Bag" yang dinamis berdasarkan ketersediaan
- Warna dan teks yang sesuai dengan status

**Product Item:**

- Badge stok yang menunjukkan status terbatas (orange) untuk stok ≤ 5
- Badge merah untuk stok habis

**Admin Product Management:**

- Toggle untuk mengatur ketersediaan produk
- Dropdown untuk status produk
- Tampilan status yang informatif di daftar produk

## Keuntungan Sistem Baru

1. **Stok Akurat**: Stok hanya berkurang saat pembayaran berhasil
2. **Produk Otomatis Tidak Tersedia**: Produk dengan stok 0 otomatis tidak ditampilkan
3. **Pencegahan Pembelian Ganda**: Pengecekan ketersediaan di setiap tahap
4. **UI yang Informatif**: Status ketersediaan yang jelas untuk user
5. **Manajemen Admin yang Fleksibel**: Admin dapat mengatur ketersediaan produk secara manual

## Alur Kerja Baru

1. **User memilih produk** → Sistem mengecek `canBePurchased`
2. **User checkout** → Sistem mengecek ketersediaan semua produk
3. **Pembayaran berhasil** → Stok berkurang, status produk diupdate
4. **Stok = 0** → Produk otomatis tidak tersedia (`isAvailable = false`)
5. **Produk tidak ditampilkan** → Filter di home/search screen

## Status Produk

- `available`: Produk tersedia untuk dibeli
- `out_of_stock`: Stok habis (otomatis saat stok = 0)
- `discontinued`: Tidak diproduksi lagi (manual oleh admin)
- `unavailable`: Tidak tersedia (manual oleh admin)

## Keuntungan Perbaikan

### 1. Akurasi Stok

- Stok hanya berkurang saat pembayaran benar-benar berhasil
- Tidak ada stok yang hilang karena pesanan unpaid yang dibatalkan

### 2. Konsistensi Data

- Stok selalu sesuai dengan pesanan yang sudah dibayar
- Tidak ada ketidaksesuaian antara stok dan status pembayaran

### 3. User Experience

- User bisa menunda pembayaran tanpa mempengaruhi stok
- Stok tetap tersedia untuk user lain selama pembayaran belum selesai

### 4. Business Logic

- Logika bisnis yang lebih masuk akal
- Stok direservasi hanya saat pembayaran berhasil

## File yang Diperbarui

### 1. `lib/services/order_service.dart`

- `createOrder()`: Hapus pengurangan stok
- `updateOrderPaymentDetails()`: Tambah pengurangan stok
- `cancelOrderWithRestore()`: Update komentar dan logika

### 2. Dokumentasi

- `README_ORDER_SYSTEM.md`: Tambah penjelasan alur baru
- `STOCK_MANAGEMENT_FIX.md`: Dokumentasi perbaikan ini

## Testing Checklist

### ✅ Test Case 1: Pembuatan Pesanan

1. Buat pesanan baru dari keranjang
2. Verifikasi stok produk tidak berkurang
3. Verifikasi pesanan masuk ke tab "Belum Bayar"

### ✅ Test Case 2: Pembayaran Berhasil

1. Lakukan pembayaran untuk pesanan unpaid
2. Verifikasi stok produk berkurang
3. Verifikasi pesanan masuk ke tab "Menunggu Konfirmasi"

### ✅ Test Case 3: Pembatalan Pesanan Unpaid

1. Batalkan pesanan dengan status unpaid
2. Verifikasi stok produk tidak berubah
3. Verifikasi item dikembalikan ke keranjang

### ✅ Test Case 4: Pembatalan Pesanan Paid

1. Batalkan pesanan dengan status paid
2. Verifikasi stok produk dikembalikan
3. Verifikasi item dikembalikan ke keranjang

## Catatan Penting

- Perubahan ini bersifat backward compatible
- Pesanan yang sudah ada tidak terpengaruh
- Semua fungsi existing tetap berjalan normal
- Hanya logika pengelolaan stok yang diperbaiki
