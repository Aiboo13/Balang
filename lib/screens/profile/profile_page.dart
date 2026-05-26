import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _whatsAppController = TextEditingController();

  String _initialName = '';
  String _initialEmail = '';
  String _initialWhatsApp = '';

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _whatsAppController.dispose();
    super.dispose();
  }

  // Mengambil data profil pengguna dari Firestore berdasarkan Email
  Future<void> _loadUserProfile() async {
    final user = _currentUser;
    if (user == null) return;

    String name = user.displayName ?? '';
    String email = user.email ?? '-';
    String whatsApp = '-';

    try {
      // Mengambil dokumen pengguna menggunakan email sebagai ID Dokumen
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(email) 
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        whatsApp = data['whatsApp'] ?? '-';
        name = data['name'] ?? (email.split('@').first);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }

    if (!mounted) return;

    setState(() {
      _nameController.text = name;
      _emailController.text = email;
      _whatsAppController.text = whatsApp;
      _initialName = name;
      _initialEmail = email;
      _initialWhatsApp = whatsApp;
    });
  }

// Menyimpan perubahan profil ke database Firestore dengan validasi nomor unik
  Future<void> _saveProfile() async {
    final user = _currentUser;
    if (user == null) return;

    final updatedName = _nameController.text.trim();
    final updatedWhatsApp = _whatsAppController.text.trim();
    final email = user.email ?? '';

    // 1. Validasi input kosong
    if (updatedName.isEmpty || updatedWhatsApp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Field tidak boleh kosong')));
      return;
    }

    // 2. Validasi format panjang nomor WhatsApp dasar
    if (!RegExp(r'^[0-9]{7,15}$').hasMatch(updatedWhatsApp)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nomor WhatsApp tidak valid (7-15 digit)')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 3. CEK DUPLIKAT: Hanya cek ke database jika nomor WhatsApp diubah dari nomor awal
      if (updatedWhatsApp != _initialWhatsApp) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('whatsApp', isEqualTo: updatedWhatsApp)
            .get();

        // Jika ditemukan dokumen lain dengan nomor yang sama
        if (querySnapshot.docs.isNotEmpty) {
          setState(() => _isSaving = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nomor WhatsApp sudah digunakan oleh akun lain!'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // 4. Proses simpan data jika lolos validasi duplikat
      await FirebaseFirestore.instance.collection('users').doc(email).set({
        'name': updatedName,
        'whatsApp': updatedWhatsApp,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (updatedName != user.displayName) {
        await user.updateDisplayName(updatedName);
      }

      setState(() {
        _initialName = updatedName;
        _initialWhatsApp = updatedWhatsApp;
        isEditing = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _startEditing() {
    setState(() => isEditing = true);
  }

  void _cancelEditing() {
    setState(() {
      _nameController.text = _initialName;
      _whatsAppController.text = _initialWhatsApp;
      isEditing = false;
    });
  }

  // Fungsi untuk menangani proses logout pengguna
  Future<void> _logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Keluar', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF104A7C), fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?', textAlign: TextAlign.center),
        actions: [
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF104A7C)), child: const Text('Keluar', style: TextStyle(color: Colors.white)))),
            ],
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Bagian Header Profil
            Container(
              width: double.infinity, height: 350,
              decoration: const BoxDecoration(
                color: Color(0xFF104A7C),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  const CircleAvatar(radius: 60, backgroundColor: Colors.white, child: Icon(Icons.person, size: 80, color: Color(0xFF104A7C))),
                  const SizedBox(height: 15),
                  Text(_nameController.text.isEmpty ? 'User' : _nameController.text, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(_emailController.text, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            // Bagian Form Informasi Kontak
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Informasi kontak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (!isEditing) TextButton.icon(onPressed: _startEditing, icon: const Icon(Icons.edit, size: 16), label: const Text('Edit')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(label: 'Nama', controller: _nameController, enabled: isEditing),
                    const SizedBox(height: 15),
                    _buildTextField(label: 'Email', controller: _emailController, enabled: false), 
                    const SizedBox(height: 15),
                    //jadikan supaya tidak bisa duplikat nomor whatsapp
                    _buildTextField(
  label: 'Nomor WhatsApp',
  controller: _whatsAppController,
  enabled: isEditing,
  keyboardType: TextInputType.number,
  maxLength: 15,
  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
),
const SizedBox(height: 25),
                    if (isEditing)
                      Row(
                        children: [
                          Expanded(child: ElevatedButton(onPressed: _isSaving ? null : _saveProfile, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan', style: TextStyle(color: Colors.white)))),
                          const SizedBox(width: 10),
                          Expanded(child: OutlinedButton(onPressed: _cancelEditing, child: const Text('Batal'))),
                        ],
                      )
                    else
                      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _logout, icon: const Icon(Icons.logout, color: Colors.red), label: const Text('Keluar', style: TextStyle(color: Colors.red)), style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1), elevation: 0))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk membuat field teks
  // Helper widget untuk membuat field teks (Sudah mendukung pembatasan input)
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            counterText: "", // Menyembunyikan angka counter text di pojok kanan
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
    }
}