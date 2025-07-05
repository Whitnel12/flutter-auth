import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';

class PaymentService {
  // Initialize service dan tampilkan konfigurasi
  static void initialize() {
    AppConfig.printConfig();
  }

  // URL server - sesuaikan dengan IP komputer Anda
  // static const String baseUrl = 'http://10.0.2.2:3000'; // untuk emulator Android
  static const String baseUrl =
      'http://localhost:3000'; // untuk testing di komputer yang sama
  // static const String baseUrl = 'http://192.168.1.100:3000'; // untuk device fisik, ganti dengan IP komputer Anda

  static Future<Map<String, dynamic>> createTransaction(
      int amount,
      Map<String, dynamic> customer,
      List<Map<String, dynamic>> items,
      String orderId) async {
    try {
      AppConfig.log('🔄 Creating transaction on server...');
      AppConfig.log('💰 Amount: $amount');
      AppConfig.log('👤 Customer: $customer');
      AppConfig.log('📦 Items: $items');
      AppConfig.log('🆔 Order ID: $orderId');
      AppConfig.log('🌐 Server URL: ${AppConfig.serverUrl}');

      final url = '${AppConfig.serverUrl}/create-transaction';
      AppConfig.log('🔗 Full URL: $url');
      AppConfig.log('📡 Request timeout: ${AppConfig.requestTimeout}s');

      // Test koneksi terlebih dahulu
      AppConfig.log('🔍 Testing connection...');
      try {
        final testResponse = await http
            .get(
              Uri.parse(AppConfig.serverUrl),
            )
            .timeout(Duration(seconds: 10));

        AppConfig.log(
            '✅ Connection test successful: ${testResponse.statusCode}');
      } catch (testError) {
        AppConfig.log('❌ Connection test failed: $testError');
        throw Exception('Tidak dapat terhubung ke server. Error: $testError');
      }

      AppConfig.log('📤 Sending transaction request...');
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'amount': amount,
              'customer': customer,
              'items': items,
              'orderId': orderId,
            }),
          )
          .timeout(Duration(seconds: AppConfig.requestTimeout));

      AppConfig.log('📡 Response status: ${response.statusCode}');
      AppConfig.log('📡 Response headers: ${response.headers}');
      AppConfig.log('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        AppConfig.log('✅ Transaction created successfully');
        AppConfig.log('🔗 Redirect URL: ${result['redirect_url']}');
        return result;
      } else {
        final errorBody = jsonDecode(response.body);
        AppConfig.log('❌ Server error: $errorBody');
        throw Exception(
            'Server error: ${errorBody['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      AppConfig.log('❌ Error creating transaction: $e');

      if (e.toString().contains('SocketException')) {
        throw Exception(
            'Tidak dapat terhubung ke server. Pastikan server berjalan di port 3000.');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Koneksi timeout. Coba restart server dan aplikasi.');
      } else if (e.toString().contains('Connection refused')) {
        throw Exception(
            'Server tidak dapat diakses. Pastikan server berjalan di ${AppConfig.serverUrl}');
      } else if (e.toString().contains('Failed host lookup')) {
        throw Exception(
            'Host tidak ditemukan. Cek URL server: ${AppConfig.serverUrl}');
      }

      throw Exception('Gagal membuat transaksi: $e');
    }
  }

  static Future<void> openPaymentPage(String redirectUrl) async {
    try {
      AppConfig.log('🌐 Opening payment page: $redirectUrl');

      // Validasi URL
      if (redirectUrl.isEmpty) {
        throw Exception('URL pembayaran kosong');
      }

      final uri = Uri.parse(redirectUrl);
      AppConfig.log('🔗 Parsed URI: $uri');

      // Cek apakah URL bisa dibuka
      final canLaunch = await canLaunchUrl(uri);
      AppConfig.log('✅ Can launch URL: $canLaunch');

      if (canLaunch) {
        // Coba berbagai mode launch
        bool launched = false;

        // Coba dengan external application mode
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          AppConfig.log('🌐 Launched with external application: $launched');
        } catch (e) {
          AppConfig.log('❌ Failed with external application: $e');
        }

        // Jika gagal, coba dengan inAppWebView mode
        if (!launched) {
          try {
            launched = await launchUrl(
              uri,
              mode: LaunchMode.inAppWebView,
            );
            AppConfig.log('🌐 Launched with inAppWebView: $launched');
          } catch (e) {
            AppConfig.log('❌ Failed with inAppWebView: $e');
          }
        }

        // Jika masih gagal, coba dengan platform default
        if (!launched) {
          try {
            launched = await launchUrl(uri);
            AppConfig.log('🌐 Launched with default mode: $launched');
          } catch (e) {
            AppConfig.log('❌ Failed with default mode: $e');
          }
        }

        if (launched) {
          AppConfig.log('✅ Payment page opened successfully');
        } else {
          throw Exception(
              'Gagal membuka halaman pembayaran setelah mencoba semua mode');
        }
      } else {
        AppConfig.log('❌ Cannot launch URL: $redirectUrl');
        throw Exception(
            'Tidak dapat membuka halaman pembayaran. URL tidak valid atau tidak didukung.');
      }
    } catch (e) {
      AppConfig.log('❌ Error opening payment page: $e');
      throw Exception('Gagal membuka halaman pembayaran: $e');
    }
  }

  static Future<Map<String, dynamic>> getTransactionStatus(
      String orderId) async {
    try {
      AppConfig.log('🔍 Checking transaction status for order: $orderId');

      final response = await http.get(
        Uri.parse('${AppConfig.serverUrl}/transaction-status/$orderId'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: AppConfig.requestTimeout));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        AppConfig.log('✅ Transaction status: $result');
        return result;
      } else {
        throw Exception('Gagal mendapatkan status transaksi');
      }
    } catch (e) {
      AppConfig.log('❌ Error getting transaction status: $e');
      throw Exception('Gagal mendapatkan status transaksi: $e');
    }
  }
}
