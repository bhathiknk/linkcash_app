import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Each group payment item returned by the backend.
class GroupPaymentHistoryItem {
  final int groupPaymentId;
  final String title;
  final String description;
  final double totalAmount;
  final bool completed; // "isCompleted" from the backend
  final DateTime createdAt;
  final String paymentUrl;
  final List<GroupMemberHistoryItem> members;

  GroupPaymentHistoryItem({
    required this.groupPaymentId,
    required this.title,
    required this.description,
    required this.totalAmount,
    required this.completed,
    required this.createdAt,
    required this.paymentUrl,
    required this.members,
  });

  factory GroupPaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    List<GroupMemberHistoryItem> memberList = [];
    if (json['members'] != null) {
      memberList = (json['members'] as List)
          .map((m) => GroupMemberHistoryItem.fromJson(m))
          .toList();
    }

    return GroupPaymentHistoryItem(
      groupPaymentId: json['groupPaymentId'],
      title: json['title'],
      description: json['description'] ?? '',
      totalAmount: (json['totalAmount'] as num).toDouble(),
      completed: json['completed'],
      createdAt: DateTime.parse(json['createdAt']),
      paymentUrl: json['paymentUrl'] ?? '',
      members: memberList,
    );
  }
}

/// Each member’s data
class GroupMemberHistoryItem {
  final String memberName;
  final double assignedAmount;
  final bool paid;
  final String? paidAt;

  GroupMemberHistoryItem({
    required this.memberName,
    required this.assignedAmount,
    required this.paid,
    this.paidAt,
  });

  factory GroupMemberHistoryItem.fromJson(Map<String, dynamic> json) {
    return GroupMemberHistoryItem(
      memberName: json['memberName'],
      assignedAmount: (json['assignedAmount'] as num).toDouble(),
      paid: json['paid'],
      paidAt: json['paidAt']?.toString(),
    );
  }
}

class GroupPaymentHistoryPage extends StatefulWidget {
  const GroupPaymentHistoryPage({Key? key}) : super(key: key);

  @override
  _GroupPaymentHistoryPageState createState() => _GroupPaymentHistoryPageState();
}

class _GroupPaymentHistoryPageState extends State<GroupPaymentHistoryPage>
    with SingleTickerProviderStateMixin {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isLoading = true;
  List<GroupPaymentHistoryItem> _historyItems = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchGroupPaymentHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Fetch all group payments for the logged-in user
  Future<void> _fetchGroupPaymentHistory() async {
    try {
      // 1) Read the user ID from secure storage
      String? userId = await _secureStorage.read(key: 'User_ID');
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No user ID found. Please log in.")),
        );
        return;
      }

      // 2) Make GET request to the new endpoint
      final String apiUrl = "http://10.0.2.2:8080/api/group-payments/history/$userId";
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<GroupPaymentHistoryItem> items = data
            .map((item) => GroupPaymentHistoryItem.fromJson(item))
            .toList();
        setState(() {
          _historyItems = items;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load history: ${response.statusCode}")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching history: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Separate the items into Unpaid vs Paid
    final unpaidItems = _historyItems.where((h) => !h.completed).toList();
    final paidItems   = _historyItems.where((h) =>  h.completed).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFE3F2FD),
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            "Group Payment History",
            style: TextStyle(color: Colors.black),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueAccent,
            tabs: const [
              Tab(text: "Unpaid"),
              Tab(text: "Paid"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          controller: _tabController,
          children: [
            // Unpaid tab
            _buildTabContent(unpaidItems, isPaidTab: false),
            // Paid tab
            _buildTabContent(paidItems, isPaidTab: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(List<GroupPaymentHistoryItem> items, {required bool isPaidTab}) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          isPaidTab ? "No paid group payments." : "No unpaid group payments.",
          style: const TextStyle(fontSize: 16),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: items.map((item) => _buildHistoryCard(item)).toList(),
      ),
    );
  }

  /// Builds a card for a single group payment
  Widget _buildHistoryCard(GroupPaymentHistoryItem item) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              item.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            // More lines
            Text("Description: ${item.description}"),
            Text("Amount: £${item.totalAmount.toStringAsFixed(2)}"),
            Text("Created: ${item.createdAt.toLocal()}"), // or format as needed
            const SizedBox(height: 4),
            // Payment Link
            Text(
              item.paymentUrl.isEmpty ? "No Link Available" : item.paymentUrl,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 8),
            // Members
            const Text("Members:", style: TextStyle(fontWeight: FontWeight.bold)),
            ...item.members.map((m) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${m.memberName} - £${m.assignedAmount.toStringAsFixed(2)}"),
                    Text(
                      m.paid ? "Paid" : "Pending",
                      style: TextStyle(
                        color: m.paid ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            })
          ],
        ),
      ),
    );
  }
}
