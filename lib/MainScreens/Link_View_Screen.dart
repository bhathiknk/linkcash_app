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

  const LinkViewPage({Key? key, required this.paymentDetailId}) : super(key: key);

  @override
  _LinkViewPageState createState() => _LinkViewPageState();
}

class _LinkViewPageState extends State<LinkViewPage> {
  final TextEditingController textEditingController = TextEditingController();
  bool isConnected = true;
  String? paymentLink; // Store the fetched payment link
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _fetchPaymentLink(); // Fetch the payment link on page load

    // Listen to connectivity changes
    _connectivityService.connectivityStream.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results as ConnectivityResult);
    });
  }

  // Checks the initial connectivity status
  Future<void> _checkConnectivity() async {
    var connectivityResults = await _connectivityService.checkInitialConnectivity();
    _updateConnectionStatus(connectivityResults as ConnectivityResult);
  }

  // Updates the connection status based on the result
  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      isConnected = result != ConnectivityResult.none;
    });
  }

  // Fetch the payment link using the paymentDetailId
  Future<void> _fetchPaymentLink() async {
    final String apiUrl = "http://10.0.2.2:8080/api/payment-links/url/${widget.paymentDetailId}";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          paymentLink = response.body; // The response is directly the payment URL
          textEditingController.text = paymentLink ?? ''; // Set the link in the text field
        });
      } else {
        print("Failed to fetch payment link: ${response.body}");
      }
    } catch (e) {
      print("Error occurred while fetching payment link: $e");
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
            _buildTransactionsList(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWithFab(
        currentIndex: 2,
        onTap: (index) {},
      ),
    );
  }

  /// Builds the section with the QR code image
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

  /// Builds the section with the payment link input and copy button
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
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy, color: DarkModeHandler.getInputTextColor()),
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

  // Builds the share link button using GradientButtonFb4
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

  /// Adds padding between the share button and transactions header
  Widget _buildPaddingBetweenSections() {
    return const SizedBox(height: 20);
  }

  /// Builds the header for the transactions section
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

  /// Builds the list of transaction containers
  Widget _buildTransactionsList() {
    return Expanded(
      child: Align(
        alignment: Alignment.center,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: DarkModeHandler.getBackgroundColor(),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                5, // Number of transactions to display
                    (index) => _buildTransactionItem(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a single transaction item
  Widget _buildTransactionItem() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: MediaQuery.of(context).size.width - 23,
          decoration: BoxDecoration(
            color: DarkModeHandler.getMainContainersColor(),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        "Payment Link Title",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: DarkModeHandler.getMainContainersTextColor(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                      child: Text(
                        "Bhathika",
                        style: TextStyle(
                          fontSize: 14,
                          color: DarkModeHandler.getMainContainersTextColor(),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "+ \$300",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DarkModeHandler.getMainContainersTextColor(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
