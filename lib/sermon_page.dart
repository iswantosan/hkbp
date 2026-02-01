import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class SermonPage extends StatefulWidget {
  const SermonPage({super.key});

  @override
  State<SermonPage> createState() => _SermonPageState();
}

class _SermonPageState extends State<SermonPage> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isCalendarExpanded = true; // Set true agar kalender langsung terlihat

  // DATA CONTOH DINAMIS
  late List<Map<String, dynamic>> _sermonEvents;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    int year = _focusedDay.year;
    int month = _focusedDay.month;

    _sermonEvents = [
      {
        'title': 'Sermon LANSIA',
        'time': '10:00 WIB',
        'date': DateTime(year, month, 3),
        'place': 'Ruang Konsistori',
        'firman': 'Mazmur 71:18',
        'category': 'LANSIA',
        'color': Colors.brown,
      },
      {
        'title': 'Sermon AMA (Kaum Bapak)',
        'time': '19:30 WIB',
        'date': DateTime(year, month, 5),
        'place': 'Gedung Serbaguna',
        'firman': 'Yosua 24:15',
        'category': 'AMA',
        'color': Colors.blue,
      },
      {
        'title': 'Sermon PAROMPUAN (Ibu)',
        'time': '16:00 WIB',
        'date': DateTime(year, month, 4),
        'place': 'Gereja (Lantai 1)',
        'firman': 'Amsal 31:30',
        'category': 'PAROMPUAN',
        'color': Colors.pink,
      },
      {
        'title': 'Sermon NAPOSO (Pemuda)',
        'time': '19:00 WIB',
        'date': DateTime(year, month, 6),
        'place': 'Ruang Pemuda',
        'firman': '1 Timotius 4:12',
        'category': 'NAPOSO',
        'color': Colors.orange,
      },
      {
        'title': 'Sermon SKM (Guru Sekolah Minggu)',
        'time': '17:00 WIB',
        'date': DateTime(year, month, 6),
        'place': 'Ruang SKM',
        'firman': 'Matius 19:14',
        'category': 'SKM',
        'color': Colors.green,
      },
      {
        'title': 'Sermon Keluarga Parhalado',
        'time': '19:00 WIB',
        'date': DateTime(year, month, 2),
        'place': 'Gereja Utama',
        'firman': '1 Korintus 15:58',
        'category': 'Parhalado',
        'color': Colors.red,
      },
    ];
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _sermonEvents.where((event) => isSameDay(event['date'], day)).toList();
  }

  List<Map<String, dynamic>> _getFilteredSermons() {
    if (_selectedDay == null) return [];
    // Mengambil semua event yang sesuai dengan tanggal yang dipilih di kalender
    return _sermonEvents.where((e) => isSameDay(e['date'], _selectedDay)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSermons = _getFilteredSermons();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // HEADER DENGAN DESKRIPSI
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 50, 20, 30),
              decoration: BoxDecoration(
                color: Colors.indigo[900],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
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
                      const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        "Jadwal Sermon",
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 50, right: 20, top: 5),
                    child: Text(
                      "Halaman ini menampilkan jadwal persiapan pelayan (Sermon) untuk seluruh kategorial di HKBP Pondok Kopi.",
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // KALENDER
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(_focusedDay),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _isCalendarExpanded = !_isCalendarExpanded),
                        icon: Icon(_isCalendarExpanded ? Icons.keyboard_arrow_up : Icons.calendar_month, color: Colors.indigo),
                      )
                    ],
                  ),
                  if (_isCalendarExpanded)
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2023, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        eventLoader: _getEventsForDay,
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarStyle: const CalendarStyle(
                          markerDecoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                          todayDecoration: BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
                          selectedDecoration: BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
                          outsideDaysVisible: false,
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // JUDUL DAFTAR KEGIATAN
          if (_selectedDay != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                child: Text(
                  "Kegiatan pada ${DateFormat('dd MMMM yyyy').format(_selectedDay!)}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                ),
              ),
            ),

          // LIST SERMON (Menampilkan semua event di tanggal terpilih)
          filteredSermons.isEmpty
              ? const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 50, color: Colors.grey),
                    SizedBox(height: 10),
                    Text("Tidak ada jadwal sermon pada tanggal ini", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          )
              : SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildSermonCard(filteredSermons[index]),
                childCount: filteredSermons.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildSermonCard(Map<String, dynamic> sermon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: (sermon['color'] as Color).withOpacity(0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    sermon['category'].toUpperCase(),
                    style: TextStyle(color: sermon['color'], fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)
                ),
                const Icon(Icons.more_horiz, size: 18, color: Colors.grey),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sermon['title'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _buildInfoRow(Icons.access_time_filled_rounded, "Waktu", sermon['time']),
                _buildInfoRow(Icons.location_on_rounded, "Tempat", sermon['place']),
                _buildInfoRow(Icons.menu_book_rounded, "Firman", sermon['firman'], isItalic: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isItalic = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.indigo[300]),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  fontStyle: isItalic ? FontStyle.italic : FontStyle.normal
              ),
            ),
          ),
        ],
      ),
    );
  }
}