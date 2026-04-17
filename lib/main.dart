import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Tambahin ini
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

// --- IMPORT SEMUA SCREEN ---
import 'screens/splash/splash_page.dart'; 
import 'screens/auth/login_page.dart';
import 'screens/auth/register_page.dart';
import 'screens/home/home_page.dart';
import 'screens/history/history_page.dart';
import 'screens/profile/profile_page.dart';
import 'screens/home/notification_page.dart'; 
import 'screens/home/add_report_page.dart';

// Fungsi buat nanganin notif pas app di background / mati
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Notif masuk pas lagi off: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inisialisasi Firebase Messaging
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Minta izin notif ke user
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  print('Izin diberikan: ${settings.authorizationStatus}');

  // Set handler buat background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Ambil token buat ngetes (liat di Debug Console)
  String? token = await messaging.getToken();
  print("TOKEN HP LO (Pake buat ngetes di Firebase Console): $token");

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
      home: const SplashPage(), 
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateActivityTime();

    // Dengerin notif pas aplikasi lagi kebuka (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Dapet notif pas app kebuka: ${message.notification?.title}');
      // Di sini lo bisa tambahin snackbar atau popup kalau mau
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _updateActivityTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_active_time', DateTime.now().millisecondsSinceEpoch);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      await _updateActivityTime();
    } else if (state == AppLifecycleState.resumed) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? lastActive = prefs.getInt('last_active_time');
      int now = DateTime.now().millisecondsSinceEpoch;
      
      const int timeout = 10 * 60 * 1000; 
      
      if (lastActive != null && (now - lastActive) > timeout) {
        await FirebaseAuth.instance.signOut();
        await prefs.remove('last_active_time');
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      } else {
        await _updateActivityTime();
      }
    }
  }

  final List<Widget> _pages = [
    const HistoryPage(),
    const HomePage(),
    const ProfilePage(),
  ];

  void _showActionMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddReportPage()),
    );
  }

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