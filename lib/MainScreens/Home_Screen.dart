import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For secure storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For secure storage
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:linkcash_app/MainScreens/payout_history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pie_chart/pie_chart.dart'; // For the pie chart

import '../ConnectionCheck/No_Internet_Ui.dart';
import '../ConnectionCheck/connectivity_service.dart';
import '../LogScreen/Asgardio_Login.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/calendar_widget.dart';
import '../WidgetsCom/dark_mode_handler.dart';
import 'Pay_Quick_Page.dart';
import 'Group_Payment_Page.dart';

// ==================== DATA CLASSES (DTOs) ====================

// Monthly Summary DTO
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
      groupTotal: (json['groupTotal'] as num).toDouble(), // parse from JSON
    );
  }
}

// Summary Response DTO
class TransactionSummaryResponse {
  final double totalOneTime;
  final double totalRegular;
  final double totalGroup; // NEW
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
  String _givenName = "User"; // Default value for givenName

  // Transaction summary
  TransactionSummaryResponse? _transactionSummary;
  bool _isSummaryLoading = true;

  // ==================== Month/Year Filtering Fields ====================
  final List<int> _yearList = [];
  final List<int> _monthList = List<int>.generate(12, (i) => i + 1);
  late int _selectedYear;
  late int _selectedMonth;

  // Filtered values for the selected month-year
  double _filteredOneTime = 0.0;
  double _filteredRegular = 0.0;
  double _filteredGroup = 0.0;

  // ==================== INIT & DISPOSE ====================

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
    // Build a year list from 2022 up to next year
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

  // ==================== LOADING DATA ====================

  Future<void> _fetchUserId() async {
    try {
      final userId = await _secureStorage.read(key: 'User_ID');
      if (userId != null) {
        setState(() {
          _userId = userId;
        });
        _fetchPendingBalance(userId);
        _fetchTransactionSummary(userId);
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
      debugPrint("Error fetching givenName: $e");
    }
  }

  /// Fetch the full summary from backend, then apply the local filter.
  Future<void> _fetchTransactionSummary(String userId) async {
    final String apiUrl =
        "http://10.0.2.2:8080/api/transactions/summary/user/$userId";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final summaryData = jsonDecode(response.body);
        setState(() {
          _transactionSummary = TransactionSummaryResponse.fromJson(summaryData);
          _isSummaryLoading = false;
        });
        // Apply filter for the default selected month/year
        _applyMonthYearFilter();
      } else {
        debugPrint("Failed to fetch summary: ${response.body}");
        setState(() {
          _isSummaryLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching summary: $e");
      setState(() {
        _isSummaryLoading = false;
      });
    }
  }

  // ==================== MONTH/YEAR FILTER LOGIC ====================

  /// Filters the monthly data for _selectedYear & _selectedMonth,
  /// storing results in _filteredOneTime, _filteredRegular, _filteredGroup.
  void _applyMonthYearFilter() {
    if (_transactionSummary == null) return;

    // Format e.g. "2023-09"
    final selectedKey =
        "${_selectedYear.toString().padLeft(4, '0')}-${_selectedMonth.toString().padLeft(2, '0')}";

    // Find the matching monthly item or default to zeros
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

  // ==================== MISC  ====================

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
                  // Circle button pinned to bottom-right corner
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
    final dayString = now.day.toString(); // e.g. 2, 15, 30

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

  // Show an attractive calendar popup
  void _showCalendarPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Rounded corners
          ),
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
                  child: CalendarWidget(), // Custom calendar widget
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
            // Row with balance & payout icon
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
                Row(
                  children: [
                    // Pending balance
                    Text(
                      _pendingBalance,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Payout icon
                    IconButton(
                      icon: const Icon(Icons.receipt_long, color: Colors.white),
                      onPressed: () {
                        // Navigate to the new PayoutHistoryPage
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
                // Add navigation if needed.
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

  /// Renders the entire transaction summary UI, including
  /// the row of (Transaction Summary + Month/Year dropdowns),
  /// the totals card, pie chart, and optional monthly list.
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

    // Build the data map for the pie chart from *filtered* values
    final dataMap = <String, double>{
      "One-Time": _filteredOneTime,
      "Regular": _filteredRegular,
      "Group": _filteredGroup,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + Dropdowns in the same row
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
            // YEAR Dropdown
            _buildDropdown<int>(
              value: _selectedYear,
              items: _yearList,
              display: (val) => val.toString(),
              onChanged: (val) {
                setState(() {
                  _selectedYear = val!;
                });
                _applyMonthYearFilter();
              },
            ),
            const SizedBox(width: 5),
            // MONTH Dropdown
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
                setState(() {
                  _selectedMonth = val!;
                });
                _applyMonthYearFilter();
              },
            ),
          ],
        ),

        // Overall Totals Card - uses *filtered* sums now
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
                // One-Time
                Row(
                  children: [
                    const Icon(Icons.event_available, color: Color(0xFF000000)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "One-Time Total:",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF000000),
                        ),
                      ),
                    ),
                    Text(
                      "£${_filteredOneTime.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:Color(0xFF060DF3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Regular
                Row(
                  children: [
                    const Icon(Icons.credit_card, color: Color(0xFF000000)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Regular Total:",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF000000),
                        ),
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

                // Group
                Row(
                  children: [
                    const Icon(Icons.people, color: Colors.black),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Group Total:",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF000000),
                        ),
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

        // Pie Chart (filtered data)
        SizedBox(
          height: 200,
          child: PieChart(
            dataMap: dataMap,
            colorList:  [
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

  /// A basic dropdown builder for year/month.
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

  const TopBarFb4({
    required this.title,
    required this.upperTitle,
    required this.onTapMenu,
    required this.onTapLogout,
    super.key,
  });

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
