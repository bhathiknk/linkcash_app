import 'package:flutter/material.dart';

class BillHistoryPage extends StatelessWidget {
  const BillHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color brightBlueColor = const Color(0xFF0054FF);
    final Color whiteColor = const Color(0xFFFFFFFF);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bill History"),
        backgroundColor: brightBlueColor,
        foregroundColor: whiteColor,
      ),
      body: Center(
        child: Text(
          "Your Bill History will appear here.",
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
