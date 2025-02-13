import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
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
    final memberData = json['members'] as List<dynamic>? ?? [];
    final memberList = memberData
        .map((m) => GroupMemberHistoryItem.fromJson(m as Map<String, dynamic>))
        .toList();

    return GroupPaymentHistoryItem(
      groupPaymentId: json['groupPaymentId'] as int,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      totalAmount: (json['totalAmount'] as num).toDouble(),
      completed: json['completed'] as bool,
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
  const GroupPaymentHistoryPage({super.key});

  @override
  _GroupPaymentHistoryPageState createState() =>
      _GroupPaymentHistoryPageState();
}

class _GroupPaymentHistoryPageState extends State<GroupPaymentHistoryPage>
    with SingleTickerProviderStateMixin {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isLoading = true;
  List<GroupPaymentHistoryItem> _allHistoryItems = [];
  List<GroupPaymentHistoryItem> _filteredItems = [];

  late TabController _tabController;

  // Date filtering
  late int _selectedYear;
  late int _selectedMonth;

  // Year range & month list
  final List<int> _yearList = [];
  final List<int> _monthList = List<int>.generate(12, (index) => index + 1);

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    // Build a year list from 2022.. now.year+1
    for (int y = 2022; y <= now.year + 1; y++) {
      _yearList.add(y);
    }
    // Default to the current year and month
    _selectedYear = now.year;
    _selectedMonth = now.month;

    _tabController = TabController(length: 2, vsync: this);
    _fetchGroupPaymentHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Fetch group payment history from backend
  Future<void> _fetchGroupPaymentHistory() async {
    try {
      final userId = await _secureStorage.read(key: 'User_ID');
      if (userId == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No user ID found. Please log in.")),
        );
        return;
      }

      final apiUrl =
          "http://10.0.2.2:8080/api/group-payments/history/$userId";
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        final items = data
            .map((item) => GroupPaymentHistoryItem.fromJson(item))
            .toList();

        // Sort descending by createdAt
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        setState(() {
          _allHistoryItems = items.cast<GroupPaymentHistoryItem>();
          _isLoading = false;
        });

        _applyDateFilter();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to load history: ${response.statusCode}")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching history: $e")),
      );
    }
  }

  /// Filter items based on _selectedYear and _selectedMonth
  void _applyDateFilter() {
    setState(() {
      _filteredItems = _allHistoryItems.where((item) {
        return item.createdAt.year == _selectedYear &&
            item.createdAt.month == _selectedMonth;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unpaidItems = _filteredItems.where((h) => !h.completed).toList();
    final paidItems = _filteredItems.where((h) => h.completed).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFE3F2FD),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0, // Remove shadow if you want
          toolbarHeight: 48, // Make the app bar smaller
          // No title here
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
            : Column(
          children: [
            // The date filter row
            _buildDateSelectorRow(),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabContent(unpaidItems, isPaidTab: false),
                  _buildTabContent(paidItems, isPaidTab: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelectorRow() {
    return Container(
      color: const Color(0xFFE3F2FD),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          // Year dropdown
          Expanded(
            child: _buildDropdown<int>(
              label: "Year",
              items: _yearList,
              value: _selectedYear,
              onChanged: (val) {
                setState(() {
                  _selectedYear = val!;
                });
                _applyDateFilter();
              },
              display: (val) => val.toString(),
            ),
          ),
          const SizedBox(width: 16),
          // Month dropdown
          Expanded(
            child: _buildDropdown<int>(
              label: "Month",
              items: _monthList,
              value: _selectedMonth,
              onChanged: (val) {
                setState(() {
                  _selectedMonth = val!;
                });
                _applyDateFilter();
              },
              display: (val) {
                final monthNames = [
                  "Jan",
                  "Feb",
                  "Mar",
                  "Apr",
                  "May",
                  "Jun",
                  "Jul",
                  "Aug",
                  "Sep",
                  "Oct",
                  "Nov",
                  "Dec"
                ];
                return monthNames[val - 1];
              },
            ),
          ),
        ],
      ),
    );
  }

  /// A smaller, simpler dropdown
  Widget _buildDropdown<T>({
    required String label,
    required List<T> items,
    required T value,
    required Function(T?) onChanged,
    required String Function(T) display,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label text
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<T>(
            isExpanded: true,
            underline: const SizedBox(),
            value: value,
            onChanged: (val) => onChanged(val),
            items: items.map((e) {
              return DropdownMenuItem<T>(
                value: e,
                child: Text(display(e)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(List<GroupPaymentHistoryItem> items,
      {required bool isPaidTab}) {
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

  /// Updated _buildHistoryCard with a professional, clean UI.
  Widget _buildHistoryCard(GroupPaymentHistoryItem item) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title and status icon
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.completed
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    item.completed ? Icons.check_circle : Icons.pending,
                    color: item.completed ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Description (if available)
            if (item.description.isNotEmpty) ...[
              Text(
                item.description,
                style:
                const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
            ],
            // Amount and Created Date Row
            Row(
              children: [
                const SizedBox(width: 4),
                Text(
                  "£${item.totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}",
                  style:
                  const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),
            // Payment Link Section
            _buildLinkSection(item.paymentUrl),
            const SizedBox(height: 12),
            // Members Section
            _buildMembersSection(item.members),
          ],
        ),
      ),
    );
  }

  /// Modified _buildLinkSection that shows half of the link with a copy icon.
  Widget _buildLinkSection(String paymentUrl) {
    if (paymentUrl.isEmpty) {
      return const Text(
        "No Payment Link Available",
        style: TextStyle(fontSize: 14, color: Colors.grey),
      );
    }
    // Show only the first half of the link followed by ellipsis.
    final int halfLength = paymentUrl.length ~/ 2;
    final String truncatedUrl = paymentUrl.substring(0, halfLength) + '...';
    return Row(
      children: [
        const Icon(Icons.link, color: Colors.blueAccent, size: 16),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            truncatedUrl,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.blueAccent,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, color: Colors.blueAccent, size: 18),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: paymentUrl));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Link copied to clipboard")),
            );
          },
        )
      ],
    );
  }

  Widget _buildMemberRow(GroupMemberHistoryItem member) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              member.memberName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            "£${member.assignedAmount.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
              member.paid ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              member.paid ? "Paid" : "Pending",
              style: TextStyle(
                fontSize: 12,
                color: member.paid ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(List<GroupMemberHistoryItem> members) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:  Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Members",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (members.isEmpty)
            const Text(
              "No members found",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            )
          else
            ...members.map((m) => _buildMemberRow(m)).toList(),
        ],
      ),
    );
  }
}
