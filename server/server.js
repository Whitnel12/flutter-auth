const express = require('express');
const midtransClient = require('midtrans-client');
const cors = require('cors');
const bodyParser = require('body-parser');
const admin = require('firebase-admin');
const crypto = require('crypto');

// Inisialisasi Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
const db = admin.firestore();
console.log('✅ Firebase Admin SDK initialized successfully.');

// Inisialisasi Express app
const app = express();

// Middleware
app.use(cors({
  origin: '*', // Izinkan semua origin untuk development
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Konfigurasi Midtrans Sandbox
const snap = new midtransClient.Snap({
  isProduction: false, // false = sandbox/emulator, true = production
  serverKey: 'SB-Mid-server-qYJLZIiRjECJv8gfBs8K_5K2',
  clientKey: 'SB-Mid-client-61XuGAwQ8Bj8LxSSHOrB'
});

// Log konfigurasi saat startup
console.log('🔧 Midtrans Configuration:');
console.log('   - Environment: Sandbox');
console.log('   - Server Key: SB-Mid-server-qYJLZIiRjECJv8gfBs8K_5K2');
console.log('   - Client Key: SB-Mid-client-61XuGAwQ8Bj8LxSSHOrB');
console.log('🚀 Server starting on port:', process.env.PORT || 3000);

// Test endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Midtrans Payment Server is running!',
    timestamp: new Date().toISOString(),
    status: 'OK'
  });
});

// Endpoint untuk membuat transaksi
app.post('/create-transaction', async (req, res) => {
  try {
    const { amount, customer, items, orderId } = req.body;
    
    if (!amount || !customer || !items || !orderId) {
      console.error('❌ Missing required fields: amount, customer, items, or orderId');
      return res.status(400).json({
        success: false,
        error: 'Amount, customer, items, and orderId are required.',
        details: 'Pastikan semua data pesanan dikirim dari aplikasi.'
      });
    }

    // Gunakan orderId yang sudah dibuat di client
    console.log(`✨ Using existing order ID from client: ${orderId}`);

    // Periksa apakah order sudah ada di Firestore
    const orderRef = db.collection('orders').doc(orderId);
    const orderDoc = await orderRef.get();
    
    if (!orderDoc.exists) {
      console.error(`❌ Order ${orderId} not found in Firestore`);
      return res.status(404).json({
        success: false,
        error: 'Order not found',
        details: 'Order yang dibuat di client tidak ditemukan di database.'
      });
    }

    console.log(`✅ Order ${orderId} found in Firestore, proceeding with payment`);

    // Parameter untuk Midtrans
    const parameter = {
      transaction_details: {
        order_id: orderId,
        gross_amount: amount
      },
      credit_card: {
        secure: true,
        installment: {
          required: false,
          terms: {
            bca: [3, 6, 12],
            bni: [3, 6, 12],
            mandiri: [3, 6, 12]
          }
        }
      },
      customer_details: {
        first_name: customer.first_name || 'Customer',
        last_name: customer.last_name || '',
        email: customer.email || 'customer@example.com',
        phone: customer.phone || '08123456789',
        billing_address: {
          first_name: customer.first_name || 'Customer',
          last_name: customer.last_name || '',
          phone: customer.phone || '08123456789',
          address: 'Jl. Sudirman No. 123',
          city: 'Jakarta',
          postal_code: '12345',
          country_code: 'IDN'
        },
        shipping_address: {
          first_name: customer.first_name || 'Customer',
          last_name: customer.last_name || '',
          phone: customer.phone || '08123456789',
          address: 'Jl. Sudirman No. 123',
          city: 'Jakarta',
          postal_code: '12345',
          country_code: 'IDN'
        }
      },
      enabled_payments: [
        'credit_card',
        'bca_va',
        'bni_va', 
        'bri_va',
        'gopay',
        'shopeepay',
        'indomaret',
        'danamon_online'
      ],
      callbacks: {
        finish: 'https://demo.midtrans.com'
      }
    };

    console.log('📋 Transaction parameter:', JSON.stringify(parameter, null, 2));

    // Buat transaksi di Midtrans
    console.log('🚀 Sending request to Midtrans...');
    const transaction = await snap.createTransaction(parameter);
    
    console.log('✅ Transaction created successfully');

    // Update pesanan dengan payment URL dari Midtrans
    await orderRef.update({ paymentUrl: transaction.redirect_url });
    console.log(`🔗 Payment URL for ${orderId} updated.`);

    // Response ke client
    const response = {
      success: true,
      order_id: orderId,
      token: transaction.token,
      redirect_url: transaction.redirect_url,
      amount: amount,
      customer: customer,
      created_at: new Date().toISOString()
    };

    console.log('📤 Sending response to client');
    res.json(response);

  } catch (error) {
    console.error('❌ Error creating transaction:', error);
    
    // Log error detail untuk debugging
    if (error.apiResponse) {
      console.error('🔍 Midtrans API Response:', error.apiResponse);
    }
    
    res.status(500).json({
      success: false,
      error: error.message,
      details: 'Gagal membuat transaksi Midtrans',
      timestamp: new Date().toISOString()
    });
  }
});

// Endpoint untuk cek status transaksi
app.get('/transaction-status/:orderId', async (req, res) => {
  try {
    const { orderId } = req.params;
    console.log('🔍 Checking status for order:', orderId);

    const transaction = await snap.transaction.status(orderId);
    
    console.log('✅ Transaction status retrieved');
    res.json({
      success: true,
      order_id: orderId,
      status: transaction,
      checked_at: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Error getting transaction status:', error);
    res.status(500).json({
      success: false,
      error: error.message,
      order_id: req.params.orderId
    });
  }
});

// Endpoint untuk notifikasi dari Midtrans (Webhook)
app.post('/notification', async (req, res) => {
  try {
    const notificationJson = req.body;
    console.log('🔔 Received Midtrans notification:', JSON.stringify(notificationJson, null, 2));

    const statusResponse = await snap.transaction.notification(notificationJson);
    const orderId = statusResponse.order_id;
    const transactionStatus = statusResponse.transaction_status;
    const fraudStatus = statusResponse.fraud_status;
    const grossAmount = statusResponse.gross_amount;
    const paymentType = statusResponse.payment_type;

    console.log(`🚚 Order ID: ${orderId}, Transaction Status: ${transactionStatus}, Fraud Status: ${fraudStatus}`);

    // Keamanan: Verifikasi signature key
    const signatureKey = crypto.createHash('sha512').update(orderId + statusResponse.status_code + statusResponse.gross_amount + snap.apiConfig.serverKey).digest('hex');
    if (signatureKey !== statusResponse.signature_key) {
      console.log('🔑 Invalid signature key.');
      return res.status(400).send('Invalid signature');
    }

    if (transactionStatus === 'settlement') {
      if (fraudStatus === 'accept') {
        console.log(`✅ Payment successful and accepted for order: ${orderId}. Updating status to 'paid'.`);
        
        // Update pesanan dengan informasi pembayaran yang lengkap
        const orderRef = db.collection('orders').doc(orderId);
        const updateData = {
          status: 'paid',
          paymentDate: admin.firestore.Timestamp.now(),
          paymentDetails: {
            payment_method: 'midtrans',
            payment_type: paymentType || 'unknown',
            payment_status: 'success',
            transaction_status: transactionStatus,
            fraud_status: fraudStatus,
            gross_amount: grossAmount,
            payment_time: new Date().toISOString(),
            midtrans_order_id: orderId,
            settlement_time: new Date().toISOString()
          }
        };
        
        await orderRef.update(updateData);
        console.log(`✅ Firestore updated for order ${orderId} with payment details.`);
      }
    } else if (transactionStatus === 'cancel' || transactionStatus === 'deny' || transactionStatus === 'expire') {
      console.log(`❌ Payment failed or expired for order: ${orderId}. Status: ${transactionStatus}`);
      
      // Update status pesanan menjadi cancelled jika pembayaran gagal
      const orderRef = db.collection('orders').doc(orderId);
      await orderRef.update({
        status: 'cancelled',
        paymentDetails: {
          payment_method: 'midtrans',
          payment_status: 'failed',
          transaction_status: transactionStatus,
          payment_time: new Date().toISOString(),
          midtrans_order_id: orderId
        }
      });
    }

    res.status(200).send('Notification received successfully.');

  } catch (error) {
    console.error('❌ Error handling Midtrans notification:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('🚨 Server error:', err);
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    message: err.message
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found',
    available_endpoints: [
      'GET /',
      'POST /create-transaction',
      'GET /transaction-status/:orderId',
      'GET /test'
    ]
  });
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server is running on port ${PORT}`);
  console.log(`📡 Server URL: http://localhost:${PORT}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/`);
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n🛑 Shutting down server...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n🛑 Shutting down server...');
  process.exit(0);
});
