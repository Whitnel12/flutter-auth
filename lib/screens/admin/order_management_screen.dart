import 'package:flutter/material.dart';
import 'package:learning_auth/models/order_model.dart';
import 'package:learning_auth/services/order_service.dart';
import 'package:learning_auth/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

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

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Stream<Map<String, int>>? _orderStatsStream;
  Map<int, Stream<List<CombinedOrder>>> _tabStreams = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _setupStreams();

    // Listen to tab changes to trigger rebuild
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  void _setupStreams() {
    _orderStatsStream = OrderService.getOrderStatistics();

    // Initialize streams for each tab
    _initializeTabStreams();

    // Mark as initialized after a short delay to ensure streams are ready
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  void _initializeTabStreams() {
    // Tab 0: Semua pesanan
    _tabStreams[0] = _createCombinedOrderStream(null);

    // Tab 1: Belum Bayar
    _tabStreams[1] = _createCombinedOrderStream(OrderStatus.unpaid);

    // Tab 2: Menunggu
    _tabStreams[2] = _createCombinedOrderStream(OrderStatus.paid);

    // Tab 3: Dikonfirmasi
    _tabStreams[3] = _createCombinedOrderStream(OrderStatus.confirmed);

    // Tab 4: Selesai
    _tabStreams[4] = _createCombinedOrderStream(OrderStatus.delivered);
  }

  Stream<List<CombinedOrder>> _createCombinedOrderStream(OrderStatus? status) {
    Stream<List<OrderModel>> orderStream;

    if (status == null) {
      orderStream = OrderService.getAllOrders();
    } else {
      orderStream = OrderService.getOrdersByStatusForAdmin(status.name);
    }

    return orderStream
        .switchMap((orders) {
          if (orders.isEmpty) {
            return Stream.value(<CombinedOrder>[]);
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

            return orders.map((order) {
              return CombinedOrder(
                orderId: order.id,
                orderData: order,
                userData: userMap[order.userId],
              );
            }).toList();
          });
        })
        .shareReplay(maxSize: 1)
        .cast<
            List<
                CombinedOrder>>(); // Cache the last emission and cast to correct type
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Manajemen Pesanan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF295D49),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: Colors.white,
            child: StreamBuilder<Map<String, int>>(
              stream: _orderStatsStream,
              builder: (context, snapshot) {
                final stats = snapshot.data ?? {};
                return TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF295D49),
                  labelColor: const Color(0xFF295D49),
                  unselectedLabelColor: const Color(0xFF7F8C8D),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  isScrollable: true,
                  tabs: [
                    _buildTab('Semua', stats['total'] ?? 0),
                    _buildTab('Belum Bayar', stats['unpaid'] ?? 0),
                    _buildTab('Menunggu', stats['paid'] ?? 0),
                    _buildTab('Dikonfirmasi', stats['confirmed'] ?? 0),
                    _buildTab('Selesai', stats['delivered'] ?? 0),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(0), // Semua pesanan
          _buildOrderList(1), // Belum Bayar
          _buildOrderList(2), // Menunggu
          _buildOrderList(3), // Dikonfirmasi
          _buildOrderList(4), // Selesai
        ],
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF295D49),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderList(int tabIndex) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF295D49),
        ),
      );
    }

    final stream = _tabStreams[tabIndex];
    if (stream == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF295D49),
        ),
      );
    }

    return StreamBuilder<List<CombinedOrder>>(
      stream: stream,
      builder: (context, snapshot) {
        // Show loading only for initial load
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF295D49),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          final status = _getStatusForTab(tabIndex);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getStatusIcon(status),
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada pesanan ${status?.name ?? ''}',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return AdminOrderCard(
              order: orders[index],
              onStatusUpdate: (newStatus) {
                _updateOrderStatus(orders[index].orderId, newStatus);
              },
            );
          },
        );
      },
    );
  }

  OrderStatus? _getStatusForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return null; // Semua
      case 1:
        return OrderStatus.unpaid;
      case 2:
        return OrderStatus.paid;
      case 3:
        return OrderStatus.confirmed;
      case 4:
        return OrderStatus.delivered;
      default:
        return null;
    }
  }

  IconData _getStatusIcon(OrderStatus? status) {
    switch (status) {
      case OrderStatus.unpaid:
        return Icons.account_balance_wallet_outlined;
      case OrderStatus.paid:
        return Icons.inventory_2_outlined;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.shipped:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.check_circle;
      default:
        return Icons.shopping_bag_outlined;
    }
  }

  Future<void> _updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await OrderService.updateOrderStatus(orderId, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Status pesanan berhasil diupdate ke ${newStatus.name}'),
          backgroundColor: const Color(0xFF0B6623),
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
}

class AdminOrderCard extends StatelessWidget {
  final CombinedOrder order;
  final Function(OrderStatus) onStatusUpdate;

  const AdminOrderCard({
    super.key,
    required this.order,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final orderData = order.orderData;
    final userData = order.userData;

    return Container(
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order #${orderData.orderId.substring(0, 8)}...',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF3D5154),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            const SizedBox(height: 12),

            // Customer Info
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Color(0xFF7F8C8D)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    userData?.fullName ?? 'Nama tidak tersedia',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF3D5154),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Color(0xFF7F8C8D)),
                const SizedBox(width: 8),
                Text(
                  userData?.phoneNumber ?? 'No. HP tidak tersedia',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Items Summary
            Text(
              '${orderData.items.length} item(s) - Rp ${orderData.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF295D49),
              ),
            ),
            const SizedBox(height: 12),

            // Date
            Text(
              'Tanggal: ${_formatDate(orderData.orderDate)}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7F8C8D),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showStatusUpdateDialog(context);
                    },
                    icon: const Icon(Icons.update, size: 18),
                    label: const Text('Update Status'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF295D49),
                      side: const BorderSide(color: Color(0xFF295D49)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showOrderDetails(context);
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Detail'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF295D49),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  void _showStatusUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status Pesanan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption(
                context, OrderStatus.paid, 'Menunggu Konfirmasi'),
            _buildStatusOption(context, OrderStatus.confirmed, 'Dikonfirmasi'),
            _buildStatusOption(context, OrderStatus.delivered, 'Selesai'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(
      BuildContext context, OrderStatus status, String label) {
    return ListTile(
      leading: Icon(
        _getStatusIcon(status),
        color: status == order.orderData.status
            ? const Color(0xFF295D49)
            : Colors.grey,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: status == order.orderData.status
              ? const Color(0xFF295D49)
              : Colors.black,
          fontWeight: status == order.orderData.status
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onStatusUpdate(status);
      },
    );
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.paid:
        return Icons.inventory_2_outlined;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.shipped:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.check_circle;
      default:
        return Icons.shopping_bag_outlined;
    }
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
                    if (order.orderData.confirmedDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Dikonfirmasi: ${_formatDate(order.orderData.confirmedDate!)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    if (order.orderData.deliveredDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Diterima: ${_formatDate(order.orderData.deliveredDate!)}',
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
