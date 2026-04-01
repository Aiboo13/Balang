import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header Biru dengan Statistik
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            decoration: const BoxDecoration(
              color: Color(0xFF0900FF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('History', 
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        Text('Laporan Saya', 
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                // Grid Statistik
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatBox('3', 'Total'),
                    _buildStatBox('0', 'Aktif'),
                    _buildStatBox('1', 'Pending'),
                    _buildStatBox('2', 'Selesai'),
                  ],
                ),
                const SizedBox(height: 25),
                // Filter Tab
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFilterChip('Semua', isActive: true),
                      _buildFilterChip('Aktif'),
                      _buildFilterChip('Pending'),
                      _buildFilterChip('Selesai'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List History
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildHistoryCard(
                  title: 'Boneka',
                  desc: 'Boneka labubu warna pink',
                  status: 'Hilang',
                  label: 'Selesai',
                  user: 'Ilya',
                  prodi: 'Manajemen Informatika - 2024',
                  image: 'https://via.placeholder.com/150', // Ganti dengan gambar boneka
                ),
                const SizedBox(height: 20),
                _buildHistoryCard(
                  title: 'CAS',
                  desc: 'Cas Merk Xiaomi 90W',
                  status: 'Ditemukan',
                  label: 'Selesai',
                  user: 'Elya',
                  prodi: 'Manajemen Informatika - 2024',
                  image: 'https://via.placeholder.com/150', // Ganti dengan gambar cas
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget Box Statistik Atas
  Widget _buildStatBox(String value, String label) {
    return Container(
      width: 75,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  // Widget Tombol Filter
  Widget _buildFilterChip(String label, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0900FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  // Widget Kartu History
  Widget _buildHistoryCard({
    required String title, required String desc, required String status,
    required String label, required String user, required String prodi, required String image
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0900FF).withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(image, width: 100, height: 120, fit: BoxFit.cover),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'Hilang' ? Colors.red.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(status, style: TextStyle(color: status == 'Hilang' ? Colors.red : Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    const Text('Ruangan E-205', style: TextStyle(fontSize: 10, color: Colors.blue)),
                    const SizedBox(width: 10),
                    const Icon(Icons.calendar_today, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    const Text('Jumat, 27 Maret', style: TextStyle(fontSize: 10, color: Colors.blue)),
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5)),
                  child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const Divider(),
                Row(
                  children: [
                    const CircleAvatar(radius: 12, backgroundColor: Color(0xFFE0E0E0), child: Icon(Icons.person, size: 16, color: Colors.grey)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('By $user', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          Text(prodi, style: const TextStyle(fontSize: 9, color: Colors.grey), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}