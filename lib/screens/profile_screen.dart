import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learning_auth/screens/my_account_screen.dart';
import 'package:learning_auth/screens/my_orders_screen.dart';
import 'package:learning_auth/models/order_model.dart';
import 'package:learning_auth/services/order_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _userName;
  String? _userEmail;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes active
    _refreshUserData();
  }

  Future<void> _loadUserData() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    print('Loading user data...'); // Debug print
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _userEmail = user.email;
        });

        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (doc.exists) {
            final data = doc.data()!;
            final fullName = data['fullName'] as String?;

            print('Firestore data: $data'); // Debug print
            print('Full name from Firestore: $fullName'); // Debug print

            setState(() {
              _userName = (fullName != null && fullName.isNotEmpty)
                  ? fullName
                  : "Not set";
            });
            print('User name set to: $_userName'); // Debug print
          } else {
            setState(() {
              _userName = "Not set";
            });
            print(
                'Document does not exist, setting name to: $_userName'); // Debug print
          }
        } catch (e) {
          print('Error loading additional data: $e');
          setState(() {
            _userName = "Not set";
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateProfileName(String newName) {
    print('Profile name updated to: $newName'); // Debug print
    if (mounted) {
      setState(() {
        _userName = newName.isNotEmpty ? newName : "Not set";
      });
      print('Profile name set to: $_userName'); // Debug print
    }
  }

  Future<void> _refreshUserData() async {
    print('Refreshing user data...'); // Debug print
    if (mounted) {
      await _loadUserData();
      print('User data refreshed. Current name: $_userName'); // Debug print
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Profil",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: Color(0xFF3D5154),
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.email_outlined,
              color: Color(0xFF7F8C8D),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none,
              color: Color(0xFF7F8C8D),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF295D49),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
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
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF295D49).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const CircleAvatar(
                            backgroundColor: Color(0xFF295D49),
                            radius: 35,
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userName ?? "Not set",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: Color(0xFF3D5154),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userEmail ?? "",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF7F8C8D),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF0B6623).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Pelanggan Aktif',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0B6623),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Menu Pesanan Saya
                  const MyOrdersMenu(),
                  const SizedBox(height: 30),
                  // General Settings
                  const Text(
                    "Pengaturan Umum",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFF3D5154),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
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
                    child: Column(
                      children: [
                        ListTile(
                          IconTile: Icons.person_outline,
                          LabelTile: "Akun Saya",
                          onTap: () async {
                            print(
                                'Navigating to MyAccountScreen...'); // Debug print
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MyAccountScreen(
                                  onProfileUpdated: _updateProfileName,
                                ),
                              ),
                            );
                            print(
                                'Returned from MyAccountScreen. Refreshing data...'); // Debug print
                            // Always refresh data when returning from MyAccountScreen
                            await _refreshUserData();
                          },
                        ),
                        const Divider(height: 1, indent: 60),
                        // ListTile(
                        //   IconTile: Icons.payment_outlined,
                        //   LabelTile: "Metode Pembayaran",
                        // ),
                        // const Divider(height: 1, indent: 60),
                        // ListTile(
                        //   IconTile: Icons.location_on_outlined,
                        //   LabelTile: "Alamat Saya",
                        //   onTap: () {
                        //     Navigator.pushNamed(context, '/my_address');
                        //   },
                        // ),
                        const Divider(height: 1, indent: 60),
                        ListTile(
                          IconTile: Icons.notifications_none,
                          LabelTile: "Notifikasi",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Other Settings
                  const Text(
                    "Lainnya",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFF3D5154),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
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
                    child: Column(
                      children: [
                        ListTile(
                          IconTile: Icons.contact_page_outlined,
                          LabelTile: "Preferensi Kontak",
                        ),
                        const Divider(height: 1, indent: 60),
                        ListTile(
                          IconTile: Icons.description_outlined,
                          LabelTile: "Syarat dan Ketentuan",
                        ),
                        const Divider(height: 1, indent: 60),
                        ListTile(
                          IconTile: Icons.help_outline,
                          LabelTile: "Bantuan",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Logout Button
                  Container(
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
                    child: ListTile(
                      IconTile: Icons.logout,
                      LabelTile: "Keluar",
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: const Text(
                                'Konfirmasi Keluar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3D5154),
                                ),
                              ),
                              content: const Text(
                                'Apakah Anda yakin ingin keluar dari aplikasi?',
                                style: TextStyle(color: Color(0xFF3D5154)),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    'Batal',
                                    style: TextStyle(color: Color(0xFF7F8C8D)),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _signOut();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text('Keluar'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Widget untuk menu "Pesanan Saya"
class MyOrdersMenu extends StatefulWidget {
  const MyOrdersMenu({super.key});

  @override
  State<MyOrdersMenu> createState() => _MyOrdersMenuState();
}

class _MyOrdersMenuState extends State<MyOrdersMenu> {
  Stream<Map<OrderStatus, int>>? _orderCountsStream;

  @override
  void initState() {
    super.initState();
    print('🔄 Initializing MyOrdersMenu stream...');
    _orderCountsStream = OrderService.getOrderCountsByStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('🔄 MyOrdersMenu dependencies changed, refreshing stream...');
    // Refresh stream when dependencies change (e.g., when returning from payment)
    _orderCountsStream = OrderService.getOrderCountsByStatus();
  }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pesanan Saya',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D5154),
                ),
              ),
              Row(
                children: [
                  // Refresh button
                  IconButton(
                    onPressed: () {
                      print('🔄 Manual refresh triggered for MyOrdersMenu');
                      setState(() {
                        _orderCountsStream =
                            OrderService.getOrderCountsByStatus();
                      });
                    },
                    icon: const Icon(
                      Icons.refresh,
                      color: Color(0xFF0B6623),
                      size: 20,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const MyOrdersScreen(initialTabIndex: 0)),
                      );
                    },
                    child: const Row(
                      children: [
                        Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0B6623),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Color(0xFF0B6623),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<Map<OrderStatus, int>>(
            stream: _orderCountsStream,
            builder: (context, snapshot) {
              print('📊 MyOrdersMenu StreamBuilder update:');
              print('   - Has data: ${snapshot.hasData}');
              print('   - Has error: ${snapshot.hasError}');
              print('   - Connection state: ${snapshot.connectionState}');

              if (snapshot.hasError) {
                print('❌ Stream error: ${snapshot.error}');
                return const Center(
                  child: Text(
                    'Error loading orders',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                print('⏳ Stream waiting for data...');
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF0B6623),
                  ),
                );
              }

              final counts = snapshot.data ?? {};
              print('📊 Order counts: $counts');

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _OrderMenuItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Belum Bayar',
                    notificationCount: counts[OrderStatus.unpaid] ?? 0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const MyOrdersScreen(initialTabIndex: 0)),
                      );
                    },
                  ),
                  _OrderMenuItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Menunggu',
                    notificationCount: counts[OrderStatus.paid] ?? 0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const MyOrdersScreen(initialTabIndex: 1)),
                      );
                    },
                  ),
                  _OrderMenuItem(
                    icon: Icons.verified_outlined,
                    label: 'Dikonfirmasi',
                    notificationCount: counts[OrderStatus.confirmed] ?? 0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const MyOrdersScreen(initialTabIndex: 2)),
                      );
                    },
                  ),
                  _OrderMenuItem(
                    icon: Icons.check_circle_outline,
                    label: 'Selesai',
                    notificationCount: counts[OrderStatus.delivered] ?? 0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const MyOrdersScreen(initialTabIndex: 3)),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// alamat saya
// Widget untuk setiap item di menu pesanan
class _OrderMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int notificationCount;
  final VoidCallback onTap;

  const _OrderMenuItem({
    required this.icon,
    required this.label,
    this.notificationCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B6623).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: const Color(0xFF0B6623),
                ),
              ),
              if (notificationCount > 0)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      notificationCount > 99 ? '99+' : '$notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3D5154),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ListTile extends StatelessWidget {
  final IconData IconTile;
  final String LabelTile;
  final VoidCallback? onTap;

  const ListTile({
    super.key,
    required this.IconTile,
    required this.LabelTile,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B6623).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    IconTile,
                    size: 20,
                    color: const Color(0xFF0B6623),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  LabelTile,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF3D5154),
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Color(0xFF7F8C8D),
            ),
          ],
        ),
      ),
    );
  }
}
