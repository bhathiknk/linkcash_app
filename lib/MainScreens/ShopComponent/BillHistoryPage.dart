import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';
import 'bill_detail_page.dart';
import 'models.dart';

class BillHistoryPage extends StatefulWidget {
  final int userId;
  const BillHistoryPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<BillHistoryPage> createState() => _BillHistoryPageState();
}

class _BillHistoryPageState extends State<BillHistoryPage> with SingleTickerProviderStateMixin {
  late Future<List<ShopTransactionHistory>> _futureHistory;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _futureHistory = fetchHistory(widget.userId);
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<List<ShopTransactionHistory>> fetchHistory(int userId) async {
    final url = Uri.parse('$baseUrl/api/shop-transactions/history/user/$userId');
    final resp = await http.get(url);
    if (resp.statusCode != 200) throw Exception('Failed to load history');
    final List<dynamic> jsonList = jsonDecode(resp.body);
    return jsonList.map((json) => ShopTransactionHistory.fromJson(json)).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = const Color(0xFF0054FF);
    final Color bgColor = const Color(0xFFE3F2FD);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Bill History',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<ShopTransactionHistory>>(
        future: _futureHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allHistory = snapshot.data!;
          final paid = allHistory
              .where((tx) => tx.billStatus.toUpperCase() == 'COMPLETED')
              .toList()
            ..sort((a, b) => b.transactionCreatedAt.compareTo(a.transactionCreatedAt));
          final unpaid = allHistory
              .where((tx) => tx.billStatus.toUpperCase() == 'PENDING')
              .toList()
            ..sort((a, b) => b.transactionCreatedAt.compareTo(a.transactionCreatedAt));

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: mainColor,
                  labelColor: mainColor,
                  unselectedLabelColor: Colors.black45,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
                      text: "Paid",
                    ),
                    Tab(
                      icon: Icon(Icons.pending_actions, color: Color(0xFFFF9800)),
                      text: "Unpaid",
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(paid, mainColor),
                    _buildList(unpaid, mainColor),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<ShopTransactionHistory> list, Color mainColor) {
    if (list.isEmpty) {
      return const Center(child: Text("No transactions found."));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: list.length,
      itemBuilder: (_, index) {
        final tx = list[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BillDetailPage(history: tx)),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: mainColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: mainColor.withOpacity(0.1),
                    child: Text(
                      '£${tx.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.customerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Bill #${tx.billId} • ${tx.transactionCreatedAt.toLocal().toString().substring(0, 16)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 24, color: Colors.black45),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
