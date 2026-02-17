import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'utils/error_handler.dart';


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

  // LOGIC DOWNLOAD LENGKAP
  Future<void> _startDownload(BuildContext context, String url, String fileName) async {
    // 1. Inisialisasi Dio dengan Timeout (Sesuai Dio 5.x)
    Dio dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ));

    try {
      // 2. REQUEST IZIN STORAGE (LOGIC ANDROID 10-13+)
      if (Platform.isAndroid) {
        bool hasPermission = false;
        bool isAndroid11Plus = await _isAndroid11OrAbove();
        
        debugPrint('=== PERMISSION CHECK ===');
        debugPrint('Android Version: ${isAndroid11Plus ? "11+" : "10 ke bawah"}');
        
        // UNTUK SEMUA VERSI ANDROID: SELALU REQUEST PERMISSION TERLEBIH DAHULU
        debugPrint('Requesting storage permission...');
        var storageStatus = await Permission.storage.request();
        debugPrint('Storage permission status: ${storageStatus.toString()}');
        debugPrint('Is granted: ${storageStatus.isGranted}');
        debugPrint('Is denied: ${storageStatus.isDenied}');
        debugPrint('Is permanently denied: ${storageStatus.isPermanentlyDenied}');
        
        if (isAndroid11Plus) {
          // Android 11+ (API 30+): Scoped Storage
          // Untuk Android 11+, kita bisa download ke Download folder tanpa permission khusus
          // Tapi tetap cek apakah permission granted untuk kompatibilitas
          if (storageStatus.isGranted) {
            hasPermission = true;
            debugPrint('Android 11+: Storage permission granted');
          } else {
            // Coba request manageExternalStorage sebagai fallback
            debugPrint('Android 11+: Storage denied, trying manageExternalStorage...');
            var manageStatus = await Permission.manageExternalStorage.request();
            debugPrint('ManageExternalStorage status: ${manageStatus.toString()}');
            hasPermission = manageStatus.isGranted;
            
            // Untuk Android 11+, tetap lanjutkan download meskipun permission ditolak
            // karena scoped storage memungkinkan akses ke Download folder tanpa permission
            if (!hasPermission) {
              debugPrint('Android 11+: All permissions denied, but continuing download (scoped storage allows)');
              hasPermission = true; // Android 11+ bisa download tanpa permission
            }
          }
        } else {
          // Android 10 ke bawah (API < 30): Wajib pakai storage permission
          hasPermission = storageStatus.isGranted;
          debugPrint('Android 10-: Storage permission granted: $hasPermission');
          
          // Jika permission ditolak atau permanently denied
          if (!hasPermission) {
            debugPrint('Android 10-: Permission denied, showing dialog...');
            if (context.mounted) {
              final isPermanentlyDenied = storageStatus.isPermanentlyDenied;
              
              // Tampilkan SnackBar error dulu
              _showSnackBar(
                context, 
                isPermanentlyDenied
                    ? 'Izin storage ditolak. Silakan aktifkan izin di Pengaturan aplikasi.'
                    : 'Izin storage diperlukan untuk mengunduh file.',
                Colors.red,
              );
              
              // Tunggu sebentar agar user bisa lihat SnackBar
              await Future.delayed(const Duration(milliseconds: 500));
              
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Izin Storage Diperlukan'),
                  content: Text(
                    isPermanentlyDenied
                        ? 'Izin storage telah ditolak secara permanen. Silakan aktifkan izin storage di Pengaturan aplikasi untuk dapat mengunduh file.\n\nCara:\n1. Klik "Buka Pengaturan"\n2. Cari "Izin" atau "Permissions"\n3. Aktifkan "Storage" atau "Penyimpanan"'
                        : 'Aplikasi memerlukan izin storage untuk menyimpan file. Silakan berikan izin saat diminta.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Buka Pengaturan'),
                    ),
                  ],
                ),
              );
              if (result == true && context.mounted) {
                await openAppSettings();
              }
            }
            debugPrint('Android 10-: Stopping download due to permission denial');
            return; // Stop download jika permission tidak diberikan
          }
        }
        debugPrint('=== PERMISSION CHECK END: hasPermission=$hasPermission ===');
      }

      // 3. TENTUKAN LOKASI PENYIMPANAN (Folder Download)
      Directory? directory;
      if (Platform.isAndroid) {
        bool isAndroid11Plus = await _isAndroid11OrAbove();
        
        if (isAndroid11Plus) {
          // Android 11+: Gunakan getExternalStoragePublicDirectory untuk Download folder
          // Ini tidak memerlukan permission khusus
          try {
            // Coba gunakan path Download yang umum
            final downloadDir = Directory('/storage/emulated/0/Download');
            if (await downloadDir.exists()) {
              directory = downloadDir;
            } else {
              // Fallback: gunakan external storage directory
              directory = await getExternalStorageDirectory();
              if (directory != null) {
                // Coba akses Download folder di external storage
                final downloadPath = '${directory.path}/Download';
                directory = Directory(downloadPath);
                if (!await directory.exists()) {
                  try {
                    await directory.create(recursive: true);
                  } catch (e) {
                    // Jika tidak bisa create, gunakan external storage directory langsung
                    directory = await getExternalStorageDirectory();
                  }
                }
              }
            }
          } catch (e) {
            // Jika semua gagal, gunakan external storage directory
            directory = await getExternalStorageDirectory();
          }
        } else {
          // Android 10 ke bawah: perlu permission, gunakan path biasa
          try {
            directory = Directory('/storage/emulated/0/Download');
            if (!await directory.exists()) {
              directory = await getExternalStorageDirectory();
              if (directory != null) {
                directory = Directory('${directory.path}/Download');
                if (!await directory.exists()) {
                  await directory.create(recursive: true);
                }
              }
            }
          } catch (e) {
            directory = await getExternalStorageDirectory();
          }
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Tidak dapat mengakses folder penyimpanan. Periksa izin aplikasi.');
      }

      // Pastikan directory bisa diakses
      if (!await directory.exists()) {
        try {
          await directory.create(recursive: true);
        } catch (e) {
          throw Exception('Tidak dapat membuat folder Download. Periksa izin storage.');
        }
      }

      // Bersihkan nama file dari karakter ilegal
      String safeFileName = fileName.replaceAll(RegExp(r'[^\w\s]+'), '_');
      String savePath = "${directory.path}/$safeFileName.pdf";
      
      debugPrint('Download path: $savePath');

      // 4. TAMPILKAN LOADING DIALOG
      if (!context.mounted) return;
      _showLoadingDialog(context);

      // 5. PROSES DOWNLOAD
      await dio.download(
        url,
        savePath,
        options: Options(followRedirects: true),
      );

      // 6. TUTUP LOADING & NOTIFIKASI BERHASIL
      if (context.mounted) {
        Navigator.pop(context); // Tutup dialog
        _showSnackBar(context, "Berhasil! File disimpan di folder Download", Colors.green);
      }
    } catch (e) {
      if (context.mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        ErrorHandler.logError(e);
        
        // Error handling yang lebih spesifik untuk download
        String errorMessage;
        final errorString = e.toString().toLowerCase();
        
        if (errorString.contains('permission') || errorString.contains('denied') || errorString.contains('access')) {
          // Cek apakah ini benar-benar permission error atau directory access error
          if (errorString.contains('directory') || errorString.contains('path') || errorString.contains('storage')) {
            errorMessage = 'Tidak dapat mengakses folder Download. Silakan aktifkan izin storage di Pengaturan aplikasi.';
          } else {
            errorMessage = 'Izin storage diperlukan. Silakan aktifkan izin di Pengaturan aplikasi.';
          }
        } else if (errorString.contains('directory') || errorString.contains('path')) {
          errorMessage = 'Tidak dapat mengakses folder Download. Periksa izin storage.';
        } else if (errorString.contains('network') || errorString.contains('connection') || errorString.contains('timeout')) {
          errorMessage = 'Gagal mengunduh. Periksa koneksi internet Anda.';
        } else if (errorString.contains('404') || errorString.contains('not found')) {
          errorMessage = 'File tidak ditemukan di server.';
        } else if (errorString.contains('403') || errorString.contains('forbidden')) {
          errorMessage = 'Akses file ditolak.';
        } else {
          errorMessage = ErrorHandler.getUserFriendlyMessage(e);
        }
        
        _showSnackBar(context, errorMessage, Colors.red);
        
        // Jika error terkait permission, tampilkan dialog juga
        if (errorString.contains('permission') || errorString.contains('denied') || 
            errorString.contains('directory') || errorString.contains('storage')) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (context.mounted) {
            final result = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Izin Storage Diperlukan'),
                content: const Text(
                  'Aplikasi memerlukan izin storage untuk menyimpan file ke folder Download.\n\nSilakan:\n1. Klik "Buka Pengaturan"\n2. Cari "Izin" atau "Permissions"\n3. Aktifkan "Storage" atau "Penyimpanan"\n4. Kembali ke aplikasi dan coba download lagi',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Buka Pengaturan'),
                  ),
                ],
              ),
            );
            if (result == true && context.mounted) {
              await openAppSettings();
            }
          }
        }
      }
    }
  }

  // Helper untuk SnackBar
  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // Helper untuk cek Android version
  Future<bool> _isAndroid11OrAbove() async {
    if (!Platform.isAndroid) return false;
    // Android 11 = API 30
    // Cek Android version dengan mencoba akses manageExternalStorage
    // Permission ini hanya tersedia di Android 11+ (API 30+)
    try {
      // Cek apakah manageExternalStorage permission tersedia (hanya Android 11+)
      await Permission.manageExternalStorage.status;
      // Jika bisa akses status tanpa error, berarti Android 11+
      return true;
    } catch (e) {
      // Jika error, berarti Android 10 ke bawah
      return false;
    }
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