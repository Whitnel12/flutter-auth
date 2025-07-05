# 🔧 Troubleshooting: Masalah Pembukaan Halaman Pembayaran

## 🚨 Error: "Tidak dapat membuka halaman pembayaran"

### Penyebab Umum:

1. **URL Launcher tidak berfungsi di emulator**
2. **Server tidak berjalan**
3. **URL Midtrans tidak valid**
4. **Permission internet tidak ada**

## 🔍 Langkah Troubleshooting

### 1. Cek Server Node.js

```bash
# Pastikan server berjalan
cd server
node server.js
```

**Output yang benar:**

```
🚀 Midtrans Server running on port 3000
📱 Sandbox mode enabled
💳 Test cards available at: https://docs.midtrans.com/docs/testing-payment-gateway
```

### 2. Test API Endpoint

Buka browser dan akses:

```
http://localhost:3000/create-transaction
```

Seharusnya muncul error karena method GET, bukan POST.

### 3. Cek Log Flutter

Lihat console Flutter untuk melihat:

- Response dari server
- URL yang diterima
- Error yang terjadi

### 4. Test URL Manual

1. Copy URL dari console Flutter
2. Paste di browser desktop
3. Cek apakah halaman Midtrans terbuka

## 🛠️ Solusi

### Solusi 1: Gunakan Device Fisik

Emulator Android sering bermasalah dengan URL Launcher.

1. **Ganti IP di payment_service.dart:**

```dart
static const String baseUrl = 'http://192.168.1.100:3000'; // Ganti dengan IP komputer Anda
```

2. **Cara cek IP komputer:**

```bash
# Windows
ipconfig

# Mac/Linux
ifconfig
```

### Solusi 2: Tambah Permission Internet

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:usesCleartextTraffic="true"
        ...>
```

### Solusi 3: Gunakan WebView

Jika URL Launcher masih bermasalah, gunakan WebView:

1. **Install package:**

```bash
flutter pub add webview_flutter
```

2. **Buat halaman WebView:**

```dart
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebView extends StatefulWidget {
  final String url;

  const PaymentWebView({Key? key, required this.url}) : super(key: key);

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: WebView(
        initialUrl: widget.url,
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
```

### Solusi 4: Debug Mode

Tambahkan logging lebih detail:

```dart
// Di payment_service.dart
static Future<void> openPaymentPage(String redirectUrl) async {
  print('🔍 Debug Info:');
  print('  - URL: $redirectUrl');
  print('  - URL Length: ${redirectUrl.length}');
  print('  - URL Valid: ${Uri.tryParse(redirectUrl) != null}');

  // ... rest of the code
}
```

## 📱 Test di Device Fisik

### Langkah:

1. **Hubungkan device fisik**
2. **Cek IP komputer**
3. **Update baseUrl di payment_service.dart**
4. **Restart server**
5. **Run app di device fisik**

### Command:

```bash
# Cek device terhubung
flutter devices

# Run di device fisik
flutter run -d <device-id>
```

## 🔗 Link Test

### Test Server:

- `http://localhost:3000` (dari komputer)
- `http://10.0.2.2:3000` (dari emulator)
- `http://192.168.1.100:3000` (dari device fisik, ganti IP)

### Test Midtrans:

- Sandbox: `https://app.sandbox.midtrans.com`
- Test Cards: `https://docs.midtrans.com/docs/testing-payment-gateway`

## 📞 Jika Masih Bermasalah

1. **Cek firewall Windows**
2. **Disable antivirus sementara**
3. **Gunakan hotspot dari HP**
4. **Test di device lain**

## 🎯 Kartu Test Midtrans

```
Credit Card:
- Nomor: 4811 1111 1111 1114
- CVV: 123
- Expired: 01/25
- OTP: 112233
```

# Troubleshooting Guide - FirjeStore

## Masalah Umum dan Solusi

### 1. Firebase Permission Denied

**Error:**

```
PERMISSION_DENIED: Missing or insufficient permissions
```

**Solusi:**

1. Pastikan Firestore Rules sudah di-deploy dengan benar
2. Jalankan: `firebase deploy --only firestore:rules`
3. Pastikan user sudah login dan memiliki role yang tepat

### 2. WebView Payment Issues

**Error:**

```
Uncaught TypeError: this.onResult is not a function
Renderer process crash detected
```

**Solusi:**

1. **Update PaymentWebViewScreen** - Sudah diperbaiki dengan:

   - Better URL handling
   - JavaScript error filtering
   - Navigation request handling
   - Payment completion tracking

2. **Fitur yang Ditambahkan:**
   - `paymentCompleted` flag untuk mencegah multiple handling
   - `onNavigationRequest` untuk handle redirect URLs
   - JavaScript channel untuk komunikasi dengan Midtrans
   - Better error handling untuk JavaScript errors

### 3. Aplikasi Keluar Setelah Pembayaran

**Masalah:** User langsung keluar dari panel setelah pembayaran berhasil

**Solusi:**

1. **Navigation Fix** - Menggunakan `pushNamedAndRemoveUntil` untuk kembali ke main app
2. **Success Dialog** - Menampilkan dialog konfirmasi dengan opsi:
   - Kembali ke Beranda
   - Lihat Pesanan
3. **WillPopScope** - Konfirmasi sebelum user keluar dari payment screen

### 4. Stok Tidak Terupdate

**Masalah:** Stok produk tidak berkurang setelah order dibuat

**Solusi:**

1. **Firestore Rules** - Pastikan ada permission untuk update stok:

   ```javascript
   allow write: if request.auth != null && (
     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' ||
     (request.auth != null && request.method == 'update' &&
      request.resource.data.diff(resource.data).affectedKeys().hasOnly(['stock']))
   );
   ```

2. **OrderService** - Menggunakan batch operations untuk konsistensi
3. **Error Handling** - Validasi stok sebelum membuat order

### 5. Overflow Layout Issues

**Error:**

```
A RenderFlex overflowed by X pixels on the right
```

**Solusi:**

1. **Wrap Widget** - Ganti Row dengan Wrap untuk layout yang fleksibel
2. **Expanded/Flexible** - Gunakan widget yang tepat untuk layout
3. **Responsive Design** - Test di berbagai ukuran layar

## Debug Tips

### 1. Payment Flow Debug

```dart
// Tambahkan print statements untuk debug
print('Loading URL: $url');
print('Navigation request: ${request.url}');
print('JavaScript message: ${message.message}');
```

### 2. Firestore Debug

```dart
// Cek data sebelum operasi
final doc = await _firestore.collection('products').doc(productId).get();
print('Current stock: ${doc.data()?['stock']}');
```

### 3. Navigation Debug

```dart
// Cek current route
print('Current route: ${ModalRoute.of(context)?.settings.name}');
```

## Best Practices

### 1. Payment Handling

- ✅ Gunakan `paymentCompleted` flag untuk mencegah multiple handling
- ✅ Handle semua kemungkinan URL redirect
- ✅ Filter JavaScript errors yang tidak relevan
- ✅ Berikan feedback yang jelas kepada user

### 2. Error Handling

- ✅ Gunakan try-catch untuk semua async operations
- ✅ Tampilkan error message yang user-friendly
- ✅ Log error untuk debugging

### 3. Navigation

- ✅ Gunakan `pushNamedAndRemoveUntil` untuk reset navigation stack
- ✅ Konfirmasi sebelum user keluar dari payment screen
- ✅ Berikan opsi yang jelas setelah pembayaran berhasil

## Testing Checklist

### Payment Flow

- [ ] User bisa masuk ke payment screen
- [ ] Payment URL load dengan benar
- [ ] JavaScript errors tidak mengganggu flow
- [ ] Success redirect ditangani dengan benar
- [ ] User kembali ke app setelah pembayaran
- [ ] Order status terupdate menjadi 'paid'
- [ ] Stok produk berkurang otomatis

### Error Scenarios

- [ ] Network error ditangani dengan baik
- [ ] Payment failure ditampilkan dengan jelas
- [ ] User bisa retry payment
- [ ] Cancel payment tidak merusak data

### Navigation

- [ ] Back button behavior yang benar
- [ ] Success dialog menampilkan opsi yang tepat
- [ ] User tidak stuck di payment screen
- [ ] Navigation stack bersih setelah payment
