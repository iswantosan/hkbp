import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';

class SetupPasswordPage extends StatefulWidget {
  final int idJemaat;
  final String namaKepalaKeluarga;

  const SetupPasswordPage({
    super.key,
    required this.idJemaat,
    required this.namaKepalaKeluarga,
  });

  @override
  State<SetupPasswordPage> createState() => _SetupPasswordPageState();
}

class _SetupPasswordPageState extends State<SetupPasswordPage> {
  final TextEditingController _useridController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isObscurePassword = true;
  bool _isObscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _useridController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSetupPassword() async {
    String userid = _useridController.text.trim();
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (userid.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError("User ID, Password, dan Konfirmasi Password harus diisi");
      return;
    }

    if (password.length < 6) {
      _showError("Password minimal 6 karakter");
      return;
    }

    if (password != confirmPassword) {
      _showError("Password dan Konfirmasi Password tidak sama");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse("https://hkbppondokkopi.org/api_hkbp/register_user.php?api_key=RAHASIA_HKBP_2024");
      // final url = Uri.parse("http://127.0.0.1/HKBP/api_hkbp/register_user.php?api_key=RAHASIA_HKBP_2024");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'id': widget.idJemaat,
          'userid': userid,
          'pass': password,
        }),
      ).timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201 && data['status'] == 'success') {
        // Jika berhasil, tampilkan dialog sukses dan kembali ke login
        _showSuccessDialog();
      } else {
        _showError(data['message'] ?? 'Terjadi kesalahan. Silahkan coba lagi.');
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        _showError("Terjadi kesalahan koneksi ke server. Periksa internet Anda.");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Berhasil!"),
        content: const Text("Pendaftaran berhasil. Silahkan login dengan User ID dan Password yang telah Anda buat."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Tutup dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
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
                    const Icon(Icons.lock_outline, size: 80, color: Colors.white),
                    const SizedBox(height: 10),
                    const Text(
                      "SETUP PASSWORD",
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
                            const Text(
                              "Buat Akun",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Selamat datang, ${widget.namaKepalaKeluarga}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 30),

                            // Input User ID
                            TextField(
                              controller: _useridController,
                              decoration: InputDecoration(
                                hintText: "User ID",
                                prefixIcon: const Icon(Icons.person_outline),
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),

                            // Input Password
                            TextField(
                              controller: _passwordController,
                              obscureText: _isObscurePassword,
                              decoration: InputDecoration(
                                hintText: "Password (minimal 6 karakter)",
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_isObscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () => setState(() =>
                                      _isObscurePassword = !_isObscurePassword),
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),

                            // Input Konfirmasi Password
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: _isObscureConfirm,
                              decoration: InputDecoration(
                                hintText: "Konfirmasi Password",
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_isObscureConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () => setState(() =>
                                      _isObscureConfirm = !_isObscureConfirm),
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Tombol Simpan
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[900],
                                minimumSize: const Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              onPressed: _handleSetupPassword,
                              child: const Text(
                                "SIMPAN",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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





