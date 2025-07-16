class UserModel {
  final String shopName;
  final String address;
  final String email;
  final String number;
  final String password;

  UserModel({
    required this.shopName,
    required this.address,
    required this.email,
    required this.number,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      "shop_name": shopName,
      "address": address,
      "email": email,
      "number": number,
      "password": password,
    };
  }
}
