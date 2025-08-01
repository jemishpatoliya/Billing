class UserModel {
  int? id;
  String shopName;
  String address;
  String email;
  String number;
  String password;
  String role;
  String? status;
  String? permissions; // JSON-encoded string

  UserModel({
    this.id,
    required this.shopName,
    required this.address,
    required this.email,
    required this.number,
    required this.password,
    required this.role,
    this.status,
    this.permissions,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'shop_name': shopName,
    'address': address,
    'email': email,
    'number': number,
    'password': password,
    'role': role,
    'status': status,
    'permissions': permissions,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    shopName: json['shop_name'],
    address: json['address'],
    email: json['email'],
    number: json['number'],
    password: json['password'],
    role: json['role'],
    status: json['status'],
    permissions: json['permissions'],
  );
}
