import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  // Logic untuk membuka URL/Aplikasi eksternal (tidak berubah)
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Di aplikasi nyata, ada baiknya menampilkan snackbar atau dialog jika gagal
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- PERUBAHAN 1: Menyamakan struktur Scaffold & Background ---
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Warna background disamakan
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- PERUBAHAN 2: Mengganti AppBar dengan Header Modern ---
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(15, 60, 25, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  // Warna gradien disamakan dengan home_screen
                  colors: [Colors.blue[900]!, Colors.blue[700]!],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  // Tombol kembali yang lebih modern
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Judul dan sub-judul header
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hubungi Kami",
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Informasi kontak dan media sosial",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Ikon di sisi kanan header
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.headset_mic, color: Colors.white, size: 22),
                  )
                ],
              ),
            ),
          ),
          // --- AKHIR PERUBAHAN HEADER ---

          // --- PERUBAHAN 3: Membungkus konten dengan SliverPadding ---
          SliverPadding(
            padding: const EdgeInsets.all(16.0), // Padding konsisten
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 10), // Jarak dari header

                // Gambar header tetap sama
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20), // Border radius konsisten
                    image: const DecorationImage(
                      image: AssetImage("assets/sekre_main.jpeg"),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                      ),
                    ),
                    alignment: Alignment.bottomLeft,
                    padding: const EdgeInsets.all(20),
                    child: const Text(
                      "HKBP Pondok Kopi",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                const Text("Informasi Kontak",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 15),

                // Kartu-kartu kontak tidak diubah, hanya diberi jarak
                _buildContactCard(
                  Icons.location_on_rounded,
                  "Alamat Gereja",
                  "Jl. Pondok Kopi Raya No.1, Jakarta Timur",
                  "Buka Maps",
                      () => _launchURL("https://maps.app.goo.gl/PDLw3G69ENf7RuY46"),
                ),
                const SizedBox(height: 12),
                _buildContactCard(
                  Icons.location_on_rounded,
                  "Alamat Sekretariat",
                  "Jl. Arabika I No.6, RT.9/RW.6, Pd. Kopi, Jakarta Timur",
                  "Buka Maps",
                      () => _launchURL("https://maps.app.goo.gl/5qHgj67SLxr53UubA"),
                ),
                const SizedBox(height: 12),
                _buildContactCard(
                  Icons.phone_rounded,
                  "Parartaon: St. M. Manurung",
                  "0813-166-17238",
                  "Hubungi Sekarang",
                      () => _launchURL("tel:+6281316617238"), // Menggunakan +62
                ),

                const SizedBox(height: 12),
                _buildContactCard(
                  Icons.phone_rounded,
                  "Tata Usaha: St. P.B Marpaung",
                  "0812-907-966-18",
                  "Hubungi Sekarang",
                      () => _launchURL("tel:+6281290796618"), // Menggunakan +62
                ),
                const SizedBox(height: 12),
                _buildContactCard(
                  Icons.email_rounded,
                  "Email",
                  "info@hkbppondokkopi.org",
                  "Kirim Email",
                      () => _launchURL("mailto:info@hkbppondokkopi.org"),
                ),

                const SizedBox(height: 30),
                const Text("Media Sosial",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 15),

                // Media sosial item tidak diubah
                Row(
                  mainAxisAlignment: MainAxisAlignment.start, // Agar tidak merenggang
                  children: [
                    _buildSocialItem(Icons.language, "Website", Colors.teal, ()=>_launchURL('https://hkbppondokkopi.org')),
                    // Anda bisa menambahkan item lain di sini
                    // const SizedBox(width: 20),
                    // _buildSocialItem(Icons.facebook, "Facebook", Colors.blue, ()=>_launchURL('...')),
                  ],
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildContactCard tidak diubah
  Widget _buildContactCard(IconData icon, String title, String content, String action, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Menambahkan margin antar kartu
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15), // Border radius konsisten
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: Colors.blue[900]),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 2),
                Text(content, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 5),
                InkWell(
                  onTap: onTap,
                  child: Text(action, style: TextStyle(color: Colors.blue[700], fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildSocialItem tidak diubah
  Widget _buildSocialItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
