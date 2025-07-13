import 'extra_service.dart';

int? parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', ''));
  return null;
}

class Service {
  final int id;
  final String title;
  final String description;
  final double price;
  final List<String> images;
  final double rating;
  final List<ExtraService> extras;

  Service({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.images,
    required this.rating,
    this.extras = const [],
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: parseInt(json['id']) ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: parseDouble(json['price']) ?? 0.0,
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      rating: parseDouble(json['rating']) ?? 0.0,
      extras: (json['extras'] as List?)
          ?.map((e) => ExtraService.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'images': images,
      'rating': rating,
      'extras': extras.map((e) => e.toMap()).toList(),
    };
  }
}
