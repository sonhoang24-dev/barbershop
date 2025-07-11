class Service {
  final int id;
  final String title;
  final String description;
  final int price;
  final double rating;
  final List<String> images;

  Service({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rating,
    required this.images,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: int.tryParse(json['price'].toString()) ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      images: List<String>.from(json['images'] ?? []),
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'rating': rating,
      'images': images,
    };
  }

}
