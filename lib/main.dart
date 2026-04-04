import 'package:flutter/material.dart';
// Pastikan folder 'screens' ada di dalam folder 'lib'
import 'screens/home/home_page.dart';
import 'screens/history/history_page.dart';
import 'screens/profile/profile_page.dart';

void main() {
  runApp(const BalangApp());
}

class BalangApp extends StatelessWidget {
  const BalangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Balang - Lost & Found',
      theme: ThemeData(
        primaryColor: const Color(0xFF0900FF),
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // Beranda sebagai halaman utama

  final List<Widget> _pages = [
    const HistoryPage(),
    const HomePage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      
      floatingActionButton: _currentIndex == 1 
        ? FloatingActionButton(
            backgroundColor: const Color(0xFF0900FF),
            shape: const CircleBorder(),
            onPressed: () {
              // Logika tambah barang
            },
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ) 
        : null,

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), 
              blurRadius: 10,
              offset: const Offset(0, -2),
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
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded), 
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), 
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), 
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}