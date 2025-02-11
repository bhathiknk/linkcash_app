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
  final bool completed; // "isCompleted" from backend
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
        setState(() => _isLoading = false);
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
        final items = data.map((item) => GroupPaymentHistoryItem.fromJson(item)).toList();
        setState(() {
          _historyItems = items.cast<GroupPaymentHistoryItem>();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load history: ${response.statusCode}")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching history: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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

  /// Build a stylized container for each group payment
  Widget _buildHistoryCard(GroupPaymentHistoryItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    item.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // If completed, show green check, else show red cancel
                item.completed
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.cancel, color: Colors.red),
              ],
            ),
            const SizedBox(height: 6),

            // Description
            if (item.description.isNotEmpty) ...[
              Text(
                item.description,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 6),
            ],

            // Amount + Created
            Text(
              "Amount: £${item.totalAmount.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              "Created: ${item.createdAt.toLocal()}",
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 6),

            // Payment link
            _buildLinkSection(item.paymentUrl),
            const SizedBox(height: 8),

            // Enhanced highlight for members
            _buildMembersSection(item.members),
          ],
        ),
      ),
    );
  }

  /// Build a row for each member's assigned amount + paid status
  Widget _buildMemberRow(GroupMemberHistoryItem member) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              "${member.memberName} - £${member.assignedAmount.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            member.paid ? "Paid" : "Pending",
            style: TextStyle(
              color: member.paid ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// A container with a subtle background to highlight the members list
  Widget _buildMembersSection(List<GroupMemberHistoryItem> members) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF), // Light blue background
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Members",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          if (members.isEmpty)
            const Text("No members found", style: TextStyle(fontSize: 14))
          else
            ...members.map((m) => _buildMemberRow(m)).toList(),
        ],
      ),
    );
  }

  /// Build a clickable link or "No Link Available" text
  Widget _buildLinkSection(String paymentUrl) {
    if (paymentUrl.isEmpty) {
      return const Text(
        "No Link Available",
        style: TextStyle(fontSize: 14, color: Colors.grey),
      );
    }
    return InkWell(
      onTap: () {
        // Optionally open link in a browser, or copy to clipboard, etc.
      },
      child: Text(
        paymentUrl,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
