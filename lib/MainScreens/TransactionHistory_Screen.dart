import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For secure storage
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/dark_mode_handler.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  int currentIndex = 4; // Set initial index to TransactionPage
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchTransactions();
  }

  Future<void> _loadUserIdAndFetchTransactions() async {
    try {
      // Retrieve the UserId from secure storage
      final storedUserId = await _secureStorage.read(key: 'User_ID');
      if (storedUserId != null) {
        setState(() {
          userId = storedUserId;
        });
        await _fetchTransactions();
      } else {
        setState(() {
          isLoading = false;
        });
        // If no UserId, show an error or redirect to login
        print("No UserId found. Redirect to login.");
      }
    } catch (e) {
      print("Error loading UserId: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchTransactions() async {
    if (userId == null) return;

    final String apiUrl = "http://10.0.2.2:8080/api/payments/transactions/user/$userId";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          transactions = List<Map<String, dynamic>>.from(json.decode(response.body));
          transactions.sort((a, b) =>
              DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
          isLoading = false;
        });
      } else {
        print("Failed to fetch transactions: ${response.body}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching transactions: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: DarkModeHandler.getAppBarColor(),
        title: const Text(
          'Transaction History',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      backgroundColor: DarkModeHandler.getBackgroundColor(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : transactions.isEmpty
          ? Center(
        child: Text(
          "No transactions found!",
          style: TextStyle(
            color: DarkModeHandler.getMainContainersTextColor(),
            fontSize: 18,
          ),
        ),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildTransactionList(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildTransactionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: transactions.map((transaction) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 0,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        child: Icon(
                          Icons.monetization_on,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          transaction['title'] ?? "No Title",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Transaction ID: ${transaction['stripeTransactionId']}",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: "Amount: ",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: "\£${transaction['amount'].toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: double.tryParse(transaction['amount'].toString())! >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Date: ${transaction['createdAt']}",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
