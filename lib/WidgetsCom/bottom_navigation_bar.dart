import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Import your existing pages:
import '../MainScreens/Home_Screen.dart';
import '../MainScreens/NotificationPage.dart';
import '../MainScreens/ProfileComponents/Profile_Screen.dart';
import '../MainScreens/QRPayReceivePage.dart';
import '../MainScreens/QRPaySendPage.dart';
import '../MainScreens/TransactionHistory_Screen.dart';

class BottomNavigationBarWithFab extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigationBarWithFab({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavigationBarWithFab> {
  final primaryColor = const Color(0xFF83B6B9);
  final backgroundColor = const Color(0xffffffff);
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  String? userId;

  @override
  void initState() {
    super.initState();
    _retrieveUserId();
  }

  Future<void> _retrieveUserId() async {
    String? retrievedUserId = await secureStorage.read(key: 'User_ID');
    if (retrievedUserId != null && mounted) {
      setState(() {
        userId = retrievedUserId;
      });
    }
  }

  void _navigateToPage(int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage(givenName: '')),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const NotificationPage(userId: '')),
        );
        break;
      case 2:
      // Show modal bottom sheet for QR actions
        _showQrOptions();
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
          MaterialPageRoute(builder: (context) => TransactionHistoryPage()),
        );
        break;
      default:
        break;
    }
  }

  void _showQrOptions() {
    if (userId == null) {
      debugPrint(" User ID not found! Cannot show QR options.");
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(16),

          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Choose an action",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _QrOptionTile(
                    icon: Icons.download_rounded,
                    label: "Receive",
                    onTap: () {
                      Navigator.pop(ctx); // dismiss bottom sheet
                      _navigateToReceivePage();
                    },
                  ),
                  _QrOptionTile(
                    icon: Icons.send_rounded,
                    label: "Send",
                    onTap: () {
                      Navigator.pop(ctx);
                      _navigateToSendPage();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToReceivePage() {
    if (userId == null) {
      debugPrint(" User ID not found! Cannot navigate to Receive.");
      return;
    }
    debugPrint("✅ Navigating to QRReceivePage with User ID: $userId");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRReceivePage(userId: int.parse(userId!)),
      ),
    );
  }

  void _navigateToSendPage() {
    if (userId == null) {
      debugPrint(" User ID not found! Cannot navigate to Send.");
      return;
    }
    debugPrint("✅ Navigating to QRSendPayPage with User ID: $userId");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRSendPayPage(userId: int.parse(userId!)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 75,
        child: BottomAppBar(
          color: backgroundColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                  icon: Icons.receipt_long,
                  selected: widget.currentIndex == 4,
                  onPressed: () {
                    widget.onTap(4);
                    _navigateToPage(4);
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

class _QrOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QrOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFF0054FF),
              radius: 28,
              child: Icon(
                icon,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class IconBottomBar extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final Function() onPressed;

  const IconBottomBar({
    super.key,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final primaryColor = const Color(0xFF0054FF);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Align(
        alignment: Alignment.topCenter,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            size: 23,
            color: selected ? primaryColor : Colors.black54,
          ),
        ),
      ),
    );
  }
}

class IconBottomBar2 extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final Function() onPressed;

  const IconBottomBar2({
    super.key,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final primaryColor = const Color(0xFF0054FF);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Align(
        alignment: Alignment.topCenter,
        child: CircleAvatar(
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
      ),
    );
  }
}
