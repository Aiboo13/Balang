import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'detail_page.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  String _formatNotificationTitle(Map<String, dynamic> data) {
    final category = (data['category'] ?? 'Kehilangan').toString().trim();
    final title = (data['title'] ?? 'Tanpa Nama').toString().trim();
    final normalizedCategory = category.toLowerCase();
    final statusText = normalizedCategory.startsWith('temu')
        ? 'ditemukan'
        : 'kehilangan';
    return '$statusText, $title';
  }

  String _statusLabel(Map<String, dynamic> data) {
    final category = (data['category'] ?? 'Kehilangan')
        .toString()
        .toLowerCase();
    return category.startsWith('temu') ? 'Ditemukan' : 'Kehilangan';
  }

  Color _statusColor(Map<String, dynamic> data) {
    final category = (data['category'] ?? 'Kehilangan')
        .toString()
        .toLowerCase();
    return category.startsWith('temu') ? Colors.green : Colors.redAccent;
  }

  String _imageUrl(Map<String, dynamic> data) {
    return (data['imageUrl'] ?? '').toString();
  }

  String _textValue(
    Map<String, dynamic> data,
    String key, {
    String fallback = '-',
  }) {
    final value = (data[key] ?? '').toString().trim();
    return value.isNotEmpty ? value : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white, // Dasar putih
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          final docs = (snapshot.data?.docs ?? []).where((doc) {
            final reportOwnerId = (doc.data()['userId'] ?? '')
                .toString()
                .trim();
            return reportOwnerId.isNotEmpty && reportOwnerId != currentUserId;
          }).toList();

          return Column(
            children: [
              // HEADER BIRU (Tanpa AppBar agar desain lengkungnya pas)
              Container(
                padding: const EdgeInsets.only(
                  top: 50,
                  left: 10,
                  right: 20,
                  bottom: 20,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF0900FF),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(30), // Lengkungan khas Balang
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Notifikasi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // LIST NOTIFIKASI
              Expanded(
                child: docs.isEmpty
                    ? const Center(
                        child: Text('Belum ada notifikasi laporan baru.'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 15),
                        itemBuilder: (context, index) {
                          final data = docs[index].data();
                          final reportId = docs[index].id;
                          return _buildNotificationCard(
                            context,
                            reportId: reportId,
                            data: data,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context, {
    required String reportId,
    required Map<String, dynamic> data,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(
              reportId: reportId,
              title: _textValue(data, 'title', fallback: 'Tanpa Nama'),
              imageUrl: _imageUrl(data),
              status: _statusLabel(data),
              statusColor: _statusColor(data),
              description: _textValue(data, 'description'),
              date: _textValue(data, 'date'),
              time: _textValue(data, 'time'),
              location: _textValue(data, 'location'),
              reportUserId: _textValue(data, 'userId', fallback: ''),
              reporterName: _textValue(data, 'reporterName'),
              reporterWhatsApp: _textValue(data, 'reporterWhatsApp'),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _statusLabel(data),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  _textValue(data, 'date', fallback: '-'),
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatNotificationTitle(data),
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Lihat detail barang →',
              style: TextStyle(
                color: Color(0xFF0900FF),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
