import 'dart:async';
import 'dart:io'; // Untuk HttpOverrides
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Localizations
import 'package:google_fonts/google_fonts.dart'; // Google Fonts
import 'package:intl/date_symbol_data_local.dart'; // Untuk format tanggal lokal
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Untuk load .env file
import 'http_overrides.dart'; // Untuk mengatasi error sertifikat
import 'login_page.dart'; // Halaman login Anda
import 'home_screen.dart'; // Home screen
import 'services/auth_service.dart'; // Auth service untuk check login state


Future<void> main() async {
  // Pastikan semua binding Flutter siap sebelum menjalankan kode lain
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file untuk API key
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: File .env tidak ditemukan. Pastikan file .env sudah dibuat di root project.");
  }

  // Menerapkan override untuk mengizinkan sertifikat SSL (HANYA UNTUK DEVELOPMENT)
  HttpOverrides.global = MyHttpOverrides();

  // Menginisialisasi format tanggal untuk bahasa lokal (Indonesia)
  initializeDateFormatting('id_ID', null).then((_) {
    // Menjalankan aplikasi
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HKBP Pondok Kopi',
      // Menambahkan localizations untuk mendukung bahasa Indonesia
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Indonesia
        Locale('en', 'US'), // English (fallback)
      ],
      locale: const Locale('id', 'ID'),
      theme: ThemeData(
        // Tema modern menggunakan Material 3
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue, // Warna utama aplikasi
          brightness: Brightness.light,
        ),
        // Menggunakan Google Fonts - Inter sebagai font utama
        textTheme: GoogleFonts.interTextTheme(),
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      // Halaman awal aplikasi adalah SplashScreen
      home: const SplashScreen(),
    );
  }
}

// Widget untuk menampilkan layar pembuka (SplashScreen)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Check login state dan redirect setelah 2 detik
    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    // Tunggu 2 detik untuk splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Cek apakah user sudah login
    final loginData = await AuthService.getLoginData();
    
    if (loginData != null) {
      // Jika sudah login, langsung ke HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            userId: loginData['userId'] as int,
            userFullName: loginData['userFullName'] as String,
          ),
        ),
      );
    } else {
      // Jika belum login, ke LoginPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo aplikasi
            Image.asset(
              'assets/logo.png',
              width: 200,
              height: 200,
              // Fallback jika gambar gagal dimuat
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.church,
                  size: 150,
                  color: Theme.of(context).colorScheme.primary,
                );
              },
            ),
            const SizedBox(height: 30),
            // Nama aplikasi
            Text(
              'HKBP Pondok Kopi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            // Versi aplikasi
            Text(
              'Versi 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
