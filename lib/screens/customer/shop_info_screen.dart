import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ShopInfoScreen extends StatefulWidget {
  const ShopInfoScreen({super.key});

  @override
  State<ShopInfoScreen> createState() => _ShopInfoScreenState();
}

class _ShopInfoScreenState extends State<ShopInfoScreen> {
  GoogleMapController? _mapController;
  final LatLng shopLocation = const LatLng(10.0467807, 105.7680453);
  final String shopAddress = '256 Đ. Nguyễn Văn Cừ, An Hoà, Ninh Kiều, Cần Thơ';
  final String phoneNumber = '02923898167';
  bool _isMapLoading = true;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();

    Future.delayed(const Duration(seconds: 10), () {
      if (_isMapLoading) setState(() => _isMapLoading = false);
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần quyền vị trí để hiển thị bản đồ')),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    if (_mapController == null) {
      _mapController = controller;
      if (_isMapLoading) setState(() => _isMapLoading = false);
    }
  }

  Future<void> _openMap() async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${shopLocation.latitude},${shopLocation.longitude}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showError('Không thể mở Google Maps');
      }
    } catch (e) {
      _showError('Đã xảy ra lỗi khi mở Google Maps');
    }
  }

  Future<void> _dialPhone() async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showError('Không thể mở ứng dụng điện thoại. Vui lòng kiểm tra cài đặt hoặc chạy trên thiết bị thật.');
      }
    } catch (e) {
      _showError('Đã xảy ra lỗi khi mở ứng dụng điện thoại: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String getWorkingStatus() {
    final now = TimeOfDay.now();
    final totalMinutes = now.hour * 60 + now.minute;

    final caSang = (8 * 60, 12 * 60);
    final caChieu = (13 * 60, 17 * 60);
    final caToi = (18 * 60, 22 * 60);

    final isOpen = (totalMinutes >= caSang.$1 && totalMinutes <= caSang.$2) ||
        (totalMinutes >= caChieu.$1 && totalMinutes <= caChieu.$2) ||
        (totalMinutes >= caToi.$1 && totalMinutes <= caToi.$2);

    if (isOpen) {
      if ((totalMinutes >= caSang.$2 - 30 && totalMinutes <= caSang.$2) ||
          (totalMinutes >= caChieu.$2 - 30 && totalMinutes <= caChieu.$2) ||
          (totalMinutes >= caToi.$2 - 30 && totalMinutes <= caToi.$2)) {
        return "Sắp đóng cửa";
      }
      return "Đang mở cửa";
    } else {
      return "Đã đóng cửa";
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = getWorkingStatus();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Thông tin cửa hàng',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.tealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isMapLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                : ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: GoogleMap(
                onMapCreated: (controller) {
                  _onMapCreated(controller);
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(shopLocation, 15),
                  );
                },
                initialCameraPosition: CameraPosition(
                  target: shopLocation,
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('shop'),
                    position: shopLocation,
                    infoWindow: const InfoWindow(title: 'Barbershop'),
                  ),
                },
                zoomControlsEnabled: true,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(
                  icon: Icons.location_on_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shopAddress,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        status,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: status.contains("Đang") ? Colors.green : status.contains("Sắp") ? Colors.orange : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _infoRow(
                  icon: Icons.access_time,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Giờ làm việc:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('• Sáng: 8:00 - 12:00'),
                      Text('• Chiều: 13:00 - 17:00'),
                      Text('• Tối: 18:00 - 22:00'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _infoRow(
                  icon: Icons.phone_outlined,
                  child: GestureDetector(
                    onTap: _dialPhone,
                    child: Text(
                      '$phoneNumber',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openMap,
                    icon: const Icon(Icons.navigation),
                    label: const Text("Chỉ đường tới cửa hàng"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({required IconData icon, String? title, Widget? child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.teal, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: child ??
              Text(
                title ?? '',
                style: const TextStyle(fontSize: 16),
              ),
        ),
      ],
    );
  }
}