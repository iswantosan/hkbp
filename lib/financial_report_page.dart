import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'financial_detail_page.dart'; // Import halaman detail
import 'config/api_config.dart';
import 'utils/error_handler.dart';


class FinancialReportPage extends StatefulWidget {
  const FinancialReportPage({super.key});

  @override
  State<FinancialReportPage> createState() => _FinancialReportPageState();
}

class _FinancialReportPageState extends State<FinancialReportPage> {
  // STATE
  int selectedYear = DateTime.now().year;
  List<dynamic> monthlyReports = [];
  List<dynamic> annualTotals = [];
  List<dynamic> persembahanList = [];
  List<dynamic> diakoniaList = [];
  bool isLoading = true;
  bool isPersembahanLoading = false;
  bool isDiakoniaLoading = false;

  // Data statis untuk filter tahun
  final List<int> yearList = [2026, 2025, 2024, 2023];

  // Menggunakan Map untuk menghubungkan angka bulan dengan namanya
  final Map<int, String> monthNames = {
    1: 'Januari', 2: 'Februari', 3: 'Maret', 4: 'April', 5: 'Mei', 6: 'Juni',
    7: 'Juli', 8: 'Agustus', 9: 'September', 10: 'Oktober', 11: 'November', 12: 'Desember'
  };

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // Fungsi untuk memanggil semua API secara bersamaan
  Future<void> _loadAllData() async {
    setState(() => isLoading = true);
    await Future.wait([
      _fetchFinancialTotals(),
      _fetchFinancialReports(),
      _fetchPersembahan(),
      _fetchDiakoniaSosial(),
    ]);
    setState(() => isLoading = false);
  }

  // API untuk total tahunan (vw_laporan_keuangan_total)
  Future<void> _fetchFinancialTotals() async {
    try {

      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/get_financial_total.php?api_key=${ApiConfig.apiKey}"),

         // final response = await http.get(
      //Uri.parse("${ApiConfig.devBaseUrl}/get_financial_total.php?api_key=${ApiConfig.apiKey}"),


    ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        String decodedString = utf8.decode(base64.decode(response.body.trim()));
        final List<dynamic> decodedData = json.decode(decodedString);
        setState(() => annualTotals = decodedData);
      }
    } catch (e) {
      ErrorHandler.logError(e);
      // Error tidak ditampilkan ke user karena ini background fetch
    }
  }

  // API untuk laporan bulanan (vw_laporan_keuangan_bulanan)
  Future<void> _fetchFinancialReports() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/get_financial_report.php?api_key=${ApiConfig.apiKey}"),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        String decodedString = utf8.decode(base64.decode(response.body.trim()));
        final List<dynamic> decodedData = json.decode(decodedString);
        setState(() => monthlyReports = decodedData);
      }
    } catch (e) {
      ErrorHandler.logError(e);
      // Error tidak ditampilkan ke user karena ini background fetch
    }
  }

  // API untuk mengambil semua data persembahan dari semua jemaat
  Future<void> _fetchPersembahan() async {
    setState(() => isPersembahanLoading = true);
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/get_persembahan.php?api_key=${ApiConfig.apiKey}"),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        String decodedString = utf8.decode(base64.decode(response.body.trim()));
        final List<dynamic> decodedData = json.decode(decodedString);
        setState(() => persembahanList = decodedData);
      }
    } catch (e) {
      ErrorHandler.logError(e);
    } finally {
      if (mounted) setState(() => isPersembahanLoading = false);
    }
  }

  // API untuk mengambil semua data diakonia sosial dari semua jemaat
  Future<void> _fetchDiakoniaSosial() async {
    setState(() => isDiakoniaLoading = true);
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/get_diakonia_sosial.php?api_key=${ApiConfig.apiKey}"),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        String decodedString = utf8.decode(base64.decode(response.body.trim()));
        final List<dynamic> decodedData = json.decode(decodedString);
        setState(() => diakoniaList = decodedData);
      }
    } catch (e) {
      ErrorHandler.logError(e);
    } finally {
      if (mounted) setState(() => isDiakoniaLoading = false);
    }
  }

  String formatIDR(num amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString == "0000-00-00") {
      return "-";
    }
    try {
      return DateFormat('d MMM yyyy', 'id_ID').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }

  void _navigateToDetail(Map<String, dynamic> reportData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FinancialDetailPage(reportData: reportData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter data laporan bulanan hanya untuk tahun yang dipilih di Dropdown
    final currentYearMonthlyReports = monthlyReports.where((report) => report['year'] == selectedYear).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _fetchFinancialTotals(),
            _fetchFinancialReports(),
            _fetchPersembahan(),
            _fetchDiakoniaSosial(),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          // PERBAIKAN: HEADER DISAMAKAN DENGAN HALAMAN LAIN
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 50, 20, 25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[900]!, Colors.blue[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      ),
                      const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        "Laporan Keuangan",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 50, top: 5),
                    child: Text(
                      "Laporan Keuangan Gereja.",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  )
                ],
              ),
            ),
          ),

          // MENAMPILKAN SEMUA RINGKASAN TAHUNAN
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Ringkasan Tahunan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 15),
                  // Looping semua data dari annualTotals
                  ...annualTotals.map((annualData) {
                    num totalHuria = num.tryParse(annualData['total_huria'] ?? '0') ?? 0;
                    num totalSentralisasi = num.tryParse(annualData['total_sentralisasi'] ?? '0') ?? 0;
                    num totalPengeluaran = num.tryParse(annualData['total_pengeluaran'] ?? '0') ?? 0;
                    num totalPemasukan = totalHuria + totalSentralisasi;
                    num sisaSaldo = totalPemasukan - totalPengeluaran;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.indigo[900]!, Colors.indigo[600]!]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "SALDO HKBP PONDOK KOPI",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const Divider(color: Colors.white24),
                          _buildAnnualRow("Total Pemasukan", formatIDR(totalPemasukan), isBold: true),
                          _buildAnnualRow("  • Huria", formatIDR(totalHuria)),
                          _buildAnnualRow("  • Sentralisasi", formatIDR(totalSentralisasi)),
                          const SizedBox(height: 5),
                          _buildAnnualRow("Total Pengeluaran", formatIDR(totalPengeluaran)),
                          const Divider(color: Colors.white24),
                          _buildAnnualRow("Sisa Saldo Akhir", formatIDR(sisaSaldo), isHighlight: true),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // SECTION PERSEMBAHAN DAN DIAKONIA SOSIAL
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Persembahan & Diakonia Sosial", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 15),
                  Column(
                    children: [
                      // Card Persembahan
                      _buildPersembahanCard(),
                      const SizedBox(height: 15),
                      // Card Diakonia Sosial
                      _buildDiakoniaCard(),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // FILTER TAHUN & LIST LAPORAN BULANAN
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Laporan Bulanan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedYear,
                        onChanged: (int? newValue) {
                          if (newValue != null) setState(() => selectedYear = newValue);
                        },
                        items: yearList.map<DropdownMenuItem<int>>((v) => DropdownMenuItem<int>(value: v, child: Text("Tahun $v"))).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  int monthKey = index + 1;
                  String monthName = monthNames[monthKey]!;
                  final reportData = currentYearMonthlyReports.firstWhere(
                        (element) => element['month'] == monthKey,
                    orElse: () => {'month': monthName, 'year': selectedYear},
                  );

                  bool isNoData = reportData.keys.length <= 2;
                  return GestureDetector(
                    onTap: isNoData ? null : () => _navigateToDetail(reportData),
                    child: _buildMonthlyCard(reportData, isNoData),
                  );
                },
                childCount: 12,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
        ),
      ),
    );
  }

  // WIDGET HELPER
  Widget _buildAnnualRow(String label, String value, {bool isBold = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13))),
          Text(value, style: TextStyle(color: isHighlight ? Colors.greenAccent : Colors.white, fontWeight: isBold || isHighlight ? FontWeight.bold : FontWeight.normal, fontSize: isHighlight ? 16 : 14)),
        ],
      ),
    );
  }

  Widget _buildMonthlyCard(Map<String, dynamic> data, bool isNoData) {
    num totalPemasukan = (data['huria'] ?? 0) + (data['sentralisasi'] ?? 0);
    num sisaSaldo = totalPemasukan - (data['pengeluaran'] ?? 0);
    String displayMonth = (data['month'] is int) ? (monthNames[data['month']] ?? "Unknown") : data['month'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isNoData ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isNoData ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: isNoData ? Colors.grey : Colors.blue[900], size: 16),
                const SizedBox(width: 8),
                Text("$displayMonth ${data['year']}", style: TextStyle(color: isNoData ? Colors.grey : Colors.blue[900], fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                if (!isNoData) Icon(Icons.chevron_right, color: Colors.grey[400]) else const Text("Belum ada data", style: TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic)),
              ],
            ),
            if (!isNoData) ...[
              const Divider(height: 20),
              _buildMonthlyDetailRow("Pemasukan Gabungan", formatIDR(totalPemasukan), color: Colors.green[700]!),
              _buildMonthlyDetailRow("  • Huria", formatIDR(data['huria'] ?? 0)),
              _buildMonthlyDetailRow("  • Sentralisasi", formatIDR(data['sentralisasi'] ?? 0)),
              _buildMonthlyDetailRow("Total Pengeluaran", formatIDR(data['pengeluaran'] ?? 0), color: Colors.red[700]!),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Selisih", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(formatIDR(sisaSaldo), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900])),
                  ],
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyDetailRow(String label, String value, {Color color = const Color(0xFF64748B)}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  // Widget untuk card Persembahan
  Widget _buildPersembahanCard() {
    return Container(
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
            child: const Row(
              children: [
                Icon(Icons.volunteer_activism, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Persembahan",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: isPersembahanLoading
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)))
                : persembahanList.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text("Belum ada data", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                      )
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: persembahanList.length,
                          itemBuilder: (context, index) {
                            final item = persembahanList[index];
                            num jumlah = num.tryParse(item['total_jumlah']?.toString() ?? '0') ?? 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['nama_pemasukan'] ?? '-',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                        ),
                                      ),
                                      Text(
                                        formatIDR(jumlah),
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green[700]),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Diberikan oleh: ${item['diberikan_oleh'] ?? '-'}",
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                  Text(
                                    _formatDate(item['tgl_pelean']),
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // Widget untuk card Diakonia Sosial
  Widget _buildDiakoniaCard() {
    return Container(
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
            child: const Row(
              children: [
                Icon(Icons.favorite, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Diakonia Sosial",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: isDiakoniaLoading
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)))
                : diakoniaList.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text("Belum ada data", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                      )
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: diakoniaList.length,
                          itemBuilder: (context, index) {
                            final item = diakoniaList[index];
                            num jumlah = num.tryParse(item['total_pengeluaran']?.toString() ?? '0') ?? 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['nama_pengeluaran'] ?? '-',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                        ),
                                      ),
                                      Text(
                                        formatIDR(jumlah),
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red[700]),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Diberikan kepada: ${item['diberikan_kepada'] ?? '-'}",
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                  Text(
                                    _formatDate(item['tgl_pengeluaran']),
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
