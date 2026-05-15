import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _errorMessage;

  final Color primaryColor = const Color(0xFF1B527E);

  void _register() async {
    final email = _emailController.text.trim();
    final whatsapp = _whatsappController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    setState(() => _errorMessage = null);

    // Validasi input form
    if (email.isEmpty || whatsapp.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'Semua field wajib diisi');
      return;
    }

    if (password != confirm) {
      setState(() => _errorMessage = 'Konfirmasi password tidak sesuai');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Proses pembuatan akun di Firebase Authentication
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Menyimpan data pengguna tambahan ke Cloud Firestore
      await FirebaseFirestore.instance.collection('users').doc(email).set({
        'uid': credential.user!.uid,
        'email': email,
        'whatsApp': whatsapp,
        'password': password,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseAuth.instance.signOut();

      if (mounted) {
        _showSuccessDialog();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Menampilkan dialog sukses registrasi dengan desain kustom
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, color: primaryColor, size: 70),
              const SizedBox(height: 20),
              Text(
                'Registrasi Berhasil',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Akun Anda telah berhasil dibuat.\nSilakan masuk untuk melanjutkan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF4A4A4A), height: 1.5),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Dekorasi UI bagian atas
          Positioned(
            right: -60, top: 70,
            child: Container(
              width: 180, height: 220,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(100), bottomLeft: Radius.circular(100)),
              ),
            ),
          ),
          // Dekorasi UI bagian bawah
          Positioned(
            left: -30, bottom: -30,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(topRight: Radius.circular(100)),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: Column(
                  children: [
                    Text('DAFTAR', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    const Text("Mulai cari barangmu di\nsini", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A))),
                    const SizedBox(height: 50),
                    _buildInputField(hint: 'Masukkan email yang terdaftar (wajib)', controller: _emailController, isPass: false),
                    const SizedBox(height: 18),
                    _buildInputField(hint: 'No. WhatsApp', controller: _whatsappController, isPass: false, keyboard: TextInputType.number),
                    const SizedBox(height: 18),
                    _buildInputField(hint: 'Kata Sandi', controller: _passwordController, isPass: true, visible: _isPasswordVisible, onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible)),
                    const SizedBox(height: 18),
                    _buildInputField(hint: 'Konfirmasi Kata Sandi', controller: _confirmController, isPass: true, visible: _isConfirmPasswordVisible, onToggle: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible)),
                    const SizedBox(height: 30),
                    if (_errorMessage != null) Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity, height: 58,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                        onPressed: _isLoading ? null : _register,
                        child: _isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Text('DAFTAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 25),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(text: TextSpan(style: const TextStyle(color: Colors.black87, fontSize: 14), children: [const TextSpan(text: 'Sudah punya akun? '), TextSpan(text: 'Masuk Sekarang', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))])),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget kustom untuk input field
  Widget _buildInputField({required String hint, required TextEditingController controller, required bool isPass, bool? visible, VoidCallback? onToggle, TextInputType? keyboard}) {
    return TextField(
      controller: controller,
      obscureText: isPass ? !(visible ?? false) : false,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal, fontSize: 14),
        filled: true, fillColor: Colors.white,
        suffixIcon: isPass ? IconButton(icon: Icon((visible ?? false) ? Icons.visibility : Icons.visibility_off, color: Colors.black), onPressed: onToggle) : null,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Colors.black54, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: primaryColor, width: 1.5)),
      ),
    );
  }
}