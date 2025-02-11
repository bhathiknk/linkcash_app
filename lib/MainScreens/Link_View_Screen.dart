import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'dart:convert'; // For JSON encoding
import '../ConnectionCheck/connectivity_service.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/dark_mode_handler.dart';
import '../WidgetsCom/gradient_button_fb4.dart';

class LinkViewPage extends StatefulWidget {
  final int paymentDetailId; // Accepts paymentDetailId from navigation

  const LinkViewPage({super.key, required this.paymentDetailId});

  @override
  _LinkViewPageState createState() => _LinkViewPageState();
}

class _LinkViewPageState extends State<LinkViewPage> {
  final TextEditingController textEditingController = TextEditingController();
  bool isConnected = true;
  String? paymentLink; // Store the fetched payment link
  List<Map<String, dynamic>> transactionData =
      []; // Store fetched transaction data
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _fetchPaymentLink(); // Fetch the payment link on page load
    _fetchTransactions(); // Fetch transaction data on page load

    // Listen to connectivity changes
    _connectivityService.connectivityStream
        .listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results as ConnectivityResult);
    });
  }

  Future<void> _checkConnectivity() async {
    var connectivityResults =
        await _connectivityService.checkInitialConnectivity();
    _updateConnectionStatus(connectivityResults as ConnectivityResult);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      isConnected = result != ConnectivityResult.none;
    });
  }

  Future<void> _fetchPaymentLink() async {
    final String apiUrl =
        "http://10.0.2.2:8080/api/payment-links/url/${widget.paymentDetailId}";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          paymentLink =
              response.body; // The response is directly the payment URL
          textEditingController.text =
              paymentLink ?? ''; // Set the link in the text field
        });
      } else {
        print("Failed to fetch payment link: ${response.body}");
      }
    } catch (e) {
      print("Error occurred while fetching payment link: $e");
    }
  }

  Future<void> _fetchTransactions() async {
    final String apiUrl =
        "http://10.0.2.2:8080/api/payments/transactions/${widget.paymentDetailId}";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          transactionData =
              List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        print("Failed to fetch transactions: ${response.body}");
      }
    } catch (e) {
      print("Error occurred while fetching transactions: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: DarkModeHandler.getAppBarColor(),
        title: const Text(
          'Link View Page',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ),
      body: Container(
        color: DarkModeHandler.getBackgroundColor(),
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQrCodeSection(),
            _buildPaymentLinkSection(),
            _buildShareButton(),
            _buildPaddingBetweenSections(),
            _buildTransactionsHeader(),
            _buildTransactionsList(), // Show transaction list
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: 2,
        onTap: (index) {},
      ),
    );
  }

  Widget _buildQrCodeSection() {
    return Align(
      alignment: FractionalOffset.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Column(
          children: [
            Image.asset(
              'lib/images/qrcode.png',
              width: 220,
              height: 220,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentLinkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Text(
            "Payment Link",
            style: TextStyle(
              fontSize: 16,
              color: DarkModeHandler.getMainContainersTextColor(),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: DarkModeHandler.getMainContainersColor(),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: textEditingController,
                  decoration: InputDecoration(
                    hintText: paymentLink ??
                        'https://example.com/checkout?product=example_product&price=19.99&currency=USD',
                    hintStyle: TextStyle(
                      color: DarkModeHandler.getInputTextColor(),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 8.0),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy,
                    color: DarkModeHandler.getInputTextColor()),
                onPressed: () {
                  String text = textEditingController.text;
                  if (text.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied to clipboard'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildShareButton() {
    return Align(
      alignment: Alignment.center,
      child: GradientButtonFb4(
        text: 'Share Link',
        onPressed: () async {
          String link = textEditingController.text.trim();
          if (link.isNotEmpty) {
            await Share.share(link, subject: 'Share Link');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter a link to share'),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildPaddingBetweenSections() {
    return const SizedBox(height: 20);
  }

  Widget _buildTransactionsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            'Transactions',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 20,
              color: DarkModeHandler.getMainContainersTextColor(),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (transactionData.isEmpty) {
      return Center(
        child: Text(
          "No transactions found!",
          style: TextStyle(color: DarkModeHandler.getMainContainersTextColor()),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: transactionData.length,
        itemBuilder: (context, index) {
          final transaction = transactionData[index];
          return _buildTransactionCard(
            title: transaction['title'],
            transactionId: transaction['stripeTransactionId'],
            amount: transaction['amount'],
            createdAt: transaction['createdAt'],
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard({
    required String title,
    required String transactionId,
    required double amount,
    required String createdAt,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 0.0,
      color: Colors.white, // Explicitly set the card background color to white
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.green, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          Colors.black, // Set text color to black for contrast
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Transaction ID: $transactionId",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 5),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Amount: ",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: "£${amount.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green, // Amount value is green
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Date: $createdAt",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
