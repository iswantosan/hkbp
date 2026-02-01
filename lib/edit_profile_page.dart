import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late Map<String, TextEditingController> _controllers;

  // --- STATE UNTUK NILAI DROPDOWN ---
  final Map<String, String?> _dropdownValues = {};
  final List<String> _statusOptions = ["Menikah", "Belum Menikah", "Janda/Duda", "Almarhum"];
  final List<String> _wilayahOptions = ["Wijk 1", "Wijk 2", "Wijk 3", "Wijk 4", "Wijk 5", "Wijk 6"];

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (var key in widget.userData.keys)
        key: TextEditingController(text: widget.userData[key]?.toString() ?? '')
    };

    // Inisialisasi semua nilai awal untuk dropdown
    _dropdownValues['status_pernikahan_kepala_rumah_tangga'] = _getInitialDropdownValue(widget.userData['status_pernikahan_kepala_rumah_tangga'], _statusOptions);
    _dropdownValues['stspasangan'] = _getInitialDropdownValue(widget.userData['stspasangan'], _statusOptions);
    _dropdownValues['wilayah'] = _getInitialDropdownValue(widget.userData['wilayah'], _wilayahOptions);

    // --- PERBAIKAN: Inisialisasi nilai awal untuk dropdown status anak ---
    for (int i = 1; i <= 5; i++) {
      String suffix = _getSuffix(i);
      String key = 'status_pernikahan_anak_$suffix';
      _dropdownValues[key] = _getInitialDropdownValue(widget.userData[key], _statusOptions);
    }
  }

  // Fungsi helper untuk mendapatkan suffix nama ('pertama', 'kedua', dst.)
  String _getSuffix(int index) {
    switch (index) {
      case 1: return 'pertama';
      case 2: return 'kedua';
      case 3: return 'ketiga';
      case 4: return 'keempat';
      case 5: return 'kelima';
      default: return '';
    }
  }

  // Fungsi helper untuk memastikan nilai awal ada di dalam daftar options, jika tidak, kembalikan null
  String? _getInitialDropdownValue(String? value, List<String> options) {
    if (value != null && options.contains(value)) {
      return value;
    }
    return null;
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, String fieldKey) async {
    DateTime initialDate;
    try {
      initialDate = DateTime.parse(_controllers[fieldKey]!.text);
    } catch (_) {
      initialDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        _controllers[fieldKey]!.text = formattedDate;
      });
    }
  }

  bool _isDateField(String key) {
    return key.toLowerCase().contains('tanggal');
  }

  // --- LOGIKA DIPERLUAS: Deteksi semua field yang menggunakan dropdown, termasuk status anak ---
  bool _isDropdownField(String key) {
    return key == 'status_pernikahan_kepala_rumah_tangga' ||
        key == 'stspasangan' ||
        key == 'wilayah' ||
        key.startsWith('status_pernikahan_anak_');
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> updatedData = {
        'id': int.tryParse(widget.userData['id']?.toString() ?? '0') ?? 0,
      };

      _controllers.forEach((key, controller) {
        if (key != 'id') {
          // Ambil nilai dari dropdown jika itu field dropdown, jika tidak, ambil dari controller teks
          if (_isDropdownField(key)) {
            updatedData[key] = _dropdownValues[key];
          } else {
            updatedData[key] = controller.text;
          }
        }
      });

      final uri = Uri.parse("https://hkbppondokkopi.org/api_hkbp/update_user_profile.php?api_key=RAHASIA_HKBP_2024");

      final response = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(updatedData),
      )
          .timeout(const Duration(seconds: 20));

      print("Update Status: ${response.statusCode}");
      print("Update Body: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data berhasil diperbarui'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception(result['message'] ?? 'Gagal menyimpan data dari server.');
        }
      } else {
        throw Exception('Gagal terhubung ke server. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> editableFields = [
      'nama_kepala_keluarga', 'nomor_telepon_kepala_rumah_tangga', 'tanggal_lahir_kepala_keluarga', 'tanggal_sidi_kepala_keluarga', 'tanggal_baptis_kepala_keluarga', 'emailkk', 'status_pernikahan_kepala_rumah_tangga',
      'alamat', 'wilayah',
      'nama_istri', 'tanggal_lahir_istri', 'tanggal_baptis_istri', 'tanggal_sidi_istri', 'nomor_telepon_istri', 'stspasangan', 'emailpasangan',
      'nama_anak_pertama','tanggal_lahir_anak_pertama','status_pernikahan_anak_pertama',
      'nama_anak_kedua', 'tanggal_lahir_anak_kedua','status_pernikahan_anak_kedua',
      'nama_anak_ketiga' ,'tanggal_lahir_anak_ketiga' ,'status_pernikahan_anak_ketiga',
      'nama_anak_keempat','tanggal_lahir_anak_keempat','status_pernikahan_anak_keempat',
      'nama_anak_kelima','tanggal_lahir_anak_kelima','status_pernikahan_anak_kelima',
      'nama_tanggungan_pertama', 'nama_tanggungan_kedua', 'nama_tanggungan_ketiga',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(15, 60, 25, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue[900]!, Colors.blue[700]!],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.only(left: 15.0),
                    child: Text(
                      "Edit Profil Jemaat",
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15.0, top: 5),
                    child: Text(
                      "Perbarui data untuk keluarga ${widget.userData['nama_kepala_keluarga']}",
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    ...editableFields.map((key) {
                      bool isDate = _isDateField(key);
                      bool isDropdown = _isDropdownField(key);

                      if (isDropdown) {
                        List<String> options;
                        if (key == 'wilayah') {
                          options = _wilayahOptions;
                        } else {
                          options = _statusOptions;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: DropdownButtonFormField<String>(
                            value: _dropdownValues[key],
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: _getLabelText(key),
                              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            items: options.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _dropdownValues[key] = newValue;
                              });
                            },
                            validator: (value) {
                              if (_isRequired(key) && value == null) {
                                return 'Field ini tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: TextFormField(
                            controller: _controllers[key],
                            readOnly: isDate,
                            decoration: InputDecoration(
                              labelText: _getLabelText(key),
                              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              suffixIcon: isDate ? const Icon(Icons.calendar_month) : null,
                            ),
                            onTap: isDate ? () => _selectDate(context, key) : null,
                            validator: (value) {
                              if (_isRequired(key) && (value == null || value.isEmpty)) {
                                return 'Field ini tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                        );
                      }
                    }).toList(),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.save_as_outlined),
                      label: const Text('Simpan Perubahan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isRequired(String key) {
    const requiredKeys = {'nama_kepala_keluarga', 'alamat', 'wilayah'};
    return requiredKeys.contains(key);
  }

  String _getLabelText(String key) {
    const Map<String, String> labels = {
      'nama_kepala_keluarga': 'Nama Kepala Keluarga', 'nomor_telepon_kepala_rumah_tangga': 'No. Telepon KK', 'tanggal_lahir_kepala_keluarga': 'Tgl. Lahir KK', 'tanggal_sidi_kepala_keluarga': 'Tgl. Sidi KK', 'tanggal_baptis_kepala_keluarga': 'Tgl. Baptis KK', 'emailkk': 'Email KK', 'status_pernikahan_kepala_rumah_tangga': 'Status Pernikahan',
      'alamat': 'Alamat', 'wilayah': 'Wilayah',
      'nama_istri': 'Nama Istri', 'tanggal_lahir_istri': 'Tgl. Lahir Istri', 'tanggal_baptis_istri': 'Tgl. Baptis Istri', 'tanggal_sidi_istri': 'Tgl. Sidi Istri', 'nomor_telepon_istri': 'No. Telepon Istri', 'stspasangan': 'Status Istri', 'emailpasangan': 'Email Istri',
      'nama_anak_pertama': 'Nama Anak Ke-1', 'tanggal_lahir_anak_pertama': 'Tgl. Lahir Anak Ke-1', 'status_pernikahan_anak_pertama': 'Status Nikah Anak Ke-1',
      'nama_anak_kedua': 'Nama Anak Ke-2', 'tanggal_lahir_anak_kedua': 'Tgl. Lahir Anak Ke-2', 'status_pernikahan_anak_kedua': 'Status Nikah Anak Ke-2',
      'nama_anak_ketiga': 'Nama Anak Ke-3', 'tanggal_lahir_anak_ketiga': 'Tgl. Lahir Anak Ke-3', 'status_pernikahan_anak_ketiga': 'Status Nikah Anak Ke-3',
      'nama_anak_keempat': 'Nama Anak Ke-4', 'tanggal_lahir_anak_keempat': 'Tgl. Lahir Anak Ke-4', 'status_pernikahan_anak_keempat': 'Status Nikah Anak Ke-4',
      'nama_anak_kelima': 'Nama Anak Ke-5', 'tanggal_lahir_anak_kelima': 'Tgl. Lahir Anak Ke-5', 'status_pernikahan_anak_kelima': 'Status Nikah Anak Ke-5',
      'nama_tanggungan_pertama': 'Nama Tanggungan Ke-1', 'nama_tanggungan_kedua': 'Nama Tanggungan Ke-2', 'nama_tanggungan_ketiga': 'Nama Tanggungan Ke-3',
    };
    return labels[key] ?? key.replaceAll('_', ' ').toUpperCase();
  }
}
