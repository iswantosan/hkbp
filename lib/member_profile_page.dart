import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Halaman untuk menampilkan detail tanggungan (contoh)
class TanggunganDetailPage extends StatelessWidget {
  final Map<String, dynamic> tanggunganData;
  const TanggunganDetailPage({super.key, required this.tanggunganData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tanggunganData['nama'] ?? 'Detail Tanggungan')),
      body: Center(
        child: Text('Detail untuk ${tanggunganData['nama']}'),
        // Anda bisa membangun UI detail di sini
      ),
    );
  }
}


class FamilyDetailPage extends StatefulWidget {
  final int familyId; // ID jemaat yang dikirim dari halaman sebelumnya

  const FamilyDetailPage({super.key, required this.familyId});

  @override
  State<FamilyDetailPage> createState() => _FamilyDetailPageState();
}

class _FamilyDetailPageState extends State<FamilyDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _familyData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFamilyData();
  }

  // --- LOGIKA PENGAMBILAN DATA DARI API ---
  Future<void> _fetchFamilyData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse(
          "https://hkbppondokkopi.org/api_hkbp/get_family_detail.php?api_key=RAHASIA_HKBP_2024&id=${widget.familyId}");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // 1. Ambil string Base64 dari body
        String encodedData = response.body;

        // 2. Dekripsi (Base64 Decode)
        String decodedString = utf8.decode(base64.decode(encodedData));

        // 3. Parse JSON
        final data = json.decode(decodedString);

        // Cek jika API mengembalikan error internal
        if (data.containsKey('error')) {
          setState(() {
            _error = data['error'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _familyData = data;
            _isLoading = false;
          });
        }
      } else {
        // Handle error HTTP (404, 401, dll)
        String decodedString = utf8.decode(base64.decode(response.body));
        final data = json.decode(decodedString);
        setState(() {
          _error = data['error'] ?? 'Gagal memuat data. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching family data: $e");
      setState(() {
        _error = "Terjadi kesalahan koneksi. Silakan coba lagi.";
        _isLoading = false;
      });
    }
  }

  // --- BUILDER WIDGET ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_familyData?['nama_kepala_keluarga'] ?? 'Detail Keluarga'),
        backgroundColor: Colors.blue[900],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchFamilyData,
                child: const Text('Coba Lagi'),
              )
            ],
          ),
        ),
      );
    }
    if (_familyData == null) {
      return const Center(child: Text('Data tidak ditemukan.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionCard('Informasi Personal', _buildPersonalSection()),
        if (_familyData!['nama_istri'] != null && _familyData!['nama_istri'].isNotEmpty)
          _buildSectionCard('Informasi Pasangan', _buildSpouseSection()),

        // Logika untuk menampilkan anak
        if (_familyData!['jlhanak'] != null && _familyData!['jlhanak'] > 0)
          _buildSectionCard('Informasi Anak', _buildChildrenSection()),

        _buildSectionCard('Informasi Tanggungan', _buildDependentsSection()),

      ],
    );
  }

  // --- WIDGET SECTIONS ---

  Widget _buildPersonalSection() {
    return Column(
      children: [
        _buildInfoRow('Nama Kepala Keluarga', _familyData!['nama_kepala_keluarga']),
        _buildInfoRow('Keanggotaan', _familyData!['keanggotaan']),
        _buildInfoRow('Alamat', _familyData!['alamat']),
        _buildInfoRow('Wilayah', _familyData!['wilayah']),
        _buildInfoRow('No. Telepon', _familyData!['nomor_telepon_kepala_rumah_tangga']),
        _buildInfoRow('Email', _familyData!['emailkk']),
        _buildInfoRow('Tanggal Lahir', _familyData!['tanggal_lahir_kepala_keluarga']),
        _buildInfoRow('Tanggal Baptis', _familyData!['tanggal_baptis_kepala_keluarga']),
        _buildInfoRow('Tanggal Sidi', _familyData!['tanggal_sidi_kepala_keluarga']),
        _buildInfoRow('Status Pernikahan', _familyData!['status_pernikahan_kepala_rumah_tangga']),
        _buildInfoRow('Tanggal Pernikahan', _familyData!['tanggal_pernikahan']),
        _buildInfoRow('Tanggal Meninggal', _familyData!['tanggal_meninggal_kepala_keluarga']),
      ],
    );
  }

  Widget _buildSpouseSection() {
    return Column(
      children: [
        _buildInfoRow('Nama Pasangan', _familyData!['nama_istri']),
        _buildInfoRow('Tanggal Lahir', _familyData!['tanggal_lahir_istri']),
        _buildInfoRow('Tanggal Baptis', _familyData!['tanggal_baptis_istri']),
        _buildInfoRow('Tanggal Sidi', _familyData!['tanggal_sidi_istri']),
        _buildInfoRow('No. Telepon', _familyData!['nomor_telepon_istri']),
        _buildInfoRow('Email', _familyData!['emailpasangan']),
        _buildInfoRow('Status', _familyData!['stspasangan']),
        _buildInfoRow('Tanggal Meninggal', _familyData!['tanggal_meninggal_istri']),
      ],
    );
  }

  Widget _buildChildrenSection() {
    // Diasumsikan data anak memiliki pola `nama_anak_pertama`, `nama_anak_kedua`, dst.
    // Kode ini hanya untuk contoh anak pertama. Anda bisa meloop berdasarkan `jlhanak`.
    return Column(
      children: [
        // --- Anak Pertama ---
        if (_familyData!['nama_anak_pertama'] != null && _familyData!['nama_anak_pertama'].isNotEmpty)
          _buildClickableCard(
            title: _familyData!['nama_anak_pertama'],
            subtitle: 'Keanggotaan: ${_familyData!['keanggotaan1'] ?? '-'}',
            onTap: () {
              // TODO: Navigasi ke halaman detail anak dengan data anak pertama
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tampilkan detail untuk ${_familyData!['nama_anak_pertama']}')),
              );
            },
          ),
        // Tambahkan logika untuk anak kedua, ketiga, dst. di sini jika perlu
      ],
    );
  }

  Widget _buildDependentsSection() {
    return Column(
      children: [
        // --- Tanggungan Pertama ---
        if (_familyData!['nama_tanggungan_pertama'] != null && _familyData!['nama_tanggungan_pertama'].isNotEmpty)
          _buildClickableCard(
            title: _familyData!['nama_tanggungan_pertama'],
            subtitle: 'Hubungan: ${_familyData!['hubungan_dengan_tanggungan_pertama'] ?? '-'}',
            onTap: () {
              // Navigasi ke halaman detail yang berbeda untuk tanggungan
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TanggunganDetailPage(
                    tanggunganData: {
                      'nama': _familyData!['nama_tanggungan_pertama'],
                      // masukkan data tanggungan lain ke map ini
                    },
                  ),
                ),
              );
            },
          ),

        // --- Tanggungan Kedua ---
        if (_familyData!['nama_tanggungan_kedua'] != null && _familyData!['nama_tanggungan_kedua'].isNotEmpty)
          _buildClickableCard(
            title: _familyData!['nama_tanggungan_kedua'],
            subtitle: 'Hubungan: ${_familyData!['hubungan_dengan_tanggungan_kedua'] ?? '-'}',
            onTap: () {
              // Menampilkan detail di halaman ini juga (sesuai permintaan)
              _showDetailDialog('Detail Tanggungan', {
                'Nama': _familyData!['nama_tanggungan_kedua'],
                'Tanggal Lahir': _familyData!['tanggal_lahir_tanggungan_kedua'],
                'Tanggal Baptis': _familyData!['tanggal_baptis_tanggungan_kedua'],
                'Tanggal Sidi': _familyData!['tanggal_sidi_tanggungan_kedua'],
                'Status': _familyData!['status_tanggungan_kedua'],
                'Hubungan': _familyData!['hubungan_dengan_tanggungan_kedua'],
              });
            },
          ),
        // Tambahkan untuk tanggungan ketiga jika ada
      ],
    );
  }

  // --- HELPER WIDGETS ---

  // Menampilkan dialog detail (untuk tanggungan kedua)
  void _showDetailDialog(String title, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('${entry.key}: ${entry.value ?? '-'}'),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }


  Widget _buildClickableCard({required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }


  Widget _buildSectionCard(String title, Widget content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
            ),
            const Divider(height: 24),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    final displayValue = (value == null || value.toString().trim().isEmpty) ? '-' : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: Colors.grey[600]))),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: Text(displayValue, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
