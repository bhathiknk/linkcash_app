import 'package:flutter/material.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';

class LinkPage extends StatelessWidget {
  const LinkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0054FF),
        title: const Text("Link Page"),
      ),
      body: Container(
        color: const Color(0xFFE3F2FD), // Background color for the body
        child: const Center(
          child: Text("This is the Link Page"),
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: 2, // Set the current index to 2 to highlight the "Link" tab
        onTap: (index) {
          // Handle navigation if needed
        },
      ),
    );
  }
}
