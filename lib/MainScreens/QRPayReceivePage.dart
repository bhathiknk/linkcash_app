import 'package:flutter/material.dart';

class QRReceivePage extends StatelessWidget {
  final int userId;

  const QRReceivePage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Payment'),
      ),
      body: Center(
        child: Text(
          'This is the Receive Page for user ID: $userId',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}