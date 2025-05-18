import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';

class QRHistoryPage extends StatefulWidget {
  final int userId;
  const QRHistoryPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<QRHistoryPage> createState() => _QRHistoryPageState();
}

class _QRHistoryPageState extends State<QRHistoryPage> {
  bool _loading = true;
  int _selectedMonth = DateTime.now().month;
  int _totalCount = 0;
  double _totalSum = 0.0;
  double _monthlySum = 0.0;
  List<dynamic> _transactions = [];

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _fetchQRHistory();
  }

  Future<void> _fetchQRHistory() async {
    setState(() => _loading = true);
    final uri = Uri.parse(
        '$baseUrl/api/qr/history/total/${widget.userId}?month=$_selectedMonth'
    );

    try {
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        setState(() {
          _totalCount   = data['totalCount'] as int;
          _totalSum     = (data['totalSum']   as num).toDouble();
          _monthlySum   = (data['monthlySum'] as num).toDouble();
          _transactions = data['transactions'] as List<dynamic>;
          _loading      = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _formatDateTime(String dt) =>
      dt.split('.').first.replaceAll('T', ' ');

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, // keep the inner cards white
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                )),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey.shade900,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> txn) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF0054FF),
              child: const Icon(Icons.qr_code, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID: ${txn['transactionId']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      )),
                  const SizedBox(height: 6),
                  Text(
                    'From: ${txn['payerName']} → ${txn['receiverName']}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '£${txn['amount']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(txn['createdAt']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: const Text('QR Payment History'),
        centerTitle: false,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchQRHistory,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Month selector
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _monthNames.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final m = i + 1;
                    return ChoiceChip(
                      label: Text(_monthNames[i]),
                      selected: _selectedMonth == m,
                      onSelected: (sel) {
                        if (sel) {
                          setState(() => _selectedMonth = m);
                          _fetchQRHistory();
                        }
                      },
                      selectedColor: Theme.of(context)
                          .primaryColor
                          .withOpacity(0.2),
                    );
                  },
                ),
              ),
            ),

            // Summary row container with custom color
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF80AFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _infoCard(
                      icon: Icons.list_alt,
                      label: 'Transactions',
                      value: '$_totalCount',
                    ),
                    const SizedBox(width: 12),
                    _infoCard(
                      icon: Icons.attach_money,
                      label: 'Total',
                      value: '£${_totalSum.toStringAsFixed(2)}',
                    ),
                    const SizedBox(width: 12),
                    _infoCard(
                      icon: Icons.calendar_today,
                      label: '${_monthNames[_selectedMonth - 1]} Total',
                      value:
                      '£${_monthlySum.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Details',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),

            // Transaction list
            ..._transactions.map((e) => _buildTransactionCard(e)),

            if (_transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No QR transactions found.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
