import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

// --- Impor yang Dibutuhkan ---
import 'document_page.dart';
import 'contact_page.dart';
import 'calendar_page.dart';
import 'clergy_page.dart';
import 'news_bulletin_page.dart';
import 'financial_report_page.dart';
import 'Home.dart';
import 'news_detail_page.dart';
import 'config/api_config.dart';
import 'profile_page.dart';
import 'gedung_serbaguna_page.dart';
import 'utils/error_handler.dart';
import 'login_page.dart';
import 'services/auth_service.dart';
// ----------------------------

class HomeScreen extends StatefulWidget {
  // Konstruktor tidak lagi memerlukan data login
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // State untuk data dari API
  Map<String, dynamic>? welcomeData;
  List<dynamic> portfolioNews = [];
  List<dynamic> birthdayList = [];
  List<dynamic> anniversaryList = [];

  // State untuk status loading
  bool isWelcomeLoading = true;
  bool isNewsLoading = true;
  bool isBirthdayLoading = true;
  bool isAnniversaryLoading = true;
  bool _showAllNews = false;

  final String _apiBaseUrl = ApiConfig.baseUrl;

  final List<String> bannerImages = [
    'assets/hkbp.jpeg',
    'assets/sekre_main.jpeg',
    'assets/sekre1.jpeg',
    'assets/sekre2.jpeg',
  ];

  @override
  void initState() {
    super.initState();
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
    fetchAllData();
  }

  // Fungsi untuk memuat semua data secara paralel untuk efisiensi
  Future<void> fetchAllData() async {
    setState(() {
      isWelcomeLoading = true;
      isNewsLoading = true;
      isBirthdayLoading = true;
      isAnniversaryLoading = true;
    });

    await Future.wait([
      fetchWelcomeData(),
      fetchPortfolioNews(),
      fetchBirthdayData(),
      fetchAnniversaryData(),
    ]);
  }

  Future<void> fetchWelcomeData() async {
    try {
      final uri = Uri.parse("$_apiBaseUrl/get_welcome.php?api_key=${ApiConfig.apiKey}");
      final response = await http.get(uri).timeout(const Duration(seconds: 35));
      if (mounted && response.statusCode == 200 && response.body.trim().isNotEmpty) {
        try {
          final decodedString = utf8.decode(base64.decode(response.body.trim()));
          final decodedData = json.decode(decodedString);
          if (mounted && decodedData is Map) {
            setState(() => welcomeData = Map<String, dynamic>.from(decodedData));
          }
        } catch (decodeError) {
          ErrorHandler.logError(decodeError, StackTrace.current);
        }
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      // Retry sekali jika gagal (khusus untuk timeout atau network error)
      if (mounted && welcomeData == null) {
        await Future.delayed(const Duration(seconds: 3));
        try {
          final uri = Uri.parse("$_apiBaseUrl/get_welcome.php?api_key=${ApiConfig.apiKey}");
          final response = await http.get(uri).timeout(const Duration(seconds: 35));
          if (mounted && response.statusCode == 200 && response.body.trim().isNotEmpty) {
            try {
              final decodedString = utf8.decode(base64.decode(response.body.trim()));
              final decodedData = json.decode(decodedString);
              if (mounted && decodedData is Map) {
                setState(() => welcomeData = Map<String, dynamic>.from(decodedData));
              }
            } catch (_) {
              // Ignore decode error on retry
            }
          }
        } catch (_) {
          // Ignore retry error - akan tetap set loading false di finally
        }
      }
    } finally {
      if (mounted) setState(() => isWelcomeLoading = false);
    }
  }

  Future<void> fetchPortfolioNews() async {
    try {
      final uri = Uri.parse("$_apiBaseUrl/get_portfolio.php?api_key=${ApiConfig.apiKey}");
      final response = await http.get(uri).timeout(const Duration(seconds: 30));
      if (mounted && response.statusCode == 200 && response.body.trim().isNotEmpty) {
        try {
          final decodedString = utf8.decode(base64.decode(response.body.trim()));
          final decodedData = json.decode(decodedString);
          if (mounted && decodedData is List) {
            setState(() => portfolioNews = decodedData);
          }
        } catch (decodeError) {
          ErrorHandler.logError(decodeError, StackTrace.current);
        }
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
    } finally {
      if (mounted) setState(() => isNewsLoading = false);
    }
  }

  Future<void> fetchBirthdayData() async {
    try {
      final uri = Uri.parse("$_apiBaseUrl/get_birthday_list.php?api_key=${ApiConfig.apiKey}");
      final response = await http.get(uri).timeout(const Duration(seconds: 35));
      List<dynamic> fetchedData = [];
      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        try {
          final data = json.decode(response.body);
          if (data is Map && data['status'] == 'success' && data['data'] is List) {
            fetchedData = data['data'];
          } else if (data is List) {
            fetchedData = data;
          }
        } catch (decodeError) {
          ErrorHandler.logError(decodeError, StackTrace.current);
        }
      }
      fetchedData.sort((a, b) {
        String wijkA = a['wijk']?.toString() ?? '';
        String wijkB = b['wijk']?.toString() ?? '';
        int umurA = a['umur'] is int ? a['umur'] : int.tryParse(a['umur'].toString()) ?? 0;
        int umurB = b['umur'] is int ? b['umur'] : int.tryParse(b['umur'].toString()) ?? 0;
        int wijkCompare = wijkA.compareTo(wijkB);
        return wijkCompare != 0 ? wijkCompare : umurA.compareTo(umurB);
      });
      if (mounted) setState(() => birthdayList = fetchedData);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      // Retry sekali jika gagal
      if (mounted && birthdayList.isEmpty) {
        await Future.delayed(const Duration(seconds: 3));
        try {
          final uri = Uri.parse("$_apiBaseUrl/get_birthday_list.php?api_key=${ApiConfig.apiKey}");
          final response = await http.get(uri).timeout(const Duration(seconds: 35));
          if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
            try {
              final data = json.decode(response.body);
              List<dynamic> fetchedData = [];
              if (data is Map && data['status'] == 'success' && data['data'] is List) {
                fetchedData = data['data'];
              } else if (data is List) {
                fetchedData = data;
              }
              if (mounted) setState(() => birthdayList = fetchedData);
            } catch (_) {
              // Ignore decode error on retry
            }
          }
        } catch (_) {
          // Ignore retry error
        }
      }
    } finally {
      if (mounted) setState(() => isBirthdayLoading = false);
    }
  }

  Future<void> fetchAnniversaryData() async {
    try {
      final uri = Uri.parse("$_apiBaseUrl/get_anniversary_list.php?api_key=${ApiConfig.apiKey}");
      final response = await http.get(uri).timeout(const Duration(seconds: 35));
      List<dynamic> fetchedData = [];
      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        try {
          final data = json.decode(response.body);
          if (data is Map && data['status'] == 'success' && data['data'] is List) {
            fetchedData = data['data'];
          } else if (data is List) {
            fetchedData = data;
          }
        } catch (decodeError) {
          ErrorHandler.logError(decodeError, StackTrace.current);
        }
      }
      fetchedData.sort((a, b) {
        String wijkA = a['wijk']?.toString() ?? '';
        String wijkB = b['wijk']?.toString() ?? '';
        int umurA = a['umur'] is int ? a['umur'] : int.tryParse(a['umur']?.toString() ?? '0') ?? 0;
        int umurB = b['umur'] is int ? b['umur'] : int.tryParse(b['umur']?.toString() ?? '0') ?? 0;
        int wijkCompare = wijkA.compareTo(wijkB);
        return wijkCompare != 0 ? wijkCompare : umurA.compareTo(umurB);
      });
      if (mounted) setState(() => anniversaryList = fetchedData);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      // Retry sekali jika gagal
      if (mounted && anniversaryList.isEmpty) {
        await Future.delayed(const Duration(seconds: 3));
        try {
          final uri = Uri.parse("$_apiBaseUrl/get_anniversary_list.php?api_key=${ApiConfig.apiKey}");
          final response = await http.get(uri).timeout(const Duration(seconds: 35));
          if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
            final data = json.decode(response.body);
            List<dynamic> fetchedData = [];
            if (data is Map && data['status'] == 'success' && data['data'] is List) {
              fetchedData = data['data'];
            } else if (data is List) {
              fetchedData = data;
            }
            if (mounted) setState(() => anniversaryList = fetchedData);
          }
        } catch (_) {
          // Ignore retry error
        }
      }
    } finally {
      if (mounted) setState(() => isAnniversaryLoading = false);
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

  Future<void> _handleProfileClick() async {
    final loginData = await AuthService.getLoginData();
    if (!mounted) return;
    if (loginData != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(userId: loginData['userId'] as int)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: fetchAllData,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
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
                    GestureDetector(
                      onTap: _handleProfileClick,
                      child: const CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("HKBP Pondok Kopi", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text("Selamat Datang di Aplikasi Gereja", style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  _buildModernBanner(),
                  const SizedBox(height: 25),
                  const Text("Layanan Gereja", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
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
                      _buildModernMenuItem(Icons.auto_stories, "Buku", Colors.indigo, () => _navigateTo(const Home())),
                      _buildModernMenuItem(Icons.business_center_rounded, "Sekretariat", Colors.teal, () => _navigateTo(const ContactPage())),
                    ],
                  ),
                  const SizedBox(height: 25),
                  _buildPremiumPastorGreeting(),
                  const SizedBox(height: 25),
                  _buildBirthdayCard(),
                  _buildAnniversaryCard(),
                  const SizedBox(height: 25),
                  const Text("Berita Terbaru", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 10),
                  _buildNewsSection(),
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
      ),
    );
  }

  // --- Widget Builder Helpers ---
  Widget _buildNewsSection() {
    if (isNewsLoading) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    if (portfolioNews.isEmpty) return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text("Belum ada berita terbaru")));
    return Column(
      children: [
        ...(_showAllNews ? portfolioNews : portfolioNews.take(5)).map((item) {
          return _buildModernNewsItem(
            title: item['title'] ?? "",
            date: item['tgl'] ?? "",
            image: item['main_image'],
            onTap: () => _navigateTo(NewsDetailPage(newsItem: item)),
          );
        }),
        if (portfolioNews.length > 5)
          TextButton.icon(
            onPressed: () => setState(() => _showAllNews = !_showAllNews),
            icon: Icon(_showAllNews ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
            label: Text(_showAllNews ? "Tampilkan Sedikit" : "Lihat Lainnya (${portfolioNews.length - 5})", style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildBirthdayCard() {
    if (isBirthdayLoading) return Padding(padding: const EdgeInsets.only(bottom: 20.0), child: _buildShimmerCard(Colors.amber));
    if (birthdayList.isEmpty) return const SizedBox.shrink();
    Map<String, List<dynamic>> groupedByWijk = {};
    for (var item in birthdayList) {
      String wijk = item['wijk']?.toString() ?? 'Lainnya';
      if (groupedByWijk[wijk] == null) groupedByWijk[wijk] = [];
      groupedByWijk[wijk]!.add(item);
    }
    int getWeekOfMonth(DateTime date) => ((date.day - 1) / 7).ceil();
    final weekNumber = getWeekOfMonth(DateTime.now());
    final monthName = DateFormat.MMMM('id_ID').format(DateTime.now());
    final year = DateTime.now().year;
    final weekText = "Minggu ke-$weekNumber $monthName $year";
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.amber[700]!, Colors.amber[500]!]),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Ulang Tahun Minggu Ini",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        weekText,
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...groupedByWijk.entries.map((entry) {
                  String wijk = entry.key;
                  List<dynamic> items = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Text(
                          wijk,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      ...items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              const Icon(Icons.person, color: Color(0xFF64748B), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item['nama_lengkap'] ?? 'N/A',
                                  style: const TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                "${item['umur'] ?? '?'} thn",
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      if (entry != groupedByWijk.entries.last)
                        const Divider(color: Color(0xFFE2E8F0), height: 24, thickness: 0.5),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnniversaryCard() {
    if (isAnniversaryLoading) return Padding(padding: const EdgeInsets.only(bottom: 20.0), child: _buildShimmerCard(Colors.pink));
    if (anniversaryList.isEmpty) return const SizedBox.shrink();
    Map<String, List<dynamic>> groupedByWijk = {};
    for (var item in anniversaryList) {
      String wijk = item['wijk']?.toString() ?? 'Lainnya';
      if (groupedByWijk[wijk] == null) groupedByWijk[wijk] = [];
      groupedByWijk[wijk]!.add(item);
    }
    int getWeekOfMonth(DateTime date) => ((date.day - 1) / 7).ceil();
    final weekNumber = getWeekOfMonth(DateTime.now());
    final monthName = DateFormat.MMMM('id_ID').format(DateTime.now());
    final year = DateTime.now().year;
    final weekText = "Minggu ke-$weekNumber $monthName $year";
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.pink[600]!, Colors.pink[400]!]),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Anniversary Minggu Ini",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        weekText,
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...groupedByWijk.entries.map((entry) {
                  String wijk = entry.key;
                  List<dynamic> items = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Text(
                          wijk,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      ...items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              const Icon(Icons.family_restroom, color: Color(0xFF64748B), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Kel. ${item['nama_lengkap'] ?? 'N/A'}",
                                  style: const TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                "ke-${item['umur'] ?? '-'}",
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      if (entry != groupedByWijk.entries.last)
                        const Divider(color: Color(0xFFE2E8F0), height: 24, thickness: 0.5),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard(Color baseColor) => Container(
    height: 120,
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: baseColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 200, height: 20, color: Colors.white.withOpacity(0.3), margin: const EdgeInsets.only(bottom: 15)),
        Container(width: double.infinity, height: 15, color: Colors.white.withOpacity(0.2), margin: const EdgeInsets.only(bottom: 8)),
        Container(width: 150, height: 15, color: Colors.white.withOpacity(0.2)),
      ],
    ),
  );

  Widget _buildModernMenuItem(IconData icon, String label, Color color, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, color: color, size: 24),
      ),
      const SizedBox(height: 8),
      Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w500)),
    ]),
  );

  Widget _buildPremiumPastorGreeting() {
    if (isWelcomeLoading || welcomeData == null) return _buildShimmerCard(Colors.blue[900]!);
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
            child: CircleAvatar(radius: 37, backgroundImage: CachedNetworkImageProvider('https://hkbppondokkopi.org/assets/img/team/pdt_benget.jpg')),
          ),
          const SizedBox(height: 20),
          Text(welcomeData!['jdl_utama'] ?? "", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 5),
          Text(welcomeData!['jdl_sub'] ?? "", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic)),
          const SizedBox(height: 15),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: HtmlWidget(welcomeData!['isi_welcome'] ?? "", textStyle: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6)),
            ),
          ),
          const SizedBox(height: 15),
          const Divider(color: Colors.white24, thickness: 1),
          const SizedBox(height: 10),
          Text(welcomeData!['nm_pendeta'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ]));
  }

  Widget _buildModernNewsItem({required String title, required String date, String? image, VoidCallback? onTap}) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: image != null && image.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: "https://hkbppondokkopi.org/upload/$image",
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (c, u) => Container(width: 80, height: 80, color: Colors.grey[100], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                errorWidget: (c, u, e) => Container(width: 80, height: 80, color: Colors.grey[100], child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 24)),
              )
                  : Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.newspaper, color: Colors.blue, size: 24),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(date, style: TextStyle(color: Colors.blue[900], fontSize: 10, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildModernBanner() => SizedBox(
    height: 200,
    child: PageView.builder(
      controller: _pageController,
      itemCount: bannerImages.length,
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemBuilder: (context, index) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          bannerImages[index],
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) {
                return child;
              }
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: frame != null
                    ? child
                    : Container(
                        key: ValueKey('loading-$index'),
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                      ),
              );
            },
            errorBuilder: (c, e, s) {
              // Log error untuk debugging
              print('Error loading image: ${bannerImages[index]}');
              print('Error: $e');
              return Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 40),
                      SizedBox(height: 8),
                      Text(
                        'Gambar tidak dapat dimuat',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
    ),
  );

  Widget _buildContactSection() => Container(
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
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
          child: const Text("Kontak"),
        ),
      ]));
}
