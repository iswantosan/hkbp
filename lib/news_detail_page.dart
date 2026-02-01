import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:cached_network_image/cached_network_image.dart';


class NewsDetailPage extends StatefulWidget {
  final Map<String, dynamic> newsItem;

  const NewsDetailPage({super.key, required this.newsItem});

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  // Controller untuk mengontrol slide gambar
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Logika Pengambilan Isi Berita
    final String content = widget.newsItem['content'] ??
        widget.newsItem['isi_news'] ??
        "Tidak ada isi berita.";

    // 2. Logika Pengumpulan Gambar (main_image + image1-image5)
    List<String> galleryImages = [];

    if (widget.newsItem['main_image'] != null && widget.newsItem['main_image'] != "") {
      galleryImages.add("https://hkbppondokkopi.org/upload/${widget.newsItem['main_image']}");
    }

    for (int i = 1; i <= 5; i++) {
      String key = 'image$i';
      if (widget.newsItem[key] != null && widget.newsItem[key].toString().trim().isNotEmpty) {
        galleryImages.add("https://hkbppondokkopi.org/upload/${widget.newsItem[key]}");
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Detail Berita", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Galeri Gambar dengan Panah Navigasi
            if (galleryImages.isNotEmpty)
              _buildImageGallery(galleryImages),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.newsItem['title'] ?? "Tanpa Judul",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        widget.newsItem['tgl'] ?? "",
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  const Divider(height: 40, thickness: 1),

                  // Menampilkan isi berita dengan render HTML
                  HtmlWidget(
                    content,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(List<String> images) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Slider Gambar
        Container(
          height: 300, // Tinggi bingkai ditingkatkan sedikit agar lebih proporsional
          width: double.infinity,
          color: const Color(0xFFF1F5F9), // Background abu-abu muda jika gambar tidak memenuhi layar
          child: PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer( // Memungkinkan user untuk zoom gambar jika diinginkan
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  // PERBAIKAN: Menggunakan BoxFit.contain agar seluruh gambar masuk kedalam bingkai
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),

        // Panah Navigasi Kiri
        if (_currentPage > 0)
          Positioned(
            left: 10,
            child: GestureDetector(
              onTap: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),

        // Panah Navigasi Kanan
        if (_currentPage < images.length - 1)
          Positioned(
            right: 10,
            child: GestureDetector(
              onTap: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),

        // Indikator Titik Posisi Gambar
        if (images.length > 1)
          Positioned(
            bottom: 15,
            child: Row(
              children: List.generate(
                images.length,
                    (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? const Color(0xFF0D47A1) // Warna biru HKBP untuk yang aktif
                        : Colors.black26,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
