# 🔧 Fix Connection Timeout Error

## 🚨 Error: "Connection timed out"

### Penyebab:

- URL server tidak sesuai dengan environment
- Server tidak berjalan
- Firewall memblokir koneksi
- IP address salah

## 🛠️ Solusi Langkah demi Langkah

### 1. **Cek Konfigurasi Environment**

Edit file `lib/config/app_config.dart`:

```dart
// Pilih environment yang sesuai:
// 1 = Emulator Android
// 2 = Device Fisik
// 3 = Testing di komputer yang sama
static const int environment = 1; // ← Ganti sesuai kebutuhan
```

**Pilihan Environment:**

- **Environment 1** (Emulator): `http://10.0.2.2:3000`
- **Environment 2** (Device Fisik): `http://192.168.1.100:3000` (ganti IP)
- **Environment 3** (Komputer): `http://localhost:3000`

### 2. **Cek IP Komputer (untuk Device Fisik)**

```bash
# Windows
ipconfig

# Mac/Linux
ifconfig
```

Cari IP yang dimulai dengan `192.168.` atau `10.0.`

### 3. **Restart Server**

```bash
# Stop server (Ctrl+C)
# Start ulang
cd server
node server.js
```

**Expected Output:**

```
🚀 Midtrans Server running on port 3000
📱 Sandbox mode enabled
💳 Test cards available at: https://docs.midtrans.com/docs/testing-payment-gateway
```

### 4. **Test Koneksi Manual**

Buka browser dan akses:

- Emulator: `http://10.0.2.2:3000`
- Device Fisik: `http://[IP-KOMPUTER]:3000`
- Komputer: `http://localhost:3000`

### 5. **Restart Flutter App**

```bash
# Stop app (Ctrl+C)
flutter clean
flutter pub get
flutter run
```

## 🔍 Debug Info

Saat app start, Anda akan melihat log seperti ini:

```
🔍 [AppConfig] Environment: 1
🔍 [AppConfig] Server URL: http://10.0.2.2:3000
🔍 [AppConfig] Timeout: 30s
🔍 [AppConfig] Midtrans Production: false
```

## 📱 Test Checklist

- [ ] Server berjalan di port 3000
- [ ] Environment config sesuai
- [ ] IP address benar (untuk device fisik)
- [ ] Firewall tidak memblokir
- [ ] App restart setelah config change

## 🚀 Quick Fix

Jika masih bermasalah, coba:

1. **Ganti ke Environment 3** (localhost):

   ```dart
   static const int environment = 3;
   ```

2. **Restart server dan app**

3. **Test checkout**

## 📞 Jika Masih Error

1. Cek log Flutter console
2. Cek log server console
3. Test URL manual di browser
4. Coba device/emulator lain
