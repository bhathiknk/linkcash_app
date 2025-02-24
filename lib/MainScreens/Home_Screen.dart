import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For secure storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For secure storage
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pie_chart/pie_chart.dart'; // For the pie chart

import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import '../ConnectionCheck/No_Internet_Ui.dart';
import '../ConnectionCheck/connectivity_service.dart';
import '../LogScreen/Asgardio_Login.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/calendar_widget.dart';
import '../WidgetsCom/dark_mode_handler.dart';
import 'Pay_Quick_Page.dart';
import 'Group_Payment_Page.dart';
import 'payout_history_page.dart';
import 'NotificationPage.dart';

// ==================== DATA CLASSES (DTOs) ====================

class TransactionMonthlySummaryDTO {
  final String month;       // e.g. "2023-09"
  final double oneTimeTotal;
  final double regularTotal;
  final double groupTotal;  // NEW

  TransactionMonthlySummaryDTO({
    required this.month,
    required this.oneTimeTotal,
    required this.regularTotal,
    required this.groupTotal,
  });

  factory TransactionMonthlySummaryDTO.fromJson(Map<String, dynamic> json) {
    return TransactionMonthlySummaryDTO(
      month: json['month'],
      oneTimeTotal: (json['oneTimeTotal'] as num).toDouble(),
      regularTotal: (json['regularTotal'] as num).toDouble(),
      groupTotal: (json['groupTotal'] as num).toDouble(),
    );
  }
}

class TransactionSummaryResponse {
  final double totalOneTime;
  final double totalRegular;
  final double totalGroup;
  final List<TransactionMonthlySummaryDTO> monthlySummaries;

  TransactionSummaryResponse({
    required this.totalOneTime,
    required this.totalRegular,
    required this.totalGroup,
    required this.monthlySummaries,
  });

  factory TransactionSummaryResponse.fromJson(Map<String, dynamic> json) {
    return TransactionSummaryResponse(
      totalOneTime: (json['totalOneTime'] as num).toDouble(),
      totalRegular: (json['totalRegular'] as num).toDouble(),
      totalGroup: (json['totalGroup'] as num).toDouble(),
      monthlySummaries: (json['monthlySummaries'] as List)
          .map((e) => TransactionMonthlySummaryDTO.fromJson(e))
          .toList(),
    );
  }
}

// ==================== MAIN HOMEPAGE WIDGET ====================

class MyHomePage extends StatefulWidget {
  final String givenName;
  const MyHomePage({super.key, required this.givenName});
  static const routeName = '/home';

  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Connectivity
  final ConnectivityService _connectivityService = ConnectivityService();
  ConnectivityResult? _initialConnectivityResult;
  bool _isInitialCheckComplete = false;

  // Secure storage & local preferences
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isBalanceVisible = true;

  // Basic user info
  String _userId = "Loading...";
  String _pendingBalance = "Loading...";
  String _givenName = "User"; // Default for givenName

  // The last payout amount
  String _lastPayout = "0.00";

  // Transaction summary
  TransactionSummaryResponse? _transactionSummary;
  bool _isSummaryLoading = true;

  // Month/Year filters
  final List<int> _yearList = [];
  final List<int> _monthList = List<int>.generate(12, (i) => i + 1);
  late int _selectedYear;
  late int _selectedMonth;

  // Filtered values for the selected month-year
  double _filteredOneTime = 0.0;
  double _filteredRegular = 0.0;
  double _filteredGroup = 0.0;

  // ==================== NOTIFICATIONS ====================
  int _notificationCount = 0;             // Unread notifications count
  StompClient? _stompClient;              // STOMP WebSocket client

  @override
  void initState() {
    super.initState();
    _initYearList();
    _initSelectedYearMonth();
    _checkInitialConnectivity();
    _loadBalanceVisibility();
    _fetchUserId();
    _fetchGivenName();
  }

  void _initYearList() {
    final now = DateTime.now();
    for (int year = 2022; year <= now.year + 1; year++) {
      _yearList.add(year);
    }
  }

  void _initSelectedYearMonth() {
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  Future<void> _checkInitialConnectivity() async {
    var connectivityResults = await _connectivityService.checkInitialConnectivity();
    setState(() {
      _initialConnectivityResult = connectivityResults.contains(ConnectivityResult.none)
          ? ConnectivityResult.none
          : ConnectivityResult.wifi;
      _isInitialCheckComplete = true;
    });
  }

  Future<void> _loadBalanceVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBalanceVisible = prefs.getBool('isBalanceVisible') ?? true;
    });
  }

  // ==================== LOADING DATA ====================

  Future<void> _fetchUserId() async {
    try {
      final userId = await _secureStorage.read(key: 'User_ID');
      if (userId != null) {
        setState(() => _userId = userId);

        // 1) Get the balance
        _fetchPendingBalance(userId);
        // 2) Get transaction summary
        _fetchTransactionSummary(userId);
        // 3) Get last payout
        _fetchLastPayout(userId);
        // 4) Setup notifications
        _initNotifications(userId);
      } else {
        setState(() => _userId = "Not Available");
      }
    } catch (e) {
      setState(() => _userId = "Error");
    }
  }

  /// Fetch the "pending balance" from your /api/stripe/balance endpoint
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
        setState(() => _pendingBalance = "Error");
      }
    } catch (e) {
      setState(() => _pendingBalance = "Error");
    }
  }

  /// Fetch the user's last payout from /api/stripe/payouts/{userId}
  Future<void> _fetchLastPayout(String userId) async {
    try {
      final url = 'http://10.0.2.2:8080/api/stripe/payouts/$userId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final payouts = data['payouts'] as List<dynamic>?;
        if (payouts == null || payouts.isEmpty) {
          setState(() => _lastPayout = "0.00");
          return;
        }
        // Sort them by arrivalDate descending
        payouts.sort((a, b) => (b['arrivalDate'] ?? 0).compareTo(a['arrivalDate'] ?? 0));
        final lastItem = payouts.first;
        final rawAmount = lastItem['amount']; // pence
        double doubleAmount = 0;
        if (rawAmount is int) {
          doubleAmount = rawAmount / 100.0;
        } else if (rawAmount is String) {
          doubleAmount = double.parse(rawAmount) / 100.0;
        }
        setState(() {
          _lastPayout = doubleAmount.toStringAsFixed(2);
        });
      } else {
        debugPrint("Failed to fetch last payout: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error fetching last payout: $e");
    }
  }

  Future<void> _fetchGivenName() async {
    try {
      final storedGivenName = await _secureStorage.read(key: 'Given_Name');
      if (storedGivenName != null) {
        setState(() => _givenName = storedGivenName);
      }
    } catch (e) {
      debugPrint("Error fetching givenName: $e");
    }
  }

  /// Fetch transaction summary from your /api/transactions/summary/user/{userId}
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
        _applyMonthYearFilter();
      } else {
        debugPrint("Failed to fetch summary: ${response.body}");
        setState(() => _isSummaryLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching summary: $e");
      setState(() => _isSummaryLoading = false);
    }
  }

  // ==================== MONTH/YEAR FILTER LOGIC ====================

  void _applyMonthYearFilter() {
    if (_transactionSummary == null) return;

    final selectedKey =
        "${_selectedYear.toString().padLeft(4, '0')}-${_selectedMonth.toString().padLeft(2, '0')}";

    final monthlyList = _transactionSummary!.monthlySummaries;
    final match = monthlyList.firstWhere(
          (m) => m.month == selectedKey,
      orElse: () => TransactionMonthlySummaryDTO(
        month: selectedKey,
        oneTimeTotal: 0.0,
        regularTotal: 0.0,
        groupTotal: 0.0,
      ),
    );

    setState(() {
      _filteredOneTime = match.oneTimeTotal;
      _filteredRegular = match.regularTotal;
      _filteredGroup = match.groupTotal;
    });
  }

  // ==================== NOTIFICATION LOGIC ====================
  Future<void> _initNotifications(String userId) async {
    // 1) Fetch unread count from your server
    await _fetchUnreadNotificationCount(userId);
    // 2) Connect to WebSocket
    _initStompClient(userId);
  }

  Future<void> _fetchUnreadNotificationCount(String userId) async {
    final url = 'http://10.0.2.2:8080/api/notifications/$userId/unread';
    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List<dynamic>;
        setState(() {
          _notificationCount = list.length; // number of unread
        });
      }
    } catch (e) {
      debugPrint("Error fetching unread notifications: $e");
    }
  }

  void _initStompClient(String userId) {
    _stompClient = StompClient(
      config: StompConfig.SockJS(
        url: 'http://10.0.2.2:8080/ws',  // your server's WS endpoint
        onConnect: (StompFrame frame) {
          debugPrint("STOMP connected, subscribing to notifications/$userId");
          // Subscribe to /topic/notifications/{userId}
          _stompClient!.subscribe(
            destination: '/topic/notifications/$userId',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                final data = jsonDecode(frame.body!);
                debugPrint("New notification from WebSocket: $data");
                // Increase unread count by 1
                setState(() {
                  _notificationCount += 1;
                });
                // Optionally show a local in-app message/snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("New notification: ${data['message']}"))
                );
              }
            },
          );
        },
        onWebSocketError: (dynamic error) => debugPrint("WS Error: $error"),
      ),
    );
    _stompClient!.activate();
  }

  void _disconnectStomp() {
    _stompClient?.deactivate();
  }

  // ==================== MISC ==================

  Future<void> _saveBalanceVisibility(bool isVisible) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBalanceVisible', isVisible);
  }

  void _toggleBalanceVisibility() {
    setState(() => _isBalanceVisible = !_isBalanceVisible);
    _saveBalanceVisibility(_isBalanceVisible);
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
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

  // Navigate to NotificationPage
  void _openNotificationPage() async {
    // Mark all as read when the user opens the page, or let them read individually
    // For example, you might do:
    // await http.post(Uri.parse("http://10.0.2.2:8080/api/notifications/$_userId/mark-all-read"));
    // setState(() => _notificationCount = 0);

    // Or let user do it inside NotificationPage
    if (_userId != "Not Available" && _userId != "Error") {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationPage(userId: _userId),
        ),
      );
      // After returning, re-fetch the unread count
      await _fetchUnreadNotificationCount(_userId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid or missing user ID.")),
      );
    }
  }

  // ==================== UI BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, toolbarHeight: 5),
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
              return const NoInternetUI();
            } else {
              return Stack(
                children: [
                  _buildHomePageContent(context),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: _buildTodayCircleButton(),
                  ),
                ],
              );
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

  Widget _buildTodayCircleButton() {
    final now = DateTime.now();
    final dayString = now.day.toString();

    return InkWell(
      onTap: _showCalendarPopup,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0054FF),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "TODAY",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              dayString,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(0.5, 0.5),
                    blurRadius: 3,
                    color: Colors.black38,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCalendarPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            width: 340,
            height: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0054FF),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Expanded(
                  child: CalendarWidget(),
                ),
              ],
            ),
          ),
        );
      },
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
              child: _buildActionButtons(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.015),
              child: _buildTransactionSummaryContainer(),
            ),
            const SizedBox(height: 15),
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
          // The top bar with user name & logout
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: TopBarFb4(
              title: 'Welcome Back',
              upperTitle: _givenName,
              onTapMenu: _openNotificationPage,  // <--- Navigate to notifications
              onTapLogout: () => _logout(context),
              notificationCount: _notificationCount, // <--- Pass unread count
            ),
          ),
          // The balance card
          Positioned(
            top: 60,
            left: screenWidth * 0.02,
            right: screenWidth * 0.02,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildBalanceCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final titleColor = DarkModeHandler.getMainBalanceContainerTextColor();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      color: DarkModeHandler.getMainBalanceContainer(),
      child: SizedBox(
        child: Stack(
          children: [
            Padding(
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
                      const Icon(Icons.account_balance_outlined,
                          color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        _userId == "Not Available"
                            ? "User ID: N/A"
                            : "User-ID: $_userId",
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
                        'Current Balance',
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _pendingBalance,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.receipt_long, color: Colors.white),
                            onPressed: () {
                              if (_userId != "Not Available" && _userId != "Error") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PayoutHistoryPage(userId: _userId),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Invalid or missing user ID."),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Last Payout: £$_lastPayout",
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
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
              } else if (title == "Group Pay") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GroupPaymentPage()),
                );
              } else if (title == "Add Event") {
                // Add navigation if needed
              }
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

  Widget _buildTransactionSummaryContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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

    final dataMap = <String, double>{
      "One-Time": _filteredOneTime,
      "Regular": _filteredRegular,
      "Group": _filteredGroup,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Transaction Summary",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: DarkModeHandler.getMainContainersTextColor(),
              ),
            ),
            const Spacer(),
            // Year dropdown
            _buildDropdown<int>(
              value: _selectedYear,
              items: _yearList,
              display: (val) => val.toString(),
              onChanged: (val) {
                setState(() => _selectedYear = val!);
                _applyMonthYearFilter();
              },
            ),
            const SizedBox(width: 5),
            // Month dropdown
            _buildDropdown<int>(
              value: _selectedMonth,
              items: _monthList,
              display: (val) {
                final monthNames = [
                  "Jan","Feb","Mar","Apr","May","Jun",
                  "Jul","Aug","Sep","Oct","Nov","Dec"
                ];
                return monthNames[val - 1];
              },
              onChanged: (val) {
                setState(() => _selectedMonth = val!);
                _applyMonthYearFilter();
              },
            ),
          ],
        ),
        Card(
          color: const Color(0xFFE3F2FD),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_available, color: Color(0xFF000000)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "One-Time Total:",
                        style: TextStyle(fontSize: 16, color: Color(0xFF000000)),
                      ),
                    ),
                    Text(
                      "£${_filteredOneTime.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF060DF3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.credit_card, color: Color(0xFF000000)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Regular Total:",
                        style: TextStyle(fontSize: 16, color: Color(0xFF000000)),
                      ),
                    ),
                    Text(
                      "£${_filteredRegular.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF060DF3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.people, color: Colors.black),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Group Total:",
                        style: TextStyle(fontSize: 16, color: Color(0xFF000000)),
                      ),
                    ),
                    Text(
                      "£${_filteredGroup.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF060DF3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Overall Summary Chart",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: DarkModeHandler.getMainContainersTextColor(),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: PieChart(
            dataMap: dataMap,
            colorList: const [
              Color(0xFFB4FFA7), // One-Time
              Color(0xFF8FBBFD), // Regular
              Color(0xFFF3D782), // Group
            ],
            chartType: ChartType.disc,
            legendOptions: const LegendOptions(
              legendPosition: LegendPosition.right,
              showLegendsInRow: false,
            ),
            chartValuesOptions: const ChartValuesOptions(
              showChartValuesInPercentage: true,
              showChartValues: true,
              decimalPlaces: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) display,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<T>(
        value: value,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down),
        onChanged: onChanged,
        items: items.map((e) {
          return DropdownMenuItem<T>(
            value: e,
            child: Text(display(e)),
          );
        }).toList(),
      ),
    );
  }
}

// ==================== TopBarFb4 WIDGET ====================

class TopBarFb4 extends StatelessWidget {
  final String title;
  final String upperTitle;
  final Function() onTapMenu;
  final Function() onTapLogout;

  // NEW: the unread notification count
  final int notificationCount;

  const TopBarFb4({
    required this.title,
    required this.upperTitle,
    required this.onTapMenu,
    required this.onTapLogout,
    this.notificationCount = 0, // default 0
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // We do not alter the layout; we just wrap the notification icon in a stack to show a badge
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Notification Icon (left side, matching your original code's position)
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (notificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: onTapMenu,
          ),

          // Title text
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
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

          // Logout Icon
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => onTapLogout(),
          ),
        ],
      ),
    );
  }
}
