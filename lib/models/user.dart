class User {
  final int id;
  final String name;
  final String email;
  final String gender;
  final String phone;
  final String role;
  final String avatar;

  User({required this.id, required this.name, required this.email, required this.role, required this.gender, required this.phone, required this.avatar});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse(json['id'].toString()),
      name: json['name'],
      email: json['email'],
      gender: json['gender'],
      phone: json['phone'],
      role: json['role'],
      avatar: json['avatar'],
    );
  }
}
