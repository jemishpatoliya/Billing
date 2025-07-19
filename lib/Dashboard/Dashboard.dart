import 'package:flutter/material.dart';
import '../Model/UserModel.dart';

class DashboardScreen extends StatelessWidget {
  final UserModel user;
  const DashboardScreen({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard"),
      automaticallyImplyLeading: false,),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Welcome, ${user.shopName}!",
                style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            Text("Email: ${user.email}"),
            Text("Mobile: ${user.number}"),
            Text("Address: ${user.address}"),
          ],
        ),
      ),
    );
  }
}
