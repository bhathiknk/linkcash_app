import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // For date/time formatting
import '../config.dart';

class LinkViewPage extends StatefulWidget {
  final int paymentDetailId;
  const LinkViewPage({super.key, required this.paymentDetailId});

  @override
  _LinkViewPageState createState() => _LinkViewPageState();
}

class _LinkViewPageState extends State<LinkViewPage> {
  Map<String, dynamic>? paymentData;
  String errorMessage = '';

  /// Helper to parse raw date/time strings into "yyyy-MM-dd HH:mm" format.
  String parseAndFormatDate(String? raw) {
    if (raw == null || raw == "N/A") return "N/A";
    try {
      final dt = DateTime.parse(raw);
      return DateFormat("yyyy-MM-dd HH:mm").format(dt);
    } catch (e) {
      // If parsing fails, just return the raw string
      return raw;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPaymentDetails();
  }

  /// Fetch payment details from server
  Future<void> fetchPaymentDetails() async {
    final String apiUrl =
        "$baseUrl/api/payment-details/view/${widget.paymentDetailId}";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          paymentData = jsonDecode(response.body);
        });
      } else {
        setState(() {
          errorMessage =
          "Failed to load payment details. (Status ${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error occurred: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // Light, banking-themed
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Transaction Details",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: paymentData != null
          ? _buildBodyContent()
          : Center(
        child: errorMessage.isNotEmpty
            ? Text(errorMessage, style: const TextStyle(color: Colors.red))
            : const CircularProgressIndicator(),
      ),
    );
  }

  /// The main layout: Payment Info + Payment URL + Transaction container
  /// all wrapped in a SingleChildScrollView to prevent overflow.
  Widget _buildBodyContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPaymentInfoSection(),
            const SizedBox(height: 16),
            _buildPaymentUrlSection(),
            const SizedBox(height: 16),
            _buildScrollableTransactionContainer(),
          ],
        ),
      ),
    );
  }

  /// Payment Info Section
  Widget _buildPaymentInfoSection() {
    final rawCreatedAt = paymentData!['createdAt'] as String?;
    final parsedCreatedAt = parseAndFormatDate(rawCreatedAt);

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Payment Info",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Title
            _buildLabeledRow(
              icon: Icons.label,
              label: "Title",
              value: paymentData!['title'] ?? "N/A",
            ),
            const Divider(height: 20, thickness: 0.8),

            // Description
            _buildLabeledRow(
              icon: Icons.description,
              label: "Description",
              value: paymentData!['description'] ?? "N/A",
            ),
            const Divider(height: 20, thickness: 0.8),

            // Amount
            _buildLabeledRow(
              icon: Icons.money,
              label: "Amount",
              value: "£${paymentData!['amount']}",
            ),
            const Divider(height: 20, thickness: 0.8),

            // Created At
            _buildLabeledRow(
              icon: Icons.calendar_month,
              label: "Created At",
              value: parsedCreatedAt,
            ),
            const Divider(height: 20, thickness: 0.8),

            // Expires
            _buildLabeledRow(
              icon: Icons.timer,
              label: "Expires",
              value: paymentData!['expireAfter'] ?? "N/A",
            ),
          ],
        ),
      ),
    );
  }

  /// Payment URL Section
  Widget _buildPaymentUrlSection() {
    String paymentUrl = paymentData!['paymentUrl'] ?? "N/A";

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Payment URL",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    paymentUrl,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.blueAccent),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: paymentUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Link copied to clipboard")),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The main container for transactions
  Widget _buildScrollableTransactionContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: [
            // Title "Transactions" in center
            const Text(
              "Transactions",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildTransactionsSectionInner(),
          ],
        ),
      ),
    );
  }

  /// The scrollable part inside the container
  Widget _buildTransactionsSectionInner() {
    final transactions = paymentData!['transactions'] as List<dynamic>;
    // We always keep the container 300px high, even if no transactions
    return SizedBox(
      height: 300,
      child: transactions.isEmpty
          ? const Center(
        child: Text(
          "No transactions found.",
          style: TextStyle(color: Colors.black54),
        ),
      )
          : _buildTransactionsList(transactions),
    );
  }

  /// The actual list of transactions
  Widget _buildTransactionsList(List<dynamic> transactions) {
    // Sort transactions by newest first
    final sortedTx = transactions.toList();
    sortedTx.sort((a, b) {
      final dateA = _tryParseDate(a['createdAt']);
      final dateB = _tryParseDate(b['createdAt']);
      return dateB.compareTo(dateA); // newest first
    });

    return ListView.builder(
      itemCount: sortedTx.length,
      itemBuilder: (context, index) {
        final txn = sortedTx[index];
        return _buildTransactionCard(txn);
      },
    );
  }

  /// Single transaction card
  Widget _buildTransactionCard(dynamic txn) {
    final rawDate = txn['createdAt'] as String?;
    final parsedDate = parseAndFormatDate(rawDate);
    final txnId = txn['stripeTransactionId'] ?? '';
    final amount = txn['amount'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                "Txn ID: $txnId",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.blueAccent),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: txnId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Txn ID copied")),
                );
              },
            ),
          ],
        ),
        subtitle: Text("Amount: £$amount | Date: $parsedDate"),
      ),
    );
  }

  /// A row with an icon, label, and value
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
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
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

  /// Parse date or fallback to epoch if fail
  DateTime _tryParseDate(String? raw) {
    if (raw == null) return DateTime.fromMillisecondsSinceEpoch(0);
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }
}
