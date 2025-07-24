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
        _services = data
          ..sort((a, b) {
            final aDate = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(1970);
            final bDate = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(1970);
            return bDate.compareTo(aDate);
          });
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchServices(searchTerm: _searchController.text.trim());
    });
  }

  bool _isNew(String? createdAt) {
    final date = DateTime.tryParse(createdAt ?? '');
    return date != null && DateTime.now().difference(date).inDays <= 7;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final textScaleFactor = mediaQuery.textScaleFactor.clamp(0.8, 1.2);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: _isSearchActive
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm dịch vụ...',
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, color: Colors.white70),
              onPressed: () {
                _searchController.clear();
                _fetchServices();
              },
            ),
          ),
          style: const TextStyle(color: Colors.white),
        )
            : const Text(
          "Dịch vụ đặt lịch cắt tóc",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal[700],
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearchActive ? Icons.close : Icons.search, color: Colors.white),
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
        flexibleSpace: SafeArea(child: Container()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _services.isEmpty
          ? Center(
        child: Text(
          _searchController.text.isNotEmpty
              ? "Không tìm thấy dịch vụ phù hợp"
              : "Chưa có dịch vụ nào",
          style: TextStyle(
            color: Colors.teal,
            fontSize: 16 * textScaleFactor,
          ),
          textAlign: TextAlign.center,
        ),
      )
          : LayoutBuilder(
        builder: (context, constraints) {
          final isPortrait = mediaQuery.orientation == Orientation.portrait;
          final crossAxisCount = _calculateCrossAxisCount(screenWidth);
          final childAspectRatio = _calculateChildAspectRatio(screenWidth, isPortrait);

          return Padding(
            padding: EdgeInsets.all(screenWidth * 0.03),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: screenWidth * 0.04,
                mainAxisSpacing: screenWidth * 0.04,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: _services.length,
              itemBuilder: (_, index) => _buildServiceCard(_services[index], textScaleFactor),
            ),
          );
        },
      ),
    );
  }

  int _calculateCrossAxisCount(double screenWidth) {
    if (screenWidth >= 1200) return 4;
    if (screenWidth >= 600) return 3;
    return 2;
  }

  double _calculateChildAspectRatio(double screenWidth, bool isPortrait) {
    if (screenWidth >= 1200) return isPortrait ? 0.75 : 0.9;
    if (screenWidth >= 600) return isPortrait ? 0.66 : 0.9;
    return isPortrait ? 0.66 : 0.9;
  }

  Widget _buildServiceCard(Service service, double textScaleFactor) {
    final isNew = _isNew(service.createdAt);
    final isHighRated = service.rating >= 4.5;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ServiceDetailScreen(service: service.toMap()),
        ),
      ),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 120 * textScaleFactor,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: _buildServiceImage(service.images.isNotEmpty ? service.images.first : ''),
                  ),
                  if (isNew || isHighRated)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isNew ? Colors.red : Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isNew ? "Mới" : "Đánh giá cao",
                          style: TextStyle(
                            color: isNew ? Colors.white : Colors.black,
                            fontSize: 11 * textScaleFactor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        service.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[900],
                          fontSize: 14 * textScaleFactor,
                        ),
                      ),
                    ),
                    SizedBox(height: 4 * textScaleFactor),
                    _buildRatingStars(service.rating, textScaleFactor),
                    SizedBox(height: 4 * textScaleFactor),
                    Text(
                      "${formatCurrency.format(service.price)} đ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[700],
                        fontSize: 14 * textScaleFactor,
                      ),
                    ),
                    SizedBox(height: 6 * textScaleFactor),
                    SizedBox(
                      width: double.infinity,
                      height: 36 * textScaleFactor,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ServiceDetailScreen(service: service.toMap()),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[50],
                          foregroundColor: Colors.teal[700],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          "Xem chi tiết",
                          style: TextStyle(fontSize: 12 * textScaleFactor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceImage(String image) {
    final isBase64 = image.startsWith("data:image/");
    try {
      if (isBase64) {
        final base64Str = image.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          height: double.infinity,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } else if (image.isNotEmpty) {
        return Image.network(
          image,
          height: double.infinity,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          },
          errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
        );
      } else {
        return _buildFallbackImage();
      }
    } catch (_) {
      return _buildFallbackImage();
    }
  }

  Widget _buildFallbackImage() {
    return Container(
      height: double.infinity,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.cut,
          size: 60,
          color: Colors.teal,
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating, double textScaleFactor) {
    if (rating == 0.0) {
      return Text(
        "Chưa đánh giá",
        style: TextStyle(fontSize: 12 * textScaleFactor, color: Colors.grey),
      );
    }
    int fullStars = rating.floor();
    bool halfStar = (rating - fullStars) >= 0.5;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(
          fullStars,
              (_) => Icon(Icons.star, size: 16 * textScaleFactor, color: Colors.amber),
        ),
        if (halfStar) Icon(Icons.star_half, size: 16 * textScaleFactor, color: Colors.amber),
        ...List.generate(
          5 - fullStars - (halfStar ? 1 : 0),
              (_) => Icon(Icons.star_border, size: 16 * textScaleFactor, color: Colors.grey),
        ),
        SizedBox(width: 4 * textScaleFactor),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(fontSize: 12 * textScaleFactor),
        ),
      ],
    );
  }
}