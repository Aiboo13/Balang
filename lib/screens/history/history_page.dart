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
  final Set<String> _processingDecisionDocIds = <String>{};

  Future<void> _decideClaimFromHistory({
    required String docId,
    required bool accepted,
  }) async {
    if (_processingDecisionDocIds.contains(docId)) {
      return;
    }

    setState(() => _processingDecisionDocIds.add(docId));
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final updateData = <String, dynamic>{
        'reportStatus': accepted ? 'Selesai' : 'Aktif',
        'claimStatus': accepted ? 'Accepted' : 'None',
        'claimRespondedAt': FieldValue.serverTimestamp(),
        'decidedBy': currentUserId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!accepted) {
        updateData['claimerId'] = FieldValue.delete();
        updateData['claimerName'] = FieldValue.delete();
        updateData['claimerWhatsApp'] = FieldValue.delete();
        updateData['claimRequestedAt'] = FieldValue.delete();
      }

      await FirebaseFirestore.instance
          .collection('reports')
          .doc(docId)
          .update(updateData);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accepted
                ? 'Klaim disetujui. Laporan dipindah ke status selesai.'
                : 'Klaim ditolak. Laporan kembali ke status aktif.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memproses keputusan: $e')));
    } finally {
      if (mounted) {
        setState(() => _processingDecisionDocIds.remove(docId));
      }
    }
  }

  void _showDecisionDialog(
    BuildContext context, {
    required String docId,
    required bool accept,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Konfirmasi Klaim',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          accept
              ? 'Setujui klaim ini? Laporan akan dipindah ke status selesai.'
              : 'Tolak klaim ini? Laporan akan kembali ke status aktif.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _decideClaimFromHistory(docId: docId, accepted: accept);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accept
                  ? const Color(0xFF0900FF)
                  : Colors.redAccent,
            ),
            child: Text(
              accept ? 'Accept' : 'Reject',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: StreamBuilder<QuerySnapshot>(
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

          List<QueryDocumentSnapshot> docs = List.from(allDocs);
          docs.sort((a, b) {
            final aTime =
                (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final bTime =
                (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          int total = docs.length;
          int aktif = 0, pending = 0, selesai = 0;
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

          List<QueryDocumentSnapshot> filteredDocs = docs;
          if (_selectedTab != 'Semua') {
            filteredDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['reportStatus'] ?? 'Aktif') == _selectedTab;
            }).toList();
          }

          return Column(
            children: [
              _buildHeader(total, aktif, pending, selesai),
              if (filteredDocs.isEmpty)
                _buildEmptyState()
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
          // Judul
          Row(
            children: [
              const Icon(
                Icons.access_time_filled,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

          // Statistik
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

          // Tab filter di dalam header
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
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
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
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
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF0900FF).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 50,
                color: Color(0xFF0900FF),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada laporan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Anda belum melaporkan barang hilang\natau temuan',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    final title = data['title'] ?? 'Tanpa Nama';
    final desc = data['description'] ?? '';
    final category = data['category'] ?? 'Kehilangan';
    final isHilang = category == 'Kehilangan';
    final reportStatus = data['reportStatus'] ?? 'Aktif';
    final claimStatus = (data['claimStatus'] ?? 'None').toString();
    final claimerName = (data['claimerName'] ?? '').toString().trim();
    final claimerWhatsApp = (data['claimerWhatsApp'] ?? '').toString().trim();
    final claimerWhatsAppDisplay = claimerWhatsApp.isNotEmpty
        ? claimerWhatsApp
        : '-';
    final isPendingClaim =
        claimStatus == 'Pending' ||
        (claimStatus == 'None' && reportStatus == 'Pending');
    final showClaimerInfo =
        claimerName.isNotEmpty && (isPendingClaim || reportStatus == 'Selesai');
    final isProcessingDecision = _processingDecisionDocIds.contains(docId);
    final imageUrl = data['imageUrl'];

    // Warna badge Hilang/Ditemukan
    final categoryColor = isHilang ? Colors.redAccent : Colors.green;

    // Warna badge status laporan
    Color statusColor;
    switch (reportStatus) {
      case 'Aktif':
        statusColor = Colors.green;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        break;
      case 'Selesai':
        statusColor = Colors.blueGrey;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImage(imageUrl),
              ),
              const SizedBox(width: 14),

              // Detail
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul + menu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Badge Hilang/Ditemukan
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isHilang ? 'Hilang' : 'Ditemukan',
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
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

                    // Deskripsi
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),

                    // Lokasi & Tanggal
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

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Status laporan di bawah
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status Laporan:',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
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
          if (showClaimerInfo) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 14,
                  color: Color(0xFF0900FF),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reportStatus == 'Selesai'
                        ? 'Diklaim oleh: $claimerName'
                        : 'Pengklaim / Penemu: $claimerName',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 13,
                  color: Color(0xFF0900FF),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    claimerWhatsAppDisplay,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (isPendingClaim) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: isProcessingDecision
                          ? null
                          : () => _showDecisionDialog(
                              context,
                              docId: docId,
                              accept: true,
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0900FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Accept',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: isProcessingDecision
                          ? null
                          : () => _showDecisionDialog(
                              context,
                              docId: docId,
                              accept: false,
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Laporan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Yakin ingin menghapus laporan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('reports')
                  .doc(docId)
                  .delete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(dynamic imageUrl) {
    if (imageUrl == null || imageUrl.toString().isEmpty) {
      return Container(
        width: 85,
        height: 85,
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
    if (imageUrl.toString().startsWith('http')) {
      return Image.network(imageUrl, width: 85, height: 85, fit: BoxFit.cover);
    }
    return Image.memory(
      base64Decode(imageUrl),
      width: 85,
      height: 85,
      fit: BoxFit.cover,
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 12, color: const Color(0xFF0900FF)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
