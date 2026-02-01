import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'document_page.dart';
import 'contact_page.dart';
import 'calendar_page.dart';
import 'clergy_page.dart';
import 'news_bulletin_page.dart';
import 'financial_report_page.dart';
import 'Home.dart';
import 'login_page.dart';
import 'news_detail_page.dart';
import 'config/api_config.dart';
import 'profile_page.dart';
import 'gedung_serbaguna_page.dart';
import 'utils/error_handler.dart';
import 'services/auth_service.dart'; // Auth service untuk logout


// --- PERBAIKAN 1: Modifikasi definisi class HomeScreen ---
class HomeScreen extends StatefulWidget {
  // Tambahkan field untuk menampung data user yang diterima dari LoginPage
  final int userId;
  final String userFullName;

  // Ubah konstruktor untuk menerima 'userId' dan 'userFullName' sebagai parameter wajib
  const HomeScreen({
    super.key,
    required this.userId,
    required this.userFullName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Map<String, dynamic>? welcomeData;
  List<dynamic> portfolioNews = [];
  bool isWelcomeLoading = true;
  bool isNewsLoading = true;
  bool _showAllNews = false;

  final String _apiBaseUrl = ApiConfig.baseUrl;
  //final String _apiBaseUrl = "http://127.0.0.1/HKBP/api_hkbp";

  // Hapus ID statis, karena kita akan menggunakan ID dinamis dari widget
  // final int loggedInUserId = 26; // <-- BARIS INI SUDAH TIDAK DIPERLUKAN

  final List<String> bannerImages = [
    'https://images.unsplash.com/photo-1438232992991-995b7058bbb3?q=80&w=1000',
    'https://images.unsplash.com/photo-1544427920-c49ccfb85579?q=80&w=1000',
    'https://images.unsplash.com/photo-1515162305285-0293e4767cc2?q=80&w=1000',
  ];

  @override
  void initState() {
    super.initState();
    // Auto-slider Banner
    Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_pageController.hasClients) {
        if (_currentPage < bannerImages.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
    fetchWelcomeData();
    fetchPortfolioNews();
  }

  // --- Fungsi-fungsi fetch data, dispose, _navigateTo, _handleLogout tidak perlu diubah ---
  Future<void> fetchWelcomeData() async {
    try {
      final uri = Uri.parse("$_apiBaseUrl/get_welcome.php?api_key=${ApiConfig.apiKey}");
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          print("fetchWelcomeData Error: Respons kosong.");
          setState(() => isWelcomeLoading = false);
          return;
        }
        String decodedString = utf8.decode(base64.decode(response.body.trim()));
        setState(() {
          welcomeData = json.decode(decodedString);
          isWelcomeLoading = false;
        });
      } else {
        print("fetchWelcomeData Error: Status Code: ${response.statusCode}");
        setState(() => isWelcomeLoading = false);
      }
    } catch (e) {
      ErrorHandler.logError(e);
      setState(() => isWelcomeLoading = false);
      // Error tidak ditampilkan ke user karena ini background fetch
    }
  }

  Future<void> fetchPortfolioNews() async {
    setState(() => isNewsLoading = true);
    try {
      final uri = Uri.parse("$_apiBaseUrl/get_portfolio.php?api_key=${ApiConfig.apiKey}");
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          print("fetchPortfolioNews Error: Respons kosong.");
          setState(() => isNewsLoading = false);
          return;
        }

        String decodedString = utf8.decode(base64.decode(response.body.trim()));
        final dynamic decodedData = json.decode(decodedString);
        setState(() {
          if (decodedData is List) {
            portfolioNews = decodedData;
          } else {
            print("fetchPortfolioNews Error: Format data bukan List.");
            portfolioNews = [];
          }
          isNewsLoading = false;
        });
      } else {
        print("fetchPortfolioNews Error: Status Code: ${response.statusCode}");
        setState(() => isNewsLoading = false);
      }
    } catch (e) {
      print("fetchPortfolioNews Exception: ${e.toString()}");
      setState(() => isNewsLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              // Clear login data
              await AuthService.logout();
              
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
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
          // 1. HEADER
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
                  GestureDetector(
                    // --- PERBAIKAN 2: Gunakan userId yang diterima dari widget ---
                    onTap: () => _navigateTo(ProfilePage(userId: widget.userId)),
                    child: const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("HKBP Pondok Kopi",
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        // --- PERBAIKAN 3: Tampilkan nama jemaat yang login ---
                        Text(
                          "Selamat Datang Keluarga, "
                              "\n${widget.userFullName}",
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                          overflow: TextOverflow.ellipsis, // Mencegah teks terlalu panjang
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
                    onPressed: _handleLogout,
                  )
                ],
              ),
            ),
          ),

          // --- SISA KONTEN TIDAK PERLU DIUBAH ---
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                _buildModernBanner(),
                const SizedBox(height: 25),
                const Text("Layanan Gereja",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 15),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.75,
                  children: [
                    _buildModernMenuItem(Icons.calendar_today_rounded, "Kegiatan", Colors.blue, () => _navigateTo(const CalendarPage())),
                    _buildModernMenuItem(Icons.menu_book_rounded, "Warta", Colors.green, () => _navigateTo(const NewsBulletinPage())),
                    _buildModernMenuItem(Icons.assignment_rounded, "Formulir", Colors.purple, () => _navigateTo(const DocumentPage())),
                    _buildModernMenuItem(Icons.account_balance_wallet_rounded, "Laporan", Colors.red, () => _navigateTo(const FinancialReportPage())),
                    _buildModernMenuItem(Icons.people_alt_rounded, "Majelis", Colors.orange, () => _navigateTo(const ClergyPage())),
                    _buildModernMenuItem(Icons.home_work, "Gedung Serba Guna", Colors.brown, () => _navigateTo(const GedungSerbagunaPage())),
                    _buildModernMenuItem(Icons.auto_stories, "Alkitab", Colors.indigo, () => _navigateTo(const Home())),
                    _buildModernMenuItem(Icons.business_center_rounded, "Sekretariat", Colors.teal, () => _navigateTo(const ContactPage())),
                  ],
                ),
                const SizedBox(height: 25),
                _buildPremiumPastorGreeting(),
                const SizedBox(height: 25),
                const Text("Berita Terbaru",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 10),
                isNewsLoading
                    ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    : portfolioNews.isEmpty
                    ? const Center(child: Text("Belum ada berita terbaru"))
                    : Column(
                  children: [
                    ...(_showAllNews ? portfolioNews : portfolioNews.take(5))
                        .map((item) {
                      return _buildModernNewsItem(
                        item['title'] ?? "",
                        item['tgl'] ?? "",
                        image: item['main_image'],
                        content: item['isi_news'],
                        onTap: () => _navigateTo(NewsDetailPage(newsItem: item)),
                      );
                    }),
                    if (portfolioNews.length > 5)
                      TextButton.icon(
                        onPressed: () => setState(() => _showAllNews = !_showAllNews),
                        icon: Icon(_showAllNews ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                        label: Text(
                          _showAllNews ? "Tampilkan Sedikit" : "Lihat Lainnya (${portfolioNews.length - 5})",
                          style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 25),
                const Text("Hubungi Kami", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _buildContactSection(),
                const SizedBox(height: 50),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // --- Semua widget builder helper di bawah ini tidak perlu diubah ---
  Widget _buildPremiumPastorGreeting() {
    if (isWelcomeLoading) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    if (welcomeData == null) return const SizedBox();
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue[900]!, Colors.blue[700]!]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white24,
            child: CircleAvatar(
              radius: 37,
              backgroundImage: CachedNetworkImageProvider('https://hkbppondokkopi.org/assets/img/team/pdt_benget.jpg'),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            welcomeData!['jdl_utama'] ?? "",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 5),
          Text(
            welcomeData!['jdl_sub'] ?? "",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 15),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: HtmlWidget(
                welcomeData!['isi_welcome'] ?? "",
                textStyle: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Divider(color: Colors.white24, thickness: 1),
          const SizedBox(height: 10),
          Text(
            welcomeData!['nm_pendeta'] ?? "",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ]));
  }

  Widget _buildModernNewsItem(String title, String date, {String? image, String? content, VoidCallback? onTap}) {
    String imageUrl = (image != null && image.isNotEmpty) ? "https://hkbppondokkopi.org/upload/$image" : "";
    String cleanContent = content != null ? content.replaceAll(RegExp(r'<[^>]*>'), '').trim() : "";
    return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))]),
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[100],
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[100],
                        child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 24),
                      ),
                    )
                        : Container(
                      width: 80,
                      height: 80,
                      color: Colors.blue[50],
                      child: const Icon(Icons.newspaper, color: Colors.blue, size: 24),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(date, style: TextStyle(color: Colors.blue[900], fontSize: 10, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(cleanContent,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 30),
                    child: Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                  ),
                ]))));
  }

  Widget _buildContactSection() {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Row(children: [
          const Icon(Icons.headset_mic, color: Colors.teal, size: 30),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Butuh Bantuan?", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Hubungi sekretariat HKBP", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
          ElevatedButton(
            onPressed: () => _navigateTo(const ContactPage()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text("Kontak", style: TextStyle(color: Colors.white)),
          ),
        ]));
  }

  Widget _buildModernBanner() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (int page) => setState(() => _currentPage = page),
          itemCount: bannerImages.length,
          itemBuilder: (context, index) => Image.network(bannerImages[index], fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildModernMenuItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w500)),
        ]));
  }
}
