import 'package:flutter/material.dart';

class AddItemsPage extends StatelessWidget {
  const AddItemsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color brightBlueColor = const Color(0xFF0054FF);
    final Color whiteColor = const Color(0xFFFFFFFF);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Items"),
        backgroundColor: brightBlueColor,
        foregroundColor: whiteColor,
      ),
      body: Center(
        child: Text(
          "Add new items for your shop here.",
          style: TextStyle(
            fontSize: 18,
            color: brightBlueColor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
