import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'http_overrides.dart';
import 'home_screen.dart';
import 'firebase_messaging_handler.dart';

// Fungsi utama yang dijalankan saat aplikasi dimulai
Future<void> main() async {
  // Pastikan semua binding Flutter siap
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }

  // Setup Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Muat file .env untuk konfigurasi
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: File .env tidak ditemukan.");
  }

  // Izinkan sertifikat SSL (HANYA UNTUK DEVELOPMENT)
  HttpOverrides.global = MyHttpOverrides();

  // Setup FCM
  await setupFCM();

  // Inisialisasi format tanggal lokal dan jalankan aplikasi
  initializeDateFormatting('id_ID', null).then((_) {
    runApp(const MyApp());
  });
}

// Widget root dari aplikasi Anda
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HKBP Pondok Kopi',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Indonesia
        Locale('en', 'US'), // Inggris sebagai fallback
      ],
      locale: const Locale('id', 'ID'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue[900]!,
          brightness: Brightness.light,
          primary: Colors.blue[900]!,
        ),
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
    _navigateToHome();
  }

  // Fungsi ini tidak lagi mengecek login dan selalu ke HomeScreen
  Future<void> _navigateToHome() async {
    // Tampilkan splash screen selama 2 detik
    await Future.delayed(const Duration(seconds: 2));

    // Pastikan widget masih ada sebelum navigasi
    if (!mounted) return;

    // Selalu arahkan ke HomeScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.church,
                  size: 120,
                  color: Theme.of(context).colorScheme.primary,
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'HKBP Pondok Kopi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
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
