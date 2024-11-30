import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ConnectionCheck/No_Internet_Ui.dart';
import '../ConnectionCheck/connectivity_service.dart';
import '../LogScreen/Asgardio_Login.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/calendar_widget.dart';
import '../WidgetsCom/dark_mode_handler.dart';


class MyHomePage extends StatefulWidget {
  final String givenName; // Accepts given_name from login

  const MyHomePage({Key? key, required this.givenName}) : super(key: key);
  static const routeName = '/home';

  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ConnectivityService _connectivityService = ConnectivityService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  ConnectivityResult? _initialConnectivityResult;
  bool _isInitialCheckComplete = false;
  bool _isBalanceVisible = true;
  String _userId = "Loading..."; // Placeholder for User_ID

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _loadBalanceVisibility(); // Load the saved visibility state
    _fetchUserId();

    // Show success message after login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login successful!")),
      );
    });
  }

  Future<void> _checkInitialConnectivity() async {
    var initialConnectivityResults =
    await _connectivityService.checkInitialConnectivity();
    setState(() {
      _initialConnectivityResult = initialConnectivityResults.contains(ConnectivityResult.none)
          ? ConnectivityResult.none
          : ConnectivityResult.wifi; // Default to WiFi if any connection exists
      _isInitialCheckComplete = true;
    });
  }

  Future<void> _loadBalanceVisibility() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBalanceVisible = prefs.getBool('isBalanceVisible') ?? true;
    });
  }

  Future<void> _saveBalanceVisibility(bool isVisible) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBalanceVisible', isVisible);
  }

  // Toggle balance visibility
  void _toggleBalanceVisibility() {
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
    _saveBalanceVisibility(_isBalanceVisible);
  }

  // Logout Function
  // Logout Function
  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Clear all locally stored session data
    await prefs.clear();

    // Navigate to the AsgardeoLoginPage and clear the navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => AsgardeoLoginPage()),
          (Route<dynamic> route) => false, // Remove all previous routes
    );

    // Show a logout success toast
    Fluttertoast.showToast(
      msg: "Logged out successfully!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _fetchUserId() async {
    try {
      final userId = await _secureStorage.read(key: 'User_ID');
      if (userId != null) {
        print("Fetched User_ID: $userId");
        setState(() {
          _userId = userId;
        });
      } else {
        print("User_ID not found in storage.");
        setState(() {
          _userId = "Not Available";
        });
      }
    } catch (e) {
      print("Error fetching User_ID: $e");
      setState(() {
        _userId = "Error";
      });
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // White background color for the app bar
        elevation: 0, // Remove shadow to keep it flat
        toolbarHeight: 5, // Minimal height for a thin dividing line
      ),
      backgroundColor: const Color(0xFFE3F2FD), // Set the background color here
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
              return _buildHomePageContent(context);
            }
          }
        },
      ),

      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: 0,
        onTap: (index) {},
      ),
    );
  }

  Widget _buildHomePageContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Container(
        color: const Color(0xFFE3F2FD), // Ensure the entire scrollable area has the background color
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopSection(screenWidth), // Make top section full width and no padding at the top
            const SizedBox(height: 15),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: _buildCalendarContainer(screenWidth),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: _buildActionButtons(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: _buildRecentTransactionsContainer(screenWidth),
            ),
            const SizedBox(height: 10), // Add padding here to create space above the bottom navigation bar
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(double screenWidth) {
    return Container(
      width: double.infinity, // Make container full width
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: Stack(
        children: [
          Container(
            height: 230, // Increased height to accommodate bottom padding
            decoration: BoxDecoration(
              color: DarkModeHandler.getTopContainerColor(),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 1), // Add padding from the top
            child: TopBarFb4(
              title: 'Welcome Back',
              upperTitle: widget.givenName, // Display given_name in the top bar
              onTapMenu: () {},
              onTapLogout: () => _logout(context), // Pass the logout function here
            ),
          ),
          Positioned(
            top: 60,
            left: screenWidth * 0.02,
            right: screenWidth * 0.02,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20), // Add bottom padding to _buildMonzoCard
              child: _buildMonzoCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonzoCard() {
    final titleColor = DarkModeHandler.getMainBalanceContainerTextColor();

    if (_userId == "Loading...") {
      return Center(child: CircularProgressIndicator()); // Show a loading indicator
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      color: DarkModeHandler.getMainBalanceContainer(),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LinkCash',
              style: TextStyle(
                color: titleColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.account_balance_outlined, color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  _userId == "Not Available" ? "User ID: N/A" : "User_ID: $_userId", // Fallback
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Balance',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '£32.56',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCalendarContainer(double screenWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      width: screenWidth - 40,
      decoration: BoxDecoration(
        color: DarkModeHandler.getCalendarContainersColor(),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const CalendarWidget(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton('Pay Quick', Icons.flash_on),
        _buildActionButton('Group Pay', Icons.group),
        _buildActionButton('Add Event', Icons.add),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: const Color(0xFF0054FF),
              padding: EdgeInsets.zero,
            ),
            onPressed: () {},
            child: Icon(
              icon,
              size: 30,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: DarkModeHandler.getMainContainersTextColor(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsContainer(double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: screenWidth - 40,
      height: 180,
      decoration: BoxDecoration(
        color: DarkModeHandler.getCalendarContainersColor(),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          "No recent transactions",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class TopBarFb4 extends StatelessWidget {
  final String title;
  final String upperTitle;
  final Function() onTapMenu;
  final Function() onTapLogout; // Added logout function

  const TopBarFb4({
    required this.title,
    required this.upperTitle,
    required this.onTapMenu,
    required this.onTapLogout, // Added logout function
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: onTapMenu,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  upperTitle,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout), // Logout icon
            onPressed: onTapLogout, // Call logout function
          ),
        ],
      ),
    );
  }
}