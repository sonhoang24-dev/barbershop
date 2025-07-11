import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ShopInfoScreen extends StatelessWidget {
  const ShopInfoScreen({super.key});

  final List<String> shopImages = const [
    'https://via.placeholder.com/400x200?text=Ảnh+1',
    'https://via.placeholder.com/400x200?text=Ảnh+2',
    'https://via.placeholder.com/400x200?text=Ảnh+3',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cửa hàng'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slider ảnh thủ công
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: shopImages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        shopImages[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.error, color: Colors.red),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Google Map (hiển thị tĩnh)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Bản đồ cửa hàng",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(10.0290, 105.7689),
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: MarkerId('shop'),
                    position: LatLng(10.0290, 105.7689),
                    infoWindow: InfoWindow(
                      title: "Barbershop - Nguyễn Văn Linh",
                    ),
                  ),
                },
                zoomControlsEnabled: false,
                liteModeEnabled: true,
              ),
            ),
            const SizedBox(height: 20),

            // Thông tin cửa hàng
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: const [
                  ListTile(
                    leading: Icon(Icons.location_on, color: Colors.teal),
                    title: Text('328 Nguyễn Văn Linh, Cần Thơ'),
                  ),
                  ListTile(
                    leading: Icon(Icons.access_time, color: Colors.teal),
                    title: Text('Giờ mở cửa: 8:00 - 21:00 hàng ngày'),
                  ),
                  ListTile(
                    leading: Icon(Icons.phone, color: Colors.teal),
                    title: Text('Liên hệ: 0909 999 999'),
                  ),
                  ListTile(
                    leading: Icon(Icons.email, color: Colors.teal),
                    title: Text('Email: info@barbershop.vn'),
                  ),
                  ListTile(
                    leading: Icon(Icons.facebook, color: Colors.teal),
                    title: Text('Facebook: fb.com/barbershopcantho'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
