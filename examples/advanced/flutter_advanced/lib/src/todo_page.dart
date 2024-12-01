import 'package:flutter/material.dart';

class TodosPage extends StatelessWidget {
  static const String path = "/todos";

  const TodosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("TODOs"),
    );
  }
}
