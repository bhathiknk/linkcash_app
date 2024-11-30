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

// Main Link Page Screen
class LinkPage extends StatefulWidget {
  LinkPage({Key? key}) : super(key: key);

  @override
  _LinkPageState createState() => _LinkPageState();
}

class _LinkPageState extends State<LinkPage> {
  final List<Color> circleColors = [
    Color(0xFFBCC2FF), // Bright Blue
    Color(0xFFFA9090), // Bright Red
    Color(0xFFBBF8AB), // Bright Green
    Color(0xFFEFCDA9), // Bright Orange
    Color(0xFFE4B6F1), // Bright Purple
    Color(0xFFEEE2A8), // Bright Gold
  ];

  List<String> linkTitles = []; // Store fetched titles
  bool isConnected = true;
  String? userId; // Store logged-in user's User_ID

  @override
  void initState() {
    super.initState();
    _retrieveUserId(); // Retrieve logged user ID from secure storage
    _checkInitialConnectivity();
    _listenToConnectivityChanges();
  }

  // Retrieve the logged-in user's User_ID from secure storage
  Future<void> _retrieveUserId() async {
    final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
    String? retrievedUserId = await secureStorage.read(key: 'User_ID');
    setState(() {
      userId = retrievedUserId; // Save retrieved User_ID to state
    });
    if (userId != null) {
      _fetchLinkTitles(); // Fetch titles after retrieving user ID
    }
  }

  // Check the initial connectivity status when the page loads
  Future<void> _checkInitialConnectivity() async {
    var connectivityResult = await ConnectivityService().checkInitialConnectivity();
    setState(() {
      isConnected = connectivityResult != ConnectivityResult.none;
    });
  }

  // Listen to connectivity changes to update the UI accordingly
  void _listenToConnectivityChanges() {
    ConnectivityService().connectivityStream.listen((result) {
      setState(() {
        isConnected = result != ConnectivityResult.none;
      });
    });
  }

  // Fetch link titles from the API
  Future<void> _fetchLinkTitles() async {
    if (userId == null) return; // If userId is not retrieved, skip fetching
    final String apiUrl = "http://10.0.2.2:8080/api/payment-links/titles/$userId";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          linkTitles = List<String>.from(json.decode(response.body)); // Parse and store titles
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
      body: isConnected ? _buildMainContent(context) : NoInternetUI(), // Show main content or NoInternetUI based on connection
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: 2,
        onTap: (index) {
          // Handle navigation if needed
        },
      ),
    );
  }

  // Main content builder method
  Widget _buildMainContent(BuildContext context) {
    return Container(
      color: DarkModeHandler.getBackgroundColor(), // Sets the background color
      padding: const EdgeInsets.all(10.0), // Padding around the entire body
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10), // Spacer
          _buildSearchBar(context), // Search bar widget
          const SizedBox(height: 20), // Spacer
          _buildCreateLinkButton(context), // Create Link Button
          const SizedBox(height: 20), // Spacer
          _buildLinkHistoryTitle(), // Title for saved link history
          const SizedBox(height: 10), // Spacer
          _buildLinkHistoryList(context), // List of saved links
        ],
      ),
    );
  }

  // Builds the search bar widget
  Widget _buildSearchBar(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50.0,
      child: Container(
        decoration: BoxDecoration(
          color: DarkModeHandler.getSearchBarColor(), // Search bar color
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0), // Inner padding of the search bar
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: TextStyle(color: DarkModeHandler.getInputTextColor()), // Hint text color
              prefixIcon: Icon(Icons.search, color: DarkModeHandler.getInputTextColor()), // Search icon color
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(top: 12.0), // Padding for text inside TextField
            ),
          ),
        ),
      ),
    );
  }

  // Builds the "Create Link" button
  Widget _buildCreateLinkButton(BuildContext context) {
    return Center(
      child: GradientButtonFb4(
        text: 'Create Link',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateLinkPage()), // Navigates to Create Link Screen
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

  // Builds the list of saved links dynamically based on fetched titles
  Widget _buildLinkHistoryList(BuildContext context) {
    if (linkTitles.isEmpty) {
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
            linkTitles.length,
                (index) => _buildLinkHistoryItem(context, index, linkTitles[index]), // Pass title dynamically
          ),
        ),
      ),
    );
  }

  // Update the link history item to display dynamic title
  Widget _buildLinkHistoryItem(BuildContext context, int index, String title) {
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
                _buildLinkText(title), // Pass the dynamic title here
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Builds the circular icon container
  Widget _buildIconContainer(int index) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0), // Rounded corners for the icon container
        color: circleColors[index % circleColors.length], // Dynamic color from the updated list
        shape: BoxShape.rectangle, // Shape of the icon container
      ),
    );
  }

  // Update the link text to display the dynamic title
  Widget _buildLinkText(String title) {
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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
