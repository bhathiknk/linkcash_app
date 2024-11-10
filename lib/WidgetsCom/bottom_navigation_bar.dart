import 'package:flutter/material.dart';
import '../MainScreens/Link_Screen.dart';
import '../MainScreens/Home_Screen.dart';
import '../MainScreens/Notification_Screen.dart';
import '../MainScreens/Profile_Screen.dart';
import '../MainScreens/TransactionHistory_Screen.dart'; // Import the new transaction history page

class BottomNavigationBarWithFab extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigationBarWithFab({
    required this.currentIndex,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  _BottomNavBarFb1State createState() => _BottomNavBarFb1State();
}

class _BottomNavBarFb1State extends State<BottomNavigationBarWithFab> {
  final primaryColor = const Color(0xFF83B6B9);
  final backgroundColor = const Color(0xffffffff);

  // Handle navigation on icon tap
  void _navigateToPage(int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage(givenName: '',)),
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
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TransactionHistoryPage()), // Navigate to Transaction History Page
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 75, // Set the desired height for the BottomAppBar
        child: BottomAppBar(
          color: backgroundColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0), // Adjust horizontal padding if needed
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconBottomBar(
                  icon: Icons.home_rounded,
                  selected: widget.currentIndex == 0,
                  onPressed: () {
                    widget.onTap(0);
                    _navigateToPage(0);
                  },
                ),
                IconBottomBar(
                  icon: Icons.receipt_long, // Updated to transaction history icon
                  selected: widget.currentIndex == 4, // Update to handle transaction history icon
                  onPressed: () {
                    widget.onTap(4);
                    _navigateToPage(4); // Navigate to the transaction history page
                  },
                ),
                IconBottomBar2(
                  icon: Icons.link_rounded,
                  selected: widget.currentIndex == 2,
                  onPressed: () {
                    widget.onTap(2);
                    _navigateToPage(2);
                  },
                ),
                IconBottomBar(
                  icon: Icons.notifications_rounded,
                  selected: widget.currentIndex == 1,
                  onPressed: () {
                    widget.onTap(1);
                    _navigateToPage(1);
                  },
                ),
                IconBottomBar(
                  icon: Icons.account_circle_rounded,
                  selected: widget.currentIndex == 3,
                  onPressed: () {
                    widget.onTap(3);
                    _navigateToPage(3);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IconBottomBar extends StatelessWidget {
  const IconBottomBar({
    Key? key,
    required this.icon,
    required this.selected,
    required this.onPressed,
  }) : super(key: key);

  final IconData icon;
  final bool selected;
  final Function() onPressed;

  final primaryColor = const Color(0xFF0054FF);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onPressed,
              icon: Icon(
                icon,
                size: 23,
                color: selected ? primaryColor : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IconBottomBar2 extends StatelessWidget {
  const IconBottomBar2({
    Key? key,
    required this.icon,
    required this.selected,
    required this.onPressed,
  }) : super(key: key);

  final IconData icon;
  final bool selected;
  final Function() onPressed;

  final primaryColor = const Color(0xFF0054FF);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: primaryColor,
              child: IconButton(
                onPressed: onPressed,
                icon: Icon(
                  icon,
                  size: 23,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
