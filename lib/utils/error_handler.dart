// Import untuk debugPrint
import 'package:flutter/foundation.dart';

/// Utility class untuk menangani error dengan pesan yang user-friendly
/// Menyembunyikan detail teknis dan API key dari user
class ErrorHandler {
  /// Mengkonversi error teknis menjadi pesan yang mudah dipahami user
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Sembunyikan API key dari error message
    String cleanError = errorString.replaceAll(RegExp(r'api_key=[^\s&]+', caseSensitive: false), 'api_key=***');
    cleanError = cleanError.replaceAll(RegExp(r'rahasia_hkbp[^\s&]+', caseSensitive: false), '***');
    
    // Network errors
    if (errorString.contains('socketexception') || 
        errorString.contains('failed host lookup') ||
        errorString.contains('no address associated with hostname') ||
        errorString.contains('network is unreachable')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }
    
    if (errorString.contains('connection timeout') || 
        errorString.contains('timeout') ||
        errorString.contains('timed out')) {
      return 'Koneksi ke server terlalu lama. Silakan coba lagi.';
    }
    
    if (errorString.contains('connection refused') ||
        errorString.contains('connection reset')) {
      return 'Server tidak dapat dijangkau. Silakan coba beberapa saat lagi.';
    }
    
    // HTTP errors
    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Data yang diminta tidak ditemukan.';
    }
    
    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'Akses ditolak. Silakan hubungi administrator.';
    }
    
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Sesi Anda telah berakhir. Silakan login kembali.';
    }
    
    if (errorString.contains('500') || errorString.contains('internal server error')) {
      return 'Terjadi kesalahan pada server. Silakan coba lagi nanti.';
    }
    
    if (errorString.contains('400') || errorString.contains('bad request')) {
      return 'Permintaan tidak valid. Silakan coba lagi.';
    }
    
    // SSL/Certificate errors
    if (errorString.contains('certificate') || 
        errorString.contains('ssl') ||
        errorString.contains('handshake')) {
      return 'Masalah keamanan koneksi. Silakan hubungi administrator.';
    }
    
    // Format/Parse errors
    if (errorString.contains('format') || 
        errorString.contains('parse') ||
        errorString.contains('json')) {
      return 'Data yang diterima tidak valid. Silakan coba lagi.';
    }
    
    // Generic error
    return 'Terjadi kesalahan. Silakan coba lagi atau hubungi administrator jika masalah berlanjut.';
  }
  
  /// Log error detail untuk debugging (hanya di development)
  static void logError(dynamic error, [StackTrace? stackTrace]) {
    // Hanya log di debug mode, jangan tampilkan ke user
    debugPrint('Error: $error');
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
  }
}

