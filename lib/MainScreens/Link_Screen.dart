import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../ConnectionCheck/No_Internet_Ui.dart';
import '../ConnectionCheck/connectivity_service.dart';
import '../WidgetsCom/bottom_navigation_bar.dart'; // Custom bottom navigation bar with floating action button
import '../WidgetsCom/dark_mode_handler.dart'; // Handles dark mode colors throughout the app
import 'Create_Link_Screen.dart'; // Create Link Screen
import '../WidgetsCom/gradient_button_fb4.dart'; // Gradient button widget

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


  bool isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _listenToConnectivityChanges();
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

  // Builds the list of saved links
  Widget _buildLinkHistoryList(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            8,
                (index) => _buildLinkHistoryItem(context, index), // Generates a list item for each index
          ),
        ),
      ),
    );
  }

  // Builds individual list items for the saved link history
  Widget _buildLinkHistoryItem(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0), // Padding around each list item
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9, // Sets width relative to screen size
          height: 100, // Fixed height for each item
          decoration: BoxDecoration(
            color: DarkModeHandler.getMainContainersColor(), // Background color of the list item
            borderRadius: BorderRadius.circular(10.0), // Rounded corners
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0), // Padding inside the list item container
            child: Row(
              children: [
                _buildIconContainer(index), // Circular colored icon container
                const SizedBox(width: 20), // Spacer between icon and text
                _buildLinkText(), // Text section inside the list item
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


  // Builds the text section inside each list item
  Widget _buildLinkText() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Link Title",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DarkModeHandler.getMainContainersTextColor(), // Text color based on theme
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8), // Spacer between title and any additional text (if needed)
        ],
      ),
    );
  }
}
