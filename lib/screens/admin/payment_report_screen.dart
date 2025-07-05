import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:learning_auth/models/user_model.dart';

class PaymentReportScreen extends StatelessWidget {
  const PaymentReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 248, 247, 247),
        appBar: AppBar(
          title: const Text(
            'Pembayaran & Laporan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: const Color(0xFF295D49),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Trigger refresh for both tabs
                // This will be handled by the StreamBuilder automatically
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Memperbarui data...'),
                    duration: Duration(seconds: 1),
                    backgroundColor: Color(0xFF295D49),
                  ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Riwayat Pembayaran'),
              Tab(text: 'Laporan Pendapatan'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
          ),
        ),
        body: const TabBarView(
          children: [
            PaymentHistoryTab(),
            RevenueReportTab(),
          ],
        ),
      ),
    );
  }
}

class PaymentHistoryTab extends StatelessWidget {
  const PaymentHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('paymentDate',
              isGreaterThan: Timestamp.fromDate(DateTime(2020, 1, 1)))
          .orderBy('paymentDate', descending: true)
          .snapshots(),
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

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.payment_outlined,
                    size: 64,
                    color: const Color(0xFF7F8C8D),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tidak ada riwayat pembayaran',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF7F8C8D),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final totalAmount = (data['totalAmount'] as num).toDouble();
            final paymentDate = data['paymentDate'] as Timestamp?;
            final orderDate = data['orderDate'] as Timestamp;
            final orderId = data['orderId'] as String;
            final userId = data['userId'] as String;
            final paymentDetails =
                data['paymentDetails'] as Map<String, dynamic>?;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, userSnapshot) {
                UserModel? userData;
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  userData = UserModel.fromFirestore(userSnapshot.data!);
                }

                return PaymentCard(
                  amount: totalAmount,
                  date: paymentDate ?? orderDate,
                  orderId: orderId,
                  userData: userData,
                  paymentDetails: paymentDetails,
                  currentStatus: data['status'] as String?,
                );
              },
            );
          },
        );
      },
    );
  }
}

class PaymentCard extends StatelessWidget {
  final double amount;
  final Timestamp date;
  final String orderId;
  final UserModel? userData;
  final Map<String, dynamic>? paymentDetails;
  final String? currentStatus;

  const PaymentCard({
    super.key,
    required this.amount,
    required this.date,
    required this.orderId,
    this.userData,
    this.paymentDetails,
    this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM yyyy HH:mm').format(date.toDate());
    final customerName = userData?.fullName ?? 'Nama tidak tersedia';
    final customerEmail = userData?.email ?? 'Email tidak tersedia';

    // Get payment method from payment details
    final paymentMethod = paymentDetails?['payment_type'] ?? 'Midtrans';
    final transactionStatus =
        paymentDetails?['transaction_status'] ?? 'settlement';
    final fraudStatus = paymentDetails?['fraud_status'] ?? 'accept';

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
            // Payment Method and Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF295D49).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.payment,
                          color: Color(0xFF295D49),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          paymentMethod.toString().toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF3D5154),
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Rp${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B6623),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Customer Information
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B6623).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF0B6623),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3D5154),
                        ),
                      ),
                      Text(
                        customerEmail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date and Time
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF485F62).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.schedule,
                    color: Color(0xFF485F62),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF3D5154),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Order ID
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7F8C8D).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.receipt,
                    color: Color(0xFF7F8C8D),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Order: ${orderId.substring(0, 8)}...',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF3D5154),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0B6623).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: const Color(0xFF0B6623),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Sukses ($transactionStatus)',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF0B6623),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Current Order Status
            if (currentStatus != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(currentStatus!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(currentStatus!),
                      size: 16,
                      color: _getStatusColor(currentStatus!),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getStatusText(currentStatus!),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(currentStatus!),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper methods untuk status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'paid':
        return Icons.payment;
      case 'confirmed':
        return Icons.check_circle;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'Menunggu Konfirmasi';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'shipped':
        return 'Dikirim';
      case 'delivered':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Status Tidak Diketahui';
    }
  }
}

class RevenueReportTab extends StatelessWidget {
  const RevenueReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('paymentDate',
              isGreaterThan: Timestamp.fromDate(DateTime(2020, 1, 1)))
          .orderBy('paymentDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        double totalRevenue = 0;
        int totalTransactions = 0;
        List<Map<String, dynamic>> recentTransactions = [];

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
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF7F8C8D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // StreamBuilder akan otomatis refresh
                  },
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasData) {
          totalTransactions = snapshot.data!.docs.length;

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = data['totalAmount'] as num?;
            final paymentDate = data['paymentDate'] as Timestamp?;

            if (amount != null) {
              totalRevenue += amount.toDouble();

              // Simpan transaksi terbaru untuk ditampilkan
              if (recentTransactions.length < 5) {
                recentTransactions.add({
                  'orderId': doc.id,
                  'amount': amount.toDouble(),
                  'paymentDate': paymentDate,
                  'customerName': data['customerName'] ?? 'Nama tidak tersedia',
                });
              }
            }
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Revenue Statistics Cards
              RevenueCard(
                title: 'Total Pendapatan',
                amount: 'Rp${totalRevenue.toStringAsFixed(0)}',
                icon: Icons.payments,
                color: const Color(0xFF295D49),
              ),
              const SizedBox(height: 16),
              RevenueCard(
                title: 'Total Transaksi',
                amount: totalTransactions.toString(),
                icon: Icons.receipt_long,
                color: const Color(0xFF0B6623),
              ),
              const SizedBox(height: 24),

              // Recent Transactions
              if (recentTransactions.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transaksi Terbaru',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D5154),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...recentTransactions
                          .map(
                            (transaction) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          transaction['customerName'],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF3D5154),
                                          ),
                                        ),
                                        Text(
                                          'Order: ${transaction['orderId'].substring(0, 8)}...',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF7F8C8D),
                                          ),
                                        ),
                                        if (transaction['paymentDate'] != null)
                                          Text(
                                            DateFormat('dd MMM yyyy HH:mm')
                                                .format(
                                                    transaction['paymentDate']
                                                        .toDate()),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF7F8C8D),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'Rp${transaction['amount'].toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0B6623),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Transaction Statistics
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  children: [
                    const Text(
                      'Statistik Transaksi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D5154),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transaksi Berhasil',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF3D5154),
                          ),
                        ),
                        Text(
                          totalTransactions.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B6623),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transaksi Gagal',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF3D5154),
                          ),
                        ),
                        Text(
                          '0',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Download Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Fitur download PDF akan segera hadir'),
                            backgroundColor: Color(0xFF295D49),
                          ),
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Unduh PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF295D49),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Fitur download CSV akan segera hadir'),
                            backgroundColor: Color(0xFF0B6623),
                          ),
                        );
                      },
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Unduh CSV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B6623),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class RevenueCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;

  const RevenueCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7F8C8D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
