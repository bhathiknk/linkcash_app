import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For secure storage
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON decoding
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:linkcash_app/MainScreens/Pay_Quick_Page.dart';
import '../ConnectionCheck/No_Internet_Ui.dart';
import '../ConnectionCheck/connectivity_service.dart';
import '../LogScreen/Asgardio_Login.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/calendar_widget.dart';
import '../WidgetsCom/dark_mode_handler.dart';

// New DTO classes for transaction summary (matching backend DTOs)
class TransactionMonthlySummaryDTO {
  final String month;
  final double oneTimeTotal;
  final double regularTotal;

  TransactionMonthlySummaryDTO({
    required this.month,
    required this.oneTimeTotal,
    required this.regularTotal,
  });

  factory TransactionMonthlySummaryDTO.fromJson(Map<String, dynamic> json) {
    return TransactionMonthlySummaryDTO(
      month: json['month'],
      oneTimeTotal: (json['oneTimeTotal'] as num).toDouble(),
      regularTotal: (json['regularTotal'] as num).toDouble(),
    );
  }
}

class TransactionSummaryResponse {
  final double totalOneTime;
  final double totalRegular;
  final List<TransactionMonthlySummaryDTO> monthlySummaries;

  TransactionSummaryResponse({
    required this.totalOneTime,
    required this.totalRegular,
    required this.monthlySummaries,
  });

  factory TransactionSummaryResponse.fromJson(Map<String, dynamic> json) {
    return TransactionSummaryResponse(
      totalOneTime: (json['totalOneTime'] as num).toDouble(),
      totalRegular: (json['totalRegular'] as num).toDouble(),
      monthlySummaries: (json['monthlySummaries'] as List)
          .map((e) => TransactionMonthlySummaryDTO.fromJson(e))
          .toList(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String givenName;

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
  String _userId = "Loading...";
  String _pendingBalance = "Loading...";
  String _givenName = "User"; // Default value for givenName

  // New variable for transaction summary.
  TransactionSummaryResponse? _transactionSummary;
  bool _isSummaryLoading = true;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _loadBalanceVisibility();
    _fetchUserId();
    _fetchGivenName();
  }

  Future<void> _checkInitialConnectivity() async {
    var connectivityResults =
    await _connectivityService.checkInitialConnectivity();
    setState(() {
      _initialConnectivityResult = connectivityResults.contains(ConnectivityResult.none)
          ? ConnectivityResult.none
          : ConnectivityResult.wifi;
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

  void _toggleBalanceVisibility() {
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
    _saveBalanceVisibility(_isBalanceVisible);
  }

  Future<void> _fetchUserId() async {
    try {
      final userId = await _secureStorage.read(key: 'User_ID');
      if (userId != null) {
        setState(() {
          _userId = userId;
        });
        _fetchPendingBalance(userId);
        _fetchTransactionSummary(userId); // Fetch summary after userId is available.
      } else {
        setState(() {
          _userId = "Not Available";
        });
      }
    } catch (e) {
      setState(() {
        _userId = "Error";
      });
    }
  }

  Future<void> _fetchPendingBalance(String userId) async {
    final String apiUrl = "http://10.0.2.2:8080/api/stripe/balance/$userId";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final pendingAmount = responseData['pending'][0]['amount'] ?? 0;
        final formattedBalance = (pendingAmount / 100).toStringAsFixed(2);
        setState(() {
          _pendingBalance = "£$formattedBalance";
        });
      } else {
        setState(() {
          _pendingBalance = "Error";
        });
      }
    } catch (e) {
      setState(() {
        _pendingBalance = "Error";
      });
    }
  }

  Future<void> _fetchGivenName() async {
    try {
      final storedGivenName = await _secureStorage.read(key: 'Given_Name');
      if (storedGivenName != null) {
        setState(() {
          _givenName = storedGivenName;
        });
      }
    } catch (e) {
      print("Error fetching givenName: $e");
    }
  }

  Future<void> _fetchTransactionSummary(String userId) async {
    final String apiUrl = "http://10.0.2.2:8080/api/transactions/summary/user/$userId";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final summaryData = jsonDecode(response.body);
        setState(() {
          _transactionSummary = TransactionSummaryResponse.fromJson(summaryData);
          _isSummaryLoading = false;
        });
      } else {
        print("Failed to fetch summary: ${response.body}");
        setState(() {
          _isSummaryLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching summary: $e");
      setState(() {
        _isSummaryLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => AsgardeoLoginPage()),
          (Route<dynamic> route) => false,
    );

    Fluttertoast.showToast(
      msg: "Logged out successfully!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 5,
      ),
      backgroundColor: const Color(0xFFE3F2FD),
      body: StreamBuilder<List<ConnectivityResult>>(
        stream: _connectivityService.connectivityStream,
        builder: (context, snapshot) {
          if (!_isInitialCheckComplete) {
            return const Center(child: CircularProgressIndicator());
          } else {
            final results = snapshot.data ?? [];
            final result = results.contains(ConnectivityResult.none)
                ? ConnectivityResult.none
                : ConnectivityResult.wifi;
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
        color: const Color(0xFFE3F2FD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopSection(screenWidth),
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
            // New Transaction Summary Graph Section.
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: _buildTransactionSummaryContainer(screenWidth),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(double screenWidth) {
    return Container(
      width: double.infinity,
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
            height: 230,
            decoration: BoxDecoration(
              color: DarkModeHandler.getTopContainerColor(),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: TopBarFb4(
              title: 'Welcome Back',
              upperTitle: _givenName,
              onTapMenu: () {},
              onTapLogout: () => _logout(context),
            ),
          ),
          Positioned(
            top: 60,
            left: screenWidth * 0.02,
            right: screenWidth * 0.02,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildMonzoCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonzoCard() {
    final titleColor = DarkModeHandler.getMainBalanceContainerTextColor();

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
                  _userId == "Not Available" ? "User ID: N/A" : "User_ID: $_userId",
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
                  _pendingBalance,
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
            onPressed: () {
              if (title == "Pay Quick") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PayQuickPage()),
                );
              }
              // Add navigation for Group Pay and Add Event if needed.
            },
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

  // New Transaction Summary Graph Section.
  Widget _buildTransactionSummaryContainer(double screenWidth) {
    return Container(
      width: screenWidth - 40,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: _buildTransactionSummaryContent(),
    );
  }

  Widget _buildTransactionSummaryContent() {
    if (_isSummaryLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_transactionSummary == null) {
      return Center(
        child: Text(
          "No transaction summary available.",
          style: TextStyle(
            color: DarkModeHandler.getMainContainersTextColor(),
            fontSize: 16,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title of the summary section.
        Text(
          "Transaction Summary",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: DarkModeHandler.getMainContainersTextColor(),
          ),
        ),
        const SizedBox(height: 12),
        // Overall totals card.
        Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                // One-Time Total Row with updated icon.
                Row(
                  children: [
                    const Icon(Icons.event_available, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "One-Time Total:",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                    Text(
                      "£${_transactionSummary!.totalOneTime.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Regular Total Row with updated icon.
                Row(
                  children: [
                    const Icon(Icons.credit_card, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Regular Total:",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                    Text(
                      "£${_transactionSummary!.totalRegular.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Monthly Totals",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: DarkModeHandler.getMainContainersTextColor(),
          ),
        ),
        const SizedBox(height: 10),
        // Horizontal list of monthly summaries.
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _transactionSummary!.monthlySummaries.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final monthly = _transactionSummary!.monthlySummaries[index];
              return Container(
                width: 140,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      monthly.month,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF83B6B9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // One-Time total in monthly summary with updated icon.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_available, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            monthly.oneTimeTotal.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Regular total in monthly summary with updated icon.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.credit_card, size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            monthly.regularTotal.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildBottomNavigationBar() {
    return BottomNavigationBarWithFab(
      currentIndex: 0,
      onTap: (index) {
        // Handle navigation if needed.
      },
    );
  }
}

class TopBarFb4 extends StatelessWidget {
  final String title;
  final String upperTitle;
  final Function() onTapMenu;
  final Function() onTapLogout;

  const TopBarFb4({
    required this.title,
    required this.upperTitle,
    required this.onTapMenu,
    required this.onTapLogout,
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
            icon: const Icon(Icons.logout),
            onPressed: onTapLogout,
          ),
        ],
      ),
    );
  }
}
