import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/payment_service.dart';
import 'payment_webview_screen.dart';
import 'package:learning_auth/services/order_service.dart';
import 'package:learning_auth/models/user_model.dart';

class BagPage extends StatefulWidget {
  const BagPage({super.key});

  @override
  State<BagPage> createState() => _BagPageState();
}

class _BagPageState extends State<BagPage> {
  final Map<String, bool> _selectedItems = {};
  final _currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Keranjang Belanja",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFF3D5154),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('carts')
            .doc(_currentUser?.uid)
            .collection('items')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Color(0xFF7F8C8D),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Terjadi kesalahan',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF295D49),
              ),
            );
          }
          final items = snapshot.data?.docs ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Color(0xFF7F8C8D),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Keranjang belanja kosong',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada produk di keranjang',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            );
          }

          final totalAmount = items
              .where((doc) => _selectedItems[doc.id] ?? false)
              .fold<double>(0, (sum, doc) {
            final item = doc.data() as Map<String, dynamic>;
            return sum + ((item['price'] ?? 0) * (item['quantity'] ?? 1));
          });

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildCartList(items),
                    ],
                  ),
                ),
              ),
              _buildCheckoutSection(items, totalAmount),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartList(List<QueryDocumentSnapshot> items) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final itemData = items[index].data() as Map<String, dynamic>;
        final itemId = items[index].id;
        final quantity = itemData['quantity'] ?? 1;
        final price = (itemData['price'] ?? 0).toDouble();
        final totalPrice = price * quantity;
        final productId = itemData['productId'] ?? itemId;
        final currentStock =
            itemData['stock'] ?? 0; // Ambil stok dari item cart

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Header dengan checkbox dan delete button
                Row(
                  children: [
                    // Checkbox
                    Checkbox(
                      value: _selectedItems[itemId] ?? false,
                      onChanged: (bool? value) {
                        setState(() => _selectedItems[itemId] = value ?? false);
                      },
                      activeColor: const Color(0xFF295D49),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Product Name
                    Expanded(
                      child: Text(
                        itemData['name'] ?? 'No Name',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF3D5154),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Delete Button
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 24,
                      ),
                      onPressed: () => _deleteItem(itemId),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Product Image and Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.network(
                          itemData['imageUrl'] ?? '',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Color(0xFF7F8C8D),
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Product Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price
                          Text(
                            'Rp ${price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF295D49),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Stock Info
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: currentStock > 0
                                  ? const Color(0xFF0B6623).withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: currentStock > 0
                                    ? const Color(0xFF0B6623).withOpacity(0.3)
                                    : Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              currentStock > 0
                                  ? 'Stok: $currentStock'
                                  : 'Stok Habis',
                              style: TextStyle(
                                fontSize: 11,
                                color: currentStock > 0
                                    ? const Color(0xFF0B6623)
                                    : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Size
                          if (itemData['size'] != null &&
                              itemData['size'].toString().isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B6623).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      const Color(0xFF0B6623).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                'Ukuran: ${itemData['size']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF0B6623),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Quantity Controls
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              const Text(
                                'Jumlah: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF7F8C8D),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE0E0E0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 18),
                                      onPressed: quantity > 1
                                          ? () => _updateQuantity(
                                              itemId, quantity - 1)
                                          : null,
                                      color: quantity > 1
                                          ? const Color(0xFF295D49)
                                          : const Color(0xFF7F8C8D),
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Text(
                                        '$quantity',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF3D5154),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 18),
                                      onPressed: quantity < currentStock
                                          ? () => _updateQuantity(
                                              itemId, quantity + 1)
                                          : null,
                                      color: quantity < currentStock
                                          ? const Color(0xFF295D49)
                                          : const Color(0xFF7F8C8D),
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Total Price
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF295D49).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF295D49).withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3D5154),
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          'Rp ${totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF295D49),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckoutSection(
      List<QueryDocumentSnapshot> items, double totalAmount) {
    final selectedCount =
        items.where((doc) => _selectedItems[doc.id] ?? false).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total ($selectedCount item)',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                    Text(
                      'Rp ${totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF295D49),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF295D49),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: totalAmount > 0
                        ? () {
                            // Filter item yang dipilih sebelum checkout
                            final selectedItemsList = items
                                .where((doc) => _selectedItems[doc.id] ?? false)
                                .toList();
                            _checkout(selectedItemsList, totalAmount);
                          }
                        : null,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Checkout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateQuantity(String itemId, int newQuantity) async {
    try {
      // Ambil data item dari cart
      final itemDoc = await FirebaseFirestore.instance
          .collection('carts')
          .doc(_currentUser?.uid)
          .collection('items')
          .doc(itemId)
          .get();

      if (!itemDoc.exists) return;

      final itemData = itemDoc.data() as Map<String, dynamic>;
      final currentStock = itemData['stock'] ?? 0;
      final productId = itemData['productId'] ?? itemId;

      // Periksa stok produk di database
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      if (productDoc.exists) {
        final productData = productDoc.data() as Map<String, dynamic>;
        final availableStock = productData['stock'] ?? 0;

        // Jika quantity baru melebihi stok yang tersedia
        if (newQuantity > availableStock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Stok tidak mencukupi. Stok tersedia: $availableStock'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Update quantity dan stok di cart
        await FirebaseFirestore.instance
            .collection('carts')
            .doc(_currentUser?.uid)
            .collection('items')
            .doc(itemId)
            .update({
          'quantity': newQuantity,
          'stock': availableStock, // Update stok terbaru
        });
      } else {
        // Jika produk tidak ditemukan, hanya update quantity
        await FirebaseFirestore.instance
            .collection('carts')
            .doc(_currentUser?.uid)
            .collection('items')
            .doc(itemId)
            .update({'quantity': newQuantity});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteItem(String itemId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Hapus Item',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF3D5154),
            ),
          ),
          content: const Text(
            'Apakah Anda yakin ingin menghapus item ini dari keranjang?',
            style: TextStyle(color: Color(0xFF3D5154)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Batal',
                style: TextStyle(color: Color(0xFF7F8C8D)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('carts')
                    .doc(_currentUser?.uid)
                    .collection('items')
                    .doc(itemId)
                    .delete();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Item berhasil dihapus'),
                    backgroundColor: Color(0xFF0B6623),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void _checkout(List<QueryDocumentSnapshot> items, double totalAmount) async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang belanja kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Ambil data user dari Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser?.uid)
          .get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data user tidak ditemukan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userData = UserModel.fromFirestore(userDoc);

      // Periksa ketersediaan semua produk sebelum checkout
      for (var item in items) {
        final itemData = item.data() as Map<String, dynamic>;
        final productId = itemData['productId'];
        final quantity = itemData['quantity'] ?? 1;

        if (productId != null) {
          // Ambil data produk terbaru
          final productDoc = await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .get();

          if (productDoc.exists) {
            final productData = productDoc.data() as Map<String, dynamic>;
            final currentStock = productData['stock'] ?? 0;
            final isAvailable = productData['isAvailable'] ?? true;
            final status = productData['status'] ?? 'available';

            // Periksa apakah produk masih tersedia
            if (!isAvailable || status != 'available') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Produk ${itemData['name']} tidak tersedia lagi'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Periksa apakah stok mencukupi
            if (currentStock < quantity) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Stok ${itemData['name']} tidak mencukupi. Stok tersedia: $currentStock'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
          }
        }
      }

      // Jika semua produk tersedia, lanjutkan checkout
      print('🔄 [bag_screen] Starting checkout process...');
      print('   - Items count: ${items.length}');
      print('   - Total amount: $totalAmount');

      final orderId = await OrderService.createOrder(
        items: items.map((item) {
          final data = item.data() as Map<String, dynamic>;
          return {
            'productId': data['productId'],
            'name': data['name'],
            'price': data['price'],
            'quantity': data['quantity'],
            'size': data['size'],
            'imageUrl': data['imageUrl'],
            'category': data['category'],
          };
        }).toList(),
        totalAmount: totalAmount,
        shippingAddress: userData.address ?? 'Alamat tidak tersedia',
        customerName: userData.fullName ?? 'Customer',
        customerPhone: userData.phoneNumber ?? '08123456789',
      );

      print('✅ [bag_screen] Order created successfully: $orderId');
      print('🔄 [bag_screen] Proceeding to payment service...');

      // Siapkan data untuk PaymentService
      final customerDetails = {
        'uid': _currentUser?.uid,
        'first_name': userData.fullName ?? 'Customer',
        'last_name': '',
        'email': _currentUser?.email ?? 'no-email@example.com',
        'phone': userData.phoneNumber ?? '08123456789',
      };

      final itemsForServer = items.map((item) {
        final data = item.data() as Map<String, dynamic>;
        return {
          'id': item.id,
          'name': data['name'] ?? 'No Name',
          'price': data['price'] ?? 0,
          'quantity': data['quantity'] ?? 1,
          'imageUrl': data['imageUrl'] ?? '',
          'size': data['size'],
        };
      }).toList();

      print(
          '📤 [bag_screen] Sending order to payment service with ID: $orderId');

      // Buat transaksi di server
      final response = await PaymentService.createTransaction(
        totalAmount.toInt(),
        customerDetails,
        itemsForServer,
        orderId, // Pass the orderId to the server
      );

      print('✅ [bag_screen] Payment service response received');
      print('   - Order ID in response: ${response['order_id']}');
      print('   - Redirect URL: ${response['redirect_url']}');

      final redirectUrl = response['redirect_url'] as String?;

      if (redirectUrl != null && redirectUrl.isNotEmpty) {
        if (mounted) {
          // Navigasi ke WebView tanpa mengganti halaman saat ini
          // Ini memastikan kita bisa kembali ke keranjang jika pembayaran dibatalkan
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentWebViewScreen(
                orderId: orderId,
                paymentUrl: redirectUrl,
              ),
            ),
          );
        }
      } else {
        throw Exception('URL pembayaran tidak diterima dari server');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checkout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearCart() async {
    // Implementasi untuk menghapus semua item dari keranjang
    await FirebaseFirestore.instance
        .collection('carts')
        .doc(_currentUser?.uid)
        .collection('items')
        .get()
        .then((snapshot) {
      for (DocumentSnapshot doc in snapshot.docs) {
        FirebaseFirestore.instance
            .collection('carts')
            .doc(_currentUser?.uid)
            .collection('items')
            .doc(doc.id)
            .delete();
      }
    });
  }
}
