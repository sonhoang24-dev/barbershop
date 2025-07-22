import 'dart:async';
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
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchActive = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchServices();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchServices({String searchTerm = ''}) async {
    try {
      setState(() => _loading = true);
      final data = await ApiService.fetchServices(searchTerm: searchTerm);
      if (!mounted) return;
      setState(() {
        _services = data;
        _services.sort((a, b) {
          final dateTimeA = a.createdAt != null ? DateTime.tryParse(a.createdAt!) ?? DateTime(1970) : DateTime(1970);
          final dateTimeB = b.createdAt != null ? DateTime.tryParse(b.createdAt!) ?? DateTime(1970) : DateTime(1970);
          return dateTimeB.compareTo(dateTimeA);
        });
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final searchTerm = _searchController.text.trim();
      _fetchServices(searchTerm: searchTerm);
    });
  }

  bool _isNewService(String? createdAt) {
    if (createdAt == null) return false;
    final date = DateTime.tryParse(createdAt);
    if (date == null) return false;
    return DateTime.now().difference(date).inDays <= 7;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearchActive
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm dịch vụ...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear, color: Colors.white70),
              onPressed: () {
                _searchController.clear();
                _fetchServices();
              },
            ),
          ),
          style: TextStyle(color: Colors.white),
        )
            : const Text(
          "Dịch vụ đặt lịch cắt tóc",
          style: TextStyle(fontSize: 20,color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal[700],
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearchActive ? Icons.close : Icons.search),
            color: Colors.white,
            onPressed: () {
              setState(() {
                _isSearchActive = !_isSearchActive;
                if (!_isSearchActive) {
                  _searchController.clear();
                  _fetchServices();
                }
              });
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _services.isEmpty
          ? Center(
        child: Text(
          _searchController.text.isNotEmpty
              ? "Không tìm thấy dịch vụ phù hợp"
              : "Chưa có dịch vụ nào",
          style: TextStyle(color: Colors.teal),
        ),
      )
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
    final isNewService = _isNewService(service.createdAt);
    final isHighRated = service.rating >= 4.5;

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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
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
            if (isNewService)
              Positioned(
                top: 0,
                left: 0,
                child: _buildBadge("Dịch vụ mới", Colors.redAccent, Colors.white),
              )
            else if (isHighRated)
              Positioned(
                top: 0,
                left: 0,
                child: _buildBadge("Đánh giá cao", Colors.amber, Colors.black),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
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
        ...List.generate(5 - fullStars - (halfStar ? 1 : 0), (_) => const Icon(Icons.star_border, color: Colors.grey, size: 18)),
        const SizedBox(width: 4),
        Text("${rating.toStringAsFixed(1)}", style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
