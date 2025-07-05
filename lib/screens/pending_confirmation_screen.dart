import 'package:flutter/material.dart';
import 'package:learning_auth/models/order_model.dart';
import 'package:learning_auth/services/order_service.dart';
import 'package:learning_auth/services/payment_service.dart';

class PendingConfirmationScreen extends StatefulWidget {
  const PendingConfirmationScreen({super.key});

  @override
  State<PendingConfirmationScreen> createState() =>
      _PendingConfirmationScreenState();
}

class _PendingConfirmationScreenState extends State<PendingConfirmationScreen> {
  Stream<List<OrderModel>>? _ordersStream;

  @override
  void initState() {
    super.initState();
    _setupStream();
  }

  void _setupStream() {
    setState(() {
      _ordersStream = OrderService.getOrdersByStatus(OrderStatus.paid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: _ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Tidak ada pesanan menunggu',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Pesanan yang sedang diproses atau menunggu konfirmasi akan muncul di sini',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
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
            return PendingOrderCard(order: orders[index]);
          },
        );
      },
    );
  }
}

class PendingOrderCard extends StatelessWidget {
  final OrderModel order;

  const PendingOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
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
            // Header dengan Order ID dan Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Order #${order.orderId.substring(0, 8)}...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF3D5154),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: order.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: order.statusColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        order.statusText,
                        style: TextStyle(
                          color: order.statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                // Tampilkan informasi pembayaran jika ada
                if (order.paymentStatus != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Status Pembayaran: ${_getPaymentStatusText(order.paymentStatus!)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Tanggal Pesanan
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: Color(0xFF7F8C8D)),
                const SizedBox(width: 8),
                Text(
                  'Pesanan: ${_formatDate(order.orderDate)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
              ],
            ),
            if (order.paymentDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.payment, size: 16, color: Color(0xFF7F8C8D)),
                  const SizedBox(width: 8),
                  Text(
                    'Pembayaran: ${_formatDate(order.paymentDate!)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Daftar Item
            const Text(
              'Item Pesanan:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF3D5154),
              ),
            ),
            const SizedBox(height: 8),
            ...order.items.map((item) => _buildItemTile(item)),
            const SizedBox(height: 16),

            // Total
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
                  'Rp ${order.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF295D49),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Informasi Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusInfoColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: _getStatusInfoColor().withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: _getStatusInfoColor(), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getStatusInfoMessage(),
                      style: TextStyle(
                        fontSize: 14,
                        color: _getStatusInfoColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item) {
    final imageUrl = item['imageUrl'] ?? 'assets/placeholder.png';
    final name = item['name'] ?? 'Nama Produk Tidak Tersedia';
    final quantity = item['quantity'] ?? 0;
    final price = (item['price'] ?? 0).toDouble();
    final size = item['size'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, color: Colors.grey),
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
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (size.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Ukuran: $size',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Qty: $quantity x Rp ${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Rp ${(price * quantity).toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF295D49),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getPaymentStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Menunggu Pembayaran';
      case PaymentStatus.success:
        return 'Pembayaran Berhasil';
      case PaymentStatus.failed:
        return 'Pembayaran Gagal';
      case PaymentStatus.expired:
        return 'Pembayaran Expired';
      case PaymentStatus.cancelled:
        return 'Pembayaran Dibatalkan';
    }
  }

  Color _getStatusInfoColor() {
    // Tentukan warna berdasarkan status pesanan dan pembayaran
    if (order.paymentStatus == PaymentStatus.pending) {
      return Colors.orange; // Menunggu pembayaran
    } else if (order.status == OrderStatus.paid) {
      return Colors.blue; // Menunggu konfirmasi admin
    } else if (order.status == OrderStatus.confirmed) {
      return Colors.purple; // Sedang diproses
    } else if (order.status == OrderStatus.shipped) {
      return Colors.indigo; // Dikirim
    } else {
      return Colors.grey;
    }
  }

  String _getStatusInfoMessage() {
    // Tentukan pesan berdasarkan status pesanan dan pembayaran
    if (order.paymentStatus == PaymentStatus.pending) {
      return 'Pembayaran Anda sedang diproses. Silakan selesaikan pembayaran sesuai instruksi yang diberikan.';
    } else if (order.status == OrderStatus.paid) {
      return 'Pembayaran berhasil! Pesanan Anda sedang menunggu konfirmasi dari admin. Kami akan memproses pesanan Anda segera.';
    } else if (order.status == OrderStatus.confirmed) {
      return 'Pesanan Anda telah dikonfirmasi dan sedang diproses. Kami akan mengirimkan pesanan Anda segera.';
    } else if (order.status == OrderStatus.shipped) {
      return 'Pesanan Anda telah dikirim. Silakan cek status pengiriman untuk informasi lebih lanjut.';
    } else {
      return 'Status pesanan tidak diketahui. Silakan hubungi kami untuk informasi lebih lanjut.';
    }
  }
}
