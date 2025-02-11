import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Pay_Quick_Page.dart'; // For JSON


class PayQuickPaymentHistoryPage extends StatefulWidget {
  const PayQuickPaymentHistoryPage({super.key});

  @override
  _PayQuickPaymentHistoryPageState createState() =>
      _PayQuickPaymentHistoryPageState();
}

class _PayQuickPaymentHistoryPageState
    extends State<PayQuickPaymentHistoryPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;

  late TabController _tabController;

  List<PaymentLinkItem> _unpaidItems = [];
  List<PaymentLinkItem> _paidItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Fetch both unpaid and paid items from your backend.
    // We'll do it in separate calls for demonstration.
    _fetchPayQuickHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Fetch data for both unpaid and paid items (two requests).
  Future<void> _fetchPayQuickHistory() async {
    try {
      // Call for unpaid links
      final responseUnpaid = await http.get(Uri.parse(
          "http://10.0.2.2:8080/api/one-time-payment-links/list?used=false"));
      // Call for paid links
      final responsePaid = await http.get(Uri.parse(
          "http://10.0.2.2:8080/api/one-time-payment-links/list?used=true"));

      if (responseUnpaid.statusCode == 200 && responsePaid.statusCode == 200) {
        final dataUnpaid = jsonDecode(responseUnpaid.body) as List<dynamic>;
        final dataPaid = jsonDecode(responsePaid.body) as List<dynamic>;

        List<PaymentLinkItem> unpaidList = dataUnpaid
            .map((item) => PaymentLinkItem.fromJson(item))
            .toList();
        List<PaymentLinkItem> paidList = dataPaid
            .map((item) => PaymentLinkItem.fromJson(item))
            .toList();

        setState(() {
          _unpaidItems = unpaidList;
          _paidItems = paidList;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "Failed to fetch data: ${responseUnpaid.statusCode}, ${responsePaid.statusCode}")));
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFE3F2FD),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 48,
          title: const Text(
            "Pay Quick History",
            style: TextStyle(color: Colors.black, fontSize: 18),
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
            _buildTabContent(_unpaidItems, isPaidTab: false),
            _buildTabContent(_paidItems, isPaidTab: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(List<PaymentLinkItem> items, {required bool isPaidTab}) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          isPaidTab
              ? "No paid links found."
              : "No unpaid links found.",
          style: const TextStyle(fontSize: 16),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: items.map((item) => _buildHistoryCard(item, isPaidTab)).toList(),
      ),
    );
  }

  Widget _buildHistoryCard(PaymentLinkItem item, bool isPaid) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
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
                    color: isPaid
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    isPaid ? Icons.check_circle : Icons.pending,
                    color: isPaid ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Amount row
            Row(
              children: [
                Text(
                  "£${item.amount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),

            // Payment Link Section (truncate + copy)
            _buildLinkSection(item.paymentUrl),
          ],
        ),
      ),
    );
  }

  /// Truncate the link, display half, and allow copy of full link.
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
              fontSize: 14,
              color: Colors.blueAccent,
              decoration: TextDecoration.underline,
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
}
