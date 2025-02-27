import 'package:flutter/material.dart';

class QRSendPayPage extends StatelessWidget {
  final int userId;

  const QRSendPayPage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Payment'),
      ),
      body: Center(
        child: Text(
          'This is the Send Page for user ID: $userId',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}