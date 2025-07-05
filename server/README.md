# 🚀 Midtrans Server

Node.js server untuk integrasi Midtrans emulator dengan aplikasi Flutter.

## 📋 Features

- ✅ **Midtrans Sandbox Integration**
- ✅ **Express.js REST API**
- ✅ **CORS Support**
- ✅ **Error Handling**
- ✅ **Logging & Debugging**
- ✅ **Health Check Endpoints**

## 🛠️ Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Start Server

```bash
# Production mode
npm start

# Development mode (with auto-restart)
npm run dev
```

### 3. Verify Server

Buka browser dan akses:

- `http://localhost:3000` (Health check)
- `http://localhost:3000/test` (Test endpoint)

## 🔧 Configuration

### Midtrans Sandbox

```javascript
const snap = new midtransClient.Snap({
  isProduction: false, // Sandbox mode
  serverKey: "SB-Mid-server-qYJLZIiRjECJv8gfBs8K_5K2",
  clientKey: "SB-Mid-client-61XuGAwQ8Bj8LxSSHOrB",
});
```

### Environment Variables

```bash
PORT=3000  # Server port (optional, default: 3000)
```

## 📡 API Endpoints

### 1. Health Check

```
GET /
```

**Response:**

```json
{
  "status": "OK",
  "message": "Midtrans Server is running",
  "environment": "Sandbox",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### 2. Create Transaction

```
POST /create-transaction
Content-Type: application/json
```

**Request Body:**

```json
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

**Response:**

```json
{
  "success": true,
  "order_id": "order-1704067200000-abc123",
  "token": "midtrans-token-here",
  "redirect_url": "https://app.sandbox.midtrans.com/snap/v2/vtweb/...",
  "amount": 100000,
  "customer": {...},
  "created_at": "2024-01-01T00:00:00.000Z"
}
```

### 3. Check Transaction Status

```
GET /transaction-status/:orderId
```

**Response:**

```json
{
  "success": true,
  "order_id": "order-1704067200000-abc123",
  "status": {...},
  "checked_at": "2024-01-01T00:00:00.000Z"
}
```

### 4. Test Endpoint

```
GET /test
```

**Response:**

```json
{
  "message": "Server is working!",
  "midtrans_environment": "Sandbox",
  "server_time": "2024-01-01T00:00:00.000Z",
  "endpoints": {...}
}
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

## 🔍 Debugging

### Server Logs

Server akan menampilkan log detail:

```
🚀 Midtrans Server started successfully!
📱 Environment: Sandbox (Emulator)
🌐 Server running on port: 3000
🔗 Local URL: http://localhost:3000
🔗 Emulator URL: http://10.0.2.2:3000
```

### Transaction Logs

```
📝 Creating new transaction...
📦 Request body: { amount: 100000, customer: {...} }
🆔 Generated Order ID: order-1704067200000-abc123
📋 Transaction parameter: {...}
🚀 Sending request to Midtrans...
✅ Transaction created successfully
🔗 Redirect URL: https://app.sandbox.midtrans.com/...
🎫 Token: midtrans-token-here
📤 Sending response to client
```

## 🚨 Error Handling

### Common Errors

1. **Invalid Amount**: Amount harus > 0
2. **Missing Customer**: Customer data diperlukan
3. **Midtrans API Error**: Cek log untuk detail
4. **Network Error**: Cek koneksi internet

### Error Response Format

```json
{
  "success": false,
  "error": "Error message",
  "details": "Additional details",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

## 🔗 Integration with Flutter

### Flutter Configuration

```dart
// lib/config/app_config.dart
static const int environment = 1; // Emulator Android
// static const int environment = 2; // Device Fisik
// static const int environment = 3; // Komputer
```

### URLs

- **Emulator**: `http://10.0.2.2:3000`
- **Device Fisik**: `http://[IP-KOMPUTER]:3000`
- **Komputer**: `http://localhost:3000`

## 🚀 Production

Untuk production:

1. Set `isProduction: true`
2. Update server key dan client key
3. Setup proper error handling
4. Add authentication
5. Use HTTPS

## 📞 Support

Jika mengalami masalah:

1. Cek server logs
2. Test endpoints manual
3. Verify Midtrans credentials
4. Check network connectivity
