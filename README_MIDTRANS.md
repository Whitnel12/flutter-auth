# 🚀 Flutter + Midtrans Emulator Integration

## 📋 Overview

Aplikasi Flutter dengan integrasi Midtrans emulator untuk pembayaran palsu. Mendukung berbagai metode pembayaran seperti Credit Card, Virtual Account, dan E-Wallet.

## 🛠️ Setup Instructions

### 1. Install Dependencies

```bash
# Install Flutter dependencies
cd flutter-auth
flutter pub get

# Install Node.js dependencies
cd server
npm install
```

### 2. Start Server

```bash
cd server
node server.js
```

**Expected Output:**

```
🚀 Midtrans Server running on port 3000
📱 Sandbox mode enabled
💳 Test cards available at: https://docs.midtrans.com/docs/testing-payment-gateway
```

### 3. Run Flutter App

```bash
cd flutter-auth
flutter run
```

## 🔧 Configuration

### For Android Emulator

- URL sudah dikonfigurasi: `http://10.0.2.2:3000`

### For Physical Device

Edit `lib/services/payment_service.dart`:

```dart
static const String baseUrl = 'http://192.168.1.100:3000'; // Ganti dengan IP komputer Anda
```

**Cara cek IP komputer:**

```bash
# Windows
ipconfig

# Mac/Linux
ifconfig
```

## 💳 Test Cards

### Credit Card

- **Number**: 4811 1111 1111 1114
- **CVV**: 123
- **Expired**: 01/25
- **OTP**: 112233

### Virtual Account

- **BCA VA**: 4811 1111 1111 1114
- **BNI VA**: 4811 1111 1111 1114
- **BRI VA**: 4811 1111 1111 1114

### E-Wallet

- **GoPay**: 08123456789
- **ShopeePay**: 08123456789

## 📱 How to Use

1. **Login** ke aplikasi
2. **Browse products** dan tambah ke keranjang
3. **Pilih items** yang ingin dibeli
4. **Tekan Checkout**
5. **Pilih metode pembayaran**:
   - Credit Card
   - Virtual Account (BCA, BNI, BRI)
   - E-Wallet (GoPay, ShopeePay)
6. **Gunakan kartu test** untuk pembayaran
7. **Selesaikan pembayaran**

## 🔍 Troubleshooting

### Error: "Tidak dapat membuka halaman pembayaran"

#### Solusi 1: Restart Server

```bash
# Stop server (Ctrl+C)
# Start ulang
cd server
node server.js
```

#### Solusi 2: Cek Network

1. Pastikan server berjalan di port 3000
2. Cek IP address komputer
3. Pastikan firewall tidak memblokir

#### Solusi 3: Use WebView

Jika URL Launcher gagal, aplikasi akan memberikan opsi untuk membuka di WebView internal.

#### Solusi 4: Manual URL

Copy URL dari console dan buka di browser desktop.

### Error: "INSTALL_FAILED_INSUFFICIENT_STORAGE"

```bash
# Bersihkan emulator
adb shell pm clear-cache

# Atau reset emulator dari AVD Manager
```

### Error: "ADB not found"

1. Install Android SDK
2. Tambahkan platform-tools ke PATH
3. Restart terminal

## 🏗️ Project Structure

```
flutter-auth/
├── lib/
│   ├── screens/
│   │   ├── bag_screen.dart          # Shopping cart & checkout
│   │   └── payment_webview_screen.dart  # WebView for payments
│   ├── services/
│   │   └── payment_service.dart     # Midtrans API integration
│   └── main.dart
├── server/
│   ├── server.js                    # Node.js server
│   └── package.json
└── android/
    └── app/
        └── src/
            └── main/
                └── AndroidManifest.xml  # Permissions
```

## 🔧 API Endpoints

### Create Transaction

```
POST http://localhost:3000/create-transaction
Content-Type: application/json

{
  "amount": 100000,
  "customer": {
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "phone": "08123456789"
  }
}
```

### Check Transaction Status

```
GET http://localhost:3000/transaction-status/:orderId
```

## 🎯 Features

- ✅ **Credit Card Payment**
- ✅ **Virtual Account** (BCA, BNI, BRI)
- ✅ **E-Wallet** (GoPay, ShopeePay)
- ✅ **Sandbox Mode**
- ✅ **Error Handling**
- ✅ **Loading States**
- ✅ **WebView Fallback**
- ✅ **Transaction Tracking**

## 🔗 Useful Links

- [Midtrans Documentation](https://docs.midtrans.com/)
- [Test Cards](https://docs.midtrans.com/docs/testing-payment-gateway)
- [Flutter HTTP Package](https://pub.dev/packages/http)
- [URL Launcher Package](https://pub.dev/packages/url_launcher)
- [WebView Flutter Package](https://pub.dev/packages/webview_flutter)

## 📞 Support

Jika mengalami masalah:

1. **Cek console server** untuk error logs
2. **Cek Flutter console** untuk debug info
3. **Test URL manual** di browser
4. **Restart server** dan aplikasi
5. **Cek network connection**

## 🚀 Production Ready

Untuk production:

1. Ganti `isProduction: false` ke `true`
2. Update server key dan client key
3. Setup callback URLs
4. Implement proper error handling
5. Add transaction logging
