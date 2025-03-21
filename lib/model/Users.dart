class User {
  int userId;
  final String name;
  final String email;
  final String password;
  final int phone;
  String? address;
  String? avatar;
  String? avatarLocation;
  int isAdmin;

  User({
    required this.userId,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    this.address,
    this.avatar,
    this.avatarLocation,
    required this.isAdmin,
  });

  // Convert User object to a Map for JSON encoding
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'address': address,
      'avatar': avatar,
      'avatarLocation': avatarLocation,
      'isAdmin': isAdmin,
    };
  }

  // Create a new User object with updated values
  User copyWith({
    int? userId,
    String? name,
    String? email,
    String? password,
    int? phone,
    String? address,
    String? avatar,
    String? avatarLocation,
    int? isAdmin,
  }) {
    return User(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      avatar: avatar ?? this.avatar,
      avatarLocation: avatarLocation ?? this.avatarLocation,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  // Update User object from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
      phone: json['phone'],
      address: json['address'],
      avatar: json['avatar'],
      avatarLocation: json['avatarLocation'],
      isAdmin: json['isAdmin'] ?? 0,
    );
  }
}
