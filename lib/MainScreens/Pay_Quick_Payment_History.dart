import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'Pay_Quick_Page.dart'; // Contains PaymentLinkItem model and fromJson constructor

// New model to parse full payment details response from backend.
class PaymentLinkFullDetails {
  final String title;
  final String description;
  final double amount;
  final String paymentUrl;
  final String usedAt;
  final String stripeTransactionId;

  PaymentLinkFullDetails({
    required this.title,
    required this.description,
    required this.amount,
    required this.paymentUrl,
    required this.usedAt,
    required this.stripeTransactionId,
  });

  factory PaymentLinkFullDetails.fromJson(Map<String, dynamic> json) {
    return PaymentLinkFullDetails(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] is int)
          ? (json['amount'] as int).toDouble()
          : json['amount']?.toDouble() ?? 0.0,
      paymentUrl: json['paymentUrl'] ?? '',
      usedAt: json['usedAt'] != null ? json['usedAt'].toString() : '',
      stripeTransactionId: json['stripeTransactionId'] ?? '',
    );
  }
}

class PayQuickPaymentHistoryPage extends StatefulWidget {
  const PayQuickPaymentHistoryPage({super.key});

  @override
  _PayQuickPaymentHistoryPageState createState() =>
      _PayQuickPaymentHistoryPageState();
}

class _PayQuickPaymentHistoryPageState extends State<PayQuickPaymentHistoryPage>
    with SingleTickerProviderStateMixin {
  // Secure storage for reading the user ID
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isLoading = true;
  late TabController _tabController;

  List<PaymentLinkItem> _paidItems = [];
  List<PaymentLinkItem> _unpaidItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Fetch both unpaid and paid items from your backend, passing userId.
    _fetchPayQuickHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Fetch data for both unpaid and paid items, passing userId to /list.
  Future<void> _fetchPayQuickHistory() async {
    try {
      // 1) Read userId from secure storage
      final userId = await _secureStorage.read(key: 'User_ID');
      if (userId == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No user ID found. Please log in.")),
        );
        return;
      }

      // 2) Build URIs with userId + used flags
      final unpaidUri = Uri.parse(
          "http://10.0.2.2:8080/api/one-time-payment-links/list?used=false&userId=$userId");
      final paidUri = Uri.parse(
          "http://10.0.2.2:8080/api/one-time-payment-links/list?used=true&userId=$userId");

      // 3) Fetch both unpaid & paid
      final responseUnpaid = await http.get(unpaidUri);
      final responsePaid = await http.get(paidUri);

      if (responseUnpaid.statusCode == 200 && responsePaid.statusCode == 200) {
        final dataUnpaid = jsonDecode(responseUnpaid.body) as List<dynamic>;
        final dataPaid = jsonDecode(responsePaid.body) as List<dynamic>;

        List<PaymentLinkItem> unpaidList =
        dataUnpaid.map((item) => PaymentLinkItem.fromJson(item)).toList();
        List<PaymentLinkItem> paidList =
        dataPaid.map((item) => PaymentLinkItem.fromJson(item)).toList();

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
              Tab(text: "Paid"),
              Tab(text: "Unpaid"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          controller: _tabController,
          children: [
            _buildTabContent(_paidItems, isPaidTab: true),
            _buildTabContent(_unpaidItems, isPaidTab: false),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(List<PaymentLinkItem> items,
      {required bool isPaidTab}) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          isPaidTab ? "No paid links found." : "No unpaid links found.",
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
    Widget card = Card(
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

    // For PAID items, wrap the card in an InkWell to detect taps.
    if (isPaid) {
      return InkWell(
        onTap: () async {
          // Extract the linkId from the paymentUrl.
          String linkId = _extractLinkId(item.paymentUrl);
          // Fetch full details from backend.
          PaymentLinkFullDetails? details = await _fetchFullPaymentDetails(linkId);
          if (details != null) {
            _showFullDetailsPopup(details);
          }
        },
        child: card,
      );
    } else {
      return card;
    }
  }

  /// Truncate the link, display half, and allow copy of full link.
  Widget _buildLinkSection(String paymentUrl) {
    if (paymentUrl.isEmpty) {
      return const Text(
        "No Payment Link Available",
        style: TextStyle(fontSize: 14, color: Colors.grey),
      );
    }
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

  /// Extract the linkId from the paymentUrl.
  String _extractLinkId(String paymentUrl) {
    try {
      Uri uri = Uri.parse(paymentUrl);
      List<String> segments = uri.pathSegments;
      return segments.isNotEmpty ? segments.last : "";
    } catch (e) {
      return "";
    }
  }

  /// Fetch full payment details for a given linkId.
  Future<PaymentLinkFullDetails?> _fetchFullPaymentDetails(String linkId) async {
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/one-time-payment-links/details/$linkId"),
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return PaymentLinkFullDetails.fromJson(jsonData);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch details. Status code: ${response.statusCode}")),
        );
        return null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
      return null;
    }
  }

  /// Show a popup dialog with full payment details styled as a professional legal document.
  void _showFullDetailsPopup(PaymentLinkFullDetails details) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.90,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      "Payment Details",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Body Section
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDocumentRow(Icons.title, "Title", details.title),
                          const Divider(color: Colors.grey, height: 16),
                          _buildDocumentRow(Icons.description, "Description", details.description),
                          const Divider(color: Colors.grey, height: 16),
                          _buildDocumentRow(Icons.money, "Amount", "£${details.amount.toStringAsFixed(2)}"),
                          const Divider(color: Colors.grey, height: 16),
                          _buildDocumentRow(Icons.link, "Payment URL", details.paymentUrl),
                          const Divider(color: Colors.grey, height: 16),
                          _buildDocumentRow(Icons.date_range, "Used At", details.usedAt.isNotEmpty ? details.usedAt : "N/A"),
                          const Divider(color: Colors.grey, height: 16),
                          _buildDocumentRow(Icons.receipt, "Transaction ID",
                              details.stripeTransactionId.isNotEmpty ? details.stripeTransactionId : "N/A"),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Footer Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _printDocument(details);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      ),
                      icon: const Icon(Icons.print),
                      label: const Text(
                        "Print",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      ),
                      child: const Text(
                        "Close",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build rows for the document-style popup with underline separation.
  Widget _buildDocumentRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.blue.shade700,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Function to handle printing the document
  void _printDocument(PaymentLinkFullDetails details) {
    // Placeholder for the print functionality
    debugPrint("Printing document for: ${details.title}");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Print functionality coming soon!")),
    );
  }
}
