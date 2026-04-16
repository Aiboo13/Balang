import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetailPage extends StatefulWidget {
  final String reportId;
  final String title;
  final String imageUrl;
  final String status;
  final Color statusColor;
  final String description;
  final String date;
  final String time;
  final String location;
  final String reportUserId;
  final String reporterName;
  final String reporterWhatsApp;

  const DetailPage({
    super.key,
    required this.reportId,
    required this.title,
    required this.imageUrl,
    required this.status,
    required this.statusColor,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.reportUserId,
    required this.reporterName,
    required this.reporterWhatsApp,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool _isSubmittingClaim = false;
  bool _isSubmittingDecision = false;
  String _resolvedReporterName = '';
  String _resolvedReporterWhatsApp = '';

  @override
  void initState() {
    super.initState();
    _resolveReporterInfo();
  }

  String get _reporterNameDisplay {
    if (widget.reporterName.trim().isNotEmpty) {
      return widget.reporterName.trim();
    }
    if (_resolvedReporterName.trim().isNotEmpty) {
      return _resolvedReporterName.trim();
    }
    if (FirebaseAuth.instance.currentUser?.uid == widget.reportUserId) {
      final currentUserName =
          (FirebaseAuth.instance.currentUser?.displayName ?? '').trim();
      if (currentUserName.isNotEmpty) {
        return currentUserName;
      }
      final email = FirebaseAuth.instance.currentUser?.email ?? '';
      if (email.contains('@')) {
        return email.split('@').first;
      }
    }
    return '-';
  }

  String get _reporterWhatsAppDisplay {
    if (widget.reporterWhatsApp.trim().isNotEmpty) {
      return widget.reporterWhatsApp.trim();
    }
    if (_resolvedReporterWhatsApp.trim().isNotEmpty) {
      return _resolvedReporterWhatsApp.trim();
    }
    return '-';
  }

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  String _asString(
    Map<String, dynamic> data,
    String key, {
    String fallback = '',
  }) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  Future<Map<String, String>> _resolveClaimerInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {'name': '-', 'whatsApp': '-'};
    }

    String name = (user.displayName ?? '').trim();
    if (name.isEmpty) {
      final email = user.email ?? '';
      name = email.contains('@') ? email.split('@').first : 'User';
    }

    String whatsApp = '-';
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = userDoc.data();
      if (data != null) {
        final dbName = (data['name'] as String?)?.trim() ?? '';
        final dbWa = (data['whatsApp'] as String?)?.trim() ?? '';
        if (dbName.isNotEmpty) {
          name = dbName;
        }
        if (dbWa.isNotEmpty) {
          whatsApp = dbWa;
        }
      }
    } catch (_) {
      // Tetap gunakan fallback jika query user gagal.
    }

    return {'name': name, 'whatsApp': whatsApp};
  }

  Future<void> _submitClaimRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    setState(() => _isSubmittingClaim = true);
    try {
      final claimer = await _resolveClaimerInfo();
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.reportId)
          .update({
            'reportStatus': 'Pending',
            'claimStatus': 'Pending',
            'claimerId': user.uid,
            'claimerName': claimer['name'] ?? '-',
            'claimerWhatsApp': claimer['whatsApp'] ?? '-',
            'claimRequestedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permintaan klaim dikirim. Menunggu persetujuan pelapor.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim klaim: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSubmittingClaim = false);
      }
    }
  }

  Future<void> _decideClaim({required bool accepted}) async {
    setState(() => _isSubmittingDecision = true);
    try {
      final updateData = <String, dynamic>{
        'reportStatus': accepted ? 'Selesai' : 'Aktif',
        'claimStatus': accepted ? 'Accepted' : 'None',
        'claimRespondedAt': FieldValue.serverTimestamp(),
        'decidedBy': _currentUserId,
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
          .doc(widget.reportId)
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
        setState(() => _isSubmittingDecision = false);
      }
    }
  }

  String get _claimButtonText {
    final normalizedStatus = widget.status.trim().toLowerCase();
    if (normalizedStatus == 'hilang') {
      return 'Saya menemukanya';
    }
    return 'Klaim Barang ini';
  }

  bool get _isLostReport => widget.status.trim().toLowerCase() == 'hilang';

  String get _claimDialogDescription {
    if (_isLostReport) {
      return 'Apakah anda menemukan barang ini? Kontak pelapor akan ditampilkan agar anda bisa menghubunginya.';
    }
    return 'Apakah barang ini milik anda? Kontak pelapor akan ditampilkan saat dikonfirmasi';
  }

  String get _claimDialogActionText {
    if (_isLostReport) {
      return 'Ya, saya menemukan';
    }
    return 'Klaim';
  }

  String get _claimSnackBarText {
    if (_isLostReport) {
      return 'Kontak pelapor ditampilkan. Silakan hubungi pelapor untuk pengembalian barang.';
    }
    return 'Kontak pelapor ditampilkan. Silakan verifikasi barang dengan pelapor.';
  }

  Future<void> _resolveReporterInfo() async {
    if (widget.reporterName.trim().isNotEmpty &&
        widget.reporterWhatsApp.trim().isNotEmpty) {
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.reportUserId)
          .get();
      final data = snapshot.data();
      if (data == null || !mounted) {
        return;
      }

      setState(() {
        _resolvedReporterName = (data['name'] as String?)?.trim() ?? '';
        _resolvedReporterWhatsApp = (data['whatsApp'] as String?)?.trim() ?? '';
      });
    } catch (_) {
      // Fallback tetap pakai nilai dari widget jika query gagal.
    }
  }

  // Dialog 1: Pengguna mengirim permintaan klaim
  void _showClaimDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                Text(
                  _claimDialogDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmittingClaim
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await _submitClaimRequest();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0900FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _claimDialogActionText,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Dialog 2: Pelapor memutuskan accept/reject klaim
  void _showDecisionDialog(BuildContext context, {required bool accept}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                Text(
                  accept
                      ? 'Setujui klaim ini? Laporan akan dipindah ke status selesai.'
                      : 'Tolak klaim ini? Laporan akan kembali ke status aktif.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmittingDecision
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await _decideClaim(accepted: accept);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accept
                          ? const Color(0xFF0900FF)
                          : Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      accept ? 'Setujui' : 'Tolak',
                      style: const TextStyle(color: Colors.white),
                    ),
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
        title: const Text(
          'Kembali',
          style: TextStyle(color: Color(0xFF0900FF), fontSize: 16),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .doc(widget.reportId)
            .snapshots(),
        builder: (context, snapshot) {
          final reportData = snapshot.data?.data() ?? <String, dynamic>{};
          final reportOwnerId = _asString(
            reportData,
            'userId',
            fallback: widget.reportUserId,
          );
          final isOwner = _currentUserId == reportOwnerId;
          final reportStatus = _asString(
            reportData,
            'reportStatus',
            fallback: 'Aktif',
          );
          final claimStatus = _asString(
            reportData,
            'claimStatus',
            fallback: 'None',
          );
          final claimerId = _asString(reportData, 'claimerId');
          final claimerName = _asString(
            reportData,
            'claimerName',
            fallback: '-',
          );
          final claimerWhatsApp = _asString(
            reportData,
            'claimerWhatsApp',
            fallback: '-',
          );
          final isPendingClaim =
              claimStatus == 'Pending' ||
              (claimStatus == 'None' && reportStatus == 'Pending');
          final isClaimAccepted =
              claimStatus == 'Accepted' || reportStatus == 'Selesai';
          final isCurrentUserClaimer =
              claimerId.isNotEmpty && claimerId == _currentUserId;
          final showReporterContact =
              isCurrentUserClaimer && (isPendingClaim || isClaimAccepted);
          final showClaimerInfoForOwner =
              isOwner && (isPendingClaim || isClaimAccepted);

          return SingleChildScrollView(
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
                            child: const Icon(
                              Icons.image,
                              size: 60,
                              color: Colors.grey,
                            ),
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
                                  child: const Icon(
                                    Icons.image,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : Container(
                                width: double.infinity,
                                height: 250,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.image,
                                  size: 60,
                                  color: Colors.grey,
                                ),
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
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
                const Text(
                  'Deskripsi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.description,
                  style: const TextStyle(color: Colors.black87, height: 1.5),
                ),
                const SizedBox(height: 25),

                // Info Lokasi, Tanggal, Waktu
                _buildInfoRow(
                  Icons.location_on_outlined,
                  'Lokasi',
                  widget.location.isEmpty ? '-' : widget.location,
                ),
                const SizedBox(height: 15),
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  'Tanggal',
                  widget.date.isEmpty ? '-' : widget.date,
                ),
                const SizedBox(height: 15),
                _buildInfoRow(
                  Icons.access_time,
                  'Waktu',
                  widget.time.isEmpty ? '-' : widget.time,
                ),

                // Info Pelapor - ditampilkan kepada user yang sedang mengklaim
                if (showReporterContact) ...[
                  const SizedBox(height: 25),
                  const Divider(),
                  const SizedBox(height: 15),
                  Row(
                    children: const [
                      Icon(Icons.person_outline, color: Color(0xFF0900FF)),
                      SizedBox(width: 10),
                      Text(
                        'Dilaporkan Oleh',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _reporterNameDisplay,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        color: Color(0xFF0900FF),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _reporterWhatsAppDisplay,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],

                if (showClaimerInfoForOwner) ...[
                  const SizedBox(height: 25),
                  const Divider(),
                  const SizedBox(height: 15),
                  Row(
                    children: const [
                      Icon(
                        Icons.verified_user_outlined,
                        color: Color(0xFF0900FF),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Pengklaim / Penemu',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    claimerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        color: Color(0xFF0900FF),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        claimerWhatsApp,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 40),

                // Tombol bawah
                if (isOwner && isPendingClaim)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSubmittingDecision
                                ? null
                                : () => _showDecisionDialog(
                                    context,
                                    accept: true,
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0900FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Accept',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSubmittingDecision
                                ? null
                                : () => _showDecisionDialog(
                                    context,
                                    accept: false,
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Reject',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else if (isOwner)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isClaimAccepted
                          ? 'Laporan selesai dan klaim telah disetujui'
                          : 'Ini adalah laporan Anda',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  )
                else if (!isPendingClaim && !isClaimAccepted)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmittingClaim
                          ? null
                          : () => _showClaimDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0900FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _claimButtonText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isClaimAccepted
                          ? 'Klaim disetujui pelapor. Status laporan selesai.'
                          : isCurrentUserClaimer
                          ? 'Permintaan klaim Anda sedang menunggu persetujuan.'
                          : 'Laporan ini sedang diklaim pengguna lain.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
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
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              value,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
