import 'package:flutter/material.dart';
import '../MainScreens/Create_Link_Screen.dart';
import '../MainScreens/Link_Screen.dart';
import '../MainScreens/Home_Screen.dart';
import '../MainScreens/Notification_Screen.dart';
import '../MainScreens/ProfileComponents/Profile_Screen.dart';
import '../MainScreens/TransactionHistory_Screen.dart'; // Import the new transaction history page
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BottomNavigationBarWithFab extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigationBarWithFab({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  @override
  _BottomNavBarFb1State createState() => _BottomNavBarFb1State();
}

class _BottomNavBarFb1State extends State<BottomNavigationBarWithFab> {
  final primaryColor = const Color(0xFF83B6B9);
  final backgroundColor = const Color(0xffffffff);
  bool isVerified = false;
  String? userId;
  String? stripeAccountId;

  @override
  void initState() {
    super.initState();
    _retrieveUserId(); // Start the process of fetching the Stripe account and verification status
  }

  /// Retrieve User ID from secure storage
  Future<void> _retrieveUserId() async {
    final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
    String? retrievedUserId = await secureStorage.read(key: 'User_ID');
    setState(() {
      userId = retrievedUserId;
    });
    if (userId != null) {
      _fetchStripeAccountId(); // Fetch Stripe account ID after retrieving User ID
    }
  }

  /// Fetch the Stripe account ID for the logged-in user
  Future<void> _fetchStripeAccountId() async {
    final String apiUrl =
        "http://10.0.2.2:8080/api/users/$userId/stripe-account";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          stripeAccountId = responseData['stripeAccountId'];
        });
        _fetchVerificationStatus(); // Fetch verification status after getting account ID
      } else {
        print("Failed to fetch Stripe Account ID: ${response.body}");
      }
    } catch (e) {
      print("Error fetching Stripe Account ID: $e");
    }
  }

  /// Fetch the Stripe account verification status
  Future<void> _fetchVerificationStatus() async {
    if (stripeAccountId == null) return;

    final String apiUrl =
        "http://10.0.2.2:8080/api/stripe/$stripeAccountId/verification-status";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          isVerified = responseData['verificationStatus'] == "Verified";
        });
      } else {
        print("Failed to fetch verification status: ${response.body}");
      }
    } catch (e) {
      print("Error fetching verification status: $e");
    }
  }

  /// Show a popup message if the user is not verified
  void _showVerificationPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Set background color to white
          title: const Text(
            "Account Not Verified",
            style: TextStyle(color: Colors.black), // Set text color
          ),
          content: const Text(
            "Please verify your Stripe account to access the Link Page.",
            style: TextStyle(color: Colors.black), // Set text color
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the popup
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black), // Set text color
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the popup
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0054FF), // Button background color
              ),
              child: const Text("Go to Profile",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// Handle navigation on icon tap
  void _navigateToPage(int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MyHomePage(
                    givenName: '',
                  )),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NotificationPage()),
        );
        break;
      case 2:
        if (isVerified) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateLinkPage()),
          );
        } else {
          _showVerificationPopup(context); // Show the popup if not verified
        }
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 75, // Set the desired height for the BottomAppBar
        child: BottomAppBar(
          color: backgroundColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 8.0), // Adjust horizontal padding if needed
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
                  icon:
                      Icons.receipt_long, // Updated to transaction history icon
                  selected: widget.currentIndex ==
                      4, // Update to handle transaction history icon
                  onPressed: () {
                    widget.onTap(4);
                    _navigateToPage(
                        4); // Navigate to the transaction history page
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
    super.key,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

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
    super.key,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

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
