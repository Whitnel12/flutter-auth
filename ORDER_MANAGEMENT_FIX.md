# Perbaikan Masalah Loading pada Manajemen Pesanan Admin

## Masalah yang Ditemukan

1. **Loading yang lama muncul** saat pertama kali masuk ke manajemen pesanan
2. **Loading tidak muncul** saat berpindah antar tab (contoh: dari "Semua" ke "Menunggu")
3. **Performa lambat** saat switching antar tab

## Penyebab Masalah

1. **Single Stream untuk Semua Tab**: Semua tab menggunakan stream yang sama, menyebabkan data harus difilter ulang setiap kali tab berubah
2. **Tidak ada Caching**: Data tidak di-cache, sehingga setiap perpindahan tab memerlukan query baru
3. **Stream Rebuild**: Setiap kali tab berubah, stream di-rebuild ulang

## Solusi yang Diterapkan

### 1. Stream Terpisah untuk Setiap Tab

```dart
Map<int, Stream<List<CombinedOrder>>> _tabStreams = {};

void _initializeTabStreams() {
  // Tab 0: Semua pesanan
  _tabStreams[0] = _createCombinedOrderStream(null);

  // Tab 1: Belum Bayar
  _tabStreams[1] = _createCombinedOrderStream(OrderStatus.unpaid);

  // Tab 2: Menunggu
  _tabStreams[2] = _createCombinedOrderStream(OrderStatus.paid);

  // Tab 3: Dikonfirmasi
  _tabStreams[3] = _createCombinedOrderStream(OrderStatus.confirmed);

  // Tab 4: Selesai
  _tabStreams[4] = _createCombinedOrderStream(OrderStatus.delivered);
}
```

### 2. Implementasi Caching dengan shareReplay

```dart
Stream<List<CombinedOrder>> _createCombinedOrderStream(OrderStatus? status) {
  // ... stream logic ...
  return orderStream.switchMap((orders) {
    // ... processing logic ...
  }).shareReplay(maxSize: 1).cast<List<CombinedOrder>>();
}
```

### 3. Optimasi Service Layer

```dart
// Di OrderService
static Stream<List<OrderModel>> getAllOrders() {
  return _firestore
      .collection('orders')
      .orderBy('orderDate', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
  }).shareReplay(maxSize: 1); // Cache the last emission
}

static Stream<List<OrderModel>> getOrdersByStatusForAdmin(OrderStatus status) {
  return _firestore
      .collection('orders')
      .where('status', isEqualTo: status.name)
      .orderBy('orderDate', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
  }).shareReplay(maxSize: 1);
}
```

### 4. State Management yang Lebih Baik

```dart
bool _isInitialized = false;

void _setupStreams() {
  // ... setup logic ...

  // Mark as initialized after a short delay to ensure streams are ready
  Future.delayed(const Duration(milliseconds: 100), () {
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  });
}
```

### 5. Loading State yang Lebih Cerdas

```dart
Widget _buildOrderList(int tabIndex) {
  if (!_isInitialized) {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF295D49),
      ),
    );
  }

  return StreamBuilder<List<CombinedOrder>>(
    stream: stream,
    builder: (context, snapshot) {
      // Show loading only for initial load
      if (snapshot.connectionState == ConnectionState.waiting &&
          snapshot.data == null) {
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF295D49),
          ),
        );
      }
      // ... rest of the logic
    },
  );
}
```

## Hasil Perbaikan

1. **Loading Cepat**: Setiap tab memiliki stream terpisah yang sudah di-cache
2. **Perpindahan Tab Lancar**: Tidak ada loading ulang saat berpindah antar tab
3. **Performa Optimal**: Menggunakan caching untuk mengurangi beban query
4. **User Experience Lebih Baik**: Loading indicator yang konsisten dan responsif

## File yang Dimodifikasi

1. `lib/screens/admin/order_management_screen.dart` - Implementasi utama
2. `lib/services/order_service.dart` - Optimasi service layer

## Dependencies yang Digunakan

- `rxdart: ^0.27.7` - Untuk stream caching dan manipulation
- `cloud_firestore: ^5.1.0` - Untuk database operations

## Cara Testing

1. Buka halaman Manajemen Pesanan Admin
2. Perhatikan loading saat pertama kali masuk
3. Coba pindah antar tab (Semua, Belum Bayar, Menunggu, dll)
4. Verifikasi bahwa perpindahan tab berjalan lancar tanpa loading lama
5. Test dengan data yang banyak untuk memastikan performa tetap optimal
