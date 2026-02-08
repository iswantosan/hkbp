import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'config/api_config.dart';
import 'utils/error_handler.dart';

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

  // State untuk nilai dropdown
  final Map<String, String?> _dropdownValues = {};
  final List<String> _statusOptions = ["Menikah", "Belum Menikah", "Janda/Duda", "Almarhum"];
  final List<String> _wilayahOptions = [
    "Wijk I", "Wijk II", "Wijk III", "Wijk IV", "Wijk V", "Wijk VI", "Wijk VII", "Wijk VIII", "Wijk IX", "Wijk X",
    "Wijk XI", "Wijk XII", "Wijk XIII", "Wijk XIV", "Wijk XV", "Wijk XVI"
  ];

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (var key in widget.userData.keys)
        key: TextEditingController(text: widget.userData[key]?.toString() ?? '')
    };
    _initializeDropdowns();
  }

  void _initializeDropdowns() {
    _dropdownValues['status_pernikahan_kepala_rumah_tangga'] = _getInitialDropdownValue(widget.userData['status_pernikahan_kepala_rumah_tangga'], _statusOptions);
    _dropdownValues['stspasangan'] = _getInitialDropdownValue(widget.userData['stspasangan'], _statusOptions);
    _dropdownValues['wilayah'] = _getInitialDropdownValue(widget.userData['wilayah'], _wilayahOptions);

    for (int i = 1; i <= 5; i++) {
      String suffix = _getSuffix(i);
      String key = 'status_pernikahan_anak_$suffix';
      _dropdownValues[key] = _getInitialDropdownValue(widget.userData[key], _statusOptions);
    }
  }

  String _getSuffix(int index) {
    const suffixes = ['pertama', 'kedua', 'ketiga', 'keempat', 'kelima'];
    return suffixes[index - 1];
  }

  String? _getInitialDropdownValue(String? value, List<String> options) {
    if (value != null && options.contains(value)) {
      return value;
    }
    return null;
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  // --- PERBAIKAN 2: Logika Date Picker ---
  Future<void> _selectDate(BuildContext context, String fieldKey) async {
    DateTime initialDate;
    String currentValue = _controllers[fieldKey]!.text;

    // Coba parse tanggal yang ada. Jika gagal atau nilainya tidak valid, gunakan tanggal hari ini.
    try {
      if (currentValue.isNotEmpty && currentValue != '0000-00-00' && currentValue != '1900-01-01') {
        initialDate = DateTime.parse(currentValue);
      } else {
        initialDate = DateTime.now();
      }
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
      setState(() {
        _controllers[fieldKey]!.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  bool _isDateField(String key) => key.toLowerCase().contains('tanggal');
  bool _isDropdownField(String key) =>
      key == 'status_pernikahan_kepala_rumah_tangga' ||
          key == 'stspasangan' ||
          key == 'wilayah' ||
          key.startsWith('status_pernikahan_anak_');

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> updatedData = {
        'id': int.tryParse(widget.userData['id']?.toString() ?? '0') ?? 0,
      };

      _controllers.forEach((key, controller) {
        if (key != 'id') {
          updatedData[key] = _isDropdownField(key) ? _dropdownValues[key] : controller.text;
        }
      });

      final uri = Uri.parse("${ApiConfig.baseUrl}/update_user_profile.php?api_key=${ApiConfig.apiKey}");
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json; charset=UTF-8'}, body: jsonEncode(updatedData))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          // --- PERBAIKAN 1: Pindahkan pengecekan 'mounted' ke posisi yang benar ---
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil diperbarui'), backgroundColor: Colors.green));
            Navigator.pop(context, true);
          }
        } else {
          throw Exception(result['message'] ?? 'Gagal menyimpan data dari server.');
        }
      } else {
        throw Exception('Gagal terhubung ke server. Status: ${response.statusCode}');
      }
    } catch (e) {
      ErrorHandler.logError(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ErrorHandler.getUserFriendlyMessage(e)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      backgroundColor: const Color(0xFFF8FAFC),
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
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Edit Profil Jemaat",
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Perbarui data keluarga Anda",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.edit, color: Colors.white, size: 22),
                  )
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    ...editableFields.map((key) {
                      if (_controllers[key] == null) return const SizedBox.shrink();

                      bool isDate = _isDateField(key);
                      bool isDropdown = _isDropdownField(key);

                      if (isDropdown) {
                        List<String> options = (key == 'wilayah') ? _wilayahOptions : _statusOptions;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: DropdownButtonFormField<String>(
                            value: _dropdownValues[key],
                            isExpanded: true,
                            decoration: _inputDecoration(_getLabelText(key)),
                            items: options.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(value: value, child: Text(value));
                            }).toList(),
                            onChanged: (String? newValue) => setState(() => _dropdownValues[key] = newValue),
                            validator: (value) => _isRequired(key) && value == null ? 'Field ini tidak boleh kosong' : null,
                          ),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: TextFormField(
                            controller: _controllers[key],
                            readOnly: isDate,
                            decoration: _inputDecoration(_getLabelText(key), suffixIcon: isDate ? const Icon(Icons.calendar_month) : null),
                            onTap: isDate ? () => _selectDate(context, key) : null,
                            validator: (value) => _isRequired(key) && (value == null || value.isEmpty) ? 'Field ini tidak boleh kosong' : null,
                          ),
                        );
                      }
                    }).toList(),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text("Simpan Perubahan"),
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
    );
  }

  String _getLabelText(String key) {
    const labelMap = {
      'nama_kepala_keluarga': 'Nama Kepala Keluarga', 'nomor_telepon_kepala_rumah_tangga': 'No. Telepon', 'tanggal_lahir_kepala_keluarga': 'Tgl. Lahir',
      'tanggal_sidi_kepala_keluarga': 'Tgl. Sidi', 'tanggal_baptis_kepala_keluarga': 'Tgl. Baptis', 'emailkk': 'Email', 'status_pernikahan_kepala_rumah_tangga': 'Status Pernikahan',
      'alamat': 'Alamat', 'wilayah': 'wilayah',
      'nama_istri': 'Nama Istri', 'tanggal_lahir_istri': 'Tgl. Lahir', 'tanggal_baptis_istri': 'Tgl. Baptis', 'tanggal_sidi_istri': 'Tgl. Sidi',
      'nomor_telepon_istri': 'No. Telepon', 'stspasangan': 'Status Pernikahan', 'emailpasangan': 'Email',
    };
    if(labelMap.containsKey(key)) return labelMap[key]!;

    if(key.startsWith('nama_anak_')) return 'Nama Anak';
    if(key.startsWith('tanggal_lahir_anak_')) return 'Tgl. Lahir Anak';
    if(key.startsWith('status_pernikahan_anak_')) return 'Status Pernikahan Anak';
    if(key.startsWith('nama_tanggungan_')) return 'Nama Tanggungan';

    return key.replaceAll('_', ' ').split(' ').map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1)}' : '').join(' ');
  }

  bool _isRequired(String key) {
    const requiredKeys = {'nama_kepala_keluarga', 'alamat', 'wilayah'};
    return requiredKeys.contains(key);
  }
}
