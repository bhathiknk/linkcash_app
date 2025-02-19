import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

// PDF packages
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
  List<Map<String, dynamic>> _transactions = []; // original filteredTransactions from server

  // Controls filter visibility and search
  bool _showFilters = false;
  final TextEditingController _searchController = TextEditingController();

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

  /// Returns the list of transactions filtered by the search query.
  List<Map<String, dynamic>> get _filteredTransactions {
    if (_searchController.text.isEmpty) {
      return _transactions;
    } else {
      final query = _searchController.text.toLowerCase();
      return _transactions.where((tx) {
        final txnId = (tx["stripeTransactionId"] ?? "").toLowerCase();
        return txnId.contains(query);
      }).toList();
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
          // Top row with filter toggle and download button.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFilterToggleButton(),
              _buildDownloadButton(),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1.0,
                child: child,
              );
            },
            child: _showFilters ? _buildFilterSection() : const SizedBox.shrink(),
          ),
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

  /// Button to toggle filter section visibility.
  Widget _buildFilterToggleButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      icon: Icon(
        _showFilters ? Icons.arrow_drop_up : Icons.arrow_drop_down,
        color: Colors.white,
      ),
      label: Text(
        _showFilters ? "Hide Filters" : "Show Filters",
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        setState(() {
          _showFilters = !_showFilters;
          if (!_showFilters) {
            _searchController.clear();
          }
        });
      },
    );
  }

  /// Button to download PDF.
  Widget _buildDownloadButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      icon: const Icon(Icons.download, color: Colors.white),
      label: const Text(
        "Download PDF",
        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      ), onPressed: () {  },
    );
  }

  /// Redesigned compact Filter Section.
  Widget _buildFilterSection() {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            const Text(
              "Filter",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            // Dates Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDateFilter("Start", _startDate, (picked) {
                  if (picked != null) setState(() => _startDate = picked);
                }),
                const SizedBox(width: 8),
                _buildDateFilter("End", _endDate, (picked) {
                  if (picked != null) setState(() => _endDate = picked);
                }),
              ],
            ),
            const SizedBox(height: 8),
            // Dropdowns Row
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: "Type",
                    value: _transactionType,
                    items: const ["ALL", "oneTime", "group", "regular"],
                    onChanged: (val) => setState(() => _transactionType = val),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDropdown(
                    label: "Sort",
                    value: _sortBy,
                    items: const ["createdAtDesc", "createdAtAsc"],
                    onChanged: (val) => setState(() => _sortBy = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              onPressed: _fetchAnalytics,
              child: const Text(
                "Apply",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper widget for date filter (compact design).
  Widget _buildDateFilter(String label, DateTime? date, Function(DateTime?) onDatePicked) {
    return Expanded(
      child: Row(
        children: [
          Text(
            "$label:",
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              date != null ? DateFormat("yyyy-MM-dd").format(date) : "None",
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, size: 16, color: Colors.blueAccent),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              onDatePicked(picked);
            },
          ),
        ],
      ),
    );
  }

  /// Helper widget for dropdown filters.
  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, size: 16, color: Colors.blueAccent),
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            onChanged: (val) => onChanged(val!),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsSummary() {
    return Card(
      color: Colors.white,
      elevation: 0,
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
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text("Transaction Breakdown", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Stack(
              children: [
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
                Positioned.fill(
                  child: Center(
                    child: Text(
                      "£$_totalSpent",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                ),
              ],
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
          // Show both label and total amount in pounds within each section.
          title: "$label\n£${value.toStringAsFixed(2)}",
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          radius: 60,
        ),
      );
    }
    return sections;
  }

  Widget _buildTransactionList() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Filtered Transactions",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.blueAccent),
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                      if (!_showFilters) {
                        _searchController.clear();
                      }
                    });
                  },
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1.0,
                  child: child,
                );
              },
              child: _showFilters
                  ? Padding(
                key: const ValueKey(1),
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blueAccent, width: 1),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search by Txn ID...",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.blueAccent, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {});
                    },
                  ),
                ),
              )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 8),
            if (_filteredTransactions.isEmpty)
              const Text("No transactions found.")
            else
              ..._filteredTransactions.map((tx) {
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
