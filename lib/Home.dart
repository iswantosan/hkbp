import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


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
        setState(() {
          _isLoading = false;
          _error = 'Gagal memuat data (HTTP ${resp.statusCode})';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Terjadi kesalahan jaringan';
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
                            Text(
                              "${v.bookName} ${v.chapter}:${v.verse}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.blue[900],
                              ),
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
