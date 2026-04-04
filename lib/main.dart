import 'package:flutter/material.dart';

// --- IMPORT SEMUA SCREEN ---
// Pastikan path ini sesuai dengan folder di proyek Balang kamu
import 'screens/splash/splash_page.dart'; 
import 'screens/auth/login_page.dart';
import 'screens/auth/register_page.dart';
import 'screens/home/home_page.dart';
import 'screens/history/history_page.dart';
import 'screens/profile/profile_page.dart';
// Pastikan kamu sudah membuat file notification_page.dart
import 'screens/home/notification_page.dart'; 

void main() {
  runApp(const BalangApp());
}

class BalangApp extends StatelessWidget {
  const BalangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Balang',
      theme: ThemeData(
        primaryColor: const Color(0xFF0900FF),
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      // Alur pertama dimulai dari Splash Screen
      home: const SplashPage(), 
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // Default ke halaman Beranda

  final List<Widget> _pages = [
    const HistoryPage(),
    const HomePage(),
    const ProfilePage(),
  ];

  // FUNGSI MENU TAMBAH (Sesuai Gambar "Menemukan" & "Kehilangan")
  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Pilih Kategori",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF0900FF),
                child: Icon(Icons.search, color: Colors.white),
              ),
              title: const Text('Menemukan Barang'),
              onTap: () {
                Navigator.pop(context);
                // Arahkan ke halaman form barang ditemukan di sini
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF0900FF),
                child: Icon(Icons.help_outline, color: Colors.white),
              ),
              title: const Text('Kehilangan Barang'),
              onTap: () {
                Navigator.pop(context);
                // Arahkan ke halaman form barang hilang di sini
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      
      // Tombol "+" yang memunculkan menu pilihan
      floatingActionButton: _currentIndex == 1 
        ? FloatingActionButton(
            backgroundColor: const Color(0xFF0900FF),
            shape: const CircleBorder(),
            onPressed: _showActionMenu, 
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ) 
        : null,

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: const Color(0xFF0900FF),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}