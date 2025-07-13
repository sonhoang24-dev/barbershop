import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/service.dart';
import '../../models/extra_service.dart';
import '../../services/api_service.dart';

class AddOrEditServiceScreen extends StatefulWidget {
  final Service? service;

  const AddOrEditServiceScreen({super.key, this.service});

  @override
  State<AddOrEditServiceScreen> createState() => _AddOrEditServiceScreenState();
}

class _AddOrEditServiceScreenState extends State<AddOrEditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _priceController;

  List<XFile> _selectedImages = [];
  List<String> _existingImages = [];
  List<Map<String, dynamic>> _extras = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.service?.title ?? '');
    _descController = TextEditingController(text: widget.service?.description ?? '');
    _priceController = TextEditingController(
      text: widget.service != null
          ? NumberFormat.decimalPattern('vi_VN').format(widget.service!.price)
          : '',
    );

    _initializeExtras();
    print('Initialized extras: $_extras'); // Debug log
  }

  void _initializeExtras() {
    if (widget.service != null) {
      _existingImages = List<String>.from(widget.service!.images ?? []);
      if (widget.service!.extras != null && widget.service!.extras.isNotEmpty) {
        _extras = widget.service!.extras.map((e) {
          return {
            'id': e.id,
            'name': e.name ?? '',
            'price': e.price != null ? NumberFormat.decimalPattern('vi_VN').format(e.price) : NumberFormat.decimalPattern('vi_VN').format(0.0),
            'priceController': TextEditingController(
              text: e.price != null ? NumberFormat.decimalPattern('vi_VN').format(e.price) : NumberFormat.decimalPattern('vi_VN').format(0.0),
            ),
          };
        }).toList();
        print('Loaded extras from service: $_extras'); // Debug log
      } else {
        print('No extras found in service, initializing default');
      }
    }
    if (_extras.isEmpty) {
      _extras.add({
        'name': '',
        'price': NumberFormat.decimalPattern('vi_VN').format(0.0),
        'priceController': TextEditingController(text: NumberFormat.decimalPattern('vi_VN').format(0.0)),
      });
      print('Initialized default extras: $_extras'); // Debug log
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() => _selectedImages.addAll(images));
    }
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _titleController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên dịch vụ không được để trống')),
      );
      return;
    }

    final priceText = _priceController.text.replaceAll('.', '');
    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giá phải là số dương hợp lệ')),
      );
      return;
    }

    final isUpdate = widget.service != null;
    final extrasList = _extras
        .where((e) => (e['name']?.isNotEmpty ?? false) && e['price'] != null && e['price'] != '')
        .map((e) {
      final cleanPrice = e['price'].toString().replaceAll('.', '');
      final parsedPrice = double.tryParse(cleanPrice) ?? 0.0;
      return ExtraService(
        id: e['id'],
        mainServiceId: isUpdate ? widget.service!.id : null,
        name: e['name']!,
        price: parsedPrice,
      );
    })
        .toList();

    if (extrasList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ít nhất phải có 1 dịch vụ đi kèm hợp lệ')),
      );
      return;
    }

    print('Sending: {name: $name, price: $price, extras: ${extrasList.map((e) => {'name': e.name, 'price': e.price, 'mainServiceId': e.mainServiceId}).toList()}, serviceId: ${isUpdate ? widget.service!.id : null}}');
    final result = await ApiService.addOrUpdateService(
      name: name,
      description: _descController.text.trim(),
      price: price,
      images: _selectedImages,
      serviceId: isUpdate ? widget.service!.id : null,
      extras: extrasList,
    );

    if (context.mounted) {
      print('API Response: $result');
      if (result is Map<String, dynamic> && result['success'] == true) {
        if (result.containsKey('images')) {
          setState(() {
            _existingImages = List<String>.from(result['images']);
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isUpdate ? 'Cập nhật thành công!' : 'Thêm thành công!'),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
        Navigator.pop(context, true);
      } else if (result is Map<String, dynamic>) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra: ${result['message'] ?? 'Không xác định'}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isUpdate ? 'Cập nhật thành công!' : 'Thêm thành công!'),
              backgroundColor: Theme.of(context).primaryColor,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Có lỗi xảy ra: ID, tên và giá phải hợp lệ'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpdate = widget.service != null;
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.decimalPattern('vi_VN');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isUpdate ? 'Chỉnh sửa dịch vụ' : 'Thêm dịch vụ mới',
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: theme.primaryColor,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin dịch vụ chính',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Tên dịch vụ *',
                          hintText: 'Nhập tên dịch vụ (tối đa 100 ký tự)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return 'Tên dịch vụ không được để trống';
                          if (value.trim().length > 100)
                            return 'Tên quá dài (tối đa 100 ký tự)';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Giá (VNĐ) *',
                          hintText: 'Nhập giá (số dương, ví dụ: 10.000)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final clean = value.replaceAll('.', '');
                          if (clean.isNotEmpty) {
                            final parsed = double.tryParse(clean) ?? 0.0;
                            final formatted = numberFormat.format(parsed);
                            _priceController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                          }
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return 'Giá không được để trống';
                          final clean = value.replaceAll('.', '');
                          final parsed = double.tryParse(clean);
                          if (parsed == null || parsed <= 0)
                            return 'Giá phải là số dương hợp lệ';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Mô tả',
                          hintText: 'Nhập mô tả (tùy chọn)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Chọn hình ảnh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedImages.isNotEmpty) _buildSelectedImageList(),
                      if (_existingImages.isNotEmpty && widget.service != null) _buildExistingImageList(),
                    ],
                  ),
                ),
              ),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dịch vụ đi kèm',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (_extras.isNotEmpty) // Đảm bảo danh sách luôn hiển thị nếu có dữ liệu
                        ..._extras.asMap().entries.map((entry) {
                          final index = entry.key;
                          final extra = entry.value;
                          final priceController = extra['priceController'] as TextEditingController? ?? (extra['priceController'] = TextEditingController(text: extra['price'] ?? NumberFormat.decimalPattern('vi_VN').format(0.0))) as TextEditingController;
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      initialValue: extra['name'],
                                      decoration: InputDecoration(
                                        labelText: 'Tên dịch vụ đi kèm *',
                                        hintText: 'Nhập tên (tối đa 100 ký tự)',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty)
                                          return 'Tên không được để trống';
                                        if (value.trim().length > 100)
                                          return 'Tên quá dài (tối đa 100 ký tự)';
                                        return null;
                                      },
                                      onChanged: (val) => setState(() => _extras[index]['name'] = val),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      controller: priceController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Giá (VNĐ) *',
                                        hintText: 'Nhập giá (số dương, ví dụ: 10.000)',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                      ),
                                      onChanged: (value) {
                                        final clean = value.replaceAll('.', '');
                                        if (clean.isNotEmpty) {
                                          final parsed = double.tryParse(clean) ?? 0.0;
                                          final formatted = numberFormat.format(parsed);
                                          priceController.value = TextEditingValue(
                                            text: formatted,
                                            selection: TextSelection.collapsed(offset: formatted.length),
                                          );
                                          setState(() => _extras[index]['price'] = formatted);
                                        }
                                      },
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty)
                                          return 'Giá không được để trống';
                                        final clean = value.replaceAll('.', '');
                                        final parsed = double.tryParse(clean);
                                        if (parsed == null || parsed <= 0)
                                          return 'Giá phải là số dương hợp lệ';
                                        return null;
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                                    onPressed: _extras.length > 1
                                        ? () => setState(() {
                                      _extras.removeAt(index);
                                      priceController.dispose();
                                    })
                                        : null,
                                    tooltip: _extras.length > 1 ? 'Xóa dịch vụ' : 'Ít nhất 1 dịch vụ đi kèm',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                          );
                        }).toList(),
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _extras.add({
                            'name': '',
                            'price': NumberFormat.decimalPattern('vi_VN').format(0.0),
                            'priceController': TextEditingController(text: NumberFormat.decimalPattern('vi_VN').format(0.0)),
                          });
                        }),
                        icon: const Icon(Icons.add, color: Colors.green),
                        label: const Text('Thêm dịch vụ đi kèm'),
                        style: TextButton.styleFrom(foregroundColor: theme.primaryColor),
                      ),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _saveService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(widget.service != null ? 'Cập nhật dịch vụ' : 'Thêm dịch vụ'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedImageList() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_selectedImages[index].path),
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedImages.removeAt(index)),
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExistingImageList() {
    print('Existing images: $_existingImages'); // Debug log
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _existingImages.length,
        itemBuilder: (context, index) {
          try {
            final imgData = base64Decode(_existingImages[index].split(',').last);
            return Stack(
              children: [
                Container(
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
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _existingImages.removeAt(index)),
                    child: const CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.redAccent,
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
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
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    for (var extra in _extras) {
      if (extra['priceController'] is TextEditingController) {
        (extra['priceController'] as TextEditingController).dispose();
      }
    }
    super.dispose();
  }
}