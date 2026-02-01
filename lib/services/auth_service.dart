import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk mengelola session/login state
/// Simple implementation tanpa JWT
class AuthService {
  static const String _keyUserId = 'user_id';
  static const String _keyUserFullName = 'user_full_name';
  static const String _keyIsLoggedIn = 'is_logged_in';

  /// Menyimpan data login setelah user berhasil login
  static Future<void> saveLoginData(int userId, String userFullName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyUserFullName, userFullName);
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  /// Mendapatkan data user yang sudah login
  static Future<Map<String, dynamic>?> getLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    
    if (!isLoggedIn) {
      return null;
    }

    final userId = prefs.getInt(_keyUserId);
    final userFullName = prefs.getString(_keyUserFullName);

    if (userId == null || userFullName == null) {
      return null;
    }

    return {
      'userId': userId,
      'userFullName': userFullName,
    };
  }

  /// Cek apakah user sudah login
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Logout - hapus semua data login
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserFullName);
    await prefs.setBool(_keyIsLoggedIn, false);
  }
}

