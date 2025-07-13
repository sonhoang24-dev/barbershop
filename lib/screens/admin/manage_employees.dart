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
  List<Service> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final employees = await ApiService.fetchEmployees();
      final services = await ApiService.fetchServices();
      setState(() {
        _employees = employees;
        _services = services;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog("Lỗi tải dữ liệu: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Thông báo", style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Chỉnh sửa nhân viên', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField("Họ và tên", nameController),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
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
                            child: Text(startTime == null ? 'Giờ bắt đầu' : 'Bắt đầu: ${startTime!.hour.toString().padLeft(2, '0')}:00'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
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
                            child: Text(endTime == null ? 'Giờ kết thúc' : 'Kết thúc: ${endTime!.hour.toString().padLeft(2, '0')}:00'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildTextField("Số điện thoại", phoneController, isPhone: true),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: "Trạng thái",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      items: ['Đang hoạt động', 'Đã nghỉ việc'].map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() => selectedStatus = value);
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Dịch vụ đảm nhiệm:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),
                    ..._services.map((service) => CheckboxListTile(
                      title: Text(service.title),
                      value: selectedServiceIds.contains(service.id),
                      onChanged: (bool? selected) {
                        setStateDialog(() {
                          selected == true
                              ? selectedServiceIds.add(service.id)
                              : selectedServiceIds.remove(service.id);
                        });
                      },
                    )),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Hủy"),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.update),
                  label: const Text("Cập nhật"),
                  onPressed: () async {
                    if (nameController.text.isEmpty || phoneController.text.isEmpty ||
                        startTime == null || endTime == null || selectedServiceIds.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
                      );
                      return;
                    }

                    if (!RegExp(r'^\d{10}$').hasMatch(phoneController.text)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Số điện thoại phải có đúng 10 chữ số")),
                      );
                      return;
                    }

                    if (endTime!.hour <= startTime!.hour) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Giờ kết thúc phải sau giờ bắt đầu")),
                      );
                      return;
                    }

                    final workingHours = "${startTime!.hour.toString().padLeft(2, '0')}:00 - ${endTime!.hour.toString().padLeft(2, '0')}:00";

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
                        _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Cập nhật thành công")),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Cập nhật thất bại")),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Lỗi: $e")),
                      );
                    }
                  },
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
        SnackBar(content: Text("Lỗi lấy danh sách dịch vụ: $e")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Thêm nhân viên', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField("Họ và tên", nameController),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
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
                            child: Text(startTime == null ? 'Giờ bắt đầu' : 'Bắt đầu: ${startTime!.hour.toString().padLeft(2, '0')}:00'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
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
                            child: Text(endTime == null ? 'Giờ kết thúc' : 'Kết thúc: ${endTime!.hour.toString().padLeft(2, '0')}:00'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildTextField("Số điện thoại", phoneController, isPhone: true),
                    const SizedBox(height: 15),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Dịch vụ đảm nhiệm:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),
                    ..._services.map((service) => CheckboxListTile(
                      title: Text(service.title),
                      value: selectedServiceIds.contains(service.id),
                      onChanged: (bool? selected) {
                        setStateDialog(() {
                          selected == true
                              ? selectedServiceIds.add(service.id)
                              : selectedServiceIds.remove(service.id);
                        });
                      },
                    )),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Lưu"),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();

                    if (name.isEmpty || phone.isEmpty || startTime == null || endTime == null || selectedServiceIds.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
                      );
                      return;
                    }

                    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Số điện thoại phải có đúng 10 chữ số"),
                          backgroundColor: Colors.orange,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                      return;
                    }

                    if (endTime!.hour <= startTime!.hour) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Giờ kết thúc phải sau giờ bắt đầu")),
                      );
                      return;
                    }

                    final workingHours =
                        "${startTime!.hour.toString().padLeft(2, '0')}:00 - ${endTime!.hour.toString().padLeft(2, '0')}:00";

                    final success = await ApiService.addEmployeeWithServices(
                      fullName: name,
                      phone: phone,
                      workingHours: workingHours,
                      serviceIds: selectedServiceIds.toList(),
                      status: 'Đang hoạt động',
                    );

                    if (success) {
                      Navigator.pop(context);
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Thêm nhân viên thành công")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Thêm nhân viên thất bại")),
                      );
                    }
                  },
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
          ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]
          : [],
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
    );
  }

  Widget _buildEmployeeCard(Employee emp) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    emp.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  tooltip: 'Chỉnh sửa nhân viên',
                  onPressed: () => _showEditEmployeeDialog(emp),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("Giờ làm: ${emp.workingHours}"),
            Text("SĐT: ${emp.phone}"),
            Text("Dịch vụ: ${emp.serviceNames.isEmpty ? 'Chưa có' : emp.serviceNames}"),
            Text("Trạng thái: ${emp.status}"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text("Quản lý nhân viên"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Thêm nhân viên',
            onPressed: _showAddEmployeeDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _employees.isEmpty
          ? const Center(child: Text("Chưa có nhân viên nào"))
          : ListView.builder(
        itemCount: _employees.length,
        itemBuilder: (context, index) => _buildEmployeeCard(_employees[index]),
      ),
    );
  }
}