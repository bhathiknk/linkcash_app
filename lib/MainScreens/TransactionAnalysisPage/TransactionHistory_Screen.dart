import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../WidgetsCom/bottom_navigation_bar.dart';
import '../../config.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({Key? key}) : super(key: key);

  @override
  _TransactionHistoryPageState createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  // Color palette
  final Color mainColor = const Color(0xFF0054FF);
  final Color secondaryColor = const Color(0xFF83B6B9);
  final Color bgColor = const Color(0xFFE3F2FD);

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
  List<Map<String, dynamic>> _transactions = [];

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

    final url = "$baseUrl/api/analytics/user/$userId/transactions";
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
          _chartData = (data['chartData'] as List<dynamic>? ?? []).map((item) {
            return {
              "label": item['label'] ?? '',
              "value": double.tryParse(item['value'].toString()) ?? 0.0,
            };
          }).toList();
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

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return "N/A";
    try {
      final dt = DateTime.parse(raw);
      return DateFormat("yyyy-MM-dd HH:mm").format(dt);
    } catch (_) {
      return raw;
    }
  }

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
      backgroundColor: bgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
          : _buildMainContent(),


      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: 4,
        onTap: (_) {},
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
              return SizeTransition(sizeFactor: animation, axisAlignment: -1.0, child: child);
            },
            child: _showFilters ? _buildFilterSection() : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          _buildAnalyticsSummary(),
          const SizedBox(height: 16),
          _buildChartSection(),  // Updated chart section
          const SizedBox(height: 16),
          _buildTransactionList(),
        ],
      ),
    );
  }

  Widget _buildFilterToggleButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: mainColor,
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
          if (!_showFilters) _searchController.clear();
        });
      },
    );
  }

  Widget _buildDownloadButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: mainColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      icon: const Icon(Icons.download, color: Colors.white),
      label: const Text(
        "Download PDF",
        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      onPressed: () {},
    );
  }

  Widget _buildFilterSection() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            const Text("Filter", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDateFilter("Start", _startDate, (picked) {
                    if (picked != null) setState(() => _startDate = picked);
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDateFilter("End", _endDate, (picked) {
                    if (picked != null) setState(() => _endDate = picked);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
                backgroundColor: mainColor,
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

  Widget _buildDateFilter(String label, DateTime? date, Function(DateTime?) onDatePicked) {
    return Row(
      children: [
        Text("$label:", style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            date != null ? DateFormat("yyyy-MM-dd").format(date) : "None",
            style: const TextStyle(fontSize: 12, color: Colors.black54),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: Icon(Icons.calendar_today, size: 16, color: mainColor),
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
    );
  }

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
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: mainColor),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down, size: 16, color: mainColor),
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            onChanged: (val) => onChanged(val!),
            items: items
                .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
                .toList(),
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
            Text("Analytics Summary",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: mainColor)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text("Total Income: ", style: TextStyle(fontWeight: FontWeight.w600)),
                Text("£$_totalSpent", style: TextStyle(color: mainColor, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text("Total Count: ", style: TextStyle(fontWeight: FontWeight.w600)),
                Text("$_totalCount", style: TextStyle(color: mainColor, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── UPDATED CHART SECTION ───────────────────────────────────────────────
  Widget _buildChartSection() {
    final total = _chartData.fold<double>(0.0, (sum, item) => sum + item['value']);
    const colorList = [
      Color(0xFFFFD37E),//group
      Color(0xFF80D1FF),//onetime
      Color(0xFF94E4B8),//regular
    ];

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Transaction Breakdown",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: mainColor)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: List.generate(_chartData.length, (i) {
                    final item = _chartData[i];
                    final value = item['value'] as double;
                    final percent = total > 0 ? (value / total * 100).toStringAsFixed(1) + '%' : '0%';
                    return PieChartSectionData(
                      color: colorList[i % colorList.length],
                      value: value,
                      title: percent,
                      titleStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      radius: 60,
                    );
                  }),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend with amount, type, and color swatch
            ...List.generate(_chartData.length, (i) {
              final item = _chartData[i];
              final value = item['value'] as double;
              final label = item['label'] as String;
              final color = colorList[i % colorList.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text("$label: £${value.toStringAsFixed(2)}", style: const TextStyle(fontSize: 14))),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildTransactionList() {
    return Card(
      color: Colors.white,
      elevation: 2,
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
                  icon: Icon(Icons.search, color: mainColor),
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                      if (!_showFilters) _searchController.clear();
                    });
                  },
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return SizeTransition(sizeFactor: animation, axisAlignment: -1.0, child: child);
              },
              child: _showFilters
                  ? Padding(
                key: const ValueKey(1),
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search by Txn ID...",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: mainColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: secondaryColor),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear, color: mainColor, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                  ),
                  onChanged: (val) => setState(() {}),
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
                final createdAt = _formatDateTime(tx["createdAt"]);
                final title = tx["title"] ?? '';
                final memberName = tx["memberName"] ?? '';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(left: BorderSide(width: 4, color: mainColor)),
                    ),
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
                              icon: Icon(Icons.copy, color: mainColor),
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
                        Text("Amount: £$amount | Date: $createdAt",
                            style: const TextStyle(color: Colors.black87)),
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
}
