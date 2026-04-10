import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> _loadUserProfile() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedWhatsApp = prefs.getString('profile_whatsapp_${user.uid}');

    final fallbackName = (user.email ?? '').split('@').first.isNotEmpty
        ? (user.email ?? '').split('@').first
        : 'User';

    final name = (user.displayName ?? '').trim().isNotEmpty
        ? user.displayName!.trim()
        : fallbackName;
    final email = user.email ?? '-';
    final whatsApp = (savedWhatsApp ?? user.phoneNumber ?? '').trim().isEmpty
        ? '-'
        : (savedWhatsApp ?? user.phoneNumber ?? '').trim();

    if (!mounted) {
      return;
    }

    setState(() {
      _nameController.text = name;
      _emailController.text = email;
      _whatsAppController.text = whatsApp;
      _initialName = name;
      _initialWhatsApp = whatsApp;
    });
  }

  Future<void> _saveProfile() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    final updatedName = _nameController.text.trim();
    final updatedWhatsApp = _whatsAppController.text.trim();

    if (updatedName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama tidak boleh kosong')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (updatedName != (user.displayName ?? '').trim()) {
        await user.updateDisplayName(updatedName);
        await user.reload();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'profile_whatsapp_${user.uid}',
        updatedWhatsApp.isEmpty ? '-' : updatedWhatsApp,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _initialName = updatedName;
        _initialWhatsApp = updatedWhatsApp.isEmpty ? '-' : updatedWhatsApp;
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
    } on FirebaseAuthException catch (e) {
      final message = e.message ?? 'Gagal memperbarui profil';
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _startEditing() {
    setState(() {
      _initialName = _nameController.text;
      _initialWhatsApp = _whatsAppController.text;
      isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _nameController.text = _initialName;
      _whatsAppController.text = _initialWhatsApp;
      isEditing = false;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) {
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Blue Header
            Container(
              width: double.infinity,
              height: 350,
              decoration: const BoxDecoration(
                color: Color(0xFF0900FF),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 80,
                      color: Color(0xFF0900FF),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _nameController.text.isEmpty
                        ? 'User'
                        : _nameController.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _emailController.text.isEmpty ? '-' : _emailController.text,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            // Information Card
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Informasi kontak',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (!isEditing)
                          TextButton.icon(
                            onPressed: _startEditing,
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Nama',
                      controller: _nameController,
                      enabled: isEditing,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      label: 'Email',
                      controller: _emailController,
                      enabled: false,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      label: 'Nomor Whatsapp',
                      controller: _whatsAppController,
                      enabled: isEditing,
                    ),
                    const SizedBox(height: 25),
                    if (isEditing)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Simpan',
                                      style: TextStyle(color: Colors.white),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSaving ? null : _cancelEditing,
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Batal'),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text(
                            'Keluar',
                            style: TextStyle(color: Colors.red),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.1),
                            elevation: 0,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          enabled: enabled,
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
