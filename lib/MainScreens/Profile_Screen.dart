import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../ConnectionCheck/No_Internet_Ui.dart';
import '../ConnectionCheck/connectivity_service.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/dark_mode_handler.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isDarkMode = DarkModeHandler.isDarkMode;
  final ConnectivityService _connectivityService = ConnectivityService();
  ConnectivityResult? _initialConnectivityResult;
  bool _isInitialCheckComplete = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
  }

  /// Checks initial network connectivity status
  Future<void> _checkInitialConnectivity() async {
    var initialConnectivityResults = await _connectivityService.checkInitialConnectivity();
    setState(() {
      _initialConnectivityResult = initialConnectivityResults.contains(ConnectivityResult.none)
          ? ConnectivityResult.none
          : ConnectivityResult.wifi; // Assume WiFi if any connection exists
      _isInitialCheckComplete = true;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: DarkModeHandler.getAppBarColor(),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<ConnectivityResult>>(
        stream: _connectivityService.connectivityStream,
        builder: (context, snapshot) {
          if (!_isInitialCheckComplete) {
            return const Center(child: CircularProgressIndicator());
          } else {
            final results = snapshot.data ?? [];
            final result = results.contains(ConnectivityResult.none)
                ? ConnectivityResult.none
                : ConnectivityResult.wifi; // Default to WiFi if any connection exists
            if (result == ConnectivityResult.none) {
              return NoInternetUI();
            } else {
              return _buildProfilePageContent(context);
            }
          }
        },
      ),

      // Custom bottom navigation bar
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: 3,
        onTap: (index) {
          // Handle navigation if needed
        },
      ),
    );
  }

  /// Builds the main content of the profile page
  Widget _buildProfilePageContent(BuildContext context) {
    return Container(
      color: DarkModeHandler.getBackgroundColor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(context),
          const SizedBox(height: 20),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildProfileDetail(
                  icon: Icons.email,
                  text: 'bhathika@gmail.com',
                  iconColor: Colors.grey,
                ),
                _buildProfileDetail(
                  icon: Icons.phone,
                  text: '11111111111',
                  iconColor: Colors.grey,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Display the settings and support containers
          _buildProfileItem(
            icon: Icons.settings,
            title: 'Settings',
            showArrow: true,
          ),
          _buildProfileItem(
            icon: Icons.support,
            title: 'Support',
            showArrow: true,
          ),
        ],
      ),
    );
  }

  /// Builds the profile header with user image, name, and edit options
  Widget _buildProfileHeader(BuildContext context) {
    return Stack(
      children: [
        // Background container with rounded corners
        Container(
          decoration: BoxDecoration(
            color: DarkModeHandler.getTopContainerColor(),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          height: 230,
        ),
        // Edit icon positioned at the top right
        const Positioned(
          top: 10,
          right: 10,
          child: Icon(Icons.edit, size: 25, color: Colors.grey),
        ),
        // Profile image container in the center
        Positioned(
          top: 30,
          left: MediaQuery.of(context).size.width / 2 - 70,
          child: Column(
            children: [
              Container(
                width: 130,
                height: 130,
                child: ClipOval(
                  child: Image.asset(
                    'lib/images/coverimage.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Bhathika Nilesh',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        // Dark mode toggle button
        Positioned(
          top: 5,
          left: 5,
          child: GestureDetector(
            onTap: () async {
              await DarkModeHandler.toggleDarkMode();
              setState(() {
                isDarkMode = DarkModeHandler.isDarkMode;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black : Color(0xFF83B6B9),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDarkMode
                        ? Icons.nightlight_round
                        : Icons.wb_sunny_rounded,
                    size: 25,
                    color: Colors.yellow,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isDarkMode ? 'Dark Mode' : 'Light Mode',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a profile detail with an icon and text
  Widget _buildProfileDetail({
    required IconData icon,
    required String text,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 30, color: iconColor),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  /// Builds a single profile item row with icon, title, and optional arrow
  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    bool showArrow = false,
  }) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0), // Padding around each list item
    child: Center(
    child: Container(
    width: MediaQuery.of(context).size.width * 0.9, // Sets width relative to screen size
    height: 80, // Fixed height for each item
    decoration: BoxDecoration(
    color: DarkModeHandler.getMainContainersColor(), // Background color of the list item
    borderRadius: BorderRadius.circular(10.0), // Rounded corners
    ),
        // Adjust padding to ensure proper left and right padding of the container
        padding: const EdgeInsets.symmetric(horizontal: 20.0), // Even padding on both sides
        child: Row(
          children: [
            // Icon for each profile item
            Icon(
              icon,
              size: 30,
              color: DarkModeHandler.getProfilePageIconColor(),
            ),
            // Space between the icon and the text
            const SizedBox(width: 16.0), // Add spacing after the icon
            // Title and optional arrow for navigable items
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      color: DarkModeHandler.getMainContainersTextColor(),
                    ),
                  ),
                  // Optional arrow for settings and support items
                  if (showArrow) const Icon(Icons.arrow_forward_ios),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }



}
