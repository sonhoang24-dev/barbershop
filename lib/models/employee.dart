class Employee {
  final int id;
  final String fullName;
  final String workingHours;
  final String phone;
  final String serviceNames;
  final String status;

  Employee({
    required this.id,
    required this.fullName,
    required this.workingHours,
    required this.phone,
    required this.serviceNames,
    required this.status,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: int.tryParse(json['id'].toString()) ?? 0,
      fullName: json['full_name'] ?? '',
      workingHours: json['working_hours'] ?? '',
      phone: json['phone'] ?? '',
      serviceNames: json['service_names'] ?? '',
      status: json['status'] ?? 'Đang hoạt động',
    );
  }
}