import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_page.dart'; 
import '../../main.dart'; 

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() async {
    // Tunggu animasi splash misalnya 2 detik
    await Future.delayed(const Duration(seconds: 2));
    
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? lastActive = prefs.getInt('last_active_time');
      int now = DateTime.now().millisecondsSinceEpoch;
      
      const int timeout = 10 * 60 * 1000; // 10 menit = waktu tunggu

      if (lastActive != null && (now - lastActive) > timeout) {
        // Sesi habis, perlu login ulang karena tidak aktif melebihi batas waktu
        await FirebaseAuth.instance.signOut();
        await prefs.remove('last_active_time');
        _navigateToLogin();
      } else {
        // Sesi masih aman dan belum kedaluwarsa, update timer lalu pergi ke layar utama (tanpa login ulang)
        await prefs.setInt('last_active_time', now);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      }
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background putih
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
          ),

          // Shape biru atas kanan
          Positioned(
            top: 0,
            right: 0,
            child: ClipPath(
              clipper: TopClipper(),
              child: Container(
                width: 150,
                height: 150,
                color: const Color(0xFF104A7C),
              ),
            ),
          ),

          // Shape biru bawah kiri
          Positioned(
            bottom: 0,
            left: 0,
            child: ClipPath(
              clipper: BottomClipper(),
              child: Container(
                width: 150,
                height: 150,
                color: const Color(0xFF104A7C),
              ),
            ),
          ),

          // Content tengah
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo (Tetap sesuai asset kamu)
                Image.asset(
                  'assets/logo.png', 
                  width: 180,
                  // Jika logo belum muncul, pastikan sudah daftar di pubspec.yaml
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 20),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    "Temukan apa yang hilang, kembalikan apa yang Anda temukan.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF104A7C), fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Clipper tetap sama seperti kode awalmu
class TopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(0, 0);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, 0);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}