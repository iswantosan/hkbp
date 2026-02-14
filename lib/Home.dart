import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'utils/error_handler.dart';


/// Model bertipe untuk satu ayat
class Verse {  final String bookName;
final String bookAbbr;
final int chapter;
final int verse;
final String text;

const Verse({
  required this.bookName,
  required this.bookAbbr,
  required this.chapter,
  required this.verse,
  required this.text,
});
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  /// State utama
  List<Verse> _verses = const [];
  bool _isLoading = true;
  String? _error;

  /// State untuk terjemahan Batak
  Map<String, String> _batakVerses = {}; // Key: "book_chapter_verse", Value: text
  Map<String, bool> _loadingBatak = {}; // Key: "book_chapter_verse", Value: loading state

  /// Variabel filter
  String selectedBook = 'Mat';
  String selectedChapter = '28';
  String startVerse = '16';
  String endVerse = '20';

  /// Controllers agar tidak dibuat ulang setiap build
  late final TextEditingController _chapterCtrl;
  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;

  final List<Map<String, dynamic>> bibleBooks = [
    {
      'category': 'PERJANJIAN LAMA',
      'items': [
        {'code': 'Gen', 'name': 'Kejadian'},
        {'code': 'Exo', 'name': 'Keluaran'},
        {'code': 'Lev', 'name': 'Imamat'},
        {'code': 'Num', 'name': 'Bilangan'},
        {'code': 'Deu', 'name': 'Ulangan'},
        {'code': 'Jos', 'name': 'Yosua'},
        {'code': 'Jud', 'name': 'Hakim-hakim'},
        {'code': 'Rut', 'name': 'Rut'},
        {'code': '1Sa', 'name': '1 Samuel'},
        {'code': '2Sa', 'name': '2 Samuel'},
        {'code': '1Ki', 'name': '1 Raja-raja'},
        {'code': '2Ki', 'name': '2 Raja-raja'},
        {'code': '1Ch', 'name': '1 Tawarikh'},
        {'code': '2Ch', 'name': '2 Tawarikh'},
        {'code': 'Ezr', 'name': 'Ezra'},
        {'code': 'Neh', 'name': 'Nehemia'},
        {'code': 'Est', 'name': 'Ester'},
        {'code': 'Job', 'name': 'Ayub'},
        {'code': 'Psa', 'name': 'Mazmur'},
        {'code': 'Pro', 'name': 'Amsal'},
        {'code': 'Ecc', 'name': 'Pengkhotbah'},
        {'code': 'Sol', 'name': 'Kidung Agung'},
        {'code': 'Isa', 'name': 'Yesaya'},
        {'code': 'Jer', 'name': 'Yeremia'},
        {'code': 'Lam', 'name': 'Ratapan'},
        {'code': 'Eze', 'name': 'Yehezkiel'},
        {'code': 'Dan', 'name': 'Daniel'},
        {'code': 'Hos', 'name': 'Hosea'},
        {'code': 'Joe', 'name': 'Yoel'},
        {'code': 'Amo', 'name': 'Amos'},
        {'code': 'Oba', 'name': 'Obaja'},
        {'code': 'Jon', 'name': 'Yunus'},
        {'code': 'Mic', 'name': 'Mikha'},
        {'code': 'Nah', 'name': 'Nahum'},
        {'code': 'Hab', 'name': 'Habakuk'},
        {'code': 'Zep', 'name': 'Zefanya'},
        {'code': 'Hag', 'name': 'Hagai'},
        {'code': 'Zec', 'name': 'Zakharia'},
        {'code': 'Mal', 'name': 'Maleakhi'},
      ]
    },
    {
      'category': 'PERJANJIAN BARU',
      'items': [
        {'code': 'Mat', 'name': 'Matius'},
        {'code': 'Mar', 'name': 'Markus'},
        {'code': 'Luk', 'name': 'Lukas'},
        {'code': 'Joh', 'name': 'Yohanes'},
        {'code': 'Act', 'name': 'Kisah Para Rasul'},
        {'code': 'Rom', 'name': 'Roma'},
        {'code': '1Co', 'name': '1 Korintus'},
        {'code': '2Co', 'name': '2 Korintus'},
        {'code': 'Gal', 'name': 'Galatia'},
        {'code': 'Eph', 'name': 'Efesus'},
        {'code': 'Phi', 'name': 'Filipi'},
        {'code': 'Col', 'name': 'Kolose'},
        {'code': '1Th', 'name': '1 Tesalonika'},
        {'code': '2Th', 'name': '2 Tesalonika'},
        {'code': '1Ti', 'name': '1 Timotius'},
        {'code': '2Ti', 'name': '2 Timotius'},
        {'code': 'Tit', 'name': 'Titus'},
        {'code': 'Phm', 'name': 'Filemon'},
        {'code': 'Heb', 'name': 'Ibrani'},
        {'code': 'Jam', 'name': 'Yakobus'},
        {'code': '1Pe', 'name': '1 Petrus'},
        {'code': '2Pe', 'name': '2 Petrus'},
        {'code': '1Jo', 'name': '1 Yohanes'},
        {'code': '2Jo', 'name': '2 Yohanes'},
        {'code': '3Jo', 'name': '3 Yohanes'},
        {'code': 'Jud', 'name': 'Yudas'},
        {'code': 'Rev', 'name': 'Wahyu'},
      ]
    }
  ];

  @override
  void initState() {
    super.initState();
    _chapterCtrl = TextEditingController(text: selectedChapter);
    _startCtrl = TextEditingController(text: startVerse);
    _endCtrl = TextEditingController(text: endVerse);
    _fetchData();
  }

  @override
  void dispose() {
    _chapterCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  String _buildPassage() {
    final ch = int.tryParse(selectedChapter) ?? 1;
    final sv = int.tryParse(startVerse) ?? 1;
    final ev = int.tryParse(endVerse) ?? sv;
    final start = sv <= 0 ? 1 : sv;
    final end = (ev < start) ? start : ev;

    return (start == end)
        ? "$selectedBook $ch:$start"
        : "$selectedBook $ch:$start-$end";
  }

  String _cleanText(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .trim();
  }

  /// Mapping kode kitab ke nama untuk API
  String _getBookNameForAPI(String code) {
    final allBooks = bibleBooks.expand((cat) => cat['items'] as List).toList();
    final book = allBooks.firstWhere(
      (b) => b['code'] == code,
      orElse: () => {'name': 'Matius'},
    );
    return book['name'] as String;
  }

  /// Mapping nama kitab ke URL path WordPress
  String _getBookUrlPath(String bookName, int chapter) {
    // Mapping nama kitab ke format URL WordPress
    final bookMap = {
      'Kejadian': 'kejadian-1-musa',
      'Keluaran': 'keluaran-2-musa',
      'Imamat': 'imamat-3-musa',
      'Bilangan': 'bilangan-4-musa',
      'Ulangan': 'ulangan-5-musa',
      'Yosua': 'yosua',
      'Hakim-hakim': 'hakim-hakim',
      'Rut': 'rut',
      '1 Samuel': '1-samuel',
      '2 Samuel': '2-samuel',
      '1 Raja-raja': '1-raja-raja',
      '2 Raja-raja': '2-raja-raja',
      '1 Tawarikh': '1-tawarikh',
      '2 Tawarikh': '2-tawarikh',
      'Ezra': 'ezra',
      'Nehemia': 'nehemia',
      'Ester': 'ester',
      'Ayub': 'ayub',
      'Mazmur': 'mazmur',
      'Amsal': 'amsal',
      'Pengkhotbah': 'pengkhotbah',
      'Kidung Agung': 'kidung-agung',
      'Yesaya': 'yesaya',
      'Yeremia': 'yeremia',
      'Ratapan': 'ratapan',
      'Yehezkiel': 'yehezkiel',
      'Daniel': 'daniel',
      'Hosea': 'hosea',
      'Yoel': 'yoel',
      'Amos': 'amos',
      'Obaja': 'obaja',
      'Yunus': 'yunus',
      'Mikha': 'mikha',
      'Nahum': 'nahum',
      'Habakuk': 'habakuk',
      'Zefanya': 'zefanya',
      'Hagai': 'hagai',
      'Zakharia': 'zakharia',
      'Maleakhi': 'maleakhi',
      'Matius': 'matius',
      'Markus': 'markus',
      'Lukas': 'lukas',
      'Yohanes': 'yohanes',
      'Kisah Para Rasul': 'kisah-para-rasul',
      'Roma': 'roma',
      '1 Korintus': '1-korintus',
      '2 Korintus': '2-korintus',
      'Galatia': 'galatia',
      'Efesus': 'efesus',
      'Filipi': 'filipi',
      'Kolose': 'kolose',
      '1 Tesalonika': '1-tesalonika',
      '2 Tesalonika': '2-tesalonika',
      '1 Timotius': '1-timotius',
      '2 Timotius': '2-timotius',
      'Titus': 'titus',
      'Filemon': 'filemon',
      'Ibrani': 'ibrani',
      'Yakobus': 'yakobus',
      '1 Petrus': '1-petrus',
      '2 Petrus': '2-petrus',
      '1 Yohanes': '1-yohanes',
      '2 Yohanes': '2-yohanes',
      '3 Yohanes': '3-yohanes',
      'Yudas': 'yudas',
      'Wahyu': 'wahyu',
    };

    final urlPath = bookMap[bookName] ?? bookName.toLowerCase().replaceAll(' ', '-');
    final isOldTestament = bibleBooks[0]['items'].any((b) => b['name'] == bookName);
    final testament = isOldTestament ? 'perjanjian-lam' : 'perjanjian-baru';
    
    return 'https://bibeltobaindonesia.wordpress.com/$testament/$urlPath/$urlPath-$chapter/';
  }

  /// Scrape terjemahan Batak dari WordPress
  Future<String?> _scrapeBatakVerse(String bookName, int chapter, int verse) async {
    try {
      final url = _getBookUrlPath(bookName, chapter);
      debugPrint('Scraping Batak from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        
        // Cari tabel yang berisi ayat-ayat
        final tables = document.querySelectorAll('table');
        
        for (final table in tables) {
          final rows = table.querySelectorAll('tr');
          
          for (final row in rows) {
            final cells = row.querySelectorAll('td');
            
            if (cells.length >= 2) {
              // Kolom pertama biasanya berisi nomor ayat dan teks Batak
              final firstCell = cells[0].text.trim();
              
              // Cek apakah ini ayat yang kita cari
              // Format: "1:1 Teks Batak" atau "1:1" diikuti teks
              if (firstCell.contains('$chapter:$verse') || 
                  firstCell.startsWith('$verse:') ||
                  firstCell.contains(':$verse ')) {
                // Ambil teks Batak (kolom pertama, setelah nomor ayat)
                String batakText = firstCell;
                
                // Hapus nomor ayat dari awal
                batakText = batakText.replaceAll(RegExp(r'^\d+:\d+\s*'), '');
                batakText = batakText.replaceAll(RegExp(r'^$verse:\s*'), '');
                
                // Jika masih kosong, coba ambil dari inner HTML
                if (batakText.isEmpty || batakText.length < 10) {
                  final innerHtml = cells[0].innerHtml;
                  // Cari teks setelah tag penutup nomor ayat
                  final match = RegExp(r'>([^<]+)<').firstMatch(innerHtml);
                  if (match != null) {
                    batakText = match.group(1) ?? '';
                  }
                }
                
                if (batakText.isNotEmpty && batakText.length > 5) {
                  return _cleanText(batakText);
                }
              }
            }
          }
        }
        
        // Alternatif: cari di semua elemen dengan pattern ayat
        final allText = document.body?.text ?? '';
        final versePattern = RegExp(r'$chapter:$verse\s+([^\n]+)', multiLine: true);
        final match = versePattern.firstMatch(allText);
        if (match != null) {
          return _cleanText(match.group(1) ?? '');
        }
      }
      
      return null;
    } catch (e) {
      ErrorHandler.logError(e);
      debugPrint('Error scraping Batak: $e');
      return null;
    }
  }

  /// Fetch terjemahan Batak untuk satu ayat dengan scraping
  Future<void> _fetchBatakVerse(Verse verse) async {
    final key = "${verse.bookAbbr}_${verse.chapter}_${verse.verse}";
    
    // Jika sudah ada, tidak perlu fetch lagi
    if (_batakVerses.containsKey(key)) return;

    setState(() {
      _loadingBatak[key] = true;
    });

    try {
      final bookName = _getBookNameForAPI(verse.bookAbbr);
      final chapter = verse.chapter;
      final verseNum = verse.verse;
      
      // Scrape dari WordPress
      final batakText = await _scrapeBatakVerse(bookName, chapter, verseNum);
      
      if (batakText != null && batakText.isNotEmpty) {
        setState(() {
          _batakVerses[key] = batakText;
          _loadingBatak[key] = false;
        });
      } else {
        setState(() {
          _loadingBatak[key] = false;
          _batakVerses[key] = 'Terjemahan Batak tidak tersedia untuk ayat ini';
        });
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      debugPrint('Error fetching Batak verse: $e');
      if (mounted) {
        setState(() {
          _loadingBatak[key] = false;
          _batakVerses[key] = ErrorHandler.getUserFriendlyMessage(e);
        });
      }
    }
  }

  List<Verse> _parsePassageResponse(dynamic decoded) {
    final result = <Verse>[];
    if (decoded is List) {
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        final res = item['res'];
        if (res is! Map<String, dynamic>) continue;
        for (final bookEntry in res.values) {
          if (bookEntry is! Map<String, dynamic>) continue;
          final info = bookEntry['info'] as Map<String, dynamic>? ?? {};
          final data = bookEntry['data'] as Map<String, dynamic>? ?? {};
          final bookName = info['book_name']?.toString() ?? '';
          final bookAbbr = info['book_abbr']?.toString() ?? '';
          for (final chapterEntry in data.entries) {
            final chapterNum = int.tryParse(chapterEntry.key.toString()) ?? 0;
            final versesMap = chapterEntry.value;
            if (versesMap is! Map<String, dynamic>) continue;
            for (final vObj in versesMap.values) {
              if (vObj is! Map<String, dynamic>) continue;
              final verseNum = int.tryParse(vObj['verse']?.toString() ?? '') ?? 0;
              final text = vObj['text']?.toString() ?? '';
              if (verseNum > 0 && text.isNotEmpty) {
                result.add(Verse(
                  bookName: bookName,
                  bookAbbr: bookAbbr,
                  chapter: chapterNum,
                  verse: verseNum,
                  text: _cleanText(text),
                ));
              }
            }
          }
        }
      }
    } else if (decoded is Map<String, dynamic>) {
      for (final entry in decoded.entries) {
        final v = entry.value;
        if (v is! Map<String, dynamic>) continue;
        final info = v['info'] as Map<String, dynamic>? ?? {};
        final ayt = (v['data'] as Map?)?['ayt'] as Map<String, dynamic>? ?? {};
        final bookName = info['book_name']?.toString() ?? '';
        final bookAbbr = info['book_abbr']?.toString() ?? '';
        final chapterNum = int.tryParse(info['chapter']?.toString() ?? '') ?? 0;
        final verseNum = int.tryParse(info['verse']?.toString() ?? '') ?? 0;
        final text = ayt['text']?.toString() ?? '';
        if (verseNum > 0 && text.isNotEmpty) {
          result.add(Verse(
            bookName: bookName,
            bookAbbr: bookAbbr,
            chapter: chapterNum,
            verse: verseNum,
            text: _cleanText(text),
          ));
        }
      }
    }
    result.sort((a, b) => a.verse.compareTo(b.verse));
    return result;
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final passage = _buildPassage();
    final url = Uri.parse(
      'https://api.ayt.co/v1/passage.php?passage=${Uri.encodeComponent(passage)}&source=yourwebsite.com',
    );

    try {
      final resp = await http.get(url);
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final verses = _parsePassageResponse(decoded);
        setState(() {
          _verses = verses;
          _isLoading = false;
        });
      } else {
        ErrorHandler.logError('HTTP ${resp.statusCode}');
        setState(() {
          _isLoading = false;
          _error = ErrorHandler.getUserFriendlyMessage('HTTP ${resp.statusCode}');
        });
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.logError(e);
      setState(() {
        _isLoading = false;
        _error = ErrorHandler.getUserFriendlyMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. MODERN GRADIENT HEADER
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 20),
                      ),
                      const Icon(Icons.auto_stories_rounded,
                          color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        "Alkitab Digital",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 50),
                    child: Text(
                      "Baca dan cari firman Tuhan setiap hari.",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. FILTER PANEL
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedBook,
                                isExpanded: true,
                                items: bibleBooks.expand((category) {
                                  return [
                                    DropdownMenuItem<String>(
                                      enabled: false,
                                      child: Text(category['category'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.blue)),
                                    ),
                                    ...List<Map<String, dynamic>>.from(
                                        category['items'])
                                        .map((item) {
                                      return DropdownMenuItem<String>(
                                        value: item['code'],
                                        child: Text(item['name'],
                                            style:
                                            const TextStyle(fontSize: 14)),
                                      );
                                    }),
                                  ];
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => selectedBook = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: _buildTextField(_chapterCtrl, "Psl", (v) {
                            selectedChapter = v;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(_startCtrl, "Dari", (v) {
                            startVerse = v;
                          }),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text("s/d",
                              style: TextStyle(color: Colors.grey)),
                        ),
                        Expanded(
                          child: _buildTextField(_endCtrl, "Ke", (v) {
                            endVerse = v;
                          }),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _fetchData,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[700],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.search, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. CONTENT (LIST OF VERSES)
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: _buildInfoState(Icons.error_outline, _error!),
            )
          else if (_verses.isEmpty)
              SliverFillRemaining(
                child: _buildInfoState(Icons.search_off, "Ayat tidak ditemukan"),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final v = _verses[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "${v.bookName} ${v.chapter}:${v.verse}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _fetchBatakVerse(v),
                                  icon: Icon(
                                    Icons.translate,
                                    size: 16,
                                    color: Colors.orange[700],
                                  ),
                                  label: Text(
                                    'Batak',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Text(
                              v.text,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Color(0xFF334155),
                              ),
                            ),
                            // Tampilkan terjemahan Batak jika sudah di-load
                            Builder(
                              builder: (context) {
                                final key = "${v.bookAbbr}_${v.chapter}_${v.verse}";
                                final isLoading = _loadingBatak[key] ?? false;
                                final batakText = _batakVerses[key];
                                
                                if (isLoading) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Memuat terjemahan Batak...',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                
                                if (batakText != null && batakText.isNotEmpty) {
                                  return Container(
                                    margin: const EdgeInsets.only(top: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.orange[200]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.translate,
                                              size: 14,
                                              color: Colors.orange[700],
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Bahasa Batak Toba',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          batakText,
                                          style: TextStyle(
                                            fontSize: 15,
                                            height: 1.6,
                                            color: Colors.orange[900],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: _verses.length,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  /// Helper untuk Input TextField
  Widget _buildTextField(TextEditingController ctrl, String hint, Function(String) onChg) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: ctrl,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: onChg,
      ),
    );
  }

  /// Helper untuk tampilan Error/Empty
  Widget _buildInfoState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
