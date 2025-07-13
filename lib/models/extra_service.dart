class ExtraService {
  final int? id;
  final int? mainServiceId; // Liên kết với services.id
  final String name;
  final double price;

  ExtraService({
    this.id,
    this.mainServiceId,
    required this.name,
    required this.price,
  });

  factory ExtraService.fromJson(Map<String, dynamic> json) {
    return ExtraService(
      id: _parseInt(json['id']),
      mainServiceId: _parseInt(json['main_service_id']),
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (mainServiceId != null) 'main_service_id': mainServiceId,
      'name': name,
      'price': price,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}