import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ConnectionCheck/No_Internet_Ui.dart';
import '../ConnectionCheck/connectivity_service.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/calendar_widget.dart';
import '../WidgetsCom/dark_mode_handler.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  static const routeName = '/home';

  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ConnectivityService _connectivityService = ConnectivityService();
  ConnectivityResult? _initialConnectivityResult;
  bool _isInitialCheckComplete = false;
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _loadBalanceVisibility(); // Load the saved visibility state
  }

  Future<void> _checkInitialConnectivity() async {
    var initialConnectivityResult =
    await _connectivityService.checkInitialConnectivity();
    setState(() {
      _initialConnectivityResult = initialConnectivityResult;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<ConnectivityResult>(
        stream: _connectivityService.connectivityStream,
        builder: (context, snapshot) {
          if (!_isInitialCheckComplete) {
            return const Center(child: CircularProgressIndicator());
          } else {
            final result = snapshot.data ?? _initialConnectivityResult;
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      color: DarkModeHandler.getBackgroundColor(),
      child: Column(
        children: [
          // Container for white background above the top section
          Container(
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.05), // Space above the top section
                _buildTopSection(screenWidth),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.02), // Space between top section and calendar
          _buildCalendarContainer(screenWidth),
          SizedBox(height: screenHeight * 0.02),
          _buildActionButtons(),
          SizedBox(height: screenHeight * 0.01),
          _buildRecentTransactionsContainer(screenWidth),
        ],
      ),
    );
  }

  Widget _buildTopSection(double screenWidth) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: DarkModeHandler.getTopContainerColor(),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          height: 250,
        ),
        TopBarFb4(
          title: 'Welcome Back',
          upperTitle: 'Bhathika Nilesh',
          onTapMenu: () {},
        ),
        Positioned(
          top: 60,
          left: 10,
          right: 10,
          child: _buildMonzoCard(),
        ),
      ],
    );
  }

  Widget _buildMonzoCard() {
    final titleColor = DarkModeHandler.getMainBalanceContainerTextColor();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      color: DarkModeHandler.getMainBalanceContainer(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                  '04-00-03 • 60526416',
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      width: screenWidth - 20,
      decoration: BoxDecoration(
        color: DarkModeHandler.getCalendarContainersColor(),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const CalendarWidget(),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton('Pay Quick', Icons.flash_on),
          _buildActionButton('Group Pay', Icons.group),
          _buildActionButton('Add Event', Icons.add),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: const Color(0xFF0054FF), // Set button color
              padding: EdgeInsets.zero, // Remove internal padding
            ),
            onPressed: () {},
            child: Icon(
              icon,
              size: 30,
              color: Colors.white, // Icon color
            ),
          ),
        ),
        const SizedBox(height: 5), // Space between button and text
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

  // Add a method to build the recent transactions container
  Widget _buildRecentTransactionsContainer(double screenWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      width: screenWidth - 20,
      height: 60,
      decoration: BoxDecoration(
        color: DarkModeHandler.getCalendarContainersColor(),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          "No recent transactions", // Placeholder text
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

  const TopBarFb4({
    required this.title,
    required this.upperTitle,
    required this.onTapMenu,
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
        ],
      ),
    );
  }
}