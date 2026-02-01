import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart'; // Pastikan package collection sudah ada di pubspec.yaml

// Enum untuk mengelola mode pengelompokan
enum GroupingMode { date, week }

class FinancialDetailPage extends StatefulWidget {
  final Map<String, dynamic> reportData;

  const FinancialDetailPage({super.key, required this.reportData});

  @override
  State<FinancialDetailPage> createState() => _FinancialDetailPageState();
}

class _FinancialDetailPageState extends State<FinancialDetailPage> with SingleTickerProviderStateMixin {
  Future<List<dynamic>>? _incomeDetailsFuture;
  Future<List<dynamic>>? _expenseDetailsFuture;

  final String _apiKey = "RAHASIA_HKBP_2024";
  late TabController _tabController;

  // --- State untuk mengelola mode drill up/down ---
  GroupingMode _groupingMode = GroupingMode.date;

  final Map<int, String> monthNames = {
    1: 'Januari', 2: 'Februari', 3: 'Maret', 4: 'April', 5: 'Mei', 6: 'Juni',
    7: 'Juli', 8: 'Agustus', 9: 'September', 10: 'Oktober', 11: 'November', 12: 'Desember'
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadInitialDetails();
  }

  void _loadInitialDetails() {
    setState(() {
      _incomeDetailsFuture = _fetchDetails("get_income_details.php");
    });
  }

  void _handleTabSelection() {
    if (_tabController.index == 1 && _expenseDetailsFuture == null) {
      setState(() {
        _expenseDetailsFuture = _fetchDetails("get_expense_details.php");
      });
    }
  }

  Future<List<dynamic>> _fetchDetails(String endpoint) async {
    int monthNumber;
    if (widget.reportData['month'] is String) {
      monthNumber = monthNames.entries.firstWhere((entry) => entry.value == widget.reportData['month'], orElse: () => const MapEntry(0, "")).key;
    } else {
      monthNumber = widget.reportData['month'];
    }
    int year = widget.reportData['year'];
    if (monthNumber == 0 || year == 0) throw Exception("Parameter bulan atau tahun tidak valid.");

    final uri = Uri.parse("https://hkbppondokkopi.org/api_hkbp/$endpoint?api_key=$_apiKey&month=$monthNumber&year=$year");
    //final uri = Uri.parse("http://127.0.0.1/HKBP/api_hkbp/$endpoint?api_key=$_apiKey&month=$monthNumber&year=$year");

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      debugPrint("Raw Response from $endpoint: ${response.body}");
      if (response.statusCode == 200) {
        final rawBody = response.body.trim();
        if (rawBody.isEmpty) return [];
        if (rawBody.startsWith('<') || rawBody.startsWith('<b>') || rawBody.startsWith('Notice') || rawBody.startsWith('Fatal error')) {
          throw Exception("Server PHP mengembalikan error HTML, bukan JSON.");
        }
        String decodedString = utf8.decode(base64.decode(rawBody));
        return json.decode(decodedString) as List<dynamic>;
      } else {
        throw Exception("Gagal terhubung ke server. Status: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Terjadi kesalahan saat memproses data: $e");
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  String formatIDR(dynamic amount) {
    num parsedAmount = num.tryParse(amount.toString()) ?? 0;
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(parsedAmount);
  }

  // --- LOGIKA PENGELOMPOKKAN ---

  Map<String, List<dynamic>> _groupDataByDate(List<dynamic> data, String dateKey) {
    data.sort((a, b) {
      final dateA = DateTime.tryParse(a[dateKey] ?? '') ?? DateTime(1900);
      final dateB = DateTime.tryParse(b[dateKey] ?? '') ?? DateTime(1900);
      return dateB.compareTo(dateA);
    });
    return groupBy(data, (item) => (item as Map<String, dynamic>)[dateKey] ?? 'Tanpa Tanggal');
  }

  Map<String, List<dynamic>> _groupDataByWeek(List<dynamic> data, String dateKey) {
    return groupBy(data, (item) {
      final dateString = (item as Map<String, dynamic>)[dateKey];
      final date = DateTime.tryParse(dateString ?? '');
      if (date == null) return 'Tanpa Tanggal';

      final firstDayOfMonth = DateTime(date.year, date.month, 1);
      final dayInMonth = date.day;
      final dayOfWeek = firstDayOfMonth.weekday;
      final weekOfMonth = ((dayInMonth + dayOfWeek - 2) / 7).ceil();
      return 'Minggu ke-$weekOfMonth';
    });
  }

  String _formatDisplayDate(String dateString) {
    if (dateString == 'Tanpa Tanggal') return dateString;
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayMonth = (widget.reportData['month'] is int)
        ? (monthNames[widget.reportData['month']] ?? "Unknown")
        : widget.reportData['month'];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text("Rincian Keuangan", style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.blue[900],
              foregroundColor: Colors.white,
              pinned: true,
              floating: true,
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.yellowAccent,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: "Pemasukan"),
                  Tab(text: "Pengeluaran"),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                color: Colors.blue[800],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Rincian Laporan $displayMonth ${widget.reportData['year']}",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Daftar rincian keuangan gereja pada periode ini.",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            // --- WIDGET UNTUK MENGGANTI MODE GROUP (DRILL UP/DOWN) ---
            SliverToBoxAdapter(
              child: Container(
                color: Colors.blue[800],
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: Center(
                  child: SegmentedButton<GroupingMode>(
                    segments: const <ButtonSegment<GroupingMode>>[
                      ButtonSegment<GroupingMode>(
                          value: GroupingMode.date,
                          label: Text('Per Tanggal'),
                          icon: Icon(Icons.calendar_view_day)),
                      ButtonSegment<GroupingMode>(
                          value: GroupingMode.week,
                          label: Text('Per Minggu'),
                          icon: Icon(Icons.calendar_view_week)),
                    ],
                    selected: <GroupingMode>{_groupingMode},
                    onSelectionChanged: (Set<GroupingMode> newSelection) {
                      setState(() {
                        _groupingMode = newSelection.first;
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white70,
                      selectedForegroundColor: Colors.white,
                      selectedBackgroundColor: Colors.blue.shade900,
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildContent(isIncome: true),
            _buildContent(isIncome: false),
          ],
        ),
      ),
    );
  }

  // --- FUNGSI UTAMA UNTUK ME-RENDER KONTEN TAB SECARA DINAMIS ---
  Widget _buildContent({required bool isIncome}) {
    final future = isIncome ? _incomeDetailsFuture : _expenseDetailsFuture;
    final dateKey = isIncome ? 'tgl_pelean' : 'tgl_pengeluaran';
    final amountKey = isIncome ? 'total_jumlah' : 'total_pengeluaran';
    final emptyMessage = isIncome ? "Tidak ada data pemasukan." : "Tidak ada data pengeluaran.";
    final errorMessage = isIncome ? "Gagal memuat pemasukan:\n" : "Gagal memuat pengeluaran:\n";

    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildErrorState("$errorMessage${snapshot.error}");
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(emptyMessage);
        }

        // --- Logika Dinamis untuk Pengelompokan ---
        final Map<String, List<dynamic>> groupedData;
        if (_groupingMode == GroupingMode.date) {
          groupedData = _groupDataByDate(snapshot.data!, dateKey);
        } else {
          groupedData = _groupDataByWeek(snapshot.data!, dateKey);
        }

        final groupKeys = groupedData.keys.toList();
        if (_groupingMode == GroupingMode.week) {
          groupKeys.sort((a, b) {
            if (a.startsWith('Minggu') && b.startsWith('Minggu')) {
              final weekA = int.tryParse(a.split('-').last) ?? 0;
              final weekB = int.tryParse(b.split('-').last) ?? 0;
              return weekB.compareTo(weekA); // Minggu terbesar (terbaru) di atas
            }
            return a.compareTo(b);
          });
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: groupKeys.length,
          itemBuilder: (context, index) {
            final groupKey = groupKeys[index];
            final itemsInGroup = groupedData[groupKey]!;

            // --- Menghitung total jumlah untuk grup ini ---
            final double totalPerGroup = itemsInGroup.fold(0.0, (sum, item) {
              final amount = num.tryParse(item[amountKey]?.toString() ?? '0') ?? 0;
              return sum + amount;
            });

            final displayTitle = _groupingMode == GroupingMode.date ? _formatDisplayDate(groupKey) : groupKey;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGroupHeader(
                  title: displayTitle,
                  total: totalPerGroup,
                  isIncome: isIncome,
                ),
                ...itemsInGroup.map((item) {
                  return isIncome ? _buildIncomeCard(item) : _buildExpenseCard(item);
                }),
              ],
            );
          },
        );
      },
    );
  }

  // --- WIDGET HELPER UNTUK HEADER GRUP ---
  Widget _buildGroupHeader({required String title, required double total, required bool isIncome}) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0, right: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[800]),
            ),
          ),
          Text(
            formatIDR(total),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isIncome ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDER LAINNYA (CARD, INFO ROW, EMPTY, ERROR) ---

  Widget _buildIncomeCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: Colors.green.shade600, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item['jenis_pemasukan'] ?? 'Lain-lain',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ),
              Text(
                formatIDR(item['total_jumlah']),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15),
              ),
            ],
          ),
          const Divider(height: 15),
          _buildInfoRow(Icons.category, "Kategori:", item['nama_pemasukan'] ?? '-'),
          _buildInfoRow(Icons.person, "Dari:", item['nama_keluarga'] ?? '-'),
          if (item['wilayah'] != null) _buildInfoRow(Icons.location_on, "Wilayah:", item['wilayah']),
          if (item['keterangan'] != null && item['keterangan'].toString().isNotEmpty) _buildInfoRow(Icons.notes, "Ket:", item['keterangan']),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: Colors.red.shade600, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item['nama_pengeluaran'] ?? 'Lain-lain',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ),
              Text(
                formatIDR(item['total_pengeluaran']),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15),
              ),
            ],
          ),
          const Divider(height: 15),
          _buildInfoRow(Icons.category, "Kategori:", item['jenis_pengeluaran'] ?? '-'),
          if (item['keterangan'] != null && item['keterangan'].toString().isNotEmpty) _buildInfoRow(Icons.notes, "Ket:", item['keterangan']),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: SingleChildScrollView(
          child: Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[800])),
        ),
      ),
    );
  }
}
