import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MemberProfilePage extends StatefulWidget {
  const MemberProfilePage({super.key});

  @override
  State<MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<MemberProfilePage> {
  // Data Simulasi
  final Map<String, dynamic> memberData = {
    'nama': 'St. Albiner Silitonga',
    'alamat': 'Jl. Jendral Sudirman No. 123, Jakarta',
    'status_jemaat': 'Aktif',
    'jenis_kelamin': 'Laki-laki',
    'status_pernikahan': 'Menikah',
    'tgl_lahir': '1980-05-20',
    'tgl_sidi': '1996-06-15',
    'tgl_menikah': '2005-08-10',
    'tgl_meninggal': null,
    'jumlah_anak': 2,
    'pasangan': {
      'nama': 'Ny. Maria Boru Regar',
      'status_jemaat': 'Aktif',
      'jenis_kelamin': 'Perempuan',
      'status_pernikahan': 'Menikah',
      'tgl_lahir': '1982-03-12',
      'tgl_sidi': '1998-04-20',
      'tgl_menikah': '2005-08-10',
      'tgl_meninggal': null,
    },
    'anak': [
      {
        'nama': 'Andi Silitonga',
        'status_jemaat': 'Aktif',
        'jenis_kelamin': 'Laki-laki',
        'status_pernikahan': 'Tidak Menikah',
        'tgl_lahir': '2007-01-15',
        'tgl_sidi': '2023-06-10',
        'tgl_menikah': null,
        'tgl_meninggal': null,
      },
      {
        'nama': 'Budi Silitonga',
        'status_jemaat': 'Aktif',
        'jenis_kelamin': 'Laki-laki',
        'status_pernikahan': 'Tidak Menikah',
        'tgl_lahir': '2010-11-22',
        'tgl_sidi': null,
        'tgl_menikah': null,
        'tgl_meninggal': null,
      }
    ]
  };

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return "-";
    DateTime dt = DateTime.parse(date);
    return DateFormat('dd MMMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    bool hasSpouse = ['Menikah', 'Duda', 'Janda', 'Meninggal']
        .contains(memberData['status_pernikahan']);
    int childCount = memberData['jumlah_anak'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. HEADER
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 50, 25, 35),
              decoration: BoxDecoration(
                color: Colors.blue[900],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      ),
                      const Text(
                        "Profil Jemaat",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white24,
                    child: CircleAvatar(
                      radius: 42,
                      backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    memberData['nama'],
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "ID Jemaat: HKBP-2023-001",
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 2. INFORMASI PRIBADI
                _buildSectionTitle("Informasi Pribadi", Icons.person_rounded),
                _buildInfoCard([
                  _buildDetailRow("Nama Lengkap", memberData['nama']),
                  _buildDetailRow("Alamat", memberData['alamat']),
                  _buildDetailRow("Status Jemaat", memberData['status_jemaat'], isStatus: true),
                  _buildDetailRow("Jenis Kelamin", memberData['jenis_kelamin']),

                  _buildDetailRow("Status Pernikahan", memberData['status_pernikahan']),
                  _buildDetailRow("Tanggal Lahir", formatDate(memberData['tgl_lahir'])),
                  _buildDetailRow("Tanggal Sidi", formatDate(memberData['tgl_sidi'])),
                  _buildDetailRow("Tanggal Menikah", formatDate(memberData['tgl_menikah'])),
                  _buildDetailRow("Tanggal Meninggal", formatDate(memberData['tgl_meninggal'])),
                  _buildDetailRow("Jumlah Anak", "${memberData['jumlah_anak']} Orang"),
                ]),

                const SizedBox(height: 25),

                // 3. DATA PASANGAN
                if (hasSpouse && memberData['pasangan'] != null) ...[
                  _buildSectionTitle("Data Pasangan", Icons.favorite_rounded),
                  _buildInfoCard([
                    _buildDetailRow("Nama Pasangan", memberData['pasangan']['nama']),
                    _buildDetailRow("Status Jemaat", memberData['pasangan']['status_jemaat'], isStatus: true),
                    _buildDetailRow("Jenis Kelamin", memberData['pasangan']['jenis_kelamin']),
                    _buildDetailRow("Status Pernikahan", memberData['pasangan']['status_pernikahan']),
                    _buildDetailRow("Tanggal Lahir", formatDate(memberData['pasangan']['tgl_lahir'])),
                    _buildDetailRow("Tanggal Sidi", formatDate(memberData['pasangan']['tgl_sidi'])),
                    _buildDetailRow("Tanggal Menikah", formatDate(memberData['pasangan']['tgl_menikah'])),
                    _buildDetailRow("Tanggal Meninggal", formatDate(memberData['pasangan']['tgl_meninggal'])),
                  ]),
                  const SizedBox(height: 25),
                ],

                // 4. DATA ANAK
                if (childCount > 0) ...[
                  _buildSectionTitle("Data Anak", Icons.family_restroom_rounded),
                  ...List.generate(memberData['anak'].length, (index) {
                    var child = memberData['anak'][index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: _buildInfoCard([
                        Text(
                          "Anak Ke-${index + 1}",
                          style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const Divider(),
                        _buildDetailRow("Nama Anak", child['nama']),
                        _buildDetailRow("Status Jemaat", child['status_jemaat'], isStatus: true),
                        _buildDetailRow("Jenis Kelamin", child['jenis_kelamin']),
                        _buildDetailRow("Status Pernikahan", child['status_pernikahan']),
                        _buildDetailRow("Tanggal Lahir", formatDate(child['tgl_lahir'])),
                        _buildDetailRow("Tanggal Sidi", formatDate(child['tgl_sidi'])),
                        _buildDetailRow("Tanggal Menikah", formatDate(child['tgl_menikah'])),
                        _buildDetailRow("Tanggal Meninggal", formatDate(child['tgl_meninggal'])),
                        // Field Jumlah Anak di sini sudah dihapus sesuai permintaan
                      ]),
                    );
                  }),
                ],

                const SizedBox(height: 20),

                // 5. TOMBOL UPDATE DATA
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Logic untuk navigasi ke halaman edit atau memunculkan modal edit
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Menuju halaman edit data...")),
                      );
                    },
                    icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                    label: const Text(
                      "Update Data Profil",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),

                const SizedBox(height: 50),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 5),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[900], size: 20),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: isStatus
                ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: value == 'Aktif' ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: value == 'Aktif' ? Colors.green[700] : Colors.red[700],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
                : Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}