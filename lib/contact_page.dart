import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';


class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  // Logic untuk membuka URL/Aplikasi eksternal
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Hubungi Kami",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[900],
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image/Map Placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                image: const DecorationImage(
                  image: AssetImage("assets/sekre_main.jpeg"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
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

            _buildContactCard(
              Icons.location_on_rounded,
              "Alamat",
              "Jl. Pondok Kopi Raya No.1, Jakarta Timur",
              "Buka Maps",
                  () => _launchURL("https://maps.google.com/?q=HKBP+Pondok+Kopi"),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              Icons.phone_rounded,
              "Telepon",
              "0813-166-172-38 / 0812-9079-6618",
              "Hubungi Sekarang",
                  () => _launchURL("tel:+681290796618"),
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSocialItem(Icons.language, "Website", Colors.teal, ()=>_launchURL('https://hkbppondokkopi.org')),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(IconData icon, String title, String content, String action, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
                Text(content, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
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

  Widget _buildSocialItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
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