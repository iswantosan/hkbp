import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'config/api_config.dart';
import 'utils/error_handler.dart';

class NewsBulletinPage extends StatefulWidget {
  const NewsBulletinPage({super.key});
  @override
  State<NewsBulletinPage> createState() => _NewsBulletinPageState();
}

class _NewsBulletinPageState extends State<NewsBulletinPage> {
  // State yang ada
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isCalendarExpanded = false;
  bool _isLoading = true;
  List<dynamic> news = [];

  // --- STATE BARU: Untuk filter per minggu ---
  int? _selectedWeek; // Minggu yang sedang dipilih (misal: 1, 2, 3, 4)

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'id_ID';
    _selectedDay = _focusedDay;
    fetchNewsFromDB();
  }

  // --- LOGIKA PENGAMBILAN DATA (TIDAK BERUBAH) ---
  Future<void> fetchNewsFromDB() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/get_news.php?api_key=${ApiConfig.apiKey}"),
      );

      if (response.statusCode == 200) {
        String encodedData = response.body;
        if (encodedData.trim().isEmpty || encodedData.trim().startsWith('<')) {
          throw Exception("Format data dari server tidak valid.");
        }
        String decodedString = utf8.decode(base64.decode(encodedData));
        final dynamic jsonData = json.decode(decodedString);

        setState(() {
          if(jsonData is List) {
            news = jsonData;
          } else if (jsonData is Map) {
            news = [jsonData as Map<String, dynamic>];
          } else {
            news = [];
          }
          _isLoading = false;
        });
      } else {
        throw Exception("Gagal memuat data dari server.");
      }
    } catch (e) {
      ErrorHandler.logError(e);
      if(mounted){
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getUserFriendlyMessage(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return news.where((item) {
      if (item is! Map || item['date'] == null) return false;
      try {
        return isSameDay(DateTime.parse(item['date']), day);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // --- FUNGSI BARU: Untuk mendapatkan jumlah minggu dalam bulan ---
  int _getWeeksInMonth(DateTime date) {
    var firstDay = DateTime(date.year, date.month, 1);
    var lastDay = DateTime(date.year, date.month + 1, 0);
    var totalDaysWithOffset = lastDay.day + firstDay.weekday - 1;
    var weeks = (totalDaysWithOffset / 7).ceil();
    return weeks;
  }

  // --- FUNGSI BARU: Untuk mendapatkan rentang tanggal sebuah minggu ---
  ({DateTime start, DateTime end}) _getDateRangeForWeek(int week, DateTime focusedDate) {
    var firstDayOfMonth = DateTime(focusedDate.year, focusedDate.month, 1);
    var firstDayOfCalendar = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));
    var startDate = firstDayOfCalendar.add(Duration(days: (week - 1) * 7));
    var endDate = startDate.add(const Duration(days: 7));
    return (start: startDate, end: endDate);
  }

  void _showNewsDetail(Map<String, dynamic> item) {
    final String category = item['cat']?.toString() ?? 'UMUM';
    final String title = item['title'] ?? 'Tanpa Judul';
    final String content = item['content'] ?? "Tidak ada deskripsi lengkap.";
    final String dateString = item['date'] ?? DateTime.now().toIso8601String();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(25),
          child: ListView(
            controller: controller,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 25),
              Row(
                children: [
                  Flexible(child: _buildCategoryChip(category)),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('d MMMM yyyy').format(DateTime.parse(dateString)),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), height: 1.3),
              ),
              const Divider(height: 40),
              HtmlWidget(
                content,
                textStyle: const TextStyle(fontSize: 16, height: 1.8, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredNews;
    if (_selectedWeek != null) {
      final dateRange = _getDateRangeForWeek(_selectedWeek!, _focusedDay);
      filteredNews = news.where((item) {
        if (item is! Map || item['date'] == null) return false;
        try {
          DateTime itemDate = DateTime.parse(item['date']);
          return itemDate.isAfter(dateRange.start.subtract(const Duration(days: 1))) && itemDate.isBefore(dateRange.end);
        } catch (e) {
          return false;
        }
      }).toList();
    } else {
      filteredNews = List.from(news);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- PERBAIKAN UI HEADER ---
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(15, 60, 25, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue[900]!, Colors.blue[700]!],
                ),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20)),
                      const Icon(Icons.menu_book_rounded, color: Colors.white, size: 24), // ICON DITAMBAHKAN
                      const SizedBox(width: 10), // Jarak antara ikon dan judul
                      const Expanded(
                        child: Text(
                          "Warta Jemaat",
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 45), // Disesuaikan agar lurus dengan judul
                    child: Text("Informasi terbaru HKBP", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildCalendarTrigger(),
                  if (_isCalendarExpanded) _buildMainCalendar(),
                  const SizedBox(height: 20),
                  _buildWeekFilter(),
                ],
              ),
            ),
          ),
          _isLoading
              ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              : filteredNews.isEmpty
              ? _buildEmptyState()
              : SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildModernNewsCard(filteredNews[index]),
                childCount: filteredNews.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildWeekFilter() {
    int weekCount = _getWeeksInMonth(_focusedDay);
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: weekCount + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            bool isSelected = _selectedWeek == null;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedWeek = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[900] : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? Colors.blue[900]! : Colors.grey[300]!),
                ),
                child: Text("Semua Minggu", style: TextStyle(color: isSelected ? Colors.white : Colors.blue[900], fontWeight: FontWeight.bold)),
              ),
            );
          }
          int weekNumber = index;
          bool isSelected = _selectedWeek == weekNumber;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedWeek = weekNumber;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[900] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? Colors.blue[900]! : Colors.grey[300]!),
              ),
              child: Text("Minggu ke-$weekNumber", style: TextStyle(color: isSelected ? Colors.white : Colors.blue[900], fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(String? cat) {
    final String categoryText = cat?.toUpperCase() ?? 'UMUM';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
      child: Text(
        categoryText,
        style: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildCalendarTrigger() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => setState(() => _isCalendarExpanded = !_isCalendarExpanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: Colors.blue[900], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(_focusedDay),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Icon(_isCalendarExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.blue[900]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCalendar() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: TableCalendar(
        locale: 'id_ID',
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
        calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(color: Colors.orange[600], shape: BoxShape.circle),
            todayDecoration: BoxDecoration(color: Colors.blue.withOpacity(0.3), shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(color: Colors.blue[900], shape: BoxShape.circle)
        ),
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
            _selectedWeek = null;
          });
        },
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
            _isCalendarExpanded = false;
            final dayInMonth = selectedDay.day;
            final firstDayOfMonth = DateTime(selectedDay.year, selectedDay.month, 1);
            final dayOfWeek = firstDayOfMonth.weekday;
            _selectedWeek = ((dayInMonth + dayOfWeek - 2) / 7).ceil();
          });
        },
      ),
    );
  }

  Widget _buildModernNewsCard(Map<String, dynamic> item) {
    final String title = item['title'] ?? 'Tanpa Judul';
    final String content = item['content']?.toString().replaceAll(RegExp(r'<[^>]*>'), '') ?? '';
    final String dateString = item['date'] ?? DateTime.now().toIso8601String();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => _showNewsDetail(item),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildCategoryChip(item['cat']),
                  const Spacer(),
                  Text(
                      DateFormat('EEEE, d MMM', 'id_ID').format(DateTime.parse(dateString)),
                      style: const TextStyle(color: Colors.grey, fontSize: 12)
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF64748B), height: 1.5, fontSize: 13),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("Baca Selengkapnya", style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 5),
                  Icon(Icons.arrow_forward, color: Colors.blue[800], size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 15),
            const Text("Tidak Ada Berita", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                  _selectedWeek == null
                      ? "Belum ada warta untuk bulan ini."
                      : "Belum ada warta untuk minggu ke-$_selectedWeek.",
                  style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
