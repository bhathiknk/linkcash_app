import 'package:flutter/material.dart';
import '../WidgetsCom/dark_mode_handler.dart'; // Make sure this import points correctly to your DarkModeHandler

class NoInternetUI extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: DarkModeHandler.getBackgroundColor(), // Set the background color
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustrative image or icon
              Icon(
                Icons.wifi_off_rounded,
                size: 120,
                color: Colors.redAccent[200],
              ),
              const SizedBox(height: 30),
              // Primary message
              const Text(
                'No Internet Connection',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              // Secondary message with a hint of professionalism
              const Text(
                'It seems you are offline. Please check your connection and try again.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
