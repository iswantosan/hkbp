import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'setup_password_page.dart';
import 'config/api_config.dart';
import 'utils/error_handler.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isLoading = false;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _phoneController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 30)), // 30 tahun lalu
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[900]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _handleRegister() async {
    String phone = _phoneController.text.trim();
    String date = _dateController.text.trim();

    if (phone.isEmpty || date.isEmpty) {
      _showError("Nomor telepon dan tanggal lahir harus diisi");
      return;
    }

    // Validasi format nomor telepon (minimal 10 digit)
    if (phone.length < 10) {
      _showError("Nomor telepon minimal 10 digit");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/validate_user.php?api_key=${ApiConfig.apiKey}");
      // final url = Uri.parse("${ApiConfig.devBaseUrl}/validate_user.php?api_key=${ApiConfig.apiKey}");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'nomor_telepon': phone,
          'tanggal_lahir': date,
        }),
      ).timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data['status'] == 'success') {
        // Jika berhasil, lanjut ke halaman setup password
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SetupPasswordPage(
              idJemaat: data['id'],
              namaKepalaKeluarga: data['nama_kepala_keluarga'] ?? '',
            ),
          ),
        );
      } else if (response.statusCode == 409) {
        // Jika sudah terdaftar
        _showError("Data sudah ada, tlg login");
      } else {
        // Error lainnya
        _showError(data['message'] ?? 'Terjadi kesalahan. Silahkan coba lagi.');
      }
    } catch (e) {
      ErrorHandler.logError(e);
      if (mounted) {
        _showError(ErrorHandler.getUserFriendlyMessage(e));
      }
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
                    const Icon(Icons.person_add, size: 80, color: Colors.white),
                    const SizedBox(height: 10),
                    const Text(
                      "REGISTRASI",
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
                              "Daftar Akun",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              "Masukkan nomor telepon dan tanggal lahir kepala keluarga",
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 30),

                            // Input Nomor Telepon
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: "Nomor Telepon",
                                prefixIcon: const Icon(Icons.phone_outlined),
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),

                            // Input Tanggal Lahir dengan DatePicker
                            TextField(
                              controller: _dateController,
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: "Tanggal Lahir Kepala Keluarga",
                                prefixIcon: const Icon(Icons.calendar_today_outlined),
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onTap: () => _selectDate(context),
                            ),
                            const SizedBox(height: 30),

                            // Tombol Daftar
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[900],
                                minimumSize: const Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              onPressed: _handleRegister,
                              child: const Text(
                                "DAFTAR",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),

                            // Tombol Kembali ke Login
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text(
                                "Kembali ke Login",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
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

