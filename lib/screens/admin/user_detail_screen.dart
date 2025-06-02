import 'package:flutter/material.dart';

class UserDetailScreen extends StatelessWidget {
  const UserDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengguna'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user icon
            const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 100,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '🧑 Detail Pengguna',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // User Details
            const DetailRow(
              icon: '👤',
              label: 'Nama',
              value: 'Rahma Nur Aini',
            ),
            const DetailRow(
              icon: '📧',
              label: 'Email',
              value: 'rahma@gmail.com',
            ),
            const DetailRow(
              icon: '📱',
              label: 'No. HP',
              value: '0812-xxxx',
            ),
            const DetailRow(
              icon: '🏠',
              label: 'Alamat',
              value: 'Makassar, Sulsel',
            ),
            const DetailRow(
              icon: '📦',
              label: 'Total Transaksi',
              value: '15',
            ),

            const SizedBox(height: 32),

            // Status Card
          ],
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
