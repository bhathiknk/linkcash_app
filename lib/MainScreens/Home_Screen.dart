import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For secure storage
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:linkcash_app/MainScreens/Pay_Quick_Page.dart';
import 'package:pie_chart/pie_chart.dart'; // For the pie chart
import '../ConnectionCheck/No_Internet_Ui.dart';
import '../ConnectionCheck/connectivity_service.dart';
import '../LogScreen/Asgardio_Login.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/calendar_widget.dart';
import '../WidgetsCom/dark_mode_handler.dart';
import 'Group_Payment_Page.dart';

// DTO classes for transaction summary (matching backend DTOs)
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

  const MyHomePage({super.key, required this.givenName});
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

  // Variable for transaction summary.
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
      _initialConnectivityResult =
          connectivityResults.contains(ConnectivityResult.none)
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

  Future<void> _fetchTransactionSummary(String userId) async {
    final String apiUrl =
        "http://10.0.2.2:8080/api/transactions/summary/user/$userId";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final summaryData = jsonDecode(response.body);
        setState(() {
          _transactionSummary =
              TransactionSummaryResponse.fromJson(summaryData);
          _isSummaryLoading = false;
        });
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

  // We have a "circular button with 'Today' & day" that shows a popup calendar
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(backgroundColor: Colors.white, elevation: 0, toolbarHeight: 5),
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
                letterSpacing: 1.2, // Adds some spacing between letters
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
                Expanded(
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

  Widget _buildTransactionSummaryContainer() {
    return Container(
      // Now takes full available width
      width: double.infinity,

      // Padding, borderRadius, and shadow remain the same
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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

    // Build a data map for the pie chart using the totalOneTime & totalRegular
    final dataMap = <String, double>{
      "One-Time": _transactionSummary!.totalOneTime,
      "Regular": _transactionSummary!.totalRegular,
    };

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
        // Overall totals card
        Card(
          color: const Color(0xFFE3F2FD),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                // One-Time Total Row
                Row(
                  children: [
                    const Icon(Icons.event_available, color: Color(0xFF148E00)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "One-Time Total:",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF148E00),
                        ),
                      ),
                    ),
                    Text(
                      "£${_transactionSummary!.totalOneTime.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF148E00),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Regular Total Row
                Row(
                  children: [
                    const Icon(Icons.credit_card, color: Color(0xFF060DF3)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Regular Total:",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF060DF3),
                        ),
                      ),
                    ),
                    Text(
                      "£${_transactionSummary!.totalRegular.toStringAsFixed(2)}",
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

        const SizedBox(height: 20),
        Text(
          "Overall Summary Chart",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: DarkModeHandler.getMainContainersTextColor(),
          ),
        ),
        const SizedBox(height: 10),

        // Pie Chart for overall summary
        SizedBox(
          height: 200,
          child: PieChart(
            dataMap: dataMap,
            colorList: const [Color(0xFF80ED6B), Color(0xFF4489F8)],
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                    // One-Time total in monthly summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_available,
                            size: 14, color: Color(0xFF148E00)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            monthly.oneTimeTotal.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF148E00),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Regular total in monthly summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.credit_card,
                            size: 14, color: Color(0xFF060DF3)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            monthly.regularTotal.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF060DF3),
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
                  MaterialPageRoute(
                      builder: (context) => const GroupPaymentPage()),
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
