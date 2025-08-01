import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/service.dart';
import '../../services/api_service.dart';
import 'AddOrEditServiceScreen.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  Future<List<Service>>? _futureServices;
  String _searchQuery = '';
  String _selectedStatus = 'Tất cả';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  void _loadServices({String search = '', String status = ''}) {
    setState(() {
      _futureServices = ApiService.fetchAllServicesForAdmin(search: search, status: status);
    });
  }

  Future<void> _refresh() async {
    _loadServices(search: _searchQuery, status: _selectedStatus == 'Tất cả' ? '' : _selectedStatus);
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim(); // Trim whitespace
      _loadServices(search: _searchQuery, status: _selectedStatus == 'Tất cả' ? '' : _selectedStatus);
    });
  }

  void _onStatusChanged(String? newStatus) {
    setState(() {
      _selectedStatus = newStatus ?? 'Tất cả';
      _loadServices(search: _searchQuery, status: _selectedStatus == 'Tất cả' ? '' : _selectedStatus);
    });
  }

  Widget _buildServiceCard(Service service, ThemeData theme) {
    final numberFormat = NumberFormat.decimalPattern('vi_VN');
    final status = service.status ?? 'Không rõ';
    final isActive = status.toLowerCase() == 'đang hoạt động';
    final statusColor = isActive ? Colors.green[700] : Colors.red[700];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: Container(
        constraints: const BoxConstraints(minHeight: 180),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.cut, color: theme.primaryColor, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          service.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 26),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddOrEditServiceScreen(service: service),
                      ),
                    );
                    if (result == true) _refresh();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Giá: ${numberFormat.format(service.price)}đ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.fiber_manual_record, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Trạng thái: $status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.description, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    service.description.isEmpty ? 'Chưa có mô tả' : service.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (service.extras.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.list, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dịch vụ đi kèm:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: service.extras.map((extra) => Text(
                            '${extra.name} (${numberFormat.format(extra.price)}đ)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (service.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: service.images.length,
                  itemBuilder: (context, i) {
                    try {
                      final imgData = base64Decode(service.images[i].split(',').last);
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            imgData,
                            height: 120,
                            width: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 120,
                              width: 120,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                            ),
                          ),
                        ),
                      );
                    } catch (e) {
                      return Container(
                        height: 120,
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                      );
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản lý dịch vụ',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: theme.primaryColor,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(140), // Tăng nếu cần
          child: SingleChildScrollView( // Thêm scroll nếu nội dung có thể dài
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm theo tên dịch vụ...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear, color: theme.primaryColor),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Trạng thái: ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _selectedStatus,
                          items: ['Tất cả', 'Đang hoạt động', 'Ngừng hoạt động']
                              .map((value) {
                            Color statusColor;
                            switch (value) {
                              case 'Đang hoạt động':
                                statusColor = Colors.green[700]!;
                                break;
                              case 'Ngừng hoạt động':
                                statusColor = Colors.red[700]!;
                                break;
                              default:
                                statusColor = Colors.grey[600]!;
                            }
                            return DropdownMenuItem(
                              value: value,
                              child: Row(
                                children: [
                                  Icon(Icons.circle, size: 12, color: statusColor),
                                  const SizedBox(width: 8),
                                  Text(value, style: TextStyle(color: statusColor)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: _onStatusChanged,
                          underline: Container(),
                          icon: Icon(Icons.arrow_drop_down, color: theme.primaryColor),
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                          dropdownColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Service>>(
        future: _futureServices,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: theme.primaryColor));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Lỗi: ${snapshot.error}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _refresh,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Thử lại',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          final services = snapshot.data ?? [];
          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, color: Colors.grey[500], size: 48),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isNotEmpty || _selectedStatus != 'Tất cả'
                        ? 'Không tìm thấy dịch vụ phù hợp.'
                        : 'Chưa có dịch vụ nào.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddOrEditServiceScreen()),
                      );
                      if (result == true) _refresh();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Thêm dịch vụ',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            color: theme.primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: services.length,
              itemBuilder: (context, index) => _buildServiceCard(services[index], theme),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddOrEditServiceScreen()),
          );
          if (result == true) _refresh();
        },
        backgroundColor: theme.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}