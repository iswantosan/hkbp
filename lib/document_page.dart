import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class DocumentPage extends StatelessWidget {
  const DocumentPage({super.key});

  final List<Map<String, dynamic>> documents = const [
    {
      'title': 'Formulir Pendaftaran Baptis',
      'category': 'Baptis',
      'icon': Icons.water_drop_rounded,
      'color': Colors.blue,
      'url': 'https://hkbppondokkopi.org/assets/download/FormTardidi.pdf'
    },
    {
      'title': 'Formulir Pernikahan (Pamasu-masuon)',
      'category': 'Pernikahan',
      'icon': Icons.favorite_rounded,
      'color': Colors.pink,
      'url': 'https://hkbppondokkopi.org/assets/download/FormPamasumasuon.pdf'
    },
    {
      'title': 'Surat Pendaftaran Jemaat',
      'category': 'Administrasi',
      'icon': Icons.description_rounded,
      'color': Colors.orange,
      'url': 'https://hkbppondokkopi.org/assets/download/FormJemaatBaru.pdf'
    },
    {
      'title': 'Formulir Pendaftaran Sidi',
      'category': 'Pendidikan',
      'icon': Icons.menu_book_rounded,
      'color': Colors.green,
      'url': 'https://hkbppondokkopi.org/assets/download/FormPeneguhanSidi.pdf'
    },
    {
      'title': 'Form Pendaftaran Martupol',
      'category': 'Martupol',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Colors.teal,
      'url': 'https://hkbppondokkopi.org/assets/download/FormMartupol.pdf'
    },
  ];

  // LOGIC DOWNLOAD MENGGUNAKAN ANDROID DOWNLOAD MANAGER
  Future<void> _startDownload(BuildContext context, String url, String fileName) async {
    try {
      // Bersihkan nama file dari karakter ilegal
      String safeFileName = fileName.replaceAll(RegExp(r'[^\w\s]+'), '_');
      String finalFileName = "$safeFileName.pdf";

      if (Platform.isAndroid) {
        // Gunakan Android DownloadManager - lebih reliable dan tidak perlu permission khusus
        const platform = MethodChannel('com.hkbp/download');
        
        try {
          // Tampilkan loading dialog
          if (context.mounted) {
            _showLoadingDialog(context);
          }

          debugPrint("Starting download: url=$url, fileName=$finalFileName");

          // Panggil native method untuk download
          final result = await platform.invokeMethod('downloadFile', {
            'url': url,
            'fileName': finalFileName,
          });

          debugPrint("Download result: $result");

          // Tutup loading dialog
          if (context.mounted) {
            Navigator.pop(context);
          }

          if (result != null) {
            // Download berhasil dimulai (result adalah download ID)
            if (context.mounted) {
              _showSnackBar(
                context, 
                "Download dimulai! File akan disimpan di folder Download", 
                Colors.green
              );
            }
          } else {
            throw PlatformException(
              code: 'DOWNLOAD_FAILED',
              message: 'Download failed to start',
            );
          }
        } on PlatformException catch (e) {
          // Tutup loading dialog jika ada error
          if (context.mounted) {
            if (Navigator.canPop(context)) Navigator.pop(context);
            debugPrint("Platform error: ${e.code} - ${e.message}");
            String errorMessage = "Gagal memulai download.";
            if (e.message != null) {
              errorMessage += " ${e.message}";
            }
            _showSnackBar(context, errorMessage, Colors.red);
          }
        } catch (e) {
          // Tutup loading dialog jika ada error
          if (context.mounted) {
            if (Navigator.canPop(context)) Navigator.pop(context);
            debugPrint("Download error: $e");
            _showSnackBar(
              context, 
              "Gagal memulai download. Periksa koneksi internet Anda.", 
              Colors.red
            );
          }
        }
      } else {
        // Untuk iOS atau platform lain, gunakan fallback
        if (context.mounted) {
          _showSnackBar(
            context, 
            "Platform tidak didukung untuk download", 
            Colors.orange
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        debugPrint("Error: $e");
        _showSnackBar(
          context, 
          "Gagal mengunduh. Periksa koneksi internet Anda.", 
          Colors.red
        );
      }
    }
  }

  // Helper untuk SnackBar
  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // Helper untuk Loading Dialog
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 15),
            Text("Mengunduh dokumen..."),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // HEADER
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 50, 20, 25),
              decoration: BoxDecoration(
                color: Colors.blue[900],
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
                      const SizedBox(width: 4),
                      const Icon(Icons.assignment_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        "Dokumen & Formulir",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 50, right: 20),
                    child: Text(
                      "Unduh formulir pelayanan jemaat HKBP Pondok Kopi dengan mudah.",
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // LIST DOKUMEN
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final doc = documents[index];
                  return _buildDocumentCard(context, doc);
                },
                childCount: documents.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, Map<String, dynamic> doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            height: 50, width: 50,
            decoration: BoxDecoration(color: (doc['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: Icon(doc['icon'], color: doc['color'], size: 26),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc['category'], style: TextStyle(color: doc['color'], fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(doc['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _startDownload(context, doc['url'], doc['title']),
            icon: const Icon(Icons.file_download_outlined, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }
}