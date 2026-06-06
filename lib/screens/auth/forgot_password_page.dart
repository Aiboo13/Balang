import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/gestures.dart'; // WAJIB ADA INI BUAT KLIK DI RICHTEXT

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  int _currentStep = 0;
  final TextEditingController _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final Color primaryColor = const Color(0xFF1B527E);

  bool _isLoading = false;

  void _nextStep() {
    setState(() {
      if (_currentStep < 3) {
        _currentStep++;
      }
    });
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.endsWith('@gmail.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan email gmail yang valid')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Generate 4 digit OTP
      final random = Random();
      final otp = (1000 + random.nextInt(9000)).toString();

      // Simpan ke Firestore untuk verifikasi nanti
      await FirebaseFirestore.instance
          .collection('password_resets')
          .doc(email)
          .set({
            'email': email,
            'code': otp,
            'createdAt': FieldValue.serverTimestamp(),
            'expiresAt': DateTime.now()
                .add(const Duration(minutes: 5))
                .millisecondsSinceEpoch,
          });

      // --- BAGIAN EMAILJS ---
      const serviceId = 'service_0vk20bb';
      const templateId = 'template_lqw064p';
      const publicKey = 'S7G31OmmctAtPmUOK';

      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'email': email,
            'passcode': otp,
            'to_name': email.split('@')[0],
          },
        }),
      );

      if (response.statusCode != 200) {
        throw 'Gagal mengirim email: ${response.body}';
      }

      print('OTP berhasil dikirim via EmailJS ke $email: $otp');
      
      // Biar kalau user klik "Kirim ulang", dia gak nambah step tapi tetep di halaman OTP
      if (_currentStep == 0) {
        _nextStep();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kode OTP baru telah dikirim ulang!')),
        );
      }
    } catch (e) {
      print('Error detail: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim kode: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final otpInput = _otpControllers.map((c) => c.text).join();

    if (otpInput.length < 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Masukkan 4 digit kode')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('password_resets')
          .doc(email)
          .get();

      if (!doc.exists) {
        throw 'Kode tidak ditemukan. Silakan kirim ulang.';
      }

      final data = doc.data()!;
      final serverOtp = data['code'];
      final expiresAt = data['expiresAt'] as int;

      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        throw 'Kode telah kadaluarsa. Silakan kirim ulang.';
      }

      if (otpInput != serverOtp) {
        throw 'Kode yang Anda masukkan salah.';
      }

      _nextStep();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final newPassword = _passwordController.text;
    final confirm = _confirmController.text;

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 6 karakter')),
      );
      return;
    }

    if (newPassword != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak cocok')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw 'Akun dengan email tersebut tidak ditemukan di database.';
      }

      final userDoc = querySnapshot.docs.first;
      final oldPassword = userDoc.data()['password'];
      if (oldPassword == null) {
        throw 'Data password lama tidak ditemukan di database.';
      }

      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: oldPassword,
      );

      await userCredential.user?.updatePassword(newPassword);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .update({
            'password': newPassword,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await FirebaseAuth.instance.signOut();

      await FirebaseFirestore.instance
          .collection('password_resets')
          .doc(email)
          .delete();

      _nextStep();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal reset password: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      } else {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -60,
            top: 70,
            child: Container(
              width: 180,
              height: 220,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(100),
                  bottomLeft: Radius.circular(100),
                ),
              ),
            ),
          ),

          Positioned(
            left: -30,
            top: MediaQuery.of(context).size.height - 130,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(100),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 35),
                      child: _buildStepContent(),
                    ),
                  ),
                ),
                _buildStepIndicator(),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildEmailStep();
      case 1:
        return _buildOtpStep();
      case 2:
        return _buildNewPasswordStep();
      case 3:
        return _buildSuccessStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmailStep() {
    return Column(
      children: [
        Text(
          'Lupa sandi?',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Masukkan email untuk\nmengatur ulang password",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A4A4A),
          ),
        ),
        const SizedBox(height: 50),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: const Text(
              'Masukkan Email',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
        _buildTextField(
          controller: _emailController,
          hintText: 'Email yang terdaftar',
        ),
        const SizedBox(height: 40),
        _isLoading
            ? const CircularProgressIndicator()
            : _buildButton(text: 'Kirim kode', onPressed: _sendOtp),
        const SizedBox(height: 25),
        GestureDetector(
          onTap: _previousStep,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, size: 18),
              SizedBox(width: 8),
              Text(
                'Kembali',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      children: [
        const Text(
          'Check your email',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Masukkan kode verifikasi yang\ntelah dikirim ke email Anda.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A4A4A),
          ),
        ),
        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) => _buildOtpBox(index)),
        ),
        const SizedBox(height: 40),
        _isLoading
            ? const CircularProgressIndicator()
            : _buildButton(text: 'Verifikasi', onPressed: _verifyOtp),
        const SizedBox(height: 25),
        // BAGIAN INI UDAH GUA FIX BIAR BISA DIKLIK COK
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 13),
            children: [
              const TextSpan(text: 'Tidak terkirim.? '),
              TextSpan(
                text: 'Kirim ulang',
                style: TextStyle(
                  color: _isLoading ? Colors.grey : primaryColor,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = _isLoading ? null : () => _sendOtp(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Column(
      children: [
        const Text(
          'Password baru',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Silakan buat password baru\nyang aman dan mudah diingat.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A4A4A),
          ),
        ),
        const SizedBox(height: 50),
        _buildPasswordField(
          hintText: 'Kata Sandi (Minimal 6 karakter)',
          controller: _passwordController,
          isVisible: _isPasswordVisible,
          maxLength: 20,
          onToggle: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        const SizedBox(height: 20),
        _buildPasswordField(
          hintText: 'Konfirmasi Kata Sandi',
          controller: _confirmController,
          isVisible: _isConfirmPasswordVisible,
          maxLength: 20,
          onToggle: () => setState(
            () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
          ),
        ),
        const SizedBox(height: 40),
        _isLoading
            ? const CircularProgressIndicator()
            : _buildButton(text: 'Reset Password', onPressed: _resetPassword),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      children: [
        const Text(
          'Password Berubah',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 40),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 60),
        ),
        const SizedBox(height: 50),
        const Text(
          'passwordmu sudah berubah!',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A4A4A),
          ),
        ),
        const SizedBox(height: 40),
        _buildButton(
          text: 'Login',
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black38, width: 1),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 3) {
            _otpFocusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.black38, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String hintText,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggle,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white,
        counterText: "",
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.black,
            size: 26,
          ),
          onPressed: onToggle,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.black54, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildButton({required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: index == _currentStep ? primaryColor : Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}