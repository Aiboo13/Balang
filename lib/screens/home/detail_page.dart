import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetailPage extends StatefulWidget {
  final String title;
  final String imageUrl;
  final String status;
  final Color statusColor;
  final String description;
  final String date;
  final String reportUserId;

  const DetailPage({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.status,
    required this.statusColor,
    required this.description,
    required this.date,
    required this.reportUserId,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  // Setelah klaim pertama dikonfirmasi, tampilkan info pelapor
  bool _isClaimed = false;

  // Dialog 1: Konfirmasi klaim barang
  void _showClaimDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Klaim Barang',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Apakah barang ini milik anda? Kontak pelapor akan ditampilkan saat dikonfirmasi',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Batal',
                        style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Tampilkan info pelapor
                      setState(() => _isClaimed = true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0900FF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Klaim',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Dialog 2: Konfirmasi sudah di tangan
  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Klaim Barang',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Apakah barang ini sudah berada di tangan anda? konfirmasi jika sudah',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Batal',
                        style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Logika selesai — bisa pop ke home atau tampilkan snackbar
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0900FF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Ya, Sudah',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0900FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Kembali',
            style: TextStyle(color: Color(0xFF0900FF), fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Barang
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: widget.imageUrl.toString().startsWith('http')
                  ? Image.network(
                      widget.imageUrl,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: double.infinity,
                        height: 250,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.image, size: 60, color: Colors.grey),
                      ),
                    )
                  : (widget.imageUrl.isNotEmpty
                      ? Image.memory(
                          base64Decode(widget.imageUrl),
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: double.infinity,
                            height: 250,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.image, size: 60, color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          height: 250,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.image, size: 60, color: Colors.grey),
                        )),
            ),
            const SizedBox(height: 20),

            // Judul & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.status,
                    style: TextStyle(
                      color: widget.statusColor == Colors.greenAccent
                          ? Colors.green[700]
                          : Colors.red[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Deskripsi
            const Text('Deskripsi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              widget.description,
              style: const TextStyle(color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 25),

            // Info Lokasi, Tanggal, Waktu
            _buildInfoRow(Icons.location_on_outlined, 'Lokasi', 'Lorong Bawah'),
            const SizedBox(height: 15),
            _buildInfoRow(Icons.calendar_today_outlined, 'Tanggal',
                'Senin, 9 Maret 2026'),
            const SizedBox(height: 15),
            _buildInfoRow(Icons.access_time, 'Waktu', '10.00 WIB'),

            // Info Pelapor — hanya muncul setelah klaim
            if (_isClaimed) ...[
              const SizedBox(height: 25),
              const Divider(),
              const SizedBox(height: 15),
              Row(
                children: const [
                  Icon(Icons.person_outline, color: Color(0xFF0900FF)),
                  SizedBox(width: 10),
                  Text('Dilaporkan Oleh',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Alfan',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Row(
                children: const [
                  Icon(Icons.phone_outlined,
                      color: Color(0xFF0900FF), size: 18),
                  SizedBox(width: 8),
                  Text('+62 865 1432 2561',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ],

            const SizedBox(height: 40),

            // Tombol bawah
            if (FirebaseAuth.instance.currentUser?.uid == widget.reportUserId)
              // Jika ini laporan miliknya sendiri
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Ini adalah laporan Anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              )
            else if (!_isClaimed)
              // Sebelum klaim: tombol "Klaim Barang ini"
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _showClaimDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0900FF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Klaim Barang ini',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
              )
            else
              // Setelah klaim: tombol Selesai & Batal
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _showConfirmDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0900FF),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Selesai',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _isClaimed = false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Batal',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0900FF), size: 22),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            Text(value,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}