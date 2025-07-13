class Booking {
  final int id;
  final int? userId;
  final int? serviceId;
  final int? employeeId;
  final DateTime date;
  final String time;
  final double total;
  final String status;
  final String customerName;
  final String customerPhone;
  final String note;
  final String serviceName;
  final String? userName;
  final String? employeeName;

  Booking({
    required this.id,
    this.userId,
    this.serviceId,
    this.employeeId,
    required this.date,
    required this.time,
    required this.total,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.note,
    required this.serviceName,
    this.userName,
    this.employeeName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null,
      serviceId: json['service_id'] != null ? int.tryParse(json['service_id'].toString()) : null,
      employeeId: json['employee_id'] != null && json['employee_id'].toString().isNotEmpty
          ? int.tryParse(json['employee_id'].toString())
          : null,
      date: DateTime.parse(json['date']),
      time: json['time'] ?? '',
      total: double.tryParse(json['total'].toString()) ?? 0.0,
      status: json['status'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      note: json['note'] ?? '',
      serviceName: json['service_name'] ?? '',
      userName: json['user_name'],
      employeeName: json['employee_name'],
    );
  }
}
