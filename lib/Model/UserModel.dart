class UserModel {
  final int? id;
  final String shopName;
  final String address;
  final String email;
  final String number;
  final String password;

  UserModel({
    this.id,
    required this.shopName,
    required this.address,
    required this.email,
    required this.number,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'shop_name': shopName,
      'address': address,
      'email': email,
      'number': number,
      'password': password,
    };
  }

  /// ✅ ADD THIS fromJson CONSTRUCTOR
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      shopName: json['shop_name'],
      address: json['address'],
      email: json['email'],
      number: json['number'],
      password: json['password'],
    );
  }
}
