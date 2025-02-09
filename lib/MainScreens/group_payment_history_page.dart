import 'package:flutter/material.dart';
import '../WidgetsCom/dark_mode_handler.dart'; // If you use custom colors

class GroupPaymentHistoryPage extends StatelessWidget {
  const GroupPaymentHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Group Payment History",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: DarkModeHandler.getAppBarColor(),
      ),
      body: Center(
        child: Text(
          "History of group payments will be displayed here.",
          style: TextStyle(fontSize: 18, color: Colors.grey[800]),
        ),
      ),
    );
  }
}
