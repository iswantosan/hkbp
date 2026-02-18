import 'dart:convert';
import 'package:flutter/material.dart';
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

/// Model untuk Buku Ende
class BukuEnde {
  final String title;
  final int nomorEnde;
  final int? nomorLogu;
  final String url;
  final String? lyrics; // Teks lagu (akan di-scrape saat dibuka)

  const BukuEnde({
    required this.title,
    required this.nomorEnde,
    this.nomorLogu,
    required this.url,
    this.lyrics,
  });
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  /// State utama
  List<Verse> _verses = const [];
  bool _isLoading = true;
  String? _error;

  /// State untuk terjemahan Batak
  Map<String, String> _batakVerses = {}; // Key: "book_chapter_verse", Value: text
  Map<String, bool> _loadingBatak = {}; // Key: "book_chapter_verse", Value: loading state

  /// State untuk Buku Ende
  List<BukuEnde> _bukuEndeList = [];
  List<BukuEnde> _filteredBukuEndeList = [];
  bool _isLoadingBukuEnde = false;
  String? _bukuEndeError;
  final TextEditingController _searchController = TextEditingController();
  Map<String, String> _bukuEndeLyrics = {}; // Key: URL, Value: lyrics
  Map<String, bool> _loadingLyrics = {}; // Key: URL, Value: loading state

  /// Variabel filter
  String selectedBook = 'Mat';
  String selectedChapter = '28';
  String startVerse = '16';
  String endVerse = '20';

  /// Controllers agar tidak dibuat ulang setiap build
  late final TextEditingController _chapterCtrl;
  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;
  late final TabController _tabController;

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
        {'code': 'Hak', 'name': 'Hakim-hakim'},
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
        {'code': 'Jude', 'name': 'Yudas'},
        {'code': 'Rev', 'name': 'Wahyu'},
      ]
    }
  ];

  /// Helper method untuk mendapatkan semua valid book codes
  Set<String> _getValidBookCodes() {
    return bibleBooks
        .expand((category) => category['items'] as List)
        .map((item) => item['code'] as String)
        .toSet();
  }

  /// Validasi dan perbaiki selectedBook jika tidak valid
  void _validateSelectedBook() {
    final validCodes = _getValidBookCodes();
    if (!validCodes.contains(selectedBook)) {
      selectedBook = 'Mat'; // Reset ke default jika tidak valid
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chapterCtrl = TextEditingController(text: selectedChapter);
    _startCtrl = TextEditingController(text: startVerse);
    _endCtrl = TextEditingController(text: endVerse);
    _searchController.addListener(_onSearchChanged);
    _validateSelectedBook(); // Validasi sebelum fetch data
    _fetchData();
    _fetchBukuEndeList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chapterCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _searchController.dispose();
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
    
    // Mapping alternatif untuk kode yang mungkin berbeda dari API
    final alternativeCodeMap = {
      'Kej': 'Gen',  // API mungkin mengembalikan "Kej" bukan "Gen"
      'Kel': 'Exo',
      'Ima': 'Lev',
      'Bil': 'Num',
      'Ula': 'Deu',
      // Fix: API mungkin mengembalikan "Jude" untuk "Hakim-hakim" (seharusnya "Jud")
      // Tapi kita tidak bisa langsung mapping "Jude" ke "Jud" karena "Jude" adalah kode untuk "Yudas"
      // Jadi kita perlu konteks tambahan atau validasi lebih lanjut
    };
    
    // Cek apakah ada mapping alternatif
    final normalizedCode = alternativeCodeMap[code] ?? code;
    
    try {
      final book = allBooks.firstWhere(
        (b) => b['code'] == normalizedCode || b['code'] == code,
      );
      final bookName = book['name'] as String;
      debugPrint('_getBookNameForAPI: code=$code (normalized=$normalizedCode) -> name=$bookName');
      return bookName;
    } catch (e) {
      debugPrint('_getBookNameForAPI: ERROR - code "$code" (normalized="$normalizedCode") not found! Available codes: ${allBooks.map((b) => b['code']).join(", ")}');
      // Fallback: coba cari berdasarkan code yang mirip atau return code as is
      return code;
    }
  }

  /// Mapping nama kitab ke URL path WordPress
  String _getBookUrlPath(String bookName, int chapter) {
    // Cek apakah Perjanjian Lama atau Baru
    final oldTestamentBooks = bibleBooks[0]['items'] as List;
    final isOldTestament = oldTestamentBooks.any((b) => b['name'] == bookName);
    
    debugPrint('_getBookUrlPath: bookName="$bookName", isOldTestament=$isOldTestament');
    if (!isOldTestament) {
      // Double check - mungkin ada masalah dengan matching
      final newTestamentBooks = bibleBooks[1]['items'] as List;
      final isNewTestament = newTestamentBooks.any((b) => b['name'] == bookName);
      debugPrint('_getBookUrlPath: isNewTestament=$isNewTestament');
      debugPrint('_getBookUrlPath: Old Testament books: ${oldTestamentBooks.map((b) => b['name']).take(5).join(", ")}...');
      debugPrint('_getBookUrlPath: New Testament books: ${newTestamentBooks.map((b) => b['name']).take(5).join(", ")}...');
    }
    
    // Mapping nama kitab ke format URL WordPress
    // Perjanjian Lama menggunakan format: kejadian-1-musa/kejadian-1-{chapter}/
    // Perjanjian Baru menggunakan format: matius-2/matius-2-{chapter}/
    final bookMap = {
      // PERJANJIAN LAMA
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
      // PERJANJIAN BARU - format berbeda: matius-2, markus-2, dll
      'Matius': 'matius-2',
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
    
    // Pastikan testament sudah benar berdasarkan isOldTestament
    // Jika tidak ada di mapping, coba deteksi ulang berdasarkan bookName
    bool finalIsOldTestament = isOldTestament;
    if (!isOldTestament && !bibleBooks[1]['items'].any((b) => b['name'] == bookName)) {
      // Jika tidak ditemukan di kedua kategori, coba cek berdasarkan bookMap
      // Jika ada di bagian PERJANJIAN LAMA di bookMap, gunakan perjanjian-lam
      final oldTestamentKeys = ['Kejadian', 'Keluaran', 'Imamat', 'Bilangan', 'Ulangan', 
                                 'Yosua', 'Hakim-hakim', 'Rut', '1 Samuel', '2 Samuel',
                                 '1 Raja-raja', '2 Raja-raja', '1 Tawarikh', '2 Tawarikh',
                                 'Ezra', 'Nehemia', 'Ester', 'Ayub', 'Mazmur', 'Amsal',
                                 'Pengkhotbah', 'Kidung Agung', 'Yesaya', 'Yeremia', 'Ratapan',
                                 'Yehezkiel', 'Daniel', 'Hosea', 'Yoel', 'Amos', 'Obaja',
                                 'Yunus', 'Mikha', 'Nahum', 'Habakuk', 'Zefanya', 'Hagai',
                                 'Zakharia', 'Maleakhi'];
      if (oldTestamentKeys.contains(bookName)) {
        finalIsOldTestament = true;
        debugPrint('_getBookUrlPath: FIXED - bookName "$bookName" should be Old Testament');
      }
    }
    
    final testament = finalIsOldTestament ? 'perjanjian-lam' : 'perjanjian-baru';
    debugPrint('_getBookUrlPath: final testament=$testament, urlPath=$urlPath');
    
    // Format URL:
    // Perjanjian Lama: /perjanjian-lam/kejadian-1-musa/kejadian-1/ (bukan kejadian-1-musa-1)
    // Perjanjian Baru: /perjanjian-baru/matius-2/matius-{chapter}/ (bukan matius-2-{chapter})
    String chapterUrl;
    if (finalIsOldTestament) {
      // Perjanjian Lama: ekstrak nama kitab dasar dari bookName dan tambahkan chapter
      // Format: {bookName-lowercase-hyphenated}-{chapter}
      // Contoh: 
      //   "Kejadian" -> "kejadian-1"
      //   "Keluaran" -> "keluaran-2"
      //   "1 Samuel" -> "1-samuel-1"
      //   "Kidung Agung" -> "kidung-agung-1"
      final baseBookName = bookName.toLowerCase().replaceAll(' ', '-');
      chapterUrl = '$baseBookName-$chapter';
      debugPrint('_getBookUrlPath: Old Testament - bookName="$bookName" -> baseBookName="$baseBookName" -> chapterUrl="$chapterUrl"');
    } else {
      // Perjanjian Baru: ekstrak nama kitab tanpa suffix angka (misal: matius-2 -> matius)
      // Untuk Matius khusus: matius-2 -> matius-{chapter}
      if (bookName == 'Matius') {
        chapterUrl = 'matius-$chapter';
      } else {
        // Untuk kitab lain, hapus suffix angka di urlPath jika ada
        final baseName = urlPath.replaceAll(RegExp(r'-\d+$'), ''); // Hapus suffix angka seperti -2
        chapterUrl = '$baseName-$chapter';
      }
    }
    
    final finalUrl = 'https://bibeltobaindonesia.wordpress.com/$testament/$urlPath/$chapterUrl/';
    debugPrint('_getBookUrlPath: final URL=$finalUrl');
    return finalUrl;
  }

  /// Mapping dari bookAbbr ke kode alkitab.mobi
  String _getAlkitabMobiCode(String bookAbbr) {
    final Map<String, String> mapping = {
      'Gen': 'Kej', 'Exo': 'Kel', 'Lev': 'Ima', 'Num': 'Bil', 'Deu': 'Ula',
      'Jos': 'Yos', 'Jud': 'Hak', 'Rut': 'Rut',
      '1Sa': '1Sa', '2Sa': '2Sa', '1Ki': '1Ra', '2Ki': '2Ra',
      '1Ch': '1Ta', '2Ch': '2Ta', 'Ezr': 'Ezr', 'Neh': 'Neh', 'Est': 'Est',
      'Job': 'Ayb', 'Psa': 'Mzm', 'Pro': 'Ams', 'Ecc': 'Pkh', 'Sol': 'Kid',
      'Isa': 'Yes', 'Jer': 'Yer', 'Lam': 'Rat', 'Eze': 'Yeh', 'Dan': 'Dan',
      'Hos': 'Hos', 'Joe': 'Yoe', 'Amo': 'Amo', 'Oba': 'Oba', 'Jon': 'Yun',
      'Mic': 'Mik', 'Nah': 'Nah', 'Hab': 'Hab', 'Zep': 'Zef', 'Hag': 'Hag',
      'Zec': 'Zak', 'Mal': 'Mal',
      'Mat': 'Mat', 'Mar': 'Mrk', 'Luk': 'Luk', 'Joh': 'Yoh', 'Act': 'Kis',
      'Rom': 'Rom', '1Co': '1Ko', '2Co': '2Ko', 'Gal': 'Gal', 'Eph': 'Efe',
      'Phi': 'Flp', 'Col': 'Kol', '1Th': '1Te', '2Th': '2Te', '1Ti': '1Ti',
      '2Ti': '2Ti', 'Tit': 'Tit', 'Phm': 'Flm', 'Heb': 'Ibr', 'Jam': 'Yak',
      '1Pe': '1Pt', '2Pe': '2Pt', '1Jo': '1Yo', '2Jo': '2Yo', '3Jo': '3Yo',
      'Jude': 'Yud', 'Rev': 'Why',
    };
    return mapping[bookAbbr] ?? bookAbbr;
  }

  /// Scrape terjemahan Batak dari alkitab.mobi/toba/
  Future<String?> _scrapeBatakVerse(String bookName, int chapter, int verse) async {
    try {
      // Gunakan bookAbbr untuk mendapatkan kode alkitab.mobi
      // Cari bookAbbr dari bookName
      String? bookAbbr;
      for (final category in bibleBooks) {
        for (final book in category['items'] as List) {
          if (book['name'] == bookName) {
            bookAbbr = book['code'];
            break;
          }
        }
        if (bookAbbr != null) break;
      }
      
      if (bookAbbr == null) {
        debugPrint('Book not found: $bookName');
        return null;
      }
      
      final mobiCode = _getAlkitabMobiCode(bookAbbr);
      final url = 'https://alkitab.mobi/toba/$mobiCode/$chapter/$verse/';
      
      debugPrint('Scraping Batak - Book: $bookName ($bookAbbr -> $mobiCode), Chapter: $chapter, Verse: $verse');
      debugPrint('Scraping Batak from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        
        // Cari elemen <p> yang mengandung "Toba:"
        // Format: <p><strong><a href="..."><span class="reftext">Toba:</span></a></strong> (I.) Di mula ni mulana ditompa Debata langit dohot tano on.</p>
        final paragraphs = document.querySelectorAll('p');
          
        for (final p in paragraphs) {
          final text = p.text.trim();
              
          // Cek apakah paragraf ini mengandung "Toba:"
          if (text.contains('Toba:') || p.querySelector('span.reftext') != null) {
            // Ambil semua teks setelah "Toba:"
            // Hapus "Toba:" dan ambil sisa teks
            String batakText = text;
                
            // Hapus "Toba:" dari awal
            batakText = batakText.replaceFirst(RegExp(r'^Toba:\s*'), '');
            
            // Jika masih ada prefix seperti "(I.)" di awal, hapus juga
            batakText = batakText.replaceFirst(RegExp(r'^\([^)]+\)\s*'), '');
            
                batakText = batakText.trim();
                
                if (batakText.isNotEmpty && batakText.length > 5) {
                  return _cleanText(batakText);
                }
          }
        }
        
        // Alternatif: cari dengan selector yang lebih spesifik
        final tobaElement = document.querySelector('p strong a span.reftext');
        if (tobaElement != null) {
          // Cari parent <p> secara manual
          var current = tobaElement.parent;
          while (current != null) {
            if (current.localName == 'p') {
              String batakText = current.text.trim();
              batakText = batakText.replaceFirst(RegExp(r'^Toba:\s*'), '');
              batakText = batakText.replaceFirst(RegExp(r'^\([^)]+\)\s*'), '');
              batakText = batakText.trim();
              
              if (batakText.isNotEmpty && batakText.length > 5) {
            return _cleanText(batakText);
          }
              break;
            }
            current = current.parent;
          }
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
      // Gunakan verse.bookName langsung karena lebih reliable daripada mapping dari bookAbbr
      // API mungkin mengembalikan bookAbbr yang berbeda (misal: "Kej" vs "Gen")
      // Fix: Validasi bookName untuk memastikan tidak ada kesalahan mapping antara "Jud" (Hakim-hakim) dan "Jude" (Yudas)
      String bookName = verse.bookName.isNotEmpty ? verse.bookName : _getBookNameForAPI(verse.bookAbbr);
      
      // Validasi: Jika selectedBook adalah "Jud" (Hakim-hakim) tapi API mengembalikan bookAbbr "Jude" (Yudas)
      // atau bookName "Yudas", berarti API salah. Perbaiki dengan menggunakan selectedBook.
      if (selectedBook == 'Jud') {
        // User memilih Hakim-hakim, jadi pastikan bookName adalah "Hakim-hakim"
        if (bookName == 'Yudas' || verse.bookAbbr == 'Jude') {
          bookName = 'Hakim-hakim';
          debugPrint('Fix: API mengembalikan bookAbbr "${verse.bookAbbr}" atau bookName "$bookName" untuk "Hakim-hakim", diperbaiki ke "Hakim-hakim"');
        }
      }
      // Validasi sebaliknya: Jika selectedBook adalah "Jude" (Yudas) tapi API mengembalikan bookAbbr "Jud" (Hakim-hakim)
      // atau bookName "Hakim-hakim", berarti API salah. Perbaiki dengan menggunakan selectedBook.
      else if (selectedBook == 'Jude') {
        // User memilih Yudas, jadi pastikan bookName adalah "Yudas"
        if (bookName == 'Hakim-hakim' || verse.bookAbbr == 'Jud') {
          bookName = 'Yudas';
          debugPrint('Fix: API mengembalikan bookAbbr "${verse.bookAbbr}" atau bookName "$bookName" untuk "Yudas", diperbaiki ke "Yudas"');
        }
      }
      
      final chapter = verse.chapter;
      final verseNum = verse.verse;
      
      debugPrint('Fetch Batak - verse.bookAbbr: ${verse.bookAbbr}, verse.bookName: ${verse.bookName}, selectedBook: $selectedBook, final bookName: $bookName, chapter: $chapter, verse: $verseNum');
      
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

  /// Helper untuk memperbaiki bookName dan bookAbbr berdasarkan selectedBook
  /// Fix: API mungkin salah mengembalikan "Jude" (Yudas) untuk "Jud" (Hakim-hakim)
  Map<String, String> _fixBookInfo(String apiBookName, String apiBookAbbr) {
    String fixedBookName = apiBookName;
    String fixedBookAbbr = apiBookAbbr;
    
    // Jika selectedBook adalah "Jud" (Hakim-hakim) tapi API mengembalikan "Jude" atau "Yudas"
    if (selectedBook == 'Jud') {
      if (apiBookAbbr == 'Jude' || apiBookName == 'Yudas') {
        fixedBookName = 'Hakim-hakim';
        fixedBookAbbr = 'Jud';
        debugPrint('Fix API response: bookName "$apiBookName" ($apiBookAbbr) -> "Hakim-hakim" (Jud)');
      }
    }
    // Jika selectedBook adalah "Jude" (Yudas) tapi API mengembalikan "Jud" atau "Hakim-hakim"
    else if (selectedBook == 'Jude') {
      if (apiBookAbbr == 'Jud' || apiBookName == 'Hakim-hakim') {
        fixedBookName = 'Yudas';
        fixedBookAbbr = 'Jude';
        debugPrint('Fix API response: bookName "$apiBookName" ($apiBookAbbr) -> "Yudas" (Jude)');
      }
    }
    
    return {'bookName': fixedBookName, 'bookAbbr': fixedBookAbbr};
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
          final apiBookName = info['book_name']?.toString() ?? '';
          final apiBookAbbr = info['book_abbr']?.toString() ?? '';
          
          // Fix bookName dan bookAbbr jika API salah mengembalikan data
          final fixed = _fixBookInfo(apiBookName, apiBookAbbr);
          final bookName = fixed['bookName']!;
          final bookAbbr = fixed['bookAbbr']!;
          
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
        final apiBookName = info['book_name']?.toString() ?? '';
        final apiBookAbbr = info['book_abbr']?.toString() ?? '';
        
        // Fix bookName dan bookAbbr jika API salah mengembalikan data
        final fixed = _fixBookInfo(apiBookName, apiBookAbbr);
        final bookName = fixed['bookName']!;
        final bookAbbr = fixed['bookAbbr']!;
        
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
      // Clear verses terlebih dahulu untuk memastikan data lama tidak ditampilkan
      _verses = [];
      // Clear juga terjemahan Batak yang sudah di-cache
      _batakVerses.clear();
      _loadingBatak.clear();
    });

    final passage = _buildPassage();
    debugPrint('_fetchData: selectedBook=$selectedBook, passage=$passage');
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
      body: Column(
        children: [
          // Header dengan Tab Bar
          Container(
            padding: const EdgeInsets.fromLTRB(15, 60, 25, 0),
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
                      "Buku",
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
                const SizedBox(height: 20),
                // Tab Bar
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'Alkitab Digital'),
                    Tab(text: 'Buku Ende'),
                  ],
                ),
              ],
            ),
          ),
          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Alkitab Digital
                _buildAlkitabDigitalTab(),
                // Tab 2: Buku Ende (kosong dulu)
                _buildBukuEndeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlkitabDigitalTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // FILTER PANEL
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
                                value: _getValidBookCodes().contains(selectedBook) ? selectedBook : 'Mat',
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
                                        const SizedBox(height: 8),
                                        Text(
                                          'Sumber: https://alkitab.mobi/',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.orange[600],
                                            fontStyle: FontStyle.normal,
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
    );
  }

  /// Fetch daftar Buku Ende dari WordPress
  Future<void> _fetchBukuEndeList() async {
    setState(() {
      _isLoadingBukuEnde = true;
      _bukuEndeError = null;
    });

    try {
      final url = 'https://bukuende.wordpress.com/daftar-isi-berdasarkan-abjad/';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        final List<BukuEnde> bukuEndeList = [];

        // Cari semua link yang berisi "Buku Ende No."
        final links = document.querySelectorAll('a');
        
        for (final link in links) {
          final href = link.attributes['href'];
          final text = link.text.trim();
          
          if (href != null && 
              href.contains('bukuende.wordpress.com') &&
              href.contains('/20') && // URL yang valid
              text.isNotEmpty &&
              (text.contains('Buku Ende No.') || text.contains('Buku Logu No.'))) {
            
            // Parse nomor dari text
            // Format: "Judul Lagu (Buku Ende No. 115, Buku Logu No. 59)"
            final endeMatch = RegExp(r'Buku Ende No\.\s*(\d+)').firstMatch(text);
            final loguMatch = RegExp(r'Buku Logu No\.\s*(\d+)').firstMatch(text);
            
            if (endeMatch != null) {
              final nomorEnde = int.tryParse(endeMatch.group(1) ?? '') ?? 0;
              final nomorLogu = loguMatch != null ? int.tryParse(loguMatch.group(1) ?? '') : null;
              
              // Ambil judul lagu (sebelum tanda kurung)
              final titleMatch = RegExp(r'^([^(]+)').firstMatch(text);
              final title = titleMatch?.group(1)?.trim() ?? text;
              
              if (nomorEnde > 0 && title.isNotEmpty) {
                bukuEndeList.add(BukuEnde(
                  title: title,
                  nomorEnde: nomorEnde,
                  nomorLogu: nomorLogu,
                  url: href,
                ));
              }
            }
          }
        }

        // Sort berdasarkan nomor
        bukuEndeList.sort((a, b) => a.nomorEnde.compareTo(b.nomorEnde));

        setState(() {
          _bukuEndeList = bukuEndeList;
          _filteredBukuEndeList = bukuEndeList;
          _isLoadingBukuEnde = false;
        });
      } else {
        setState(() {
          _isLoadingBukuEnde = false;
          _bukuEndeError = 'Gagal memuat daftar Buku Ende';
        });
      }
    } catch (e) {
      ErrorHandler.logError(e);
      if (mounted) {
        setState(() {
          _isLoadingBukuEnde = false;
          _bukuEndeError = ErrorHandler.getUserFriendlyMessage(e);
        });
      }
    }
  }

  /// Fetch detail lagu Buku Ende
  Future<void> _fetchBukuEndeLyrics(String url) async {
    if (_bukuEndeLyrics.containsKey(url)) return;

    setState(() {
      _loadingLyrics[url] = true;
    });

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        
        // Cari konten utama lagu
        // Biasanya ada di div dengan class "entry-content" atau sejenisnya
        final content = document.querySelector('.entry-content') ?? 
                       document.querySelector('.post-content') ??
                       document.querySelector('article');
        
        String lyrics = '';
        if (content != null) {
          print('=== DEBUG BUKU ENDE SCRAPING ===');
          print('Content found: true');
          
          // Hapus elemen share button dan social media sebelum mengambil konten
          // Hapus semua elemen yang terkait dengan share/social media
          content.querySelectorAll('.sharedaddy, .sd-block, .jetpack-share, .social-share, [class*="share"], [class*="facebook"], [class*="twitter"], [id*="share"], [id*="facebook"]').forEach((el) => el.remove());
          
          // Ambil semua <li> elements (setiap <li> adalah satu bait)
          final listItems = content.querySelectorAll('li');
          print('Jumlah <li> ditemukan: ${listItems.length}');
          
          if (listItems.isNotEmpty) {
            for (int i = 0; i < listItems.length; i++) {
              final li = listItems[i];
              final text = li.text.trim();
              print('LI[$i]: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
              
              // Filter konten share/social media
              if (text.isNotEmpty && 
                  !text.toLowerCase().contains('bagikan') &&
                  !text.toLowerCase().contains('suka') &&
                  !text.toLowerCase().contains('komentar') &&
                  !text.toLowerCase().contains('facebook') &&
                  !text.toLowerCase().contains('twitter') &&
                  !text.toLowerCase().contains('whatsapp') &&
                  !text.toLowerCase().contains('share') &&
                  !text.toLowerCase().contains('tweet') &&
                  !text.toLowerCase().contains('like') &&
                  !text.toLowerCase().contains('follow') &&
                  text.length > 3) {
                // Normalisasi: gabung semua baris dalam <li> jadi satu (hapus semua newline, ganti dengan spasi)
                // Lalu hapus spasi berlebihan
                final normalizedText = text.replaceAll(RegExp(r'\s+'), ' ').trim();
                if (normalizedText.isNotEmpty) {
                  if (lyrics.isNotEmpty) {
                    lyrics += '\n\n'; // Setiap <li> dipisahkan dengan double enter
                  }
                  lyrics += normalizedText;
                }
              }
            }
          } else {
            print('Tidak ada <li>, coba ambil dari <p>');
            // Fallback: jika tidak ada <li>, ambil dari paragraf
          final paragraphs = content.querySelectorAll('p');
            print('Jumlah <p> ditemukan: ${paragraphs.length}');
            
            for (int i = 0; i < paragraphs.length; i++) {
              final p = paragraphs[i];
            final text = p.text.trim();
              print('P[$i]: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
              
            if (text.isNotEmpty && 
                !text.toLowerCase().contains('bagikan') &&
                !text.toLowerCase().contains('suka') &&
                !text.toLowerCase().contains('komentar') &&
                !text.toLowerCase().contains('facebook') &&
                !text.toLowerCase().contains('twitter') &&
                !text.toLowerCase().contains('whatsapp') &&
                !text.toLowerCase().contains('share') &&
                !text.toLowerCase().contains('tweet') &&
                !text.toLowerCase().contains('like') &&
                !text.toLowerCase().contains('follow') &&
                  text.length > 3) {
                final normalizedText = text.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
                if (normalizedText.isNotEmpty) {
                  if (lyrics.isNotEmpty) {
                    lyrics += '\n\n';
                  }
                  lyrics += normalizedText;
                }
              }
            }
          }
          
          print('Hasil akhir lyrics length: ${lyrics.length}');
          print('Jumlah newline dalam lyrics: ${lyrics.split('\n').length - 1}');
          print('Preview lyrics (dengan newline terlihat):');
          print(lyrics.substring(0, lyrics.length > 300 ? 300 : lyrics.length).replaceAll('\n', '\\n'));
          print('=== END DEBUG ===');
        } else {
          print('=== DEBUG: Content tidak ditemukan ===');
        }

        if (lyrics.isNotEmpty) {
          // Bersihkan baris kosong berlebihan (maksimal 2 newline antar bait)
          lyrics = lyrics.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
          
          // Hapus teks "Sumber", "Copyrighted", dan teks terkait yang ikut ter-scrape
          lyrics = lyrics
              .replaceAll(RegExp(r'Sumber:.*', caseSensitive: false), '')
              .replaceAll(RegExp(r'Copyrighted.*', caseSensitive: false), '')
              .replaceAll(RegExp(r'Copyright.*', caseSensitive: false), '')
              .replaceAll(RegExp(r'Yayasan Lentera Bangsa.*', caseSensitive: false), '')
              .replaceAll(RegExp(r'bukuende\.wordpress\.com.*', caseSensitive: false), '')
              .replaceAll(RegExp(r'https?://.*', caseSensitive: false), '')
              .replaceAll(RegExp(r'\n{3,}'), '\n\n')
              .trim();
          
          setState(() {
            _bukuEndeLyrics[url] = lyrics;
            _loadingLyrics[url] = false;
          });
        } else {
          setState(() {
            _bukuEndeLyrics[url] = 'Lirik tidak ditemukan';
            _loadingLyrics[url] = false;
          });
        }
      } else {
        setState(() {
          _bukuEndeLyrics[url] = 'Gagal memuat lirik';
          _loadingLyrics[url] = false;
        });
      }
    } catch (e) {
      ErrorHandler.logError(e);
      if (mounted) {
        setState(() {
          _bukuEndeLyrics[url] = ErrorHandler.getUserFriendlyMessage(e);
          _loadingLyrics[url] = false;
        });
      }
    }
  }

  /// Filter daftar berdasarkan search query
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    
    if (query.isEmpty) {
      setState(() {
        _filteredBukuEndeList = _bukuEndeList;
      });
    } else {
      setState(() {
        _filteredBukuEndeList = _bukuEndeList.where((lagu) {
          return lagu.title.toLowerCase().contains(query) ||
                 lagu.nomorEnde.toString().contains(query) ||
                 (lagu.nomorLogu != null && lagu.nomorLogu.toString().contains(query));
        }).toList();
      });
    }
  }

  Widget _buildBukuEndeTab() {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari lagu Buku Ende...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ),
        // Content
        Expanded(
          child: _isLoadingBukuEnde
              ? const Center(child: CircularProgressIndicator())
              : _bukuEndeError != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            _bukuEndeError!,
                            style: const TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchBukuEndeList,
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    )
                  : _filteredBukuEndeList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isNotEmpty
                                    ? 'Tidak ada hasil pencarian'
                                    : 'Tidak ada data',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredBukuEndeList.length,
                          itemBuilder: (context, index) {
                            final lagu = _filteredBukuEndeList[index];
                            return _buildBukuEndeItem(lagu);
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildBukuEndeItem(BukuEnde lagu) {
    final hasLyrics = _bukuEndeLyrics.containsKey(lagu.url);
    final isLoading = _loadingLyrics[lagu.url] ?? false;
    final lyrics = _bukuEndeLyrics[lagu.url];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo[100],
          child: Text(
            '${lagu.nomorEnde}',
            style: TextStyle(
              color: Colors.indigo[900],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          lagu.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          'No. ${lagu.nomorEnde}${lagu.nomorLogu != null ? ' / Logu No. ${lagu.nomorLogu}' : ''}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                hasLyrics ? Icons.expand_less : Icons.expand_more,
                color: Colors.indigo[700],
              ),
        onExpansionChanged: (expanded) {
          if (expanded && !hasLyrics && !isLoading) {
            _fetchBukuEndeLyrics(lagu.url);
          }
        },
        children: [
          if (hasLyrics)
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  // Tampilkan lirik dengan pemisahan yang jelas antar ayat/bagian
                  Builder(
                    builder: (context) {
                      final lyricsText = lyrics ?? 'Lirik tidak tersedia';
                      if (lyricsText == 'Lirik tidak tersedia') {
                        return Text(
                          lyricsText,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Colors.grey[800],
                          ),
                        );
                      }
                      
                      // Bersihkan dan tampilkan lirik dengan spasi yang rapi
                      // Hapus baris kosong berlebihan (maksimal 1 newline antar bait)
                      String cleanedText = lyricsText
                          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
                          .trim();
                          
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cleanedText,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sumber: https://bukuende.wordpress.com/',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            )
          else if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
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
