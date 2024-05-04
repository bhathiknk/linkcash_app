import 'package:flutter/material.dart';

class BottomNavigationBarWithFab extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigationBarWithFab({
    required this.currentIndex,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  _BottomNavigationBarWithFabState createState() =>
      _BottomNavigationBarWithFabState();
}

class _BottomNavigationBarWithFabState
    extends State<BottomNavigationBarWithFab> {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.black, // Set the background color to black
      elevation: 0.0, // Remove the default shadow effect
      currentIndex: widget.currentIndex,
      onTap: widget.onTap,
      unselectedItemColor: Colors.black, // Set the unselected item color to black
      selectedItemColor: Colors.blue, // Set the selected item color to blue
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_rounded),
          label: 'Notification',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.link_rounded),
          label: 'Link',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle_rounded),
          label: 'Account',
        ),
      ],
    );
  }
}
