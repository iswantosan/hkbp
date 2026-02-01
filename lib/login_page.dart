import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import library http
import 'dart:convert'; // Untuk jsonEncode dan jsonDecode
import 'home_screen.dart';
import 'register_page.dart';
import 'config/api_config.dart';
import 'utils/error_handler.dart';
import 'services/auth_service.dart'; // Auth service untuk save login data


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isObscure = true;
  bool _isLoading = false; // Indikator loading

  // PERBAIKAN: Mengganti nama controller agar lebih sesuai
  final TextEditingController _useridController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Fungsi Login ke Database via API PHP
  Future<void> _handleLogin() async {
    // PERBAIKAN: Menggunakan controller yang benar
    String userid = _useridController.text.trim();
    String pass = _passwordController.text;

    if (userid.isEmpty || pass.isEmpty) {
      _showError("User ID dan Password tidak boleh kosong");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
     var url = Uri.parse("${ApiConfig.baseUrl}/login.php?api_key=${ApiConfig.apiKey}");
     // var url = Uri.parse("${ApiConfig.devBaseUrl}/login.php?api_key=${ApiConfig.apiKey}");

      // --- PERBAIKAN UTAMA: Mengirim data sebagai JSON ---
      var response = await http.post(
        url,
        headers: {
          // Memberitahu server bahwa kita mengirim data JSON
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          // Menggunakan key yang diharapkan oleh login.php
          "userid": userid,
          "pass": pass,
        }),
      ).timeout(const Duration(seconds: 20)); // Tambahkan timeout untuk koneksi lambat

      // Selalu decode body untuk mendapatkan pesan, bahkan saat gagal
      var data = jsonDecode(response.body);

      // --- PERBAIKAN LOGIKA: Menangani respons baru dari API ---
      if (response.statusCode == 200 && data['status'] == 'success') {
        // Jika Benar, ambil data user dan pindah ke HomeScreen
        final int userId = data['id_jemaat'];
        final String userFullName = data['nama_kepala_keluarga'];

        // Simpan data login untuk auto-login di next session
        await AuthService.saveLoginData(userId, userFullName);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            // --- PERBAIKAN NAVIGASI: Teruskan data yang didapat ke HomeScreen ---
            builder: (context) => HomeScreen(
              userId: userId,
              userFullName: userFullName,
            ),
          ),
        );
      } else {
        // Jika Gagal, tampilkan pesan error dari API
        _showError(data['message'] ?? 'Terjadi kesalahan yang tidak diketahui.');
      }
    } catch (e) {
      // Menangkap error koneksi (timeout, no internet, DNS, SSL, dll)
      ErrorHandler.logError(e);
      _showError(ErrorHandler.getUserFriendlyMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    // Selalu dispose controller untuk mencegah memory leak
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

                            // Input User ID
                            TextField(
                              // PERBAIKAN: Menggunakan controller yang benar
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

                            // Input Password
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

                            // Tombol Masuk
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[900],
                                minimumSize: const Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                              ),
                              onPressed: _handleLogin,
                              child: const Text("MASUK",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            
                            // Spacer untuk mendorong konten ke bawah
                            const Expanded(child: SizedBox()),
                            
                            // Link Daftar dan Versi Aplikasi di kanan bawah
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Versi aplikasi di kiri
                                const Text(
                                  "Versi 1.0.0",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                // Link Daftar di kanan
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const RegisterPage(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Daftar",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
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
