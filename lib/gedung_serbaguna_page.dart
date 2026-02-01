import 'package:flutter/material.dart';
import 'contact_page.dart'; // Import halaman kontak untuk navigasi
import 'package:url_launcher/url_launcher.dart'; // Import untuk membuka URL

class GedungSerbagunaPage extends StatefulWidget {
  const GedungSerbagunaPage({super.key});

  @override
  State<GedungSerbagunaPage> createState() => _GedungSerbagunaPageState();
}

class _GedungSerbagunaPageState extends State<GedungSerbagunaPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Daftar path gambar lokal dari folder assets
  final List<String> galleryImages = [
    'assets/sekre_main.jpeg',
    'assets/sekre1.jpeg',
    'assets/sekre2.jpeg',
    'assets/sekre3.jpeg',
    'assets/sekre4.jpeg',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Fungsi untuk membuka URL
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Jika gagal, tampilkan snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header Halaman yang konsisten dengan HomeScreen
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(15, 60, 25, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue[900]!, Colors.blue[700]!], // Warna disesuaikan dengan ikon menu
                ),
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
                      const Icon(Icons.home_work_outlined, color: Colors.white, size: 24), // Ikon yang sesuai
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Gedung Serba Guna",
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // ...
                  const Padding(
                    padding: EdgeInsets.only(left: 45), // <-- INI PENYEBABNYA
                    child: Text(
                      "Informasi fasilitas dan pemesanan",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
//...

                ],
              ),
            ),
          ),
          // Konten halaman
          SliverList(
            delegate: SliverChildListDelegate(
              [
                // 1. Galeri Gambar
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildImageGallery(),
                ),

                // 2. Detail Fasilitas
                _buildSectionCard(
                  title: "Fasilitas & Kapasitas",
                  icon: Icons.info_outline,
                  iconColor: Colors.blue,
                  children: [
                    _buildInfoRow(Icons.people_alt_outlined, "Kapasitas", "150 - 200 Pax"),
                    _buildInfoRow(Icons.chair_sharp, "Kursi Futura", "Tersedia"),
                    _buildInfoRow(Icons.table_bar_outlined, "Meja Panjang", "Tersedia"),
                    _buildInfoRow(Icons.volume_up_outlined, "Sound System", "Tersedia"),
                    _buildInfoRow(Icons.mic_none_outlined, "Mikrofon", "Tersedia"),
                    _buildInfoRow(Icons.speaker_group_outlined, "Speaker", "Tersedia"),
                    _buildInfoRow(Icons.wc_outlined, "Toilet", "Tersedia (Pria & Wanita)"),
                    _buildInfoRow(Icons.local_parking, "Parkiran", "Tersedia"),
                    _buildInfoRow(Icons.camera_outdoor, "CCTV", "Tersedia"),
                  ],
                ),

                // 3. Informasi Alamat
                _buildSectionCard(
                  title: "Alamat",
                  icon: Icons.location_on_outlined,
                  iconColor: Colors.red,
                  children: [
                    _buildInfoRow(Icons.location_city_rounded, "Lokasi", "Jl. Raya Pondok Kopi Raya No.1, Jakarta Timur"),
                    _buildInfoRow(Icons.map_outlined, "Google Maps", "Lihat Peta", isLink: true, onTap: () {
                      _launchURL("https://maps.app.goo.gl/9ZBpscbR18KkipFGA"); // Ganti dengan link Google Maps Anda
                    }),
                  ],
                ),

                // 4. Jadwal Booking
                _buildSectionCard(
                  title: "Jadwal Booking",
                  icon: Icons.calendar_month_outlined,
                  iconColor: Colors.green,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "Untuk mengetahui jadwal yang tersedia, silakan hubungi sekretariat.",
                        style: TextStyle(color: Colors.black54, height: 1.5),
                      ),
                    )
                  ],
                ),

                // 5. Cara Booking
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Arahkan ke halaman Hubungi Kami
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactPage()));
                    },
                    icon: const Icon(Icons.phone_in_talk_outlined),
                    label: const Text("Hubungi Sekretariat"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk membangun galeri gambar
  Widget _buildImageGallery() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: PageView.builder(
              controller: _pageController,
              itemCount: galleryImages.length,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemBuilder: (context, index) {
                return Image.asset(
                  galleryImages[index],
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.error_outline, color: Colors.redAccent),
                  ),
                );
              },
            ),
          ),
          // Indikator titik
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                galleryImages.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk membangun kartu bagian informasi
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
          const Divider(height: 25, thickness: 0.5),
          ...children,
        ],
      ),
    );
  }

  // Widget untuk membangun baris info
  Widget _buildInfoRow(IconData icon, String label, String value, {bool isLink = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: isLink ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(width: 15),
            Text("$label: ", style: TextStyle(color: Colors.grey[700])),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isLink ? Colors.blue[700] : Colors.black87,
                  decoration: isLink ? TextDecoration.underline : TextDecoration.none,
                  decorationColor: Colors.blue[700],
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
