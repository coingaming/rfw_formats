import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  static const String path = "/settings";

  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Settings"),
    );
  }
}
