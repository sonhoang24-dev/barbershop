import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/service.dart';
import '../../services/service_service.dart';
import 'package:barbershop_app/screens/customer/service_detail_screen.dart';

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
      final data = await ServiceService.fetchServices();
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
        title: const Text("Dịch vụ tiệm tóc"),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
          ? const Center(child: Text("Chưa có dịch vụ nào"))
          : Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: _services.length,
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
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
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (service.images.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  service.images.first,
                  height: 80,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported),
                ),
              )
            else
              const Icon(Icons.cut, size: 50, color: Colors.teal),
            const SizedBox(height: 10),

            // Tiêu đề
            Text(
              service.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),

            // Mô tả
            Text(
              service.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 6),

            // Đánh giá
            _buildRatingStars(service.rating),
            const Spacer(),

            // Giá (định dạng)
            Text(
              "${formatCurrency.format(service.price)} đ",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Xem chi tiết",
                style: TextStyle(fontSize: 12, color: Colors.teal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    int fullStars = rating.floor();
    bool halfStar = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(
          fullStars,
              (_) => const Icon(Icons.star, color: Colors.amber, size: 16),
        ),
        if (halfStar)
          const Icon(Icons.star_half, color: Colors.amber, size: 16),
        ...List.generate(
          5 - fullStars - (halfStar ? 1 : 0),
              (_) => const Icon(Icons.star_border, color: Colors.grey, size: 16),
        ),
        const SizedBox(width: 4),
        Text(
          "${rating.toStringAsFixed(1)} / 5",
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}
