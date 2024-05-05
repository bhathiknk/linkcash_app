import 'package:flutter/material.dart';
import '../MainScreens/Create_Link_Screen.dart';
import '../MainScreens/Home_Screen.dart';
import '../MainScreens/Notification_Screen.dart';
import '../MainScreens/Profile_Screen.dart'; // Import other page files

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
    return Theme(
      data: ThemeData(
        splashColor: Colors.transparent, // Make splash color transparent
        highlightColor: Colors.transparent, // Make highlight color transparent
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.blue,
        elevation: 0.0, // Remove the default shadow effect
        currentIndex: widget.currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyHomePage()),
              );
              break;
            case 1:

            Navigator.push(
             context,
             MaterialPageRoute(builder: (context) => NotificationPage()),
            );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LinkPage()),
              );
              break;
            case 3:

             Navigator.push(
               context,
               MaterialPageRoute(builder: (context) => ProfilePage()),
             );
              break;
          }
        },
        unselectedItemColor: Colors.black, // Set the unselected item color to black
        selectedItemColor: Colors.blue, // Set the selected item color to blue
        items: const [
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
      ),
    );
  }
}
