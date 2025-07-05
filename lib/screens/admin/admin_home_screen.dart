import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learning_auth/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'incoming_orders_screen.dart';
import 'product_management_screen.dart';
import 'user_management_screen.dart';
import 'payment_report_screen.dart';
import 'package:learning_auth/screens/admin/order_management_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  // Function to extract admin name from email
  String _getAdminNameFromEmail(String email) {
    // Extract the part before @ symbol
    String namePart = email.split('@')[0];

    // Capitalize first letter and handle camelCase
    if (namePart.isNotEmpty) {
      // Handle camelCase like "Firjestore" -> "FirjeStore"
      if (namePart.length > 1) {
        return namePart[0].toUpperCase() + namePart.substring(1);
      }
      return namePart[0].toUpperCase();
    }

    return 'Admin';
  }

  // Function to load statistics efficiently
  Future<List<Map<String, dynamic>>> _loadStatistics() async {
    try {
      // Load products and users in parallel
      final productsFuture =
          FirebaseFirestore.instance.collection('products').get();
      final usersFuture = FirebaseFirestore.instance.collection('users').get();

      final results = await Future.wait([productsFuture, usersFuture]);

      final totalProducts = results[0].size;
      final totalUsers = results[1].docs.where((doc) {
        final userData = doc.data() as Map<String, dynamic>;
        final role = userData['role'] ?? 'pelanggan';
        return role != 'admin'; // Only count regular users
      }).length;

      return [
        {'products': totalProducts},
        {'users': totalUsers},
      ];
    } catch (e) {
      print('Error loading statistics: $e');
      return [
        {'products': 0},
        {'users': 0},
      ];
    }
  }

  // Function to load revenue efficiently
  Future<double> _loadRevenue() async {
    try {
      final revenueSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('status',
              whereIn: ['paid', 'confirmed', 'shipped', 'delivered']).get();

      double totalRevenue = 0;

      if (revenueSnapshot.docs.isNotEmpty) {
        for (var doc in revenueSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = data['totalAmount'] as num?;
          final paymentDate = data['paymentDate'] as Timestamp?;

          // Hanya hitung jika ada totalAmount dan paymentDate
          if (amount != null && paymentDate != null) {
            totalRevenue += amount.toDouble();
          }
        }
      }

      print(
          '💰 Total revenue calculated: Rp${totalRevenue.toStringAsFixed(0)}');
      return totalRevenue;
    } catch (e) {
      print('Error loading revenue: $e');
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 247, 247),
      appBar: AppBar(
        title: const Text(
          'Dashboard Admin',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF295D49),
        foregroundColor: Colors.white,
        elevation: 0,
        // Tidak ada leading (kiri atas), hanya actions di kanan atas
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 24),
            onPressed: () async {
              await authService.signOut();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF295D49),
                    const Color(0xFF0B6623),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF295D49).withOpacity(0.3),
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
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '👋 Hai, ${_getAdminNameFromEmail(currentUser?.email ?? '')}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Selamat datang di Dashboard Admin FirjeStore',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Statistik Kartu
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadStatistics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Row(
                    children: [
                      Expanded(
                        child: StatisticCard(
                          title: 'Total Produk',
                          value: '...',
                          icon: Icons.inventory_2,
                          color: const Color(0xFF295D49),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: StatisticCard(
                          title: 'Total User',
                          value: '...',
                          icon: Icons.people,
                          color: const Color(0xFF0B6623),
                        ),
                      ),
                    ],
                  );
                }

                final stats = snapshot.data ??
                    [
                      {'products': 0},
                      {'users': 0}
                    ];
                final totalProducts =
                    stats.isNotEmpty ? stats[0]['products'] ?? 0 : 0;
                final totalUsers =
                    stats.length > 1 ? stats[1]['users'] ?? 0 : 0;

                return Row(
                  children: [
                    Expanded(
                      child: StatisticCard(
                        title: 'Total Produk',
                        value: totalProducts.toString(),
                        icon: Icons.inventory_2,
                        color: const Color(0xFF295D49),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: StatisticCard(
                        title: 'Total User',
                        value: totalUsers.toString(),
                        icon: Icons.people,
                        color: const Color(0xFF0B6623),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 26),

            // Pendapatan
            FutureBuilder<double>(
              future: _loadRevenue(),
              builder: (context, snapshot) {
                final totalRevenue = snapshot.data ?? 0.0;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF485F62),
                        const Color(0xFF3D5154),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF485F62).withOpacity(0.3),
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
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.payments,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Pendapatan',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp${totalRevenue.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Menu Section Title
            const Text(
              'Menu Admin',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3D5154),
              ),
            ),
            const SizedBox(height: 16),

            // Tombol Menu
            MenuButton(
              icon: Icons.shopping_bag,
              label: 'Lihat Pesanan Masuk',
              color: const Color(0xFF295D49),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const IncomingOrdersScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            MenuButton(
              icon: Icons.manage_accounts,
              label: 'Manajemen Pesanan',
              color: const Color(0xFF485F62),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OrderManagementScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            MenuButton(
              icon: Icons.inventory,
              label: 'Manajemen Produk',
              color: const Color(0xFF0B6623),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProductManagementScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            MenuButton(
              icon: Icons.people,
              label: 'Manajemen User',
              color: const Color(0xFF485F62),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UserManagementScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            MenuButton(
              icon: Icons.payment,
              label: 'Pembayaran & Laporan',
              color: const Color(0xFF3D5154),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PaymentReportScreen()),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Statistic Card
class StatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatisticCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Menu Button
class MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const MenuButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3D5154),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
