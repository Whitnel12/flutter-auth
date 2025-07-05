import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:learning_auth/services/order_service.dart';
import 'package:learning_auth/models/order_model.dart';
import 'dart:convert';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String orderId;

  const PaymentWebViewScreen({
    Key? key,
    required this.paymentUrl,
    required this.orderId,
  }) : super(key: key);

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController controller;
  bool isLoading = true;
  bool paymentCompleted = false;

  @override
  void initState() {
    super.initState();

    // Validasi paymentUrl
    if (widget.paymentUrl.isEmpty) {
      _showErrorDialog('URL pembayaran kosong');
      return;
    }

    try {
      final uri = Uri.parse(widget.paymentUrl);
      if (!uri.hasScheme) {
        _showErrorDialog('URL pembayaran tidak valid: missing scheme');
        return;
      }

      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..addJavaScriptChannel(
          'PaymentResult',
          onMessageReceived: (JavaScriptMessage message) {
            print('JavaScript message: ${message.message}');
            _handleJavaScriptMessage(message.message);
          },
        )
        ..addJavaScriptChannel(
          'MidtransCallback',
          onMessageReceived: (JavaScriptMessage message) {
            print('Midtrans callback: ${message.message}');
            _handleMidtransCallback(message.message);
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              // Update loading bar.
            },
            onPageStarted: (String url) {
              setState(() {
                isLoading = true;
              });
              print('Loading URL: $url');
            },
            onPageFinished: (String url) {
              setState(() {
                isLoading = false;
              });
              print('Finished loading URL: $url');

              // Inject JavaScript to handle Midtrans callbacks
              _injectMidtransHandler();

              // Handle different payment result URLs
              _handlePaymentResult(url);
            },
            onNavigationRequest: (NavigationRequest request) {
              print('Navigation request: ${request.url}');

              // Handle Midtrans callback URLs
              if (request.url.contains('demo.midtrans.com') ||
                  request.url.contains('finish') ||
                  request.url.contains('success') ||
                  request.url.contains('error') ||
                  request.url.contains('failed') ||
                  request.url.contains('transaction_status=') ||
                  request.url.contains('status_code=')) {
                // Extract transaction status from URL
                final uri = Uri.parse(request.url);
                final transactionStatus =
                    uri.queryParameters['transaction_status'];
                final statusCode = uri.queryParameters['status_code'];

                print(
                    'Transaction status: $transactionStatus, Status code: $statusCode');

                // Handle based on transaction status
                if (transactionStatus == 'settlement' ||
                    transactionStatus == 'capture' ||
                    statusCode == '200') {
                  paymentCompleted = true;
                  _handlePaymentSuccess();
                  return NavigationDecision.prevent;
                } else if (transactionStatus == 'pending' ||
                    statusCode == '201') {
                  paymentCompleted = true;
                  _handlePaymentPending();
                  return NavigationDecision.prevent;
                } else if (transactionStatus == 'deny' ||
                    transactionStatus == 'expire' ||
                    transactionStatus == 'cancel') {
                  paymentCompleted = true;
                  _handlePaymentFailed();
                  return NavigationDecision.prevent;
                }
              }

              return NavigationDecision.navigate;
            },
            onWebResourceError: (WebResourceError error) {
              print('WebView error: ${error.description}');
              // Don't show error dialog for JavaScript errors or permission errors
              if (!error.description.contains('onResult') &&
                  !error.description.contains('JavaScript') &&
                  !error.description.contains('permission')) {
                _showErrorDialog(
                    'Error loading payment page: ${error.description}');
              }
            },
          ),
        )
        ..loadRequest(uri);
    } catch (e) {
      print('Error parsing payment URL: $e');
      _showErrorDialog('URL pembayaran tidak valid: $e');
    }
  }

  void _handlePaymentResult(String url) {
    if (paymentCompleted) return; // Prevent multiple handling

    print('Handling payment result: $url');

    // Parse URL to extract parameters
    try {
      final uri = Uri.parse(url);
      final transactionStatus = uri.queryParameters['transaction_status'];
      final statusCode = uri.queryParameters['status_code'];

      print('Parsed URL parameters:');
      print('  - transaction_status: $transactionStatus');
      print('  - status_code: $statusCode');
      print('  - URL path: ${uri.path}');
      print('  - URL fragment: ${uri.fragment}');

      // Handle Midtrans success callback - check for success in URL
      if (transactionStatus == 'settlement' ||
          transactionStatus == 'capture' ||
          statusCode == '200' ||
          url.contains('finish') ||
          url.contains('success') ||
          uri.fragment.contains('success')) {
        print('✅ Payment result indicates success');
        paymentCompleted = true;
        _handlePaymentSuccess();
        return;
      }
      // Handle Midtrans pending callback
      else if (transactionStatus == 'pending' || statusCode == '201') {
        print('⏳ Payment result indicates pending');
        paymentCompleted = true;
        _handlePaymentPending();
        return;
      }
      // Handle Midtrans failed callback
      else if (transactionStatus == 'deny' ||
          transactionStatus == 'expire' ||
          transactionStatus == 'cancel' ||
          url.contains('error') ||
          url.contains('failed')) {
        print('❌ Payment result indicates failure');
        paymentCompleted = true;
        _handlePaymentFailed();
        return;
      }

      // If no clear status but URL contains success, assume success
      if (url.contains('success') || uri.fragment.contains('success')) {
        print('✅ URL contains success indicator, assuming success');
        paymentCompleted = true;
        _handlePaymentSuccess();
        return;
      }
    } catch (e) {
      print('Error parsing URL: $e');
      // Fallback: if URL contains success, assume success
      if (url.contains('success')) {
        print('✅ Fallback: URL contains success, handling payment success');
        paymentCompleted = true;
        _handlePaymentSuccess();
      }
    }
  }

  void _handleJavaScriptMessage(String message) {
    if (paymentCompleted) return;

    print('JavaScript message received: $message');

    if (message.contains('success') || message.contains('finish')) {
      paymentCompleted = true;
      _handlePaymentSuccess();
    } else if (message.contains('error') || message.contains('failed')) {
      paymentCompleted = true;
      _handlePaymentFailed();
    }
  }

  void _handleMidtransCallback(String message) {
    if (paymentCompleted) return;

    print('Midtrans callback received: $message');

    try {
      // Parse the JSON message
      final Map<String, dynamic> data = jsonDecode(message);
      print('Parsed callback data: $data');

      final String? url = data['url'] as String?;
      final String? transactionStatus = data['transaction_status'] as String?;
      final String? statusCode = data['status_code'] as String?;

      print('URL: $url');
      print('Transaction Status: $transactionStatus');
      print('Status Code: $statusCode');

      // Check if URL contains success indicators
      if (url != null && (url.contains('success') || url.contains('finish'))) {
        print('✅ URL indicates success, handling payment success');
        paymentCompleted = true;
        _handlePaymentSuccess();
        return;
      }

      // Check transaction status
      if (transactionStatus == 'settlement' || transactionStatus == 'capture') {
        print('✅ Transaction status indicates success');
        paymentCompleted = true;
        _handlePaymentSuccess();
      } else if (transactionStatus == 'pending') {
        print('⏳ Transaction status indicates pending');
        paymentCompleted = true;
        _handlePaymentPending();
      } else if (transactionStatus == 'deny' ||
          transactionStatus == 'expire' ||
          transactionStatus == 'cancel') {
        print('❌ Transaction status indicates failure');
        paymentCompleted = true;
        _handlePaymentFailed();
      } else if (statusCode == '200') {
        print('✅ Status code indicates success');
        paymentCompleted = true;
        _handlePaymentSuccess();
      } else if (statusCode == '201') {
        print('⏳ Status code indicates pending');
        paymentCompleted = true;
        _handlePaymentPending();
      } else {
        print(
            '⚠️ Unknown transaction status, defaulting to success based on URL');
        // If URL contains success but no clear status, assume success
        if (url != null && url.contains('success')) {
          paymentCompleted = true;
          _handlePaymentSuccess();
        }
      }
    } catch (e) {
      print('Error parsing Midtrans callback: $e');
      // If parsing fails but message contains success, assume success
      if (message.contains('success')) {
        print('✅ Fallback: Message contains success, handling payment success');
        paymentCompleted = true;
        _handlePaymentSuccess();
      }
    }
  }

  void _injectMidtransHandler() {
    final script = '''
      // Handle Midtrans callbacks
      if (typeof window !== 'undefined') {
        // Override onResult function if it exists
        if (window.onResult) {
          const originalOnResult = window.onResult;
          window.onResult = function(result) {
            console.log('Midtrans result:', result);
            MidtransCallback.postMessage(JSON.stringify(result));
            if (originalOnResult) {
              originalOnResult(result);
            }
          };
        }
        
        // Listen for URL changes
        let currentUrl = window.location.href;
        const observer = new MutationObserver(function() {
          if (window.location.href !== currentUrl) {
            currentUrl = window.location.href;
            console.log('URL changed:', currentUrl);
            
            // Try to extract parameters from URL
            let transactionStatus = null;
            let statusCode = null;
            
            try {
              const url = new URL(currentUrl);
              transactionStatus = url.searchParams.get('transaction_status');
              statusCode = url.searchParams.get('status_code');
              
              // If no query parameters, check fragment
              if (!transactionStatus && !statusCode && url.hash) {
                const fragmentParams = new URLSearchParams(url.hash.substring(1));
                transactionStatus = fragmentParams.get('transaction_status');
                statusCode = fragmentParams.get('status_code');
              }
            } catch (e) {
              console.log('Error parsing URL:', e);
            }
            
            MidtransCallback.postMessage(JSON.stringify({
              url: currentUrl,
              transaction_status: transactionStatus,
              status_code: statusCode
            }));
          }
        });
        
        observer.observe(document, {subtree: true, childList: true});
        
        // Also listen for hash changes
        window.addEventListener('hashchange', function() {
          const currentUrl = window.location.href;
          console.log('Hash changed:', currentUrl);
          
          let transactionStatus = null;
          let statusCode = null;
          
          try {
            const url = new URL(currentUrl);
            transactionStatus = url.searchParams.get('transaction_status');
            statusCode = url.searchParams.get('status_code');
            
            // Check fragment for parameters
            if (url.hash) {
              const fragmentParams = new URLSearchParams(url.hash.substring(1));
              if (!transactionStatus) transactionStatus = fragmentParams.get('transaction_status');
              if (!statusCode) statusCode = fragmentParams.get('status_code');
            }
          } catch (e) {
            console.log('Error parsing URL:', e);
          }
          
          MidtransCallback.postMessage(JSON.stringify({
            url: currentUrl,
            transaction_status: transactionStatus,
            status_code: statusCode
          }));
        });
      }
    ''';

    controller.runJavaScript(script);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: paymentCompleted,
      onPopInvoked: (didPop) async {
        if (!paymentCompleted) {
          // Show confirmation dialog when user tries to go back
          final shouldPop = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Batalkan Pembayaran?'),
                  content: const Text(
                    'Apakah Anda yakin ingin membatalkan pembayaran? Pesanan Anda akan tetap tersimpan.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Lanjutkan'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Batalkan'),
                    ),
                  ],
                ),
              ) ??
              false;

          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran'),
          backgroundColor: const Color(0xFF0B6623),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                controller.reload();
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: controller),
            if (isLoading)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF0B6623)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Memuat halaman pembayaran...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handlePaymentSuccess() async {
    try {
      // Update status pesanan menjadi paid dengan data yang konsisten dengan webhook
      await OrderService.updateOrderPaymentDetails(
        widget.orderId,
        {
          'payment_method': 'midtrans',
          'payment_type': 'unknown', // Akan diupdate oleh webhook jika tersedia
          'payment_status': 'success',
          'transaction_status': 'settlement', // Default untuk success
          'fraud_status': 'accept', // Default untuk success
          'payment_time': DateTime.now().toIso8601String(),
          'midtrans_order_id': widget.orderId,
          'settlement_time': DateTime.now().toIso8601String(),
        },
      );

      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF0B6623)),
              SizedBox(width: 8),
              Text('Pembayaran Berhasil'),
            ],
          ),
          content: const Text(
            'Pembayaran Anda telah berhasil diproses. Pesanan Anda sedang menunggu konfirmasi dari admin.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Navigate back to bottom navigation (main app)
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/bottom_nav',
                  (route) => false,
                );
              },
              child: const Text('Kembali ke Beranda'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Navigate to profile screen (which contains orders menu)
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/bottom_nav',
                  (route) => false,
                );
                // Set the selected tab to profile (index 3)
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // This will be handled by the bottom navigation
                  // The user can then tap on the orders menu in profile
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B6623),
                foregroundColor: Colors.white,
              ),
              child: const Text('Lihat Pesanan'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handlePaymentPending() async {
    try {
      // Update status pesanan menjadi pending dengan data yang konsisten
      await OrderService.updateOrderPaymentDetails(
        widget.orderId,
        {
          'payment_method': 'midtrans',
          'payment_type': 'unknown',
          'payment_status': 'pending',
          'transaction_status': 'pending',
          'payment_time': DateTime.now().toIso8601String(),
          'midtrans_order_id': widget.orderId,
        },
      );

      if (!mounted) return;

      // Show pending dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.pending, color: Colors.orange),
              SizedBox(width: 8),
              Text('Pembayaran Pending'),
            ],
          ),
          content: const Text(
            'Pembayaran Anda sedang diproses. Silakan selesaikan pembayaran sesuai instruksi yang diberikan.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Back to previous screen
              },
              child: const Text('Kembali'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Error updating order: $e');
    }
  }

  void _handlePaymentFailed() async {
    try {
      // Update status pesanan menjadi failed dengan data yang konsisten
      await OrderService.updateOrderPaymentDetails(
        widget.orderId,
        {
          'payment_method': 'midtrans',
          'payment_type': 'unknown',
          'payment_status': 'failed',
          'transaction_status': 'deny', // atau 'expire' atau 'cancel'
          'payment_time': DateTime.now().toIso8601String(),
          'midtrans_order_id': widget.orderId,
        },
      );

      if (!mounted) return;

      _showErrorDialog('Pembayaran gagal diproses. Silakan coba lagi.');
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Error updating order: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Pembayaran Gagal'),
            ],
          ),
          content: Text(
            message.isEmpty
                ? 'Maaf, pembayaran Anda gagal diproses. Silakan coba lagi.'
                : message,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                Navigator.of(context).pop(); // Kembali ke screen sebelumnya
              },
              child: const Text('Kembali'),
            ),
            if (message.isEmpty ||
                message.contains('Error loading payment page'))
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog
                  controller.reload(); // Reload halaman
                },
                child: const Text('Coba Lagi'),
              ),
          ],
        );
      },
    );
  }
}
