import 'package:flutter/material.dart';

/// Temporary destination page for staff dashboard actions.
class StaffPlaceholderPage extends StatelessWidget {
  const StaffPlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}