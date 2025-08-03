import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Authentication/Login.dart';
import '../../Database/UserRepository.dart';

class Topbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Logo/Branding
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: theme.primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                "Invoxel",
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          // Right: Action Icons
          Row(
            children: [
              _buildActionButton(
                context,
                icon: Icons.note_outlined,
                tooltip: "Quick Notes",
                onPressed: () {
                  // TODO: Handle notes action
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.local_shipping_outlined,
                tooltip: "Transport Management",
                onPressed: () {
                  // TODO: Handle transport action
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.account_circle_outlined,
                tooltip: "User Profile",
                onPressed: () {
                  // TODO: Navigate to profile
                },
              ),
              const SizedBox(width: 8),
              Container(
                height: 32,
                width: 1,
                color: Colors.grey[300],
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                context,
                icon: Icons.logout_outlined,
                tooltip: "Logout",
                onPressed: () => _handleLogout(context),
                isLogout: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
              (route) => false,
        );
      }
    }
  }

  Widget _buildActionButton(
      BuildContext context, {
        required IconData icon,
        required String tooltip,
        required VoidCallback onPressed,
        bool isLogout = false,
      }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return IconButton(
      icon: Icon(
        icon,
        size: 22,
        color: isLogout
            ? Colors.red[400]
            : isDarkMode
            ? Colors.grey[300]
            : Colors.grey[700],
      ),
      tooltip: tooltip,
      onPressed: onPressed,
      splashRadius: 20,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
    );
  }
}