import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ReviewListAdminScreen extends StatefulWidget {
  const ReviewListAdminScreen({super.key});

  @override
  State<ReviewListAdminScreen> createState() => _ReviewListAdminScreenState();
}

class _ReviewListAdminScreenState extends State<ReviewListAdminScreen> {
  List reviews = [];
  List services = [];
  int? selectedRating;
  int? selectedServiceId;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchServices();
    fetchReviews();
  }

  Future<void> fetchServices() async {
    setState(() => isLoading = true);
    final res = await http.get(Uri.parse('http://10.0.2.2/barbershop/backend/services/get_services.php'));
    if (res.statusCode == 200) {
      final jsonData = json.decode(res.body);
      setState(() {
        services = jsonData['data'];
        isLoading = false;
      });
    }
  }

  Future<void> fetchReviews() async {
    setState(() => isLoading = true);
    String url = 'http://10.0.2.2/barbershop/backend/reviews/get_reviews.php';
    List<String> params = [];

    if (selectedRating != null) params.add('rating=$selectedRating');
    if (selectedServiceId != null) params.add('service_id=$selectedServiceId');
    if (params.isNotEmpty) url += '?' + params.join('&');

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);
        setState(() {
          reviews = jsonData['success'] ? jsonData['data'] : [];
          isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi API: $e");
      setState(() {
        reviews = [];
        isLoading = false;
      });
    }
  }

  String _formatPrice(dynamic price) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0);
    return formatter.format(double.tryParse(price.toString()) ?? 0).trim();
  }

  Widget buildFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bộ lọc đánh giá',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.teal),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            decoration: _inputDecoration("Số sao"),
            value: selectedRating,
            items: List.generate(5, (i) => i + 1).map((s) {
              return DropdownMenuItem(
                value: s,
                child: Row(
                  children: [
                    ...List.generate(s, (_) => const Icon(Icons.star, color: Colors.amber, size: 18)),
                    const SizedBox(width: 8),
                    Text('$s sao'),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => selectedRating = value);
              fetchReviews();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            decoration: _inputDecoration("Dịch vụ"),
            value: selectedServiceId,
            items: services.map<DropdownMenuItem<int>>((s) {
              return DropdownMenuItem(
                value: int.tryParse(s['id'].toString()),
                child: Text(s['name'], style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => selectedServiceId = value);
              fetchReviews();
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  selectedRating = null;
                  selectedServiceId = null;
                });
                fetchReviews();
              },
              icon: const Icon(Icons.clear, size: 20),
              label: const Text("Xóa bộ lọc"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[50],
                foregroundColor: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget buildReviewItem(Map review) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(review['customer_name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(review['service_name'], style: TextStyle(color: Colors.teal[700], fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                int.parse(review['rating'].toString()),
                    (_) => const Icon(Icons.star, color: Colors.amber, size: 20),
              ),
            ),
            const SizedBox(height: 8),
            if ((review['feedback'] ?? '').toString().isNotEmpty)
              Text(review['feedback'], style: TextStyle(fontSize: 14, color: Colors.grey[800])),
            const SizedBox(height: 8),
            Text('Ngày đánh giá: ${review['reviewed_at']}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
            if (review['price'] != null)
              Text('Giá: ${_formatPrice(review['price'])} đ',
                  style: TextStyle(fontSize: 14, color: Colors.grey[800])),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Danh sách đánh giá', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildFilter(),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                  : reviews.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text("Không có đánh giá nào", style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: reviews.length,
                itemBuilder: (_, i) => buildReviewItem(reviews[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
