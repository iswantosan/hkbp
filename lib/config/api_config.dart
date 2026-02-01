import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Konfigurasi API untuk aplikasi HKBP
/// Menggunakan .env file untuk menyimpan API key secara aman
class ApiConfig {
  /// Mendapatkan API key dari environment variable
  /// Pastikan file .env sudah di-load di main.dart
  static String get apiKey {
    try {
      final key = dotenv.env['API_KEY'];
      if (key == null || key.isEmpty) {
        // Fallback ke hardcoded jika .env tidak ada (untuk development)
        debugPrint('Warning: API_KEY tidak ditemukan di .env, menggunakan fallback');
        return 'RAHASIA_HKBP_2024';
      }
      return key;
    } catch (e) {
      // Jika dotenv belum di-initialize, gunakan fallback
      debugPrint('Warning: dotenv belum di-initialize, menggunakan fallback API key');
      return 'RAHASIA_HKBP_2024';
    }
  }

  /// Base URL untuk API
  static const String baseUrl = 'https://hkbppondokkopi.org/api_hkbp';
  
  /// Base URL untuk development (jika diperlukan)
  static const String devBaseUrl = 'http://127.0.0.1/HKBP/api_hkbp';
}
