import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';


class ClergyPage extends StatefulWidget {
  const ClergyPage({super.key});

  @override
  State<ClergyPage> createState() => _ClergyPageState();
}

class _ClergyPageState extends State<ClergyPage> {
  List<dynamic> _clergyList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchClergyData();
  }

  // 1. LOGIK PENGAMBILAN DATA DARI DATABASE (DENGAN DECODE BASE64)
  Future<void> fetchClergyData() async {
    setState(() => _isLoading = true);
    try {
      // Sesuaikan IP: 10.0.2.2 untuk Android Emulator, localhost untuk iOS
      final response = await http.get(
        Uri.parse("https://hkbppondokkopi.org/api_hkbp/get_clergy.php?api_key=RAHASIA_HKBP_2024"),

       //   final response = await http.get(
      //Uri.parse("http://127.0.0.1/HKBP/api_hkbp/get_clergy.php?api_key=RAHASIA_HKBP_2024"),

    ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // 1. Ambil string Base64 dari body respon
        String encodedData = response.body;

        // 2. Dekripsi / Decode dari Base64 ke String JSON asli
        String decodedString = utf8.decode(base64.decode(encodedData));

        setState(() {
          // 3. Parse string JSON yang sudah didecode ke dalam List
          final data = json.decode(decodedString);

          if (data is List) {
            // Logika sorting tetap dipertahankan agar Pdt berada di urutan teratas
            data.sort((a, b) {
              String nameA = (a['nama'] ?? "").toString().toLowerCase();
              String nameB = (b['nama'] ?? "").toString().toLowerCase();
              bool isPdtA = nameA.contains("pdt");
              bool isPdtB = nameB.contains("pdt");
              if (isPdtA && !isPdtB) return -1;
              if (!isPdtA && isPdtB) return 1;
              return 0;
            });
            _clergyList = data;
            // Debug: Print sample data untuk cek field telepon
            if (data.isNotEmpty) {
              debugPrint("Sample clergy data: ${data[0]}");
            }
          } else {
            _clergyList = [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error Koneksi Clergy: $e");
      setState(() => _isLoading = false);
    }
  }


  // 2. LOGIK WHATSAPP
  Future<void> _openWhatsApp(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.trim().isEmpty || phoneNumber == "-") {
      _showNoNumberDialog();
      return;
    }

    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '62${cleanNumber.substring(1)}';
    }

    final Uri whatsappUri = Uri.parse("https://wa.me/$cleanNumber");
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      debugPrint("Gagal WhatsApp: $e");
    }
  }

  // 3. LOGIK CALL DENGAN POP-UP VALIDASI
  Future<void> _makeCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.trim().isEmpty || phoneNumber == "-") {
      _showNoNumberDialog();
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      debugPrint("Gagal telp: $e");
    }
  }

  void _showNoNumberDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Informasi"),
        content: const Text("Nomor telepon/WhatsApp tidak tersedia."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 50, 20, 30),
              decoration: BoxDecoration(
                color: Colors.blue[900],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      ),
                      const Icon(Icons.people_alt_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        "Pendeta & Majelis",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 50, top: 5),
                    child: Text(
                      "Hubungi pelayan gereja dan majelis jemaat untuk keperluan pelayanan.",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          _isLoading
              ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              : _clergyList.isEmpty
              ? const SliverFillRemaining(child: Center(child: Text("Data tidak tersedia")))
              : SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildClergyCard(_clergyList[index]),
                childCount: _clergyList.length,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildClergyCard(Map<String, dynamic> person) {
    String rawFoto = person['foto'] ?? "";
    String photoUrl = "";

    try {
      if (rawFoto.isNotEmpty && !rawFoto.startsWith("http")) {
        String decodedFileName = utf8.decode(base64.decode(rawFoto));
        // PERBAIKAN: Path URL lengkap di posisi caret
        photoUrl = "https://hkbppondokkopi.org/$decodedFileName";
      } else {
        photoUrl = rawFoto;
      }
    } catch (e) {
      photoUrl = "https://hkbppondokkopi.org/$rawFoto";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 90,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                  imageUrl: photoUrl,
                  // PERBAIKAN: Menggunakan BoxFit.cover agar foto pas (fit) dalam bingkai
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.person, size: 50, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person['nama'] ?? "-",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D47A1))),
                  Text(person['jabatan'] ?? "-",
                      style: TextStyle(color: Colors.blueGrey[700], fontSize: 13, fontWeight: FontWeight.w500)),
                  const Divider(height: 20),
                  _buildInfoRow(Icons.location_on, "Wilayah", person['wilayah'] ?? "-"),
                  const SizedBox(height: 4),
                  _buildInfoRow(
                      Icons.info,
                      "Status",
                      (person['status'] == "1" || person['status'] == 1) ? "Aktif" : "Tidak Aktif"
                  ),

                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          onPressed: () => _makeCall(person['telepon'] ?? person['hp'] ?? person['no_telp']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D47A1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Icon(Icons.phone, size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          onPressed: () => _openWhatsApp(person['telepon'] ?? person['hp'] ?? person['no_telp']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Icon(Icons.chat_bubble_outline, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF0D47A1)),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
