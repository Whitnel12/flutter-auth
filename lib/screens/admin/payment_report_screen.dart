import 'package:flutter/material.dart';

class PaymentReportScreen extends StatelessWidget {
  const PaymentReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran & Laporan'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Riwayat Pembayaran'),
              Tab(text: 'Laporan Pendapatan'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10, // Replace with actual payment count
      itemBuilder: (context, index) {
        return const PaymentCard();
      },
    );
  }
}

class PaymentCard extends StatelessWidget {
  const PaymentCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                Row(
                  children: [
                    const Text(
                      '💰',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Gopay',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Rp200.000',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date and Time
            const Row(
              children: [
                Text(
                  '📅',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 8),
                Text(
                  '31 Mei 2025 11:45',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // User
            const Row(
              children: [
                Text(
                  '🧍',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 8),
                Text(
                  'User: Bagus',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Sukses (settlement)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
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
}

class RevenueReportTab extends StatelessWidget {
  const RevenueReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue Statistics Cards
          const RevenueCard(
            title: 'Hari Ini',
            amount: 'Rp1.200.000',
            icon: Icons.today,
          ),
          const SizedBox(height: 16),
          const RevenueCard(
            title: 'Bulan Ini',
            amount: 'Rp15.400.000',
            icon: Icons.calendar_month,
          ),
          const SizedBox(height: 24),

          // Transaction Statistics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transaksi Berhasil',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '73',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transaksi Gagal',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '3',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
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
                    // Implement PDF download
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Unduh PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Implement CSV download
                  },
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Unduh CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RevenueCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;

  const RevenueCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Colors.orange),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
