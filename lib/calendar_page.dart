import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  // State variables
  List<dynamic> _allEvents = [];
  bool _isLoading = true;
  bool _showAllEvents = false;
  String _errorMessage = "";

  // 1. VARIABLE FILTER
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month; // 1-12

  final List<String> _monthNames = [
    "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
    "Jul", "Agu", "Sep", "Okt", "Nov", "Des"
  ];

  @override
  void initState() {
    super.initState();
    fetchSermons();
  }

  // LOGIKA PENGAMBILAN DATA (API)
  // LOGIKA PENGAMBILAN DATA (DENGAN DECODE BASE64)
  Future<void> fetchSermons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      // CATATAN: Gunakan 10.0.2.2 untuk Android Emulator.
      // Jika pakai iOS Simulator, gunakan 'localhost'.
      final response = await http.get(
        Uri.parse("https://hkbppondokkopi.org/api_hkbp/get_sermons.php?api_key=RAHASIA_HKBP_2024"),
      ).timeout(const Duration(seconds: 10));

     // Uri.parse("http://127.0.0.1/HKBP/api_hkbp/get_sermons.php?api_key=RAHASIA_HKBP_2024"),
    //).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // 1. Ambil string Base64 dari body respon
        String encodedData = response.body;

        // 2. Dekripsi / Decode dari Base64 ke String JSON asli
        // Menggunakan utf8.decode untuk menangani karakter spesial
        String decodedString = utf8.decode(base64.decode(encodedData.trim()));

        setState(() {
          final dynamic decodedData = json.decode(decodedString);

          if (decodedData is List) {
            _allEvents = decodedData;
          } else if (decodedData is Map && decodedData.containsKey('error')) {
            _errorMessage = decodedData['error'];
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Server error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error Koneksi Calendar: $e");
      setState(() {
        _errorMessage = "Gagal terhubung ke server. Pastikan XAMPP menyala.";
        _isLoading = false;
      });
    }
  }


  // 2. FUNGSI UNTUK MEMILIH TAHUN
  Future<void> _selectYear(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Pilih Tahun"),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              initialDate: DateTime(_selectedYear),
              selectedDate: DateTime(_selectedYear),
              onChanged: (DateTime dateTime) {
                setState(() {
                  _selectedYear = dateTime.year;
                  _showAllEvents = false;
                });
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 3. LOGIKA FILTERING & SORTING (Berdasarkan tombol yang dipilih)
    List<dynamic> filteredEvents = _allEvents.where((event) {
      try {
        DateTime dt = DateTime.parse(event['date']);
        return dt.year == _selectedYear && dt.month == _selectedMonth;
      } catch (e) {
        return false;
      }
    }).toList();

    // Urutkan Terbaru ke Terlama
    filteredEvents.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));

    // Logika limit tampilan
    List<dynamic> displayedEvents = _showAllEvents
        ? filteredEvents
        : filteredEvents.take(10).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // HEADER
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 50, 20, 30),
              decoration: const BoxDecoration(
                color: Color(0xFF0D47A1),
                borderRadius: BorderRadius.only(
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
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      ),
                      const Icon(Icons.event_note_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        "Daftar Kegiatan",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 50, top: 5),
                    child: Text(
                      "Daftar kegiatan yang ada di HKBP Pondok Kopi",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),


          // 4. PANEL FILTER (TAHUN & BULAN)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  // Filter Tahun
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Tahun", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                        ActionChip(
                          avatar: const Icon(Icons.calendar_today, size: 16),
                          label: Text("$_selectedYear"),
                          onPressed: () => _selectYear(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Filter Bulan (Horizontal Scroll)

                  // Filter Bulan (Menampilkan 5 tombol pas di layar)
                  // Filter Bulan (Premium Pill-Shaped Design - Tampilan 5 Tombol)
                  Container(
                    height: 45,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _monthNames.length,
                      itemBuilder: (context, index) {
                        bool isSelected = _selectedMonth == (index + 1);

                        // LOGIK: Menghitung lebar agar tepat 5 tombol terlihat di layar
                        double screenWidth = MediaQuery.of(context).size.width;
                        // 30 (padding list) + 40 (total margin antar tombol)
                        double buttonWidth = (screenWidth - 70) / 5;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMonth = index + 1;
                              _showAllEvents = false;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: buttonWidth,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF0D47A1) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade300,
                                width: 1,
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: const Color(0xFF0D47A1).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ] : [],
                            ),
                            child: Center(
                              child: Text(
                                _monthNames[index],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),


                ],
              ),
            ),
          ),

          // 5. DAFTAR DATA
          _isLoading
              ? const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1))),
          )
              : _errorMessage.isNotEmpty
              ? SliverFillRemaining(child: _buildErrorState())
              : filteredEvents.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState())
              : SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildEventCard(displayedEvents[index]),
                childCount: displayedEvents.length,
              ),
            ),
          ),

          // TOMBOL TAMPILKAN SEMUA
          if (filteredEvents.length > 10)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showAllEvents = !_showAllEvents),
                    icon: Icon(_showAllEvents ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                    label: Text(_showAllEvents ? "Tampilkan Sedikit" : "Tampilkan Semua"),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // WIDGET UNTUK KARTU DATA
  Widget _buildEventCard(Map<String, dynamic> event) {
    DateTime date;
    try {
      date = DateTime.parse(event['date']);
    } catch (e) {
      date = DateTime.now();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 70,
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(DateFormat('MMM').format(date).toUpperCase(),
                    style: TextStyle(color: Colors.blue[900], fontSize: 10, fontWeight: FontWeight.bold)),
                Text(DateFormat('dd').format(date),
                    style: TextStyle(color: Colors.blue[900], fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event['title'] ?? "-",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                Text(event['category'] ?? "Sermon",
                    style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(event['time'] ?? "-", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(width: 12),


                  ],
                ),
                Row(
                  children: [

                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(event['location'] ?? "-",
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_outlined, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            "Tidak ada jadwal untuk ${_monthNames[_selectedMonth - 1]} $_selectedYear",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 60, color: Colors.redAccent),
            const SizedBox(height: 15),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 15),
            ElevatedButton(onPressed: fetchSermons, child: const Text("Coba Lagi")),
          ],
        ),
      ),
    );
  }
}
