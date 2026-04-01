import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0900FF), // Background Biru Atas
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Kembali', style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: 6,
                separatorBuilder: (_, __) => const SizedBox(height: 15),
                itemBuilder: (context, index) => _buildNotificationCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ditemukan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('19 Maret 2026 10.00', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 5),
          const Text('Tas Hitam', style: TextStyle(color: Colors.black87)),
          const SizedBox(height: 10),
          const Text('Lihat Barang →', style: TextStyle(color: Color(0xFF0900FF), fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}