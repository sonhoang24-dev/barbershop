import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../services/api_service.dart';

class ServiceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  List<Map<String, dynamic>> reviews = [];
  bool loading = true;
  final _pageController = PageController();
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('vi', timeago.ViMessages());
    _fetchReviews();
    _pageController.addListener(() {
      final nextPage = _pageController.page?.floor() ?? 0;
      if (nextPage != _currentPageIndex && mounted) {
        setState(() {
          _currentPageIndex = nextPage;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchReviews() async {
    try {
      final fetched = await ApiService.fetchReviews(widget.service['id']);
      fetched.sort((a, b) {
        final dateA = DateTime.tryParse(a['reviewed_at'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['reviewed_at'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
      if (mounted) {
        setState(() {
          reviews = fetched;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final imageList = List<String>.from(service['images'] ?? []);
    final rating = reviews.isNotEmpty
        ? reviews.map((e) => e['rating'] as num).reduce((a, b) => a + b) / reviews.length
        : 0.0;
    final rawPrice = service['price'];
    final parsedPrice = double.tryParse(rawPrice.toString()) ?? 0.0;

    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, service['title'], imageList),
          _buildServiceInfo(context, service, rating, parsedPrice),
          _buildReviewHeader(context),
          _buildReviewList(context),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String title, List<String> images) {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      backgroundColor: Colors.black, // chống lộ nền khi chuyển ảnh
      foregroundColor: Colors.white,
      title: const Text(
        "Chi tiết dịch vụ",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: _buildImageGallery(images),
      ),
    );
  }

  Widget _buildImageGallery(List<String> images) {
    if (images.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
        ),
      );
    }

    return Container(
      height: 250,
      color: Colors.grey, // chống khựng khi chuyển ảnh
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            itemBuilder: (context, index) {
              final image = images[index];
              final isBase64 = image.startsWith("data:image/");
              return isBase64
                  ? _buildBase64Image(image)
                  : Image.network(
                image,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60),
              );
            },
          ),

          // Gradient che trên ảnh
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                ),
              ),
            ),
          ),

          if (_currentPageIndex > 0)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () {
                    if (_pageController.hasClients) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ),
            ),

          if (_currentPageIndex < images.length - 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onPressed: () {
                    if (_pageController.hasClients) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ),
            ),

          Positioned(
            bottom: 10.0,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: images.length,
                effect: WormEffect(
                  dotHeight: 8.0,
                  dotWidth: 8.0,
                  activeDotColor: Colors.white,
                  dotColor: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBase64Image(String imageData) {
    try {
      final base64Str = imageData.split(',').last;
      final bytes = base64Decode(base64Str);
      return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity);
    } catch (_) {
      return const Icon(Icons.broken_image, size: 40);
    }
  }

  Widget _buildServiceInfo(BuildContext context, Map<String, dynamic> service, double rating, double price) {
    final textTheme = Theme.of(context).textTheme;

    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(service['title'], style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            service['description'],
            style: textTheme.bodyLarge?.copyWith(color: Colors.black54, height: 1.5),
          ),
          const SizedBox(height: 16),
          _buildRatingStars(rating),
          const SizedBox(height: 16),
          Text(
            "${NumberFormat("#,##0", "vi_VN").format(price.round())} đ",
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today, color: Colors.white),
              label: const Text("Đặt lịch ngay"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/booking_form', arguments: service);
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildReviewHeader(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      sliver: SliverToBoxAdapter(
        child: Text(
          "Đánh giá từ khách hàng (${reviews.length})",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildReviewList(BuildContext context) {
    if (reviews.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: Text("Chưa có đánh giá nào", style: TextStyle(color: Colors.grey[600])),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) => _buildReviewCard(reviews[index]),
        childCount: reviews.length,
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    int fullStars = rating.floor();
    bool halfStar = (rating - fullStars) >= 0.5;

    return Row(
      children: [
        ...List.generate(fullStars, (_) => const Icon(Icons.star, color: Colors.amber)),
        if (halfStar) const Icon(Icons.star_half, color: Colors.amber),
        ...List.generate(5 - fullStars - (halfStar ? 1 : 0), (_) => const Icon(Icons.star_border, color: Colors.grey)),
        const SizedBox(width: 8),
        Text(
          "${rating.toStringAsFixed(1)}/5.0 (${reviews.length} đánh giá)",
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rawName = review["name"] ?? review["customer_name"] ?? "";
    final name = rawName.trim().isEmpty ? "Ẩn danh" : rawName;
    final rating = (review["rating"] ?? 0).toInt().clamp(0, 5) as int;
    final feedback = review["feedback"] ?? "";
    final reviewedAtStr = review["reviewed_at"];
    DateTime? reviewedAt;
    if (reviewedAtStr != null) {
      reviewedAt = DateTime.tryParse(reviewedAtStr);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'A',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          ...List.generate(rating, (_) => const Icon(Icons.star, color: Colors.amber, size: 16)),
                          ...List.generate(5 - rating, (_) => const Icon(Icons.star_border, color: Colors.grey, size: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (reviewedAt != null)
                  Text(
                    timeago.format(reviewedAt, locale: 'vi'),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            if (feedback.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(feedback, style: const TextStyle(color: Colors.black87, height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }
}
