import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/employee.dart';
import '../../models/service.dart';
import '../../services/api_service.dart';

class ManageEmployeesScreen extends StatefulWidget {
  const ManageEmployeesScreen({super.key});

  @override
  State<ManageEmployeesScreen> createState() => _ManageEmployeesScreenState();
}

class _ManageEmployeesScreenState extends State<ManageEmployeesScreen> {
  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  List<Service> _services = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'Tất cả';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      String searchText = _searchController.text.trim();
      String? name;
      String? phone;
    if (searchText.isNotEmpty && RegExp(r'^\d+$').hasMatch(searchText)) {
    phone = searchText;
    } else {
    name = searchText;
    }

    final employees = await ApiService.fetchEmployees(
    name: name ?? '',
    phone: phone ?? '',
    status: _selectedStatus == 'Tất cả' ? '' : _selectedStatus,
    );
    final services = await ApiService.fetchServices();
    setState(() {
    _employees = employees;
    _filteredEmployees = employees;
    _services = services;
    _isLoading = false;
    });
    } catch (e) {
    setState(() => _isLoading = false);
    _showErrorDialog("Lỗi tải dữ liệu: $e");
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _filterEmployees();
    });
  }

  void _filterEmployees() async {
    try {
      String searchText = _searchController.text.trim();
      String? name;
      String? phone;
      if (searchText.isNotEmpty && RegExp(r'^\d+$').hasMatch(searchText)) {
        phone = searchText;
      } else {
        name = searchText;
      }

      final employees = await ApiService.fetchEmployees(
        name: name ?? '',
        phone: phone ?? '',
        status: _selectedStatus == 'Tất cả' ? '' : _selectedStatus,
      );
      setState(() {
        _filteredEmployees = employees;
      });
    } catch (e) {
      _showErrorDialog("Lỗi tìm kiếm: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          "Thông báo",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

  void _showEditEmployeeDialog(Employee emp) async {
    final nameController = TextEditingController(text: emp.fullName);
    final phoneController = TextEditingController(text: emp.phone);
    String selectedStatus = emp.status;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    final parts = emp.workingHours.split(" - ");
    if (parts.length == 2) {
      final startParts = parts[0].split(":");
      final endParts = parts[1].split(":");
      startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: 0);
      endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: 0);
    }

    Set<int> selectedServiceIds = {};
    try {
      final currentServices = await ApiService.fetchEmployeeServices(emp.id);
      selectedServiceIds.addAll(currentServices.map((s) => s.id));
    } catch (e) {
      _showErrorDialog("Lỗi tải dịch vụ: $e");
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text(
                'Chỉnh sửa nhân viên',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0288D1),
                  fontSize: 16,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField("Họ và tên", nameController),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: startTime ?? const TimeOfDay(hour: 8, minute: 0),
                                builder: (context, child) => MediaQuery(
                                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                  child: child!,
                                ),
                              );
                              if (picked != null) {
                                setStateDialog(() => startTime = picked);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF0288D1)),
                              foregroundColor: const Color(0xFF0288D1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              startTime == null
                                  ? 'Giờ bắt đầu'
                                  : 'Bắt đầu: ${startTime!.hour.toString().padLeft(2, '0')}:00',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: endTime ?? const TimeOfDay(hour: 17, minute: 0),
                                builder: (context, child) => MediaQuery(
                                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                  child: child!,
                                ),
                              );
                              if (picked != null) {
                                setStateDialog(() => endTime = picked);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF0288D1)),
                              foregroundColor: const Color(0xFF0288D1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              endTime == null
                                  ? 'Giờ kết thúc'
                                  : 'Kết thúc: ${endTime!.hour.toString().padLeft(2, '0')}:00',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTextField("Số điện thoại", phoneController, isPhone: true),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: "Trạng thái",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Đang hoạt động',
                          child: Text('Đang hoạt động', style: TextStyle(color: Colors.green)),
                        ),
                        DropdownMenuItem(
                          value: 'Đã nghỉ việc',
                          child: Text('Đã nghỉ việc', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() => selectedStatus = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Dịch vụ đảm nhiệm:",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0288D1),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ..._services.map((service) => CheckboxListTile(
                      title: Text(service.title, style: const TextStyle(fontSize: 14)),
                      value: selectedServiceIds.contains(service.id),
                      activeColor: const Color(0xFF0288D1),
                      checkColor: Colors.white,
                      onChanged: (bool? selected) {
                        setStateDialog(() {
                          if (selected == true) {
                            selectedServiceIds.add(service.id);
                          } else {
                            selectedServiceIds.remove(service.id);
                          }
                        });
                      },
                    )),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  child: const Text("Hủy"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        phoneController.text.isEmpty ||
                        startTime == null ||
                        endTime == null ||
                        selectedServiceIds.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Vui lòng nhập đầy đủ thông tin"),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                      return;
                    }

                    if (!RegExp(r'^\d{10}$').hasMatch(phoneController.text)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Số điện thoại phải có đúng 10 chữ số"),
                          backgroundColor: const Color(0xFFFFA726),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                      return;
                    }

                    if (endTime!.hour <= startTime!.hour) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Giờ kết thúc phải sau giờ bắt đầu"),
                          backgroundColor: const Color(0xFFFFA726),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                      return;
                    }

                    final workingHours =
                        "${startTime!.hour.toString().padLeft(2, '0')}:00 - ${endTime!.hour.toString().padLeft(2, '0')}:00";

                    try {
                      final success = await ApiService.updateEmployee(
                        id: emp.id,
                        fullName: nameController.text.trim(),
                        phone: phoneController.text.trim(),
                        workingHours: workingHours,
                        serviceIds: selectedServiceIds.toList(),
                        status: selectedStatus,
                      );

                      if (success) {
                        Navigator.pop(context);
                        await _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Cập nhật thành công"),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Cập nhật thất bại"),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Lỗi: $e"),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Cập nhật",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddEmployeeDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    Set<int> selectedServiceIds = {};

    try {
      _services = await ApiService.fetchServices();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi lấy danh sách dịch vụ: $e"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text(
                'Thêm nhân viên',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0288D1),
                  fontSize: 16,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField("Họ và tên", nameController),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(hour: 8, minute: 0),
                                builder: (context, child) => MediaQuery(
                                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                  child: child!,
                                ),
                              );
                              if (picked != null) {
                                setStateDialog(() => startTime = picked);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF0288D1)),
                              foregroundColor: const Color(0xFF0288D1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              startTime == null
                                  ? 'Giờ bắt đầu'
                                  : 'Bắt đầu: ${startTime!.hour.toString().padLeft(2, '0')}:00',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(hour: 17, minute: 0),
                                builder: (context, child) => MediaQuery(
                                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                  child: child!,
                                ),
                              );
                              if (picked != null) {
                                setStateDialog(() => endTime = picked);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF0288D1)),
                              foregroundColor: const Color(0xFF0288D1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              endTime == null
                                  ? 'Giờ kết thúc'
                                  : 'Kết thúc: ${endTime!.hour.toString().padLeft(2, '0')}:00',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTextField("Số điện thoại", phoneController, isPhone: true),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Dịch vụ đảm nhiệm:",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0288D1),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ..._services.map((service) => CheckboxListTile(
                      title: Text(service.title, style: const TextStyle(fontSize: 14)),
                      value: selectedServiceIds.contains(service.id),
                      activeColor: const Color(0xFF0288D1),
                      checkColor: Colors.white,
                      onChanged: (bool? selected) {
                        setStateDialog(() {
                          if (selected == true) {
                            selectedServiceIds.add(service.id);
                          } else {
                            selectedServiceIds.remove(service.id);
                          }
                        });
                      },
                    )),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  child: const Text("Hủy"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();

                    if (name.isEmpty ||
                        phone.isEmpty ||
                        startTime == null ||
                        endTime == null ||
                        selectedServiceIds.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Vui lòng nhập đầy đủ thông tin"),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                      return;
                    }

                    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Số điện thoại phải có đúng 10 chữ số"),
                          backgroundColor: const Color(0xFFFFA726),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                      return;
                    }

                    if (endTime!.hour <= startTime!.hour) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Giờ kết thúc phải sau giờ bắt đầu"),
                          backgroundColor: const Color(0xFFFFA726),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                      return;
                    }

                    final workingHours =
                        "${startTime!.hour.toString().padLeft(2, '0')}:00 - ${endTime!.hour.toString().padLeft(2, '0')}:00";

                    try {
                      final success = await ApiService.addEmployeeWithServices(
                        fullName: name,
                        phone: phone,
                        workingHours: workingHours,
                        serviceIds: selectedServiceIds.toList(),
                        status: 'Đang hoạt động',
                      );

                      if (success) {
                        Navigator.pop(context);
                        await _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Thêm nhân viên thành công"),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Thêm nhân viên thất bại"),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Lỗi: $e"),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Lưu",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isPhone = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      inputFormatters: isPhone
          ? [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ]
          : [],
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        errorText: isPhone && controller.text.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(controller.text)
            ? 'Số điện thoại phải có đúng 10 chữ số'
            : null,
      ),
      style: const TextStyle(fontSize: 14),
      onChanged: (value) {
        if (isPhone) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildEmployeeCard(Employee emp) {
    Color statusColor = emp.status == 'Đang hoạt động' ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16), // Tăng padding để thẻ rộng hơn
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              child: const Icon(
                Icons.person,
                color: Color(0xFF0288D1),
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emp.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "SĐT: ${emp.phone}",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Giờ làm: ${emp.workingHours}",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Dịch vụ: ${emp.serviceNames.isEmpty ? 'Chưa có' : emp.serviceNames}",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: null, // Cho phép đa dòng để hiển thị hết tên dịch vụ
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.circle, color: statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        emp.status,
                        style: TextStyle(
                          fontSize: 14,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: Color(0xFF0288D1),
                size: 24,
              ),
              onPressed: () => _showEditEmployeeDialog(emp),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0288D1);
    const accentColor = Color(0xFFFFA726);
    const backgroundColor = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Tìm tên hoặc tiền tố số điện thoại (VD: 03, 033)",
            hintStyle: const TextStyle(color: Colors.white70, fontSize: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.2),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            prefixIcon: const Icon(
              Icons.search,
              color: Colors.white,
              size: 24,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged();
              },
            )
                : null,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          keyboardType: TextInputType.text,
          onChanged: (value) => _onSearchChanged(),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedStatus = value;
                _filterEmployees();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'Tất cả',
                child: Text('Tất cả', style: TextStyle(fontSize: 16)),
              ),
              PopupMenuItem(
                value: 'Đang hoạt động',
                child: Text('Đang hoạt động', style: TextStyle(fontSize: 16, color: Colors.green)),
              ),
              PopupMenuItem(
                value: 'Đã nghỉ việc',
                child: Text('Đã nghỉ việc', style: TextStyle(fontSize: 16, color: Colors.red)),
              ),
            ],
            icon: const Icon(
              Icons.filter_list,
              color: Colors.white,
              size: 24,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      )
          : _filteredEmployees.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              color: Colors.grey[500],
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              "Chưa có nhân viên nào",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _showAddEmployeeDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Thêm nhân viên',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadData,
        color: primaryColor,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _filteredEmployees.length,
          itemBuilder: (context, index) => _buildEmployeeCard(_filteredEmployees[index]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEmployeeDialog,
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(
          Icons.person_add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}