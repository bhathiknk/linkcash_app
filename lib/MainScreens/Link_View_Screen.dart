import 'package:flutter/material.dart';

import '../WidgetsCom/bottom_navigation_bar.dart';

class LinkViewPage extends StatelessWidget {
  const LinkViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0054FF),
        title: const Text("Link View Page"),
      ),
      body: Container(
        color: const Color(0xFFE3F2FD), // Background color for the body
        child: const Center(
          child: Text("This is the Link View Page"),
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: 2,
        onTap: (index) {
          // Handle navigation if needed
        },
      ),
    );
  }
}
