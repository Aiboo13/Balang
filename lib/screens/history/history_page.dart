import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home/add_report_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _selectedTab = 'Semua';

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        // Menggunakan filter langsung di query lebih efisien
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('userId', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
          }

          final allDocs = snapshot.data?.docs ?? [];

          // Sorting manual berdasarkan waktu (karena query Firestore butuh index untuk orderBy)
          List<QueryDocumentSnapshot> docs = List.from(allDocs);
          docs.sort((a, b) {
            final aTime =
                (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final bTime =
                (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          // Hitung Statistik berdasarkan field 'reportStatus'
          int total = docs.length;
          int aktif = 0;
          int pending = 0;
          int selesai = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['reportStatus'] ?? 'Aktif';
            if (status == 'Aktif')
              aktif++;
            else if (status == 'Pending')
              pending++;
            else if (status == 'Selesai')
              selesai++;
          }

          // Filter Tab
          List<QueryDocumentSnapshot> filteredDocs = docs;
          if (_selectedTab != 'Semua') {
            filteredDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['reportStatus'] ?? 'Aktif') == _selectedTab;
            }).toList();
          }

          return Column(
            children: [
              // --- Header Biru (Tetap sama seperti kode Anda) ---
              _buildHeader(total, aktif, pending, selesai),

              // --- Area Daftar History ---
              if (filteredDocs.isEmpty)
                _buildEmptyState()
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final docId = filteredDocs[index].id;
                      final data =
                          filteredDocs[index].data() as Map<String, dynamic>;
                      return _buildHistoryCard(context, docId, data);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // --- Widget Helper agar kode lebih bersih ---

  Widget _buildHeader(int total, int aktif, int pending, int selesai) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 20),
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
          Row(
            children: [
              const Icon(
                Icons.access_time_filled,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Laporan Saya',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('$total', 'Total'),
              _buildStatItem('$aktif', 'Aktif'),
              _buildStatItem('$pending', 'Pending'),
              _buildStatItem('$selesai', 'Selesai'),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                'Semua',
                'Aktif',
                'Pending',
                'Selesai',
              ].map((e) => _buildTab(e)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    // Sesuaikan pengambilan data dengan gambar Firestore Anda
    final title = data['title'] ?? 'Tanpa Nama';
    final desc = data['description'] ?? '';
    final category = data['category'] ?? 'Kehilangan';
    final isHilang = category == 'Kehilangan';
    final reportStatus = data['reportStatus'] ?? 'Aktif'; // Default ke Aktif
    final imageUrl = data['imageUrl'];

    Color statusColor = reportStatus == 'Aktif'
        ? Colors.green
        : (reportStatus == 'Pending' ? Colors.orange : Colors.blueGrey);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0900FF).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Loader (Base64 atau URL)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildImage(imageUrl),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (val) =>
                              _handleMenuAction(context, val, docId, data),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Hapus',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                          child: const Icon(
                            Icons.more_vert,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    _buildIconText(
                      Icons.location_on_outlined,
                      data['location'] ?? '-',
                    ),
                    _buildIconText(
                      Icons.calendar_today_outlined,
                      data['date'] ?? '-',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Status Laporan:",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  reportStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Fungsi Tambahan ---

  void _handleMenuAction(
    BuildContext context,
    String action,
    String docId,
    Map<String, dynamic> data,
  ) {
    if (action == 'edit') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddReportPage(docId: docId, existingData: data),
        ),
      );
    } else if (action == 'delete') {
      _showDeleteDialog(context, docId);
    }
  }

  void _showDeleteDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus'),
        content: const Text('Yakin ingin menghapus laporan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('reports')
                  .doc(docId)
                  .delete();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(dynamic imageUrl) {
    if (imageUrl == null || imageUrl.toString().isEmpty) {
      return Container(
        width: 80,
        height: 80,
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported),
      );
    }
    if (imageUrl.toString().startsWith('http')) {
      return Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover);
    }
    return Image.memory(
      base64Decode(imageUrl),
      width: 80,
      height: 80,
      fit: BoxFit.cover,
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF0900FF)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Container(
      width: 75,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label) {
    bool isActive = _selectedTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF3333CC) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              "Belum ada laporan",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
