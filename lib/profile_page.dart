import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'edit_profile_page.dart'; // Pastikan file ini ada dan benar
import 'config/api_config.dart';
import 'utils/error_handler.dart';

class ProfilePage extends StatefulWidget {
  final int userId;

  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<Map<String, dynamic>>? _userProfileFuture;

  // Peta untuk label khusus yang disesuaikan dengan daftar kolom Anda
  static const Map<String, String> _specialLabels = {
    'id': 'ID Jemaat', 'timestamp': 'Waktu Input', 'nama_keluarga': 'Nama Keluarga', 'keanggotaan': 'Keanggotaan', 'alamat': 'Alamat', 'wilayah': 'Wilayah',
    'nama_kepala_keluarga': 'Nama Kepala Keluarga', 'nomor_telepon_kepala_rumah_tangga': 'No. Telepon KK', 'emailkk': 'Email KK',
    'tanggal_lahir_kepala_keluarga': 'Tgl. Lahir KK', 'tanggal_baptis_kepala_keluarga': 'Tgl. Baptis KK', 'tanggal_sidi_kepala_keluarga': 'Tgl. Sidi KK',
    'status_pernikahan_kepala_rumah_tangga': 'Status Pernikahan KK', 'tanggal_pernikahan': 'Tgl. Pernikahan Keluarga', 'tanggal_meninggal_kepala_keluarga': 'Tgl. Meninggal KK',
    'nama_istri': 'Nama Istri', 'tanggal_lahir_istri': 'Tgl. Lahir Istri', 'tanggal_baptis_istri': 'Tgl. Baptis Istri',
    'tanggal_sidi_istri': 'Tgl. Sidi Istri', 'nomor_telepon_istri': 'No. Telepon Istri', 'emailpasangan': 'Email Istri', 'stspasangan': 'Status Istri',
    'tanggal_meninggal_istri': 'Tgl. Meninggal Istri', 'jlhanak': 'Jumlah Anak',
    'nama_anak_pertama': 'Nama Anak Ke-1', 'keanggotaan1': 'Keanggotaan Anak Ke-1', 'tanggal_lahir_anak_pertama': 'Tgl. Lahir Anak Ke-1', 'tanggal_baptis_anak_pertama': 'Tgl. Baptis Anak Ke-1', 'tanggal_sidi_anak_pertama': 'Tgl. Sidi Anak Ke-1', 'status_pernikahan_anak_pertama': 'Status Nikah Anak Ke-1', 'tanggal_pernikahan_anak_pertama': 'Tgl. Nikah Anak Ke-1', 'tanggal_meninggal_anak_pertama': 'Tgl. Meninggal Anak Ke-1',
    'nama_istri_dari_anak_pertama': 'Nama Pasangan Anak Ke-1', 'tanggal_lahir_istri_dari_anak_pertama': 'Tgl. Lahir Pasangan Anak Ke-1', 'tanggal_baptis_istri_dari_anak_pertama': 'Tgl. Baptis Pasangan Anak Ke-1', 'tanggal_sidi_istri_dari_anak_pertama': 'Tgl. Sidi Pasangan Anak Ke-1', 'stspasangan1': 'Status Pasangan Anak Ke-1', 'tanggal_meninggal_istri_dari_anak_pertama': 'Tgl. Meninggal Pasangan Anak Ke-1',
    'nama_anak_kedua': 'Nama Anak Ke-2', 'keanggotaan2': 'Keanggotaan Anak Ke-2', 'tanggal_lahir_anak_kedua': 'Tgl. Lahir Anak Ke-2', 'tanggal_baptis_anak_kedua': 'Tgl. Baptis Anak Ke-2', 'tanggal_sidi_anak_kedua': 'Tgl. Sidi Anak Ke-2', 'status_pernikahan_anak_kedua': 'Status Nikah Anak Ke-2', 'tanggal_pernikahan_anak_kedua': 'Tgl. Nikah Anak Ke-2', 'tanggal_meninggal_anak_kedua': 'Tgl. Meninggal Anak Ke-2',
    'nama_istri_dari_anak_kedua': 'Nama Pasangan Anak Ke-2', 'tanggal_lahir_istri_dari_anak_kedua': 'Tgl. Lahir Pasangan Anak Ke-2', 'tanggal_baptis_istri_dari_anak_kedua': 'Tgl. Baptis Pasangan Anak Ke-2', 'tanggal_sidi_istri_dari_anak_kedua': 'Tgl. Sidi Pasangan Anak Ke-2', 'stspasangan2': 'Status Pasangan Anak Ke-2', 'tanggal_meninggal_istri_dari_anak_kedua': 'Tgl. Meninggal Pasangan Anak Ke-2',
    'nama_anak_ketiga': 'Nama Anak Ke-3', 'keanggotaan3': 'Keanggotaan Anak Ke-3', 'tanggal_lahir_anak_ketiga': 'Tgl. Lahir Anak Ke-3',
    'nama_anak_keempat': 'Nama Anak Ke-4', 'keanggotaan4': 'Keanggotaan Anak Ke-4', 'tanggal_lahir_anak_keempat': 'Tgl. Lahir Anak Ke-4',
    'nama_anak_kelima': 'Nama Anak Ke-5', 'keanggotaan5': 'Keanggotaan Anak Ke-5', 'tanggal_lahir_anak_kelima': 'Tgl. Lahir Anak Ke-5',
    'nama_tanggungan_pertama': 'Nama Tanggungan Ke-1', 'tanggal_lahir_tanggungan_pertama': 'Tgl. Lahir Tanggungan Ke-1', 'tanggal_baptis_tanggungan_pertama': 'Tgl. Baptis Tanggungan Ke-1', 'tanggal_sidi_tanggungan_pertama': 'Tgl. Sidi Tanggungan Ke-1', 'status_tanggungan_pertama': 'Status Tanggungan Ke-1', 'hubungan_dengan_tanggungan_pertama': 'Hubungan Tanggungan Ke-1',
    'nama_tanggungan_kedua': 'Nama Tanggungan Ke-2', 'tanggal_lahir_tanggungan_kedua': 'Tgl. Lahir Tanggungan Ke-2', 'tanggal_baptis_tanggungan_kedua': 'Tgl. Baptis Tanggungan Ke-2', 'tanggal_sidi_tanggungan_kedua': 'Tgl. Sidi Tanggungan Ke-2', 'status_tanggungan_kedua': 'Status Tanggungan Ke-2', 'hubungan_dengan_tanggungan_kedua': 'Hubungan Tanggungan Ke-2',
    'nama_tanggungan_ketiga': 'Nama Tanggungan Ke-3', 'tanggal_lahir_tanggungan_ketiga': 'Tgl. Lahir Tanggungan Ke-3', 'tanggal_baptis_tanggungan_ketiga': 'Tgl. Baptis Tanggungan Ke-3', 'tanggal_sidi_tanggungan_ketiga': 'Tgl. Sidi Tanggungan Ke-3', 'status_tanggungan_ketiga': 'Status Tanggungan Ke-3', 'hubungan_dengan_tanggungan_ketiga': 'Hubungan Tanggungan Ke-3',
  };

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'id_ID';
    _userProfileFuture = fetchUserProfile();
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString == "0000-00-00" || dateString == "1990-01-01" || dateString == "1900-01-01") {
      return "-";
    }
    try {
      return DateFormat('d MMMM yyyy').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }

  String _formatLabel(String key) {
    if (_specialLabels.containsKey(key)) return _specialLabels[key]!;
    return key.replaceAll('_', ' ').split(' ').map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1)}' : '').join(' ');
  }

  Future<Map<String, dynamic>> fetchUserProfile() async {
    // --- PERBAIKAN: Menambahkan parameter cache-busting (anti-cache) ---
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final uri = Uri.parse("${ApiConfig.baseUrl}/get_user_profile.php?api_key=${ApiConfig.apiKey}&id_jemaat=${widget.userId}&cache_buster=$timestamp");

    print("Memanggil API Profil: $uri");

    try {
      final response = await http.get(uri, headers: {
        // Header ini meminta server agar tidak menggunakan cache
        'Cache-Control': 'no-cache, must-revalidate',
      }).timeout(const Duration(seconds: 20));

      print("Status Code API Profil: ${response.statusCode}");

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) throw Exception('Respons dari server kosong.');
        if (response.body.trim().startsWith('{')) {
          final errorJson = json.decode(response.body.trim());
          throw Exception(errorJson['message'] ?? 'Format data tidak dikenal.');
        }
        String decodedString = utf8.decode(base64.decode(response.body.trim()));
        return json.decode(decodedString) as Map<String, dynamic>;
      } else {
        throw Exception('Gagal memuat data. Server merespons dengan status: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception(ErrorHandler.getUserFriendlyMessage('timeout'));
    } catch (e) {
      throw Exception(ErrorHandler.getUserFriendlyMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingState();
          if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
          if (snapshot.hasData && snapshot.data!.isNotEmpty) return _buildProfileView(snapshot.data!);
          return _buildErrorState("Data profil untuk jemaat ini tidak ditemukan.");
        },
      ),
    );
  }

  Widget _buildProfileView(Map<String, dynamic> user) {
    print("datanya");
    print(user);
    final List<Map<String, dynamic>> dataGroups = [
      { "title": "Data Umum Keluarga", "icon": Icons.home_work_outlined, "color": Colors.indigo, "columns": ['nama_keluarga', 'keanggotaan', 'alamat', 'wilayah', 'timestamp'] },
      { "title": "Kepala Keluarga", "icon": Icons.person_outline, "color": Colors.blue, "check_key": "nama_kepala_keluarga", "columns": [ 'nama_kepala_keluarga', 'nomor_telepon_kepala_rumah_tangga', 'emailkk', 'tanggal_lahir_kepala_keluarga', 'tanggal_baptis_kepala_keluarga', 'tanggal_sidi_kepala_keluarga', 'status_pernikahan_kepala_rumah_tangga', 'tanggal_pernikahan', 'tanggal_meninggal_kepala_keluarga' ] },
      { "title": "Istri", "icon": Icons.woman_outlined, "color": Colors.pink, "check_key": "nama_istri", "columns": [ 'nama_istri', 'tanggal_lahir_istri', 'tanggal_baptis_istri', 'tanggal_sidi_istri', 'nomor_telepon_istri', 'emailpasangan', 'stspasangan', 'tanggal_meninggal_istri', 'jlhanak' ] },
      ...List.generate(5, (i) { int n=i+1; String s=i==0?'pertama':(i==1?'kedua':(i==2?'ketiga':(i==3?'keempat':'kelima'))); return { "title": "Anak Ke-$n", "icon": Icons.child_care_outlined, "color": Colors.orange, "check_key": "nama_anak_$s", "columns": [ 'nama_anak_$s', 'keanggotaan$n', 'tanggal_lahir_anak_$s', 'tanggal_baptis_anak_$s', 'tanggal_sidi_anak_$s', 'status_pernikahan_anak_$s', 'tanggal_pernikahan_anak_$s', 'tanggal_meninggal_anak_$s' ] }; }),
      ...List.generate(5, (i) { int n=i+1; String s=i==0?'pertama':(i==1?'kedua':(i==2?'ketiga':(i==3?'keempat':'kelima'))); return { "title": "Pasangan Anak Ke-$n", "icon": Icons.favorite_outline, "color": Colors.red, "check_key": "nama_istri_dari_anak_$s", "columns": [ 'nama_istri_dari_anak_$s', 'tanggal_lahir_istri_dari_anak_$s', 'tanggal_baptis_istri_dari_anak_$s', 'tanggal_sidi_istri_dari_anak_$s', 'stspasangan$n', 'tanggal_meninggal_istri_dari_anak_$s' ] }; }),
      ...List.generate(3, (i) { int n=i+1; String s=i==0?'pertama':(i==1?'kedua':'ketiga'); return { "title": "Tanggungan Ke-$n", "icon": Icons.people_outline, "color": Colors.purple, "check_key": "nama_tanggungan_$s", "columns": [ 'nama_tanggungan_$s', 'tanggal_lahir_tanggungan_$s', 'tanggal_baptis_tanggungan_$s', 'tanggal_sidi_tanggungan_$s', 'status_tanggungan_$s', 'hubungan_dengan_tanggungan_$s' ] }; })
    ];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 180.0, pinned: true, stretch: true,
          backgroundColor: Colors.blue[900],
          iconTheme: IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_note, color: Colors.white),
              onPressed: () {
                // --- PERBAIKAN LOGIKA REFRESH ---
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfilePage(userData: user)),
                ).then((isDataUpdated) {
                  // Jika halaman edit mengembalikan nilai 'true' (artinya ada update)
                  if (isDataUpdated == true) {
                    // Panggil setState untuk memuat ulang data dengan fetchUserProfile()
                    setState(() {
                      _userProfileFuture = fetchUserProfile();
                    });
                  }
                });
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(user['nama_kepala_keluarga'] ?? 'Profil Jemaat', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold,color: Color(0xFFFFFFFF))),
            centerTitle: true,
            background: Container(
              decoration: BoxDecoration( gradient: LinearGradient( begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.blue[900]!, Colors.blue[700]!], ), ),
              child: Stack(
                children: [
                  const Positioned.fill(child: Icon(Icons.person, color: Colors.white24, size: 100)),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircleAvatar(radius: 40, backgroundColor: Colors.white24, child: Icon(Icons.person, size: 40, color: Colors.white)),
                        const SizedBox(height: 10),
                        Text("No. Urut: ${user['no_pokok'] ?? user['id'] ?? 'N/A'}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              dataGroups.map((group) {
                if (group.containsKey('check_key') && (user[group['check_key']] == null || user[group['check_key']].toString().isEmpty)) {
                  return const SizedBox.shrink();
                }
                final Map<String, String?> cardData = { for (var col in group['columns']) _formatLabel(col): user[col]?.toString() };
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildInfoCard( title: group['title'], icon: group['icon'], iconColor: group['color'], data: cardData, ),
                );
              }).toList(),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }

  Widget _buildInfoCard({ required String title, required IconData icon, required Color iconColor, required Map<String, String?> data, }) {
    final validEntries = data.entries.where((entry) => entry.value != null && entry.value!.trim().isNotEmpty).toList();
    if (validEntries.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)], ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
          const Divider(height: 20, thickness: 0.5),
          ...validEntries.map((entry) {
            String displayValue = entry.value!;
            String originalKey = _specialLabels.entries.firstWhere((mapEntry) => mapEntry.value == entry.key, orElse: () => MapEntry(entry.key.toLowerCase().replaceAll(' ', '_'),'')).key;
            if (originalKey.contains('tanggal_')) {
              displayValue = _formatDate(displayValue);
            }
            if(displayValue == "-") return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded( flex: 2, child: Text(entry.key, style: TextStyle(color: Colors.grey[600], fontSize: 13)), ),
                  const Text(" : ", style: TextStyle(color: Colors.grey)),
                  Expanded( flex: 3, child: Text(displayValue, style: const TextStyle(color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.w500)), ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 16),
          Text("Memuat Profil...", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            const Text("Gagal Memuat Data", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(error, style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
