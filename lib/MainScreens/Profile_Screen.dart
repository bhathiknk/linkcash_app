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
    var initialConnectivityResult =
    await _connectivityService.checkInitialConnectivity();
    setState(() {
      _initialConnectivityResult = initialConnectivityResult;
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
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<ConnectivityResult>(
        stream: _connectivityService.connectivityStream,
        builder: (context, snapshot) {
          // Display loading spinner until the initial check is complete
          if (!_isInitialCheckComplete) {
            return const Center(child: CircularProgressIndicator());
          } else {
            // Check network connectivity and display relevant content
            ConnectivityResult? result =
                snapshot.data ?? _initialConnectivityResult;
            if (result == ConnectivityResult.none) {
              // Display no internet connection UI
              return NoInternetUI();
            } else {
              // Display profile page content if connected
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
                color: isDarkMode ? Colors.black : Colors.blue[300],
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
  Widget _buildProfileItem(
      {required IconData icon, required String title, bool showArrow = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        width: MediaQuery.of(context).size.width - 20,
        height: 80,
        decoration: BoxDecoration(
          color: DarkModeHandler.getMainContainersColor(),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          children: [
            // Icon for each profile item
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                icon,
                size: 30,
                color: DarkModeHandler.getProfilePageIconColor(),
              ),
            ),
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
    );
  }
}
