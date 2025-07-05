import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learning_auth/models/user_model.dart';
import 'package:learning_auth/models/order_model.dart';
import 'package:learning_auth/services/order_service.dart';
import 'package:rxdart/rxdart.dart';

// Model untuk data pesanan yang sudah digabung dengan data user
class CombinedOrder {
  final String orderId;
  final OrderModel orderData;
  final UserModel? userData;

  CombinedOrder({
    required this.orderId,
    required this.orderData,
    this.userData,
  });
}

class IncomingOrdersScreen extends StatefulWidget {
  const IncomingOrdersScreen({super.key});

  @override
  State<IncomingOrdersScreen> createState() => _IncomingOrdersScreenState();
}

class _IncomingOrdersScreenState extends State<IncomingOrdersScreen> {
  Stream<List<CombinedOrder>>? _ordersStream;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _setupOrdersStream();
  }

  void _setupOrdersStream() {
    final ordersStream = OrderService.getPendingConfirmationOrders();

    _ordersStream = ordersStream.switchMap((orders) {
      if (orders.isEmpty) {
        return Stream.value([]);
      }

      final userIds = orders.map((order) => order.userId).toSet().toList();

      final userStreams = userIds.map((userId) {
        return FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots()
            .map((userDoc) =>
                userDoc.exists ? UserModel.fromFirestore(userDoc) : null);
      }).toList();

      return CombineLatestStream.list(userStreams).map((users) {
        final userMap = {
          for (var user in users.where((u) => u != null)) user!.uid: user
        };

        var combinedOrders = orders.map((order) {
          return CombinedOrder(
            orderId: order.id,
            orderData: order,
            userData: userMap[order.userId],
          );
        }).toList();

        // Filter berdasarkan search query
        if (_searchQuery.isNotEmpty) {
          combinedOrders = combinedOrders.where((combinedOrder) {
            final orderId = combinedOrder.orderData.orderId.toLowerCase();
            final customerName =
                combinedOrder.userData?.fullName?.toLowerCase() ?? '';
            final searchLower = _searchQuery.toLowerCase();

            return orderId.contains(searchLower) ||
                customerName.contains(searchLower);
          }).toList();
        }

        return combinedOrders;
      });
    });
    setState(() {});
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _setupOrdersStream(); // Rebuild stream dengan filter baru
  }

  Future<void> _confirmOrder(String orderId) async {
    try {
      await OrderService.confirmOrder(orderId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan berhasil dikonfirmasi'),
          backgroundColor: Color(0xFF0B6623),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 247, 247),
      appBar: AppBar(
        title: const Text(
          'Pesanan Masuk',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF295D49),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Bar
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText:
                      '🔍 Cari berdasarkan nama pelanggan atau ID pesanan...',
                  hintStyle: const TextStyle(color: Color(0xFF7F8C8D)),
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF7F8C8D)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon:
                              const Icon(Icons.clear, color: Color(0xFF7F8C8D)),
                          onPressed: () => _onSearchChanged(''),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onChanged: _onSearchChanged,
              ),
            ),

            // Order List
            StreamBuilder<List<CombinedOrder>>(
              stream: _ordersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF295D49),
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return SizedBox(
                    height: 200,
                    child: Center(child: Text('Error: ${snapshot.error}')),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty
                                ? Icons.search_off
                                : Icons.shopping_bag_outlined,
                            size: 64,
                            color: const Color(0xFF7F8C8D),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Tidak ada pesanan yang cocok dengan pencarian "$_searchQuery"'
                                : 'Tidak ada pesanan masuk saat ini.',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF7F8C8D),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => _onSearchChanged(''),
                              child: const Text(
                                'Hapus Pencarian',
                                style: TextStyle(
                                  color: Color(0xFF295D49),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                final orders = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Results Info
                    if (_searchQuery.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              size: 16,
                              color: const Color(0xFF295D49),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ditemukan ${orders.length} pesanan untuk "$_searchQuery"',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF295D49),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => _onSearchChanged(''),
                              child: const Text(
                                'Hapus',
                                style: TextStyle(
                                  color: Color(0xFF7F8C8D),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        return OrderCard(
                          order: orders[index],
                          onConfirm: () => _confirmOrder(orders[index].orderId),
                          searchQuery: _searchQuery,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final CombinedOrder order;
  final VoidCallback onConfirm;
  final String searchQuery;

  const OrderCard({
    super.key,
    required this.order,
    required this.onConfirm,
    required this.searchQuery,
  });

  Widget _highlightText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF3D5154),
        ),
        overflow: TextOverflow.ellipsis,
      );
    }

    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();
    final index = textLower.indexOf(queryLower);

    if (index == -1) {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF3D5154),
        ),
        overflow: TextOverflow.ellipsis,
      );
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF3D5154),
        ),
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: const TextStyle(
              backgroundColor: Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderData = order.orderData;
    final userData = order.userData;
    final items = orderData.items
        .map((item) => '${item['name']} (x${item['quantity']})')
        .join(', ');
    final totalAmount = orderData.totalAmount;
    final customerName = userData?.fullName ?? 'Nama tidak tersedia';
    final customerAddress = userData?.address ?? 'Alamat tidak tersedia';
    final customerPhone = userData?.phoneNumber ?? 'No. HP tidak tersedia';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID and Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF295D49).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt,
                    color: Color(0xFF295D49),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _highlightText(
                    '#${orderData.orderId.substring(0, 8)}...',
                    searchQuery,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: orderData.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    orderData.statusText,
                    style: TextStyle(
                      color: orderData.statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Order Details
            OrderDetailRow(
              icon: Icons.shopping_bag,
              text: items,
              color: const Color(0xFF295D49),
              searchQuery: searchQuery,
            ),
            const SizedBox(height: 8),
            OrderDetailRow(
              icon: Icons.person,
              text: customerName,
              color: const Color(0xFF0B6623),
              searchQuery: searchQuery,
            ),
            const SizedBox(height: 8),
            OrderDetailRow(
              icon: Icons.location_on,
              text: customerAddress,
              color: const Color(0xFF485F62),
              searchQuery: searchQuery,
            ),
            const SizedBox(height: 8),
            OrderDetailRow(
              icon: Icons.phone,
              text: customerPhone,
              color: const Color(0xFF7F8C8D),
              searchQuery: searchQuery,
            ),
            const SizedBox(height: 8),
            OrderDetailRow(
              icon: Icons.calendar_today,
              text: _formatDate(orderData.orderDate),
              color: const Color(0xFF7F8C8D),
              searchQuery: searchQuery,
            ),
            const SizedBox(height: 16),

            // Total Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Pembayaran:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D5154),
                  ),
                ),
                Text(
                  'Rp ${totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF295D49),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Konfirmasi Pesanan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B6623),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showOrderDetails(context),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Lihat Detail'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF295D49),
                      side: const BorderSide(color: Color(0xFF295D49)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Pesanan'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Order Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ID: ${order.orderData.orderId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tanggal: ${_formatDate(order.orderData.orderDate)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (order.orderData.paymentDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Pembayaran: ${_formatDate(order.orderData.paymentDate!)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Customer Info
              const Text(
                'Informasi Pelanggan:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF0B6623).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person,
                            size: 16, color: Color(0xFF0B6623)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.userData?.fullName ?? 'Nama tidak tersedia',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone,
                            size: 16, color: Color(0xFF0B6623)),
                        const SizedBox(width: 8),
                        Text(
                          order.userData?.phoneNumber ??
                              'No. HP tidak tersedia',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    if (order.userData?.address != null &&
                        order.userData!.address!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: Color(0xFF0B6623)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.userData!.address!,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (order.userData?.email != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.email,
                              size: 16, color: Color(0xFF0B6623)),
                          const SizedBox(width: 8),
                          Text(
                            order.userData!.email!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Items
              const Text(
                'Item Pesanan:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...order.orderData.items.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            item['imageUrl'] ?? '',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 40,
                                height: 40,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image,
                                    color: Colors.grey, size: 20),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'] ?? 'Nama Produk',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item['size'] != null &&
                                  item['size'].toString().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Ukuran: ${item['size']}',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey),
                                ),
                              ],
                              const SizedBox(height: 2),
                              Text(
                                'Qty: ${item['quantity']} x Rp ${(item['price'] ?? 0).toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Rp ${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF0B6623),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),

              // Total
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B6623).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Pembayaran:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Rp ${order.orderData.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF0B6623),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class OrderDetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final String searchQuery;

  const OrderDetailRow({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: _highlightText(text, searchQuery),
        ),
      ],
    );
  }

  Widget _highlightText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
      );
    }

    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();
    final index = textLower.indexOf(queryLower);

    if (index == -1) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
      );
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          color: color,
        ),
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: const TextStyle(
              backgroundColor: Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}
