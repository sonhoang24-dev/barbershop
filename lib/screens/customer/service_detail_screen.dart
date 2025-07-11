import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/service_service.dart';
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
      final fetched = await ServiceService.fetchReviews(widget.service['id']);
      setState(() {
        reviews = fetched;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi tải đánh giá: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final imageBase64List = List<String>.from(service['images'] ?? []);

    final rating = reviews.isNotEmpty
        ? reviews.map((e) => e['rating'] as num).reduce((a, b) => a + b) / reviews.length
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(service['title']),
        backgroundColor: Colors.teal,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageGallery(imageBase64List),
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
              "Giá: ${NumberFormat("#,##0", "vi_VN").format(service['price'])} đ",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
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
              ...reviews.map((review) => _buildReviewCard(review)).toList(),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: const Text("Đặt lịch ngay"),
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
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(List<String> base64Images) {
    if (base64Images.isEmpty) {
      return const Center(
        child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: base64Images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          try {
            final bytes = base64Decode(base64Images[index]);
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                bytes,
                width: 280,
                height: 180,
                fit: BoxFit.cover,
              ),
            );
          } catch (_) {
            return const Icon(Icons.broken_image, size: 60);
          }
        },
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
        Text("${rating.toStringAsFixed(1)} / 5", style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final name = review["name"] ?? "Ẩn danh";
    final rating = review["rating"] is int ? review["rating"] : 0;
    final feedback = review["feedback"] ?? "";

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
          ],
        ),
      ),
    );
  }
}
