import 'package:flutter/material.dart';
import 'package:flutter_advanced/src/services/auth_service.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  static const String path = "/settings";

  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.person),
            title: Text("Account"),
            subtitle: Text("Manage your account settings"),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text("Notifications"),
            subtitle: Text("Configure notification preferences"),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.security),
            title: Text("Privacy & Security"),
            subtitle: Text("Manage your privacy settings"),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () async {
              final authService = AuthService();
              await authService.logout();
              if (context.mounted) {
                context.go("/login");
              }
            },
          ),
        ],
      ),
    );
  }
}
