import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({Key? key}) : super(key: key);

  @override
  _TransactionHistoryPageState createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  bool _isLoading = false;
  String _errorMessage = '';

  // Filter fields
  DateTime? _startDate;
  DateTime? _endDate;
  String _transactionType = "ALL"; // "ALL", "oneTime", "group", "regular"
  String _sortBy = "createdAtDesc"; // "createdAtAsc" or "createdAtDesc"

  // Analytics data
  double _totalSpent = 0.0;
  int _totalCount = 0;
  List<Map<String, dynamic>> _chartData = [];
  List<Map<String, dynamic>> _transactions = []; // filteredTransactions

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Retrieve user ID from secure storage.
    String? storedUserId = await secureStorage.read(key: 'User_ID');
    if (storedUserId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error: User is not logged in!";
      });
      return;
    }

    int userId;
    try {
      userId = int.parse(storedUserId);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error: Invalid User ID stored!";
      });
      return;
    }

    final filterBody = {
      "startDate": _startDate != null ? DateFormat("yyyy-MM-dd").format(_startDate!) : null,
      "endDate": _endDate != null ? DateFormat("yyyy-MM-dd").format(_endDate!) : null,
      "transactionType": _transactionType,
      "sortBy": _sortBy,
    };

    final url = "http://10.0.2.2:8080/api/analytics/user/$userId/transactions";
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(filterBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _totalSpent = double.tryParse(data['totalSpent'].toString()) ?? 0.0;
          _totalCount = data['totalCount'] as int? ?? 0;

          // Chart data mapping
          _chartData = (data['chartData'] as List<dynamic>? ?? []).map((item) {
            return {
              "label": item['label'] ?? '',
              "value": double.tryParse(item['value'].toString()) ?? 0.0,
            };
          }).toList();

          // Mapping filtered transactions including title, memberName, and transactionType.
          _transactions = (data['filteredTransactions'] as List<dynamic>? ?? [])
              .map((tx) => {
            "transactionType": tx['transactionType'],
            "stripeTransactionId": tx['stripeTransactionId'],
            "amount": tx['amount'],
            "createdAt": tx['createdAt'],
            "title": tx['title'] ?? "",
            "memberName": tx['memberName'] ?? ""
          })
              .toList();
        });
      } else {
        setState(() {
          _errorMessage = "Failed to fetch analytics. Status: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching analytics: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Helper to format DateTime strings.
  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return "N/A";
    try {
      final dt = DateTime.parse(raw);
      return DateFormat("yyyy-MM-dd HH:mm").format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaction History & Analytics"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFE3F2FD),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
          : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFilterSection(),
          const SizedBox(height: 16),
          _buildAnalyticsSummary(),
          const SizedBox(height: 16),
          _buildChartSection(),
          const SizedBox(height: 16),
          _buildTransactionList(),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text("Filters", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            // Start Date
            Row(
              children: [
                const Text("Start Date:"),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_startDate != null
                      ? DateFormat("yyyy-MM-dd").format(_startDate!)
                      : "Not selected"),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today, color: Colors.blueAccent),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _startDate = picked);
                    }
                  },
                )
              ],
            ),
            // End Date
            Row(
              children: [
                const Text("End Date:"),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_endDate != null
                      ? DateFormat("yyyy-MM-dd").format(_endDate!)
                      : "Not selected"),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today, color: Colors.blueAccent),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _endDate = picked);
                    }
                  },
                )
              ],
            ),
            // Transaction Type
            Row(
              children: [
                const Text("Type:"),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _transactionType,
                  items: const [
                    DropdownMenuItem(value: "ALL", child: Text("ALL")),
                    DropdownMenuItem(value: "oneTime", child: Text("OneTime")),
                    DropdownMenuItem(value: "group", child: Text("Group")),
                    DropdownMenuItem(value: "regular", child: Text("Regular")),
                  ],
                  onChanged: (val) {
                    setState(() => _transactionType = val!);
                  },
                ),
              ],
            ),
            // Sort By
            Row(
              children: [
                const Text("Sort By:"),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(value: "createdAtDesc", child: Text("Newest First")),
                    DropdownMenuItem(value: "createdAtAsc", child: Text("Oldest First")),
                  ],
                  onChanged: (val) {
                    setState(() => _sortBy = val!);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              onPressed: _fetchAnalytics,
              child: const Text("Apply Filters",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSummary() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text("Analytics Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text("Total Spent: ", style: TextStyle(fontWeight: FontWeight.w600)),
                Text("£$_totalSpent", style: const TextStyle(color: Colors.blueAccent)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text("Total Count: ", style: TextStyle(fontWeight: FontWeight.w600)),
                Text("$_totalCount", style: const TextStyle(color: Colors.blueAccent)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text("Transaction Breakdown", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final colors = [
      Colors.blueAccent,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];

    List<PieChartSectionData> sections = [];
    for (int i = 0; i < _chartData.length; i++) {
      final item = _chartData[i];
      final double value = item['value'];
      final String label = item['label'];

      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: value,
          title: label,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          radius: 60,
        ),
      );
    }
    return sections;
  }

  Widget _buildTransactionList() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text("Filtered Transactions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (_transactions.isEmpty)
              const Text("No transactions found.")
            else
              ..._transactions.map((tx) {
                final type = tx["transactionType"] ?? '';
                final stripeId = tx["stripeTransactionId"] ?? '';
                final amount = tx["amount"].toString();
                final createdAt = tx["createdAt"] ?? '';
                final title = tx["title"] ?? '';
                final memberName = tx["memberName"] ?? '';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  color: const Color(0xFFE3F2FD),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Txn ID: $stripeId",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.blueAccent),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: stripeId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Txn ID copied")),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text("Payment Type: $type", style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text("What's for: $title", style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (type.toLowerCase() == "group" && memberName.isNotEmpty)
                          Text("Paid member: $memberName", style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text("Amount: £$amount | Date: $createdAt", style: const TextStyle(color: Colors.black87)),
                      ],
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  /// Reusable row with an icon, label, and value.
  Widget _buildLabeledRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blueAccent),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
