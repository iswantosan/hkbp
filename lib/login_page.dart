import 'package:flutter/material.dart';
import 'package:hkbp/profile_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'register_page.dart';
import 'config/api_config.dart';
import 'utils/error_handler.dart';
import 'services/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isObscure = true;
  bool _isLoading = false;

  final TextEditingController _useridController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    String userid = _useridController.text.trim();
    String pass = _passwordController.text;

    if (userid.isEmpty || pass.isEmpty) {
      _showError("User ID dan Password tidak boleh kosong");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get FCM token dengan retry
      String? fcmToken;
      try {
        // Coba ambil token dengan timeout
        fcmToken = await FirebaseMessaging.instance.getToken().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('FCM token timeout after 5 seconds');
            return null;
          },
        );
        
        debugPrint('=== FCM TOKEN DEBUG ===');
        debugPrint('FCM Token: ${fcmToken != null ? "${fcmToken.substring(0, 50)}..." : "null"}');
        debugPrint('FCM Token length: ${fcmToken?.length ?? 0}');
        debugPrint('FCM Token is null: ${fcmToken == null}');
        debugPrint('FCM Token is empty: ${fcmToken?.isEmpty ?? true}');
        debugPrint('======================');
        
        // Jika token null, coba sekali lagi
        if (fcmToken == null) {
          debugPrint('FCM token is null, retrying...');
          await Future.delayed(const Duration(milliseconds: 500));
          fcmToken = await FirebaseMessaging.instance.getToken().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('FCM token retry timeout');
              return null;
            },
          );
          debugPrint('FCM Token after retry: ${fcmToken != null ? "received" : "still null"}');
        }
      } catch (e, stackTrace) {
        debugPrint('=== FCM TOKEN ERROR ===');
        debugPrint('Error getting FCM token: $e');
        debugPrint('Stack trace: $stackTrace');
        debugPrint('======================');
        // Continue login even if FCM token fails
      }

      var url = Uri.parse("${ApiConfig.baseUrl}/login.php?api_key=${ApiConfig.apiKey}");
      
      // Prepare request body with FCM token
      Map<String, dynamic> requestBody = {
        "userid": userid,
        "pass": pass,
      };
      
      // Add FCM token if available
      if (fcmToken != null && fcmToken.isNotEmpty) {
        requestBody["fcm_token"] = fcmToken;
        debugPrint('FCM token added to request body');
      } else {
        debugPrint('WARNING: FCM token is null or empty, not sending to API');
      }
      
      debugPrint('Request body: ${jsonEncode(requestBody)}');
      
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 20));

      debugPrint('=== LOGIN RESPONSE ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('=====================');

      var data = jsonDecode(response.body);
      
      // Log FCM token update status jika ada
      if (data.containsKey('fcm_token_update')) {
        debugPrint('=== FCM TOKEN UPDATE STATUS ===');
        debugPrint('Status: ${data['fcm_token_update']['status']}');
        debugPrint('Message: ${data['fcm_token_update']['message']}');
        debugPrint('==============================');
      }

      if (response.statusCode == 200 && data['status'] == 'success') {
        final int userId = data['id_jemaat'];
        final String userFullName = data['nama_kepala_keluarga'];

        // Simpan sesi login untuk penggunaan di masa mendatang
        await AuthService.saveLoginData(userId, userFullName);

        if (!mounted) return;

        // Arahkan ke ProfilePage setelah login berhasil
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(userId: userId),
          ),
        );

      } else {
        _showError(data['message'] ?? 'Terjadi kesalahan yang tidak diketahui.');
      }
    } catch (e) {
      ErrorHandler.logError(e);
      _showError(ErrorHandler.getUserFriendlyMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  void dispose() {
    _useridController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [Colors.blue[900]!, Colors.blue[700]!],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    const Icon(Icons.church, size: 80, color: Colors.white),
                    const SizedBox(height: 10),
                    const Text(
                      "HKBP PONDOK KOPI",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 50),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          BorderRadius.vertical(top: Radius.circular(40)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Selamat Datang",
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            const Text("Silahkan masuk ke akun jemaat Anda",
                                style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 30),
                            TextField(
                              controller: _useridController,
                              decoration: InputDecoration(
                                hintText: "User ID",
                                prefixIcon: const Icon(Icons.person_outline),
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              controller: _passwordController,
                              obscureText: _isObscure,
                              decoration: InputDecoration(
                                hintText: "Password",
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_isObscure
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () =>
                                      setState(() => _isObscure = !_isObscure),
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 30),
                            // Tombol Masuk dan Batal
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[900],
                                      minimumSize: const Size(0, 55),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15)),
                                    ),
                                    onPressed: _handleLogin,
                                    child: const Text("MASUK",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 55),
                                      side: BorderSide(color: Colors.grey[300]!),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15)),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text("Batal",
                                        style: TextStyle(
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Link Daftar di bawah tombol
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const RegisterPage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Belum punya akun? Daftar di sini",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const Expanded(child: SizedBox()),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  "Versi 1.0.0",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
