import 'package:flutter/material.dart';

class NoInternetUI extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 100, color: Colors.red),
          SizedBox(height: 20),
          Text(
            'No Internet Connection',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          SizedBox(height: 10),
          Text(
            'Please check your internet connection and try again.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
