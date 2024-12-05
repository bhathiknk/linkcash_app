import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For secure storage
import '../ConnectionCheck/No_Internet_Ui.dart';
import '../ConnectionCheck/connectivity_service.dart';
import '../WidgetsCom/bottom_navigation_bar.dart'; // Custom bottom navigation bar with floating action button
import '../WidgetsCom/dark_mode_handler.dart'; // Handles dark mode colors throughout the app
import 'Create_Link_Screen.dart'; // Create Link Screen
import '../WidgetsCom/gradient_button_fb4.dart'; // Gradient button widget
import 'package:http/http.dart' as http; // For HTTP requests

class LinkPage extends StatefulWidget {
  LinkPage({Key? key}) : super(key: key);

  @override
  _LinkPageState createState() => _LinkPageState();
}

class _LinkPageState extends State<LinkPage> {
  final List<Color> circleColors = [
    Color(0xFFBCC2FF),
    Color(0xFFFA9090),
    Color(0xFFBBF8AB),
    Color(0xFFEFCDA9),
    Color(0xFFE4B6F1),
    Color(0xFFEEE2A8),
  ];

  List<Map<String, dynamic>> linkData = [];// Store fetched titles
  bool isConnected = true;
  String? userId;
  bool showActiveLinks = true; // Default to active links

  @override
  void initState() {
    super.initState();
    _retrieveUserId();
    _checkInitialConnectivity();
    _listenToConnectivityChanges();
  }

  Future<void> _retrieveUserId() async {
    final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
    String? retrievedUserId = await secureStorage.read(key: 'User_ID');
    setState(() {
      userId = retrievedUserId;
    });
    if (userId != null) {
      _fetchLinkTitles(); // Fetch titles initially
    }
  }

  Future<void> _checkInitialConnectivity() async {
    var connectivityResult = await ConnectivityService().checkInitialConnectivity();
    setState(() {
      isConnected = connectivityResult != ConnectivityResult.none;
    });
  }

  void _listenToConnectivityChanges() {
    ConnectivityService().connectivityStream.listen((result) {
      setState(() {
        isConnected = result != ConnectivityResult.none;
      });
    });
  }

  // Fetch link titles from the API based on active or expired state
  // Fetch link titles from the API
  Future<void> _fetchLinkTitles() async {
    if (userId == null) return; // If userId is not retrieved, skip fetching
    final String apiUrl = showActiveLinks
        ? "http://10.0.2.2:8080/api/payment-links/user/$userId/active"
        : "http://10.0.2.2:8080/api/payment-links/user/$userId/expired";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          // Parse API response as List<Map<String, dynamic>>
          linkData = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        print("Failed to fetch link titles: ${response.body}");
      }
    } catch (e) {
      print("Error occurred while fetching link titles: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: DarkModeHandler.getAppBarColor(),
        title: const Text(
          'Payment Link',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: isConnected ? _buildMainContent(context) : NoInternetUI(),
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: 2,
        onTap: (index) {
          // Handle navigation if needed
        },
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Container(
      color: DarkModeHandler.getBackgroundColor(),
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          _buildSearchBar(context),
          const SizedBox(height: 20),
          _buildCreateLinkButton(context),
          const SizedBox(height: 20),
          _buildLinkHistoryTitle(),
          const SizedBox(height: 20),
          _buildLinkHistoryToggleButtons(), // Toggle buttons for Active and Expired links
          const SizedBox(height: 10),
          _buildLinkHistoryList(context),

        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50.0,
      child: Container(
        decoration: BoxDecoration(
          color: DarkModeHandler.getSearchBarColor(),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: TextStyle(color: DarkModeHandler.getInputTextColor()),
              prefixIcon: Icon(Icons.search, color: DarkModeHandler.getInputTextColor()),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(top: 12.0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateLinkButton(BuildContext context) {
    return Center(
      child: GradientButtonFb4(
        text: 'Create Link',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateLinkPage()),
          );
        },
      ),
    );
  }

  // Builds the title for the saved link history section
  Widget _buildLinkHistoryTitle() {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Saved Link History',
          style: TextStyle(
            fontSize: 18,
            color: DarkModeHandler.getMainBackgroundTextColor(), // Text color based on theme
          ),
        ),
      ),
    );
  }

  Widget _buildLinkHistoryToggleButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            if (!showActiveLinks) {
              setState(() {
                showActiveLinks = true;
                _fetchLinkTitles(); // Fetch Active links
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: showActiveLinks
                ? Color(0xFF83B6B9) // Selected button color
                : Colors.grey.withOpacity(0.3), // Unselected button color
            foregroundColor: Colors.white,
          ),
          child: const Text('Active'),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {
            if (showActiveLinks) {
              setState(() {
                showActiveLinks = false;
                _fetchLinkTitles(); // Fetch Expired links
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: !showActiveLinks
                ? Color(0xFF83B6B9) // Selected button color
                : Colors.grey.withOpacity(0.3), // Unselected button color
            foregroundColor: Colors.white,
          ),
          child: const Text('Expired'),
        ),
      ],
    );
  }




  // Update the link history item to display dynamic title and calculate expired before days
  Widget _buildLinkHistoryItem(BuildContext context, int index, Map<String, dynamic> link) {
    final String title = link['title'] ?? 'Untitled'; // Extract title from the structured data
    final String expireAfter = link['expireAfter'] ?? 'N/A'; // Extract expireAfter from the structured data
    final String createdAt = link['createdAt'] ?? ''; // Extract createdAt from the structured data

    // Calculate "expired before" days
    String expiredBefore = '';
    if (!showActiveLinks && createdAt.isNotEmpty) {
      expiredBefore = _calculateExpiredBefore(createdAt, expireAfter);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: 100,
          decoration: BoxDecoration(
            color: DarkModeHandler.getMainContainersColor(),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                _buildIconContainer(index),
                const SizedBox(width: 20),
                _buildLinkText(title, expireAfter, expiredBefore), // Pass title, expireAfter, and expiredBefore
              ],
            ),
          ),
        ),
      ),
    );
  }

// Update link history list to use structured data
  Widget _buildLinkHistoryList(BuildContext context) {
    if (linkData.isEmpty) {
      return Center(
        child: Text(
          "No links found!",
          style: TextStyle(color: DarkModeHandler.getMainBackgroundTextColor(), fontSize: 16),
        ),
      );
    }

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            linkData.length,
                (index) => _buildLinkHistoryItem(context, index, linkData[index]), // Pass entire object
          ),
        ),
      ),
    );
  }


  Widget _buildIconContainer(int index) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: circleColors[index % circleColors.length],
        shape: BoxShape.rectangle,
      ),
    );
  }

  // Update the link text widget to include the expireAfter and expiredBefore data
  Widget _buildLinkText(String title, String expireAfter, String expiredBefore) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DarkModeHandler.getMainContainersTextColor(),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Expires: $expireAfter", // Display expireAfter under the title
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey, // Use secondary text color
            ),
          ),
          if (expiredBefore.isNotEmpty) // Display "expired before" only in the Expired tab
            Text(
              "Expired before: $expiredBefore",
              style: TextStyle(
                fontSize: 14,
                color: Colors.redAccent, // Highlight in red
              ),
            ),
        ],
      ),
    );
  }

// Helper function to calculate "expired before" days
  String _calculateExpiredBefore(String createdAt, String expireAfter) {
    try {
      // Parse createdAt date
      final DateTime createdDate = DateTime.parse(createdAt);

      // Add the expiration period to the createdAt date
      DateTime expirationDate;
      switch (expireAfter) {
        case 'One Hour':
          expirationDate = createdDate.add(Duration(hours: 1));
          break;
        case 'One Day':
          expirationDate = createdDate.add(Duration(days: 1));
          break;
        case 'One Week':
          expirationDate = createdDate.add(Duration(days: 7));
          break;
        case 'Unlimited':
        case 'One Time Only':
          return ''; // No expiration for Unlimited or One Time Only
        default:
          return ''; // Fallback for unknown values
      }

      // Calculate difference in days
      final int daysDifference = DateTime.now().difference(expirationDate).inDays;

      if (daysDifference > 0) {
        return "$daysDifference days ago";
      } else if (daysDifference == 0) {
        return "Today";
      } else {
        return "In ${daysDifference.abs()} days"; // If expiration is in the future
      }
    } catch (e) {
      print("Error calculating expired before: $e");
      return '';
    }
  }
}
