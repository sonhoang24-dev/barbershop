import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class ServiceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  List<Map<String, dynamic>> reviews = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    try {
      final fetched = await ApiService.fetchReviews(widget.service['id']);
      print("Fetched reviews: $fetched");

      // Sắp xếp reviews theo thời gian giảm dần
      fetched.sort((a, b) {
        final dateA = DateTime.tryParse(a['reviewed_at'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['reviewed_at'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA); // Mới nhất lên đầu
      });

      setState(() {
        reviews = fetched;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final rawPrice = service['price'];
    final parsedPrice = double.tryParse(rawPrice.toString()) ?? 0.0;
    print("Service price raw: $rawPrice, parsed: $parsedPrice"); // Debug: Kiểm tra giá thô và sau parse
    final imageList = List<String>.from(service['images'] ?? []);
    final rating = reviews.isNotEmpty
        ? reviews.map((e) => e['rating'] as num).reduce((a, b) => a + b) / reviews.length
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text("Chi tiết dịch vụ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),),
        backgroundColor: Colors.teal,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageGallery(imageList),
            const SizedBox(height: 20),
            Text(
              service['title'],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              service['description'],
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              "Giá: ${NumberFormat("#,##0", "vi_VN").format(parsedPrice.round())} đ",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                label: const Text("Đặt lịch ngay", style: TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/booking_form', arguments: service);
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildRatingStars(rating),
            const SizedBox(height: 16),
            const Text(
              "Đánh giá từ khách hàng",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (reviews.isEmpty)
              const Text("Chưa có đánh giá nào", style: TextStyle(color: Colors.grey))
            else
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Scrollbar(
                  child: ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      return _buildReviewCard(reviews[index]);
                    },
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(List<String> images) {
    if (images.isEmpty) {
      return const Center(
        child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final image = images[index];
          final isBase64 = image.startsWith("data:image/");

          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isBase64
                ? _buildBase64Image(image)
                : Image.network(
              image,
              width: 280,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 60),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBase64Image(String imageData) {
    try {
      final base64Str = imageData.split(',').last;
      final bytes = base64Decode(base64Str);
      return Image.memory(
        bytes,
        width: 280,
        height: 180,
        fit: BoxFit.cover,
      );
    } catch (_) {
      return const Icon(Icons.broken_image, size: 60);
    }
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
        Text("${rating.toStringAsFixed(1)} / 5", style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rawName = review["name"] ?? review["customer_name"] ?? "";
    final name = rawName.trim().isEmpty ? "Ẩn danh" : rawName;
    final rating = review["rating"] is int ? review["rating"] : 0;
    final feedback = review["feedback"] ?? "";
    final reviewedAtStr = review["reviewed_at"];
    DateTime? reviewedAt;
    if (reviewedAtStr != null) {
      try {
        reviewedAt = DateFormat("yyyy-MM-dd HH:mm:ss").parse(reviewedAtStr);
      } catch (e) {
        print("Không thể parse thời gian đánh giá: $reviewedAtStr");
      }
    }

    print("Review data: $review"); // Debug
    print("Giá trị reviewed_at: ${review["reviewed_at"]}");

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: List.generate(
                rating,
                    (_) => const Icon(Icons.star, color: Colors.amber, size: 16),
              ),
            ),
            const SizedBox(height: 6),
            Text(feedback),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: reviewedAt != null
                  ? Text(
                "Đánh giá ${timeago.format(reviewedAt, locale: 'vi')}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              )
                  : const Text(
                "Không rõ thời gian đánh giá",
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

}