import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  // Instance of ConnectivityService to check internet connectivity
  final ConnectivityService _connectivityService = ConnectivityService();
  ConnectivityResult? _initialConnectivityResult;
  bool _isInitialCheckComplete = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity(); // Check initial internet connectivity when the widget is initialized
  }

  // Function to check initial connectivity and set state accordingly
  Future<void> _checkInitialConnectivity() async {
    var initialConnectivityResult = await _connectivityService.checkInitialConnectivity();
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
          "Link Cash",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true, // Center the title in the AppBar
      ),
      // Using StreamBuilder to monitor connectivity changes
      body: StreamBuilder<ConnectivityResult>(
        stream: _connectivityService.connectivityStream,
        builder: (context, snapshot) {
          if (!_isInitialCheckComplete) {
            // Show loading indicator while checking initial connectivity
            return const Center(child: CircularProgressIndicator());
          } else {
            final result = snapshot.data ?? _initialConnectivityResult;
            if (result == ConnectivityResult.none) {
              // Show No Internet UI if there's no connectivity
              return NoInternetUI();
            } else {
              // If connected, show the main content of the homepage
              return _buildHomePageContent(context);
            }
          }
        },
      ),
      // Custom Bottom Navigation Bar with a Floating Action Button
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: 0,
        onTap: (index) {
          // Handle bottom navigation tap events if needed
        },
      ),
    );
  }

  // Function to build the main content of the homepage
  Widget _buildHomePageContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; // Get screen width for responsive design

    return Container(
      color: DarkModeHandler.getBackgroundColor(), // Set background color based on theme
      child: Column(
        children: [
          _buildTopSection(screenWidth), // Top section with greeting and balance information
          const SizedBox(height: 10),
          _buildCalendarContainer(screenWidth), // Calendar widget showing current date and events
          const SizedBox(height: 20),
          _buildTransactionsHeader(), // Header for the Transactions section
          _buildTransactionsList(screenWidth), // Horizontal list of recent transactions
        ],
      ),
    );
  }

  // Function to build the top section containing welcome message and balance
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
          height: 200, // Height of the background container
        ),
        TopBarFb4(
          title: 'Welcome Back', // Title message
          upperTitle: 'Bhathika Nilesh', // Subheading with the user’s name
          onTapMenu: () {
            // Handle menu button tap here
          },
        ),
        Positioned(
          top: 80,
          left: 10,
          right: 10,
          child: _buildBalanceContainer(), // Positioned widget showing the balance
        ),
      ],
    );
  }

  // Function to build the balance container showing the current balance amount
  Widget _buildBalanceContainer() {
    return Container(
      height: 110,
      decoration: DarkModeHandler.getMainBalanceContainer().copyWith(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff000000).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(3, 3), // Shadow effect for depth
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: DarkModeHandler.getMainBalanceContainerTextColor(),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '\$800.00', // Display the current balance
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 30,
                color: DarkModeHandler.getMainBalanceContainerTextColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }



  // Function to build the container that holds the Calendar widget
  Widget _buildCalendarContainer(double screenWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      width: screenWidth - 20,
      decoration: BoxDecoration(
        color: DarkModeHandler.getCalendarContainersColor(),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff000000).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(2, 2), // Shadow for the container
          ),
        ],
      ),
      child: const CalendarWidget(), // Custom calendar widget
    );
  }

  // Function to build the header for the Transactions section
  Widget _buildTransactionsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            'Transactions',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 20,
              color: DarkModeHandler.getMainBackgroundTextColor(),
            ),
          ),
          const Spacer(), // Space between the header and any potential action buttons
        ],
      ),
    );
  }

  // Function to build the list of recent transactions
  Widget _buildTransactionsList(double screenWidth) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: List.generate(
            5, // Number of transactions to display
                (index) => _buildTransactionItem(screenWidth),
          ),
        ),
      ),
    );
  }

// Function to build each transaction item in the list
  Widget _buildTransactionItem(double screenWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Adjusted padding for spacing between items
      child: Container(
        decoration: BoxDecoration(
          color: DarkModeHandler.getBackgroundColor(),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff000000).withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 1,
              offset: const Offset(2, 2), // Shadow for the container
            ),
          ],
        ),
        child: _buildTransactionDetails(screenWidth), // Updated for vertical scrolling
      ),
    );
  }

  // Function to build the details of each transaction, including title and amount
  Widget _buildTransactionDetails(double screenWidth) {
    return Container(
      width: screenWidth * 0.95,
      decoration: BoxDecoration(
        color: DarkModeHandler.getMainContainersColor(),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff000000).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(2, 2), // Shadow for the transaction item
          ),
        ],
      ),
      child: SizedBox(
        width: screenWidth * 0.75,
        height: 100, // Set the height for the transaction detail container
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Payment Link Title", // Title of the transaction
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DarkModeHandler.getMainContainersTextColor(),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    "Bhathika", // Payee or transaction participant name
                    style: TextStyle(
                      fontSize: 14,
                      color: DarkModeHandler.getMainContainersTextColor(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "+ \$300", // Transaction amount
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: DarkModeHandler.getMainContainersTextColor(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Define the TopBarFb4 widget used in the top section
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
            onPressed: onTapMenu, // Trigger action when menu button is pressed
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
