import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/service.dart';
import '../../../services/api_service.dart';
import 'package:Barbershopdht/screens/customer/service_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Service> _services = [];
  bool _loading = true;
  final formatCurrency = NumberFormat("#,##0", "vi_VN");

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final data = await ApiService.fetchServices();
      setState(() {
        _services = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi tải dịch vụ: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dịch vụ đặt lịch cắt tóc", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal[700],
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _services.isEmpty
          ? const Center(child: Text("Chưa có dịch vụ nào", style: TextStyle(color: Colors.teal)))
          : Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: _services.length,
          itemBuilder: (context, index) {
            final service = _services[index];
            return _buildServiceCard(service);
          },
        ),
      ),
    );
  }

  Widget _buildServiceCard(Service service) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceDetailScreen(service: service.toMap()),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (service.images.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildServiceImage(service.images.first),
              )
            else
              const Icon(Icons.cut, size: 100, color: Colors.teal),

            const SizedBox(height: 4),

            Text(
              service.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.teal[900],
              ),
            ),

            const SizedBox(height: 4),

            _buildRatingStars(service.rating),

            const SizedBox(height: 4),

            Text(
              "${formatCurrency.format(service.price)} đ",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.teal[700],
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              height: 36,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ServiceDetailScreen(service: service.toMap()),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[50],
                  foregroundColor: Colors.teal[700],
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Xem chi tiết", style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceImage(String image) {
    final isBase64 = image.startsWith("data:image/");
    if (isBase64) {
      try {
        final base64Str = image.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          height: 100,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60, color: Colors.grey),
        );
      } catch (_) {
        return const Icon(Icons.broken_image, size: 60, color: Colors.grey);
      }
    } else {
      return Image.network(
        image,
        height: 100,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60, color: Colors.grey),
      );
    }
  }

  Widget _buildRatingStars(double rating) {
    if (rating == 0.0) {
      return const Text(
        "Chưa đánh giá",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: Colors.grey),
      );
    }

    int fullStars = rating.floor();
    bool halfStar = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(fullStars, (_) => const Icon(Icons.star, color: Colors.amber, size: 18)),
        if (halfStar) const Icon(Icons.star_half, color: Colors.amber, size: 18),
        ...List.generate(5 - fullStars - (halfStar ? 1 : 0),
                (_) => const Icon(Icons.star_border, color: Colors.grey, size: 18)),
        const SizedBox(width: 4),
        Text("${rating.toStringAsFixed(1)}", style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
