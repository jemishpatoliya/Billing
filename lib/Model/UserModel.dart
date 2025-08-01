class UserModel {
  int? id;
  String shopName;
  String username; // 👈 NEW FIELD
  String address;
  String email;
  String number;
  String password;
  String role;
  String? status;
  String? permissions;

  UserModel({
    this.id,
    required this.shopName,
    required this.username, // 👈 add here too
    required this.address,
    required this.email,
    required this.number,
    required this.password,
    required this.role,
    this.status,
    this.permissions,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_name': shopName,
      'username': username, // 👈 insert into db
      'address': address,
      'email': email,
      'number': number,
      'password': password,
      'role': role,
      'status': status,
      'permissions': permissions,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      shopName: json['shop_name'],
      username: json['username'] ?? '', // 👈 read from db
      address: json['address'],
      email: json['email'],
      number: json['number'],
      password: json['password'],
      role: json['role'],
      status: json['status'],
      permissions: json['permissions'],
    );
  }
}
