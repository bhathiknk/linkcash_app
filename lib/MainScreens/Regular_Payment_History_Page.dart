import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Link_View_Screen.dart';

// Model class that mirrors the PaymentDetails structure
class PaymentDetailsItem {
  final int paymentDetailId;
  final int paymentDetailUserId;
  final String title;
  final String description;
  final double amount;
  final String expireAfter;

  PaymentDetailsItem({
    required this.paymentDetailId,
    required this.paymentDetailUserId,
    required this.title,
    required this.description,
    required this.amount,
    required this.expireAfter,
  });

  factory PaymentDetailsItem.fromJson(Map<String, dynamic> json) {
    return PaymentDetailsItem(
      paymentDetailId: json['paymentDetailId'] as int,
      paymentDetailUserId: json['paymentDetailUserId'] as int,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      expireAfter: json['expireAfter'] ?? 'Unlimited',
    );
  }
}

class RegularPaymentHistoryPage extends StatefulWidget {
  const RegularPaymentHistoryPage({Key? key}) : super(key: key);

  @override
  _RegularPaymentHistoryPageState createState() =>
      _RegularPaymentHistoryPageState();
}

class _RegularPaymentHistoryPageState extends State<RegularPaymentHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Separate lists for each expireAfter type
  List<PaymentDetailsItem> _unlimitedItems = [];
  List<PaymentDetailsItem> _oneWeekItems = [];
  List<PaymentDetailsItem> _oneDayItems = [];
  List<PaymentDetailsItem> _oneHourItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchAllExpireTypes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Main function to fetch each expire type in parallel
  Future<void> _fetchAllExpireTypes() async {
    try {
      final userId = await _secureStorage.read(key: 'User_ID');
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Error: User is not logged in.';
        });
        return;
      }

      // Fetch each type
      await Future.wait([
        _fetchExpireTypeData('Unlimited', userId),
        _fetchExpireTypeData('One Week', userId),
        _fetchExpireTypeData('One Day', userId),
        _fetchExpireTypeData('One Hour', userId),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  // Generic method to fetch data for a specific expireType
  Future<void> _fetchExpireTypeData(String expireType, String userId) async {
    final encodedExpireType = Uri.encodeComponent(expireType);
    final url =
        "http://10.0.2.2:8080/api/payment-details/user/$userId/expire-type/$encodedExpireType";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      final items =
      data.map((item) => PaymentDetailsItem.fromJson(item)).toList();

      setState(() {
        switch (expireType) {
          case 'Unlimited':
            _unlimitedItems = items;
            break;
          case 'One Week':
            _oneWeekItems = items;
            break;
          case 'One Day':
            _oneDayItems = items;
            break;
          case 'One Hour':
            _oneHourItems = items;
            break;
        }
      });
    } else {
      // If one call fails, we can set an error, but we can still display partial data for other tabs
      setState(() {
        _hasError = true;
        _errorMessage =
        "Failed to load data for $expireType: ${response.statusCode}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Regular Payment History"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: "Unlimited"),
            Tab(text: "One Week"),
            Tab(text: "One Day"),
            Tab(text: "One Hour"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? _buildErrorWidget()
          : TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent(_unlimitedItems, "Unlimited"),
          _buildTabContent(_oneWeekItems, "One Week"),
          _buildTabContent(_oneDayItems, "One Day"),
          _buildTabContent(_oneHourItems, "One Hour"),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Text(
        _errorMessage,
        style: const TextStyle(fontSize: 16, color: Colors.red),
      ),
    );
  }

  // Display a list of PaymentDetailsItem in a ListView
  Widget _buildTabContent(List<PaymentDetailsItem> items, String expireType) {
    if (items.isEmpty) {
      return Center(
        child: Text("No records found for $expireType"),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildHistoryCard(item);
      },
    );
  }

  Widget _buildHistoryCard(PaymentDetailsItem item) {
    return GestureDetector(
      onTap: () {
        // Navigate to LinkViewPage when a card is clicked
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                LinkViewPage(paymentDetailId: item.paymentDetailId),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  )),
              const SizedBox(height: 4),
              if (item.description.isNotEmpty)
                Text(item.description,
                    style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text("Amount: ",
                      style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text("£${item.amount.toStringAsFixed(2)}",
                      style:
                      const TextStyle(fontSize: 14, color: Colors.black87)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text("Expire After: ",
                      style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(item.expireAfter,
                      style:
                      const TextStyle(fontSize: 14, color: Colors.black87)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
