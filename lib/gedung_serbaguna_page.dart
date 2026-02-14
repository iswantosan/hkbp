import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http; // <-- Import http
import 'dart:convert'; // <-- Import convert
import 'config/api_config.dart'; // <-- Import config API Anda
import 'utils/error_handler.dart'; // <-- Import error handler
import 'contact_page.dart';

class GedungSerbagunaPage extends StatefulWidget {
  const GedungSerbagunaPage({super.key});

  @override
  State<GedungSerbagunaPage> createState() => _GedungSerbagunaPageState();
}

class _GedungSerbagunaPageState extends State<GedungSerbagunaPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> galleryImages = [
    'assets/sekre_main.jpeg',
    'assets/sekre1.jpeg',
    'assets/sekre2.jpeg',
    'assets/sekre3.jpeg',
    'assets/sekre4.jpeg',
  ];

  // --- PERUBAHAN 1: Modifikasi State ---
  Map<DateTime, List<Map<String, dynamic>>> _bookingsByDate = {};
  bool _isLoading = true; // State untuk loading indicator

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _selectedBookings = [];
  // `allBookings` (dummy data) dihapus dari sini

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    fetchBookings(); // Panggil fungsi untuk mengambil data dari API
  }

  // --- PERUBAHAN 2: Fungsi Baru untuk Fetch Data dari API ---
  Future<void> fetchBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final uri = Uri.parse("${ApiConfig.baseUrl}/get_booking_list.php?api_key=${ApiConfig.apiKey}");
      final response = await http.get(uri).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted && data['status'] == 'success' && data['data'] is List) {
          final List<dynamic> bookingsFromApi = data['data'];
          final Map<DateTime, List<Map<String, dynamic>>> groupedBookings = {};

          for (var booking in bookingsFromApi) {
            // Parsing tanggal dan waktu dari string
            try {
              final DateTime date = DateFormat('yyyy-MM-dd').parse(booking['tglbooking']);
              final TimeOfDay time = TimeOfDay(
                hour: int.parse(booking['waktu'].split(':')[0]),
                minute: int.parse(booking['waktu'].split(':')[1]),
              );

              // Normalisasi tanggal (kunci map)
              final DateTime normalizedDate = DateTime(date.year, date.month, date.day);

              final bookingData = {
                'nama_pembooking': booking['nm_pembooking'],
                'tujuan_acara': booking['tujuan'],
                'tanggal': date, // Simpan tanggal asli
                'jam_acara': time, // Simpan TimeOfDay
              };

              if (groupedBookings[normalizedDate] == null) {
                groupedBookings[normalizedDate] = [];
              }
              groupedBookings[normalizedDate]!.add(bookingData);

            } catch (e) {
              print("Error parsing booking data: $e");
              // Lewati data yang formatnya salah
            }
          }

          setState(() {
            _bookingsByDate = groupedBookings;
            // Muat booking untuk hari yang dipilih saat ini
            _selectedBookings = _getBookingsForDay(_selectedDay!);
          });
        }
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      if(mounted) {
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getBookingsForDay(DateTime day) {
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);
    return _bookingsByDate[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedBookings = _getBookingsForDay(selectedDay);
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
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
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Gedung Serba Guna",
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Informasi, fasilitas, dan jadwal booking",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.home_work, color: Colors.white, size: 22),
                  )
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  const SizedBox(height: 20),
                  _buildImageGallery(),
                  const SizedBox(height: 25),
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
                  _buildSectionCard(
                    title: "Alamat",
                    icon: Icons.location_on_outlined,
                    iconColor: Colors.red,
                    children: [
                      _buildInfoRow(Icons.location_city_rounded, "Lokasi", "Jl. Arabika I No.6, RT.9/RW.6, Pd. Kopi,Jakarta Timur"),
                      _buildInfoRow(Icons.map_outlined, "Google Maps", "Lihat Peta", isLink: true, onTap: () {
                        _launchURL("https://maps.app.goo.gl/5qHgj67SLxr53UubA");
                      }),
                    ],
                  ),
                  _buildCalendarCard(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: ElevatedButton.icon(
                      onPressed: () {
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
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    return SizedBox(
      height: 150,
      child: PageView.builder(
        controller: _pageController,
        itemCount: galleryImages.length,
        onPageChanged: (page) => setState(() => _currentPage = page),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                galleryImages[index],
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.error_outline, color: Colors.redAccent),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
          const Divider(height: 25, thickness: 0.5),
          ...children,
        ],
      ),
    );
  }

  // --- PERUBAHAN 3: Menambahkan Loading Indicator ---
  Widget _buildCalendarCard() {
    return _buildSectionCard(
      title: "Jadwal Booking",
      icon: Icons.calendar_month_outlined,
      iconColor: Colors.green,
      children: [
        TableCalendar(
          locale: 'id_ID',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: _onDaySelected,
          eventLoader: _getBookingsForDay,
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() => _calendarFormat = format);
            }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(color: Colors.purple[700], shape: BoxShape.circle),
            todayDecoration: BoxDecoration(color: Colors.blue[200], shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(color: Colors.blue[900], shape: BoxShape.circle),
          ),
          headerStyle: const HeaderStyle(
            titleCentered: true,
            formatButtonShowsNext: false,
          ),
        ),
        const SizedBox(height: 16.0),
        const Divider(),
        const SizedBox(height: 8.0),
        if (_isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
        else
          ..._buildBookingDetails(_selectedBookings),
      ],
    );
  }

  List<Widget> _buildBookingDetails(List<Map<String, dynamic>> bookings) {
    if (bookings.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Text("Tidak ada jadwal ter-booking pada tanggal ini.", style: TextStyle(color: Colors.black54)),
          ),
        )
      ];
    }
    return bookings.map((booking) {
      final formattedTime = booking['jam_acara'].format(context);
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(booking['tujuan_acara'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.person, "Pembooking", booking['nama_pembooking']),
            _buildInfoRow(Icons.access_time_filled, "Jam", formattedTime),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isLink = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
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
                  fontWeight: FontWeight.w600,
                  color: isLink ? Colors.blue[700] : const Color(0xFF334155),
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
