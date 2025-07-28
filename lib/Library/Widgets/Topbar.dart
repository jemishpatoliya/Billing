import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Authentication/Login.dart';
import '../../Database/UserRepository.dart';

class Topbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.deepPurple,
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Drawer button and title
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
              SizedBox(width: 10),
              Text(
                "All Transports",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          // Right: Icons
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.note, color: Colors.white),
                onPressed: () {
                  // TODO: Navigate or handle notes icon
                },
              ),
              IconButton(
                icon: Icon(Icons.local_shipping, color: Colors.white),
                onPressed: () {
                  // TODO: Handle transport action
                },
              ),
              IconButton(
                icon: Icon(Icons.account_circle, color: Colors.white),
                onPressed: () {
                  // TODO: Navigate to profile
                },
              ),
              IconButton(
                icon: Icon(Icons.logout, color: Colors.white),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();

                    Future.delayed(Duration(milliseconds: 100), () {
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      }
                    });
                  }
              ),
              SizedBox(width: 10),
            ],
          ),
        ],
      ),
    );
  }
}
