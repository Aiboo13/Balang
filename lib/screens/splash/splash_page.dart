import 'dart:async';
import 'package:flutter/material.dart';
import '../auth/login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    // Delay 5 detik lalu pindah ke Login
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background biru
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0900FF), Color(0xFF211D9B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Shape putih atas kanan
          Positioned(
            top: 0,
            right: 0,
            child: ClipPath(
              clipper: TopClipper(),
              child: Container(
                width: 150,
                height: 150,
                color: Colors.grey[200],
              ),
            ),
          ),

          // Shape putih bawah kiri
          Positioned(
            bottom: 0,
            left: 0,
            child: ClipPath(
              clipper: BottomClipper(),
              child: Container(
                width: 150,
                height: 150,
                color: Colors.grey[200],
              ),
            ),
          ),

          // Content tengah
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ganti dengan logo kamu
                Image.asset(
                  'assets/logo.png', // <-- pastikan ada
                  width: 120,
                ),
                const SizedBox(height: 20),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    "Find what you've lost, return what you found.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 14),
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
