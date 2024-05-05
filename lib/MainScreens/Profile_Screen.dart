import 'package:flutter/material.dart';

import '../WidgetsCom/bottom_navigation_bar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0054FF),
        title: const Text("Profile Page"),
      ),
      body: Container(
        color: const Color(0xFFE3F2FD), // Background color for the body
        child: const Center(
          child: Text("This is the Link Page"),
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: 3,
        onTap: (index) {
          // Handle navigation if needed
        },
      ),
    );
  }
}
