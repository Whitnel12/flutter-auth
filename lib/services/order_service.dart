import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learning_auth/models/order_model.dart';
import 'package:rxdart/rxdart.dart';

class OrderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream untuk mendapatkan jumlah pesanan berdasarkan status
  static Stream<Map<OrderStatus, int>> getOrderCountsByStatus() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value({});
    }

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final Map<OrderStatus, int> counts = {};

      for (var doc in snapshot.docs) {
        final order = OrderModel.fromFirestore(doc);

        // Debug logging untuk setiap pesanan
        print('🔍 Order ${order.id}:');
        print('   - Status: ${order.status}');
        print('   - Payment Status: ${order.paymentStatus}');
        print('   - Payment Details: ${order.paymentDetails}');
        print('   - isUnpaid: ${order.isUnpaid}');
        print('   - isPending: ${order.isPending}');
        print('   - isConfirmed: ${order.isConfirmed}');
        print('   - isCompleted: ${order.isCompleted}');

        // Gunakan helper methods untuk menentukan kategori
        if (order.isUnpaid) {
          counts[OrderStatus.unpaid] = (counts[OrderStatus.unpaid] ?? 0) + 1;
          print('   ✅ Counted as UNPAID');
        } else if (order.isPending) {
          counts[OrderStatus.paid] = (counts[OrderStatus.paid] ?? 0) + 1;
          print('   ✅ Counted as PENDING');
        } else if (order.isConfirmed) {
          counts[OrderStatus.confirmed] =
              (counts[OrderStatus.confirmed] ?? 0) + 1;
          print('   ✅ Counted as CONFIRMED');
        } else if (order.isCompleted) {
          counts[OrderStatus.delivered] =
              (counts[OrderStatus.delivered] ?? 0) + 1;
          print('   ✅ Counted as COMPLETED');
        }
        print('---');
      }

      print('📊 Final counts: $counts');
      return counts;
    });
  }

  // Stream untuk mendapatkan pesanan berdasarkan status
  static Stream<List<OrderModel>> getOrdersByStatus(OrderStatus status) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
      print(
          '🔄 [getOrdersByStatus] Processing ${snapshot.docs.length} orders for status: $status');

      final orders =
          snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();

      // Log all orders first
      print('📋 [getOrdersByStatus] All orders:');
      for (int i = 0; i < orders.length; i++) {
        final order = orders[i];
        print('   ${i + 1}. Order ${order.id}:');
        print('      - Status: ${order.status}');
        print('      - Payment Status: ${order.paymentStatus}');
        print('      - Payment Details: ${order.paymentDetails}');
        print('      - Order Date: ${order.orderDate}');
      }

      // Filter berdasarkan helper methods
      List<OrderModel> filteredOrders;
      switch (status) {
        case OrderStatus.unpaid:
          filteredOrders = orders.where((order) {
            final isUnpaid = order.isUnpaid;
            print(
                '🔍 [getOrdersByStatus] Order ${order.id}: isUnpaid = $isUnpaid');
            if (isUnpaid) {
              print('   ✅ INCLUDED in unpaid orders');
            } else {
              print('   ❌ EXCLUDED from unpaid orders');
            }
            return isUnpaid;
          }).toList();
          print(
              '📊 [getOrdersByStatus] Filtered ${filteredOrders.length} unpaid orders');
          return filteredOrders;
        case OrderStatus.paid:
          filteredOrders = orders.where((order) {
            final isPending = order.isPending;
            print(
                '🔍 [getOrdersByStatus] Order ${order.id}: isPending = $isPending');
            return isPending;
          }).toList();
          print(
              '📊 [getOrdersByStatus] Filtered ${filteredOrders.length} pending orders');
          return filteredOrders;
        case OrderStatus.confirmed:
          filteredOrders = orders.where((order) {
            final isConfirmed = order.isConfirmed;
            print(
                '🔍 [getOrdersByStatus] Order ${order.id}: isConfirmed = $isConfirmed');
            return isConfirmed;
          }).toList();
          print(
              '📊 [getOrdersByStatus] Filtered ${filteredOrders.length} confirmed orders');
          return filteredOrders;
        case OrderStatus.delivered:
          filteredOrders = orders.where((order) {
            final isCompleted = order.isCompleted;
            print(
                '🔍 [getOrdersByStatus] Order ${order.id}: isCompleted = $isCompleted');
            return isCompleted;
          }).toList();
          print(
              '📊 [getOrdersByStatus] Filtered ${filteredOrders.length} completed orders');
          return filteredOrders;
        default:
          filteredOrders =
              orders.where((order) => order.status == status).toList();
          print(
              '📊 [getOrdersByStatus] Filtered ${filteredOrders.length} orders with status: $status');
          return filteredOrders;
      }
    });
  }

  // Stream untuk mendapatkan semua pesanan user
  static Stream<List<OrderModel>> getAllUserOrders() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    });
  }

  // Stream untuk admin - mendapatkan pesanan yang menunggu konfirmasi
  static Stream<List<OrderModel>> getPendingConfirmationOrders() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: OrderStatus.paid.name)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    });
  }

  // Stream untuk admin - mendapatkan semua pesanan
  static Stream<List<OrderModel>> getAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OrderModel.fromFirestore(doc);
      }).toList();
    });
  }

  // Stream untuk admin - mendapatkan pesanan berdasarkan status (optimized)
  static Stream<List<OrderModel>> getOrdersByStatusForAdmin(String status) {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: status)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OrderModel.fromFirestore(doc);
      }).toList();
    });
  }

  // Membuat pesanan baru
  static Future<String> createOrder({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    String? shippingAddress,
    String? customerName,
    String? customerPhone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    if (items.isEmpty) {
      throw Exception('Items tidak boleh kosong');
    }

    print('🚀 [createOrder] Starting order creation process...');
    print('   - User ID: ${user.uid}');
    print('   - Items count: ${items.length}');
    print('   - Total amount: $totalAmount');
    print(
        '   - Items: ${items.map((item) => '${item['productId'] ?? item['id']}_${item['quantity']}_${item['size']}').join('|')}');

    // Periksa apakah ada pesanan yang sama dalam 5 menit terakhir
    try {
      final fiveMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 5));
      print(
          '🔍 [createOrder] Checking for duplicate orders in last 5 minutes...');

      final recentOrdersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('orderDate', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
          .where('totalAmount', isEqualTo: totalAmount)
          .get();

      print(
          '📊 [createOrder] Found ${recentOrdersSnapshot.docs.length} recent orders with same amount');

      // Buat key untuk items
      final itemsKey = items
          .map((item) =>
              '${item['productId'] ?? item['id']}_${item['quantity']}_${item['size']}')
          .join('|');

      // Periksa duplikat
      for (var doc in recentOrdersSnapshot.docs) {
        final data = doc.data();
        final existingItems = data['items'] as List<dynamic>?;

        if (existingItems != null) {
          final existingItemsKey = existingItems
              .map((item) =>
                  '${item['productId'] ?? item['id']}_${item['quantity']}_${item['size']}')
              .join('|');

          if (existingItemsKey == itemsKey) {
            final existingStatus = data['status'] as String?;
            print('⚠️ [createOrder] Duplicate order detected: ${doc.id}');
            print('   - Existing status: $existingStatus');
            print('   - Items match: $itemsKey');

            // Jika pesanan yang ada masih unpaid, gunakan itu
            if (existingStatus == 'unpaid') {
              print('   ✅ Reusing existing unpaid order: ${doc.id}');
              return doc.id;
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ [createOrder] Error checking for duplicates: $e');
      print('   - This might be due to missing Firestore index');
      print('   - Continuing with new order creation...');

      // Fallback: cek duplikat dengan query yang lebih sederhana
      try {
        final recentOrdersSnapshot = await _firestore
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .orderBy('orderDate', descending: true)
            .limit(10)
            .get();

        print('🔄 [createOrder] Fallback: Checking last 10 orders...');

        final fiveMinutesAgo =
            DateTime.now().subtract(const Duration(minutes: 5));

        for (var doc in recentOrdersSnapshot.docs) {
          final data = doc.data();
          final orderDate = data['orderDate'] as Timestamp?;
          final existingTotalAmount = data['totalAmount'] as num?;

          if (orderDate != null && existingTotalAmount != null) {
            // Cek apakah order dibuat dalam 5 menit terakhir dan memiliki total yang sama
            if (orderDate.toDate().isAfter(fiveMinutesAgo) &&
                existingTotalAmount == totalAmount) {
              final existingItems = data['items'] as List<dynamic>?;
              if (existingItems != null) {
                final itemsKey = items
                    .map((item) =>
                        '${item['productId'] ?? item['id']}_${item['quantity']}_${item['size']}')
                    .join('|');

                final existingItemsKey = existingItems
                    .map((item) =>
                        '${item['productId'] ?? item['id']}_${item['quantity']}_${item['size']}')
                    .join('|');

                if (existingItemsKey == itemsKey) {
                  final existingStatus = data['status'] as String?;
                  print(
                      '⚠️ [createOrder] Duplicate order detected (fallback): ${doc.id}');
                  print('   - Existing status: $existingStatus');

                  if (existingStatus == 'unpaid') {
                    print('   ✅ Reusing existing unpaid order: ${doc.id}');
                    return doc.id;
                  }
                }
              }
            }
          }
        }
      } catch (fallbackError) {
        print('❌ [createOrder] Fallback query also failed: $fallbackError');
        print('   - Proceeding with new order creation...');
      }
    }

    // Periksa stok produk tanpa mengurangi stok (karena status unpaid)
    print('📦 [createOrder] Checking product availability...');
    for (var item in items) {
      final productId = item['productId'] ?? item['id'];
      final quantity = item['quantity'] ?? 1;

      if (productId == null) {
        throw Exception('Product ID tidak valid');
      }

      // Ambil data produk
      final productDoc =
          await _firestore.collection('products').doc(productId).get();

      if (!productDoc.exists) {
        throw Exception('Produk tidak ditemukan: $productId');
      }

      final productData = productDoc.data() as Map<String, dynamic>;
      final currentStock = productData['stock'] ?? 0;
      final isAvailable = productData['isAvailable'] ?? true;
      final status = productData['status'] ?? 'available';

      // Periksa apakah produk masih tersedia
      if (!isAvailable || status != 'available') {
        throw Exception('Produk ${item['name']} tidak tersedia lagi');
      }

      // Periksa apakah stok mencukupi (tanpa mengurangi)
      if (currentStock < quantity) {
        throw Exception('Stok tidak mencukupi untuk produk: ${item['name']}');
      }
    }

    print('✅ [createOrder] All products available, generating new order ID...');
    final orderId = _generateOrderId();
    print('🆔 [createOrder] Generated order ID: $orderId');

    final order = OrderModel(
      id: orderId,
      orderId: orderId,
      userId: user.uid,
      items: items,
      totalAmount: totalAmount,
      status: OrderStatus.unpaid,
      orderDate: DateTime.now(),
      shippingAddress: shippingAddress,
      customerName: customerName,
      customerPhone: customerPhone,
    );

    print('🆕 [createOrder] Creating new order: $orderId');
    print(
        '   - Items: ${items.map((item) => '${item['productId'] ?? item['id']}_${item['quantity']}_${item['size']}').join('|')}');
    print('   - Total Amount: $totalAmount');
    print('   - User ID: ${user.uid}');

    // Buat order tanpa mengurangi stok
    await _firestore.collection('orders').doc(orderId).set(order.toMap());
    print('✅ [createOrder] Order created successfully in Firestore: $orderId');

    return orderId;
  }

  // Update status pesanan
  static Future<void> updateOrderStatus(
      String orderId, OrderStatus newStatus) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus.name,
      };

      // Tambahkan timestamp sesuai status
      switch (newStatus) {
        case OrderStatus.paid:
          updates['paymentDate'] = Timestamp.now();
          break;
        case OrderStatus.confirmed:
          updates['confirmedDate'] = Timestamp.now();
          break;
        case OrderStatus.shipped:
          updates['shippedDate'] = Timestamp.now();
          break;
        case OrderStatus.delivered:
          updates['deliveredDate'] = Timestamp.now();
          break;
        default:
          break;
      }

      await _firestore.collection('orders').doc(orderId).update(updates);
    } catch (e) {
      throw Exception('Gagal update status pesanan: $e');
    }
  }

  // Update pesanan dengan payment URL
  static Future<void> updateOrderPaymentUrl(
      String orderId, String paymentUrl) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'paymentUrl': paymentUrl,
      });
    } catch (e) {
      throw Exception('Gagal update payment URL: $e');
    }
  }

  // Update pesanan dengan detail pembayaran dan kurangi stok
  static Future<void> updateOrderPaymentDetails(
      String orderId, Map<String, dynamic> paymentDetails) async {
    try {
      print('🔄 Starting updateOrderPaymentDetails for order: $orderId');
      print('📋 Payment details: $paymentDetails');

      // Ambil data pesanan
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Pesanan tidak ditemukan');
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final items = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
      final status = orderData['status'] as String?;

      print('📊 Current order status: $status');
      print('📦 Order items: $items');

      // Update status pesanan berdasarkan payment status
      final orderUpdates = <String, dynamic>{
        'paymentDetails': paymentDetails,
        'paymentDate': Timestamp.now(),
      };

      final paymentStatus = paymentDetails['payment_status'] as String?;
      print('💰 Payment status: $paymentStatus');

      if (paymentStatus == 'success') {
        // Pembayaran berhasil - update status menjadi paid dan kurangi stok
        orderUpdates['status'] = OrderStatus.paid.name;
        print('✅ Setting order status to: ${OrderStatus.paid.name}');

        // Hanya kurangi stok jika status masih unpaid
        if (status == OrderStatus.unpaid.name) {
          print('📦 Reducing stock and clearing cart for unpaid order...');
          try {
            final batch = _firestore.batch();

            // Kurangi stok untuk setiap item
            for (var item in items) {
              final productId = item['productId'] ?? item['id'];
              final quantity = item['quantity'] ?? 1;

              if (productId == null) continue;

              final productDoc =
                  await _firestore.collection('products').doc(productId).get();
              if (!productDoc.exists) {
                print('Warning: Produk tidak ditemukan: $productId');
                continue;
              }

              final productData = productDoc.data() as Map<String, dynamic>;
              final currentStock = productData['stock'] ?? 0;

              if (currentStock < quantity) {
                print(
                    'Warning: Stok tidak mencukupi untuk produk: ${item['name']}');
                continue;
              }

              final newStock = currentStock - quantity;
              final productUpdates = <String, dynamic>{'stock': newStock};
              if (newStock <= 0) {
                productUpdates['isAvailable'] = false;
                productUpdates['status'] = 'out_of_stock';
              }
              batch.update(_firestore.collection('products').doc(productId),
                  productUpdates);
            }

            // Hapus item dari keranjang setelah pembayaran berhasil
            final userId = orderData['userId'] as String?;
            if (userId != null) {
              print(
                  '🗑️ Adding cart item deletions to batch for user: $userId');
              final cartItemsRef = _firestore
                  .collection('carts')
                  .doc(userId)
                  .collection('items');
              for (var item in items) {
                final productId = item['productId'] ?? item['id'];
                if (productId != null) {
                  batch.delete(cartItemsRef.doc(productId));
                }
              }
            }

            // Commit perubahan stok dan cart secara bersamaan
            await batch.commit();
            print(
                '✅ Stock updated and cart cleared successfully for order: $orderId');
          } catch (e) {
            print('Warning: Failed to update stock and/or clear cart: $e');
            // Tetap lanjutkan update order meskipun stok/cart gagal
          }
        } else {
          print(
              'ℹ️ Order status is not unpaid, skipping stock reduction and cart clearing');
        }
      } else if (paymentStatus == 'pending') {
        // Pembayaran pending - tetap status unpaid
        orderUpdates['status'] = OrderStatus.unpaid.name;
        print(
            '⏳ Setting order status to: ${OrderStatus.unpaid.name} (pending payment)');
      } else if (paymentStatus == 'failed' ||
          paymentStatus == 'expire' ||
          paymentStatus == 'deny' ||
          paymentStatus == 'cancel') {
        // Pembayaran gagal - tetap status unpaid
        orderUpdates['status'] = OrderStatus.unpaid.name;
        print(
            '❌ Setting order status to: ${OrderStatus.unpaid.name} (payment failed)');
      }

      print('📝 Final order updates: $orderUpdates');
      await _firestore.collection('orders').doc(orderId).update(orderUpdates);
      print(
          '✅ Order payment details updated successfully: $orderId with status: $paymentStatus');

      // Verify the update
      final updatedDoc =
          await _firestore.collection('orders').doc(orderId).get();
      final updatedData = updatedDoc.data() as Map<String, dynamic>;
      print('🔍 Verification - Updated order status: ${updatedData['status']}');
      print(
          '🔍 Verification - Updated payment details: ${updatedData['paymentDetails']}');
    } catch (e) {
      print('❌ Error in updateOrderPaymentDetails: $e');
      throw Exception('Gagal memproses pembayaran: $e');
    }
  }

  // Admin: Konfirmasi pesanan
  static Future<void> confirmOrder(String orderId, {String? adminNotes}) async {
    try {
      final updates = <String, dynamic>{
        'status': OrderStatus.confirmed.name,
        'confirmedDate': Timestamp.now(),
      };

      if (adminNotes != null) {
        updates['adminNotes'] = adminNotes;
      }

      await _firestore.collection('orders').doc(orderId).update(updates);
    } catch (e) {
      throw Exception('Gagal konfirmasi pesanan: $e');
    }
  }

  // Admin: Kirim pesanan
  static Future<void> shipOrder(String orderId, {String? adminNotes}) async {
    try {
      final updates = <String, dynamic>{
        'status': OrderStatus.shipped.name,
        'shippedDate': Timestamp.now(),
      };

      if (adminNotes != null) {
        updates['adminNotes'] = adminNotes;
      }

      await _firestore.collection('orders').doc(orderId).update(updates);
    } catch (e) {
      throw Exception('Gagal kirim pesanan: $e');
    }
  }

  // Admin: Tandai pesanan sebagai selesai
  static Future<void> deliverOrder(String orderId, {String? adminNotes}) async {
    try {
      final updates = <String, dynamic>{
        'status': OrderStatus.delivered.name,
        'deliveredDate': Timestamp.now(),
      };

      if (adminNotes != null) {
        updates['adminNotes'] = adminNotes;
      }

      await _firestore.collection('orders').doc(orderId).update(updates);
    } catch (e) {
      throw Exception('Gagal tandai pesanan selesai: $e');
    }
  }

  // Batalkan pesanan
  static Future<void> cancelOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.cancelled.name,
      });
    } catch (e) {
      throw Exception('Gagal batalkan pesanan: $e');
    }
  }

  // Batalkan pesanan dan kembalikan stok + keranjang
  // Catatan: Stok hanya dikembalikan untuk pesanan yang sudah dibayar
  // karena stok tidak dikurangi saat pesanan unpaid dibuat
  static Future<void> cancelOrderWithRestore(
      String orderId, String userId) async {
    try {
      // Ambil data pesanan
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Pesanan tidak ditemukan');
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final items = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
      final status = orderData['status'] as String?;

      // Kembalikan stok jika pesanan sudah dibayar atau diproses
      // (karena stok sudah dikurangi saat pembayaran berhasil)
      if (status == OrderStatus.paid.name ||
          status == OrderStatus.confirmed.name ||
          status == OrderStatus.shipped.name) {
        final batch = _firestore.batch();

        // Kembalikan stok untuk setiap item
        for (var item in items) {
          final productId = item['id'] ?? item['productId'];
          if (productId == null) continue;

          final quantity = item['quantity'] ?? 1;

          // Ambil data produk
          final productDoc =
              await _firestore.collection('products').doc(productId).get();
          if (productDoc.exists) {
            final productData = productDoc.data() as Map<String, dynamic>;
            final currentStock = productData['stock'] ?? 0;
            final newStock = currentStock + quantity;

            // Update stok produk
            batch.update(_firestore.collection('products').doc(productId), {
              'stock': newStock,
              'isAvailable': true,
              'status': 'available',
            });
          }
        }

        // Commit perubahan stok
        await batch.commit();
      }

      // Kembalikan produk ke keranjang belanja
      final cartBatch = _firestore.batch();

      for (var item in items) {
        final productId = item['id'] ?? item['productId'];
        if (productId == null) continue;

        // Ambil data produk terbaru
        final productDoc =
            await _firestore.collection('products').doc(productId).get();
        if (!productDoc.exists) continue;

        final productData = productDoc.data() as Map<String, dynamic>;
        final itemQuantity = item['quantity'] ?? 1;

        final cartItemRef = _firestore
            .collection('carts')
            .doc(userId)
            .collection('items')
            .doc(productId);

        final cartItemSnapshot = await cartItemRef.get();
        if (cartItemSnapshot.exists) {
          // Update quantity jika item sudah ada di cart
          final existingQty = cartItemSnapshot.data()?['quantity'] ?? 0;
          cartBatch.update(cartItemRef, {
            'quantity': existingQty + itemQuantity,
            'name': productData['name'],
            'price': productData['price'],
            'imageUrl': productData['imageUrl'],
            'productId': productId,
            'id': productId,
            'category': productData['category'],
            'stock': productData['stock'],
            'size': item['size'],
          });
        } else {
          // Tambahkan item baru ke cart
          cartBatch.set(cartItemRef, {
            'productId': productId,
            'id': productId,
            'name': productData['name'],
            'price': productData['price'],
            'quantity': itemQuantity,
            'imageUrl': productData['imageUrl'],
            'category': productData['category'],
            'stock': productData['stock'],
            'size': item['size'],
          });
        }
      }

      // Hapus pesanan
      cartBatch.delete(_firestore.collection('orders').doc(orderId));

      // Commit semua perubahan
      await cartBatch.commit();
    } catch (e) {
      throw Exception('Gagal membatalkan pesanan: $e');
    }
  }

  // Hapus pesanan
  static Future<void> deleteOrder(String orderId) async {
    await _firestore.collection('orders').doc(orderId).delete();
  }

  // Mendapatkan detail pesanan
  static Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return OrderModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil data pesanan: $e');
    }
  }

  // Generate Order ID
  static String _generateOrderId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'order-$timestamp-$random';
  }

  // Get order statistics for admin
  static Stream<Map<String, int>> getOrderStatistics() {
    return _firestore.collection('orders').snapshots().map((snapshot) {
      final Map<String, int> stats = {
        'total': 0,
        'unpaid': 0,
        'paid': 0,
        'confirmed': 0,
        'shipped': 0,
        'delivered': 0,
        'cancelled': 0,
      };

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final statusString = data['status'] as String?;

        stats['total'] = (stats['total'] ?? 0) + 1;

        if (statusString != null) {
          stats[statusString] = (stats[statusString] ?? 0) + 1;
        }
      }

      return stats;
    });
  }

  // Method untuk memeriksa dan memperbaiki status pesanan yang salah
  static Future<void> checkAndFixOrderStatuses() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      print(
          '🔍 [checkAndFixOrderStatuses] Checking all orders for user: ${user.uid}');

      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .get();

      print(
          '📊 [checkAndFixOrderStatuses] Found ${snapshot.docs.length} orders');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final orderId = doc.id;
        final status = data['status'] as String?;
        final paymentDetails = data['paymentDetails'] as Map<String, dynamic>?;

        print('🔍 [checkAndFixOrderStatuses] Order $orderId:');
        print('   - Status: $status');
        print('   - Payment Details: $paymentDetails');

        // Jika status adalah unpaid tetapi ada paymentDetails dengan success
        if (status == 'unpaid' && paymentDetails != null) {
          final paymentStatus = paymentDetails['payment_status'] as String?;
          final transactionStatus =
              paymentDetails['transaction_status'] as String?;

          print('   - Payment Status: $paymentStatus');
          print('   - Transaction Status: $transactionStatus');

          // Jika pembayaran berhasil, update status menjadi paid
          if (paymentStatus == 'success' ||
              transactionStatus == 'settlement' ||
              transactionStatus == 'capture') {
            print('   ✅ Payment successful, updating status to paid');
            await _firestore.collection('orders').doc(orderId).update({
              'status': 'paid',
              'paymentDate': Timestamp.now(),
            });
            print('   ✅ Status updated successfully');
          }
        }
      }
    } catch (e) {
      print('❌ [checkAndFixOrderStatuses] Error: $e');
    }
  }

  // Method untuk mendeteksi dan membersihkan pesanan duplikat
  static Future<void> detectAndCleanupDuplicateOrders() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      print(
          '🔍 [detectAndCleanupDuplicateOrders] Checking for duplicate orders...');

      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('orderDate', descending: true)
          .get();

      print(
          '📊 [detectAndCleanupDuplicateOrders] Found ${snapshot.docs.length} orders');

      // Kelompokkan pesanan berdasarkan totalAmount dan items
      final Map<String, List<Map<String, dynamic>>> groupedOrders = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final orderId = doc.id;
        final totalAmount = data['totalAmount'] as num?;
        final items = data['items'] as List<dynamic>?;
        final orderDate = data['orderDate'] as Timestamp?;
        final status = data['status'] as String?;
        final paymentDetails = data['paymentDetails'] as Map<String, dynamic>?;

        if (totalAmount != null && items != null && orderDate != null) {
          // Buat key berdasarkan totalAmount dan items
          final itemsKey = items
              .map((item) =>
                  '${item['productId'] ?? item['id']}_${item['quantity']}_${item['size']}')
              .join('|');
          final key = '${totalAmount}_$itemsKey';

          if (!groupedOrders.containsKey(key)) {
            groupedOrders[key] = [];
          }

          groupedOrders[key]!.add({
            'docId': doc.id,
            'orderId': orderId,
            'orderDate': orderDate,
            'status': status,
            'paymentDetails': paymentDetails,
            'data': data,
          });
        }
      }

      // Periksa setiap grup untuk duplikat
      for (var entry in groupedOrders.entries) {
        final orders = entry.value;
        if (orders.length > 1) {
          print(
              '🔍 [detectAndCleanupDuplicateOrders] Found ${orders.length} orders with same items and amount:');

          // Urutkan berdasarkan waktu pembuatan
          orders.sort((a, b) => (b['orderDate'] as Timestamp)
              .compareTo(a['orderDate'] as Timestamp));

          for (int i = 0; i < orders.length; i++) {
            final order = orders[i];
            print('   ${i + 1}. Order ${order['orderId']}:');
            print('      - Status: ${order['status']}');
            print(
                '      - Payment Details: ${order['paymentDetails'] != null ? 'Yes' : 'No'}');
            print('      - Date: ${order['orderDate']}');
          }

          // Tentukan pesanan mana yang harus dipertahankan
          String? orderToKeep;
          List<String> ordersToDelete = [];

          // Cari pesanan yang sudah dibayar
          for (var order in orders) {
            if (order['status'] == 'paid' && order['paymentDetails'] != null) {
              orderToKeep = order['docId'];
              print('   ✅ Keeping paid order: ${order['orderId']}');
              break;
            }
          }

          // Jika tidak ada yang dibayar, pertahankan yang terbaru
          if (orderToKeep == null) {
            orderToKeep = orders.first['docId'];
            print('   ✅ Keeping latest order: ${orders.first['orderId']}');
          }

          // Tandai pesanan lain untuk dihapus
          for (var order in orders) {
            if (order['docId'] != orderToKeep) {
              ordersToDelete.add(order['docId']);
              print('   🗑️ Marking for deletion: ${order['orderId']}');
            }
          }

          // Hapus pesanan duplikat
          if (ordersToDelete.isNotEmpty) {
            print(
                '   🗑️ Deleting ${ordersToDelete.length} duplicate orders...');
            final batch = _firestore.batch();

            for (var docId in ordersToDelete) {
              batch.delete(_firestore.collection('orders').doc(docId));
            }

            await batch.commit();
            print('   ✅ Duplicate orders deleted successfully');
          }
        }
      }

      print('✅ [detectAndCleanupDuplicateOrders] Cleanup completed');
    } catch (e) {
      print('❌ [detectAndCleanupDuplicateOrders] Error: $e');
    }
  }

  // Method untuk membersihkan order duplikat spesifik yang disebutkan user
  static Future<void> cleanupSpecificDuplicateOrders() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      print(
          '🔍 [cleanupSpecificDuplicateOrders] Cleaning up specific duplicate orders...');

      // Cari order dengan ID yang disebutkan user
      final specificOrderIds = [
        'order-1750638180882-0882',
        'order-1750638181123-49896ee9'
      ];

      for (var orderId in specificOrderIds) {
        try {
          final orderDoc =
              await _firestore.collection('orders').doc(orderId).get();
          if (orderDoc.exists) {
            final data = orderDoc.data() as Map<String, dynamic>;
            final status = data['status'] as String?;
            final paymentDetails =
                data['paymentDetails'] as Map<String, dynamic>?;
            final totalAmount = data['totalAmount'] as num?;
            final items = data['items'] as List<dynamic>?;

            print('🔍 [cleanupSpecificDuplicateOrders] Found order: $orderId');
            print('   - Status: $status');
            print(
                '   - Payment Details: ${paymentDetails != null ? 'Yes' : 'No'}');
            print('   - Total Amount: $totalAmount');
            print('   - Items count: ${items?.length ?? 0}');

            // Jika order ini unpaid dan tidak ada paymentDetails, hapus
            if (status == 'unpaid' && paymentDetails == null) {
              print(
                  '   🗑️ Deleting unpaid order without payment details: $orderId');
              await _firestore.collection('orders').doc(orderId).delete();
              print('   ✅ Successfully deleted: $orderId');
            } else if (status == 'paid' && paymentDetails != null) {
              print('   ✅ Keeping paid order with payment details: $orderId');
            }
          } else {
            print('   ℹ️ Order not found: $orderId');
          }
        } catch (e) {
          print('   ❌ Error processing order $orderId: $e');
        }
      }

      print('🎉 [cleanupSpecificDuplicateOrders] Cleanup completed!');
    } catch (e) {
      print('❌ [cleanupSpecificDuplicateOrders] Error: $e');
    }
  }

  // Method untuk membersihkan order duplikat yang sudah ada (legacy cleanup)
  static Future<void> cleanupLegacyDuplicateOrders() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      print(
          '🔍 [cleanupLegacyDuplicateOrders] Cleaning up legacy duplicate orders...');

      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('orderDate', descending: true)
          .get();

      print(
          '📊 [cleanupLegacyDuplicateOrders] Found ${snapshot.docs.length} total orders');

      // Kelompokkan berdasarkan totalAmount dan items
      final Map<String, List<Map<String, dynamic>>> groupedOrders = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final totalAmount = data['totalAmount'] as num?;
        final items = data['items'] as List<dynamic>?;
        final status = data['status'] as String?;
        final paymentDetails = data['paymentDetails'] as Map<String, dynamic>?;

        if (totalAmount != null && items != null) {
          // Buat key berdasarkan totalAmount dan items
          final itemsKey = items
              .map((item) =>
                  '${item['productId'] ?? item['id']}_${item['quantity']}_${item['size']}')
              .join('|');
          final key = '${totalAmount}_$itemsKey';

          if (!groupedOrders.containsKey(key)) {
            groupedOrders[key] = [];
          }

          groupedOrders[key]!.add({
            'docId': doc.id,
            'orderId': data['orderId'] ?? doc.id,
            'status': status,
            'paymentDetails': paymentDetails,
            'orderDate': data['orderDate'],
            'data': data,
          });
        }
      }

      int totalDeleted = 0;

      // Periksa setiap grup untuk duplikat
      for (var entry in groupedOrders.entries) {
        final orders = entry.value;
        if (orders.length > 1) {
          print(
              '🔍 [cleanupLegacyDuplicateOrders] Found ${orders.length} orders with same items and amount:');

          // Urutkan berdasarkan waktu pembuatan (terbaru dulu)
          orders.sort((a, b) => (b['orderDate'] as Timestamp)
              .compareTo(a['orderDate'] as Timestamp));

          for (int i = 0; i < orders.length; i++) {
            final order = orders[i];
            print('   ${i + 1}. Order ${order['orderId']}:');
            print('      - Status: ${order['status']}');
            print(
                '      - Payment Details: ${order['paymentDetails'] != null ? 'Yes' : 'No'}');
            print('      - Date: ${order['orderDate']}');
          }

          // Tentukan pesanan mana yang harus dipertahankan
          String? orderToKeep;
          List<String> ordersToDelete = [];

          // Prioritas 1: Pesanan yang sudah dibayar
          for (var order in orders) {
            if (order['status'] == 'paid' && order['paymentDetails'] != null) {
              orderToKeep = order['docId'];
              print('   ✅ Keeping paid order: ${order['orderId']}');
              break;
            }
          }

          // Prioritas 2: Pesanan yang memiliki paymentDetails (dari server)
          if (orderToKeep == null) {
            for (var order in orders) {
              if (order['paymentDetails'] != null) {
                orderToKeep = order['docId'];
                print(
                    '   ✅ Keeping order with payment details: ${order['orderId']}');
                break;
              }
            }
          }

          // Prioritas 3: Pesanan yang terbaru
          if (orderToKeep == null) {
            orderToKeep = orders.first['docId'];
            print('   ✅ Keeping latest order: ${orders.first['orderId']}');
          }

          // Tandai pesanan lain untuk dihapus
          for (var order in orders) {
            if (order['docId'] != orderToKeep) {
              ordersToDelete.add(order['docId']);
              print('   🗑️ Marking for deletion: ${order['orderId']}');
            }
          }

          // Hapus pesanan duplikat
          if (ordersToDelete.isNotEmpty) {
            print(
                '   🗑️ Deleting ${ordersToDelete.length} duplicate orders...');
            final batch = _firestore.batch();

            for (var docId in ordersToDelete) {
              batch.delete(_firestore.collection('orders').doc(docId));
            }

            await batch.commit();
            totalDeleted += ordersToDelete.length;
            print(
                '   ✅ Successfully deleted ${ordersToDelete.length} duplicate orders');
          }
        }
      }

      print('🎉 [cleanupLegacyDuplicateOrders] Cleanup completed!');
      print('   - Total orders processed: ${snapshot.docs.length}');
      print('   - Total duplicates deleted: $totalDeleted');
    } catch (e) {
      print('❌ [cleanupLegacyDuplicateOrders] Error: $e');
    }
  }
}
