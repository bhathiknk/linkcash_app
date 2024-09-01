import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_share/flutter_share.dart';

// Importing custom widgets
import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/dark_mode_handler.dart';
import '../WidgetsCom/gradient_button_fb4.dart';

class LinkViewPage extends StatefulWidget {
  const LinkViewPage({Key? key}) : super(key: key);

  @override
  _LinkViewPageState createState() => _LinkViewPageState();
}

class _LinkViewPageState extends State<LinkViewPage> {
  // Controller for the text field
  final TextEditingController textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // AppBar styling and title
        backgroundColor: DarkModeHandler.getAppBarColor(),
        title: const Text(
          'Link View Page',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        // Main background color and padding
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
      // Custom bottom navigation bar with floating action button
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
        // Label for the payment link input
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
        // Input field for the payment link with a copy button
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
                    hintText:
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
              // Copy button to copy the link to clipboard
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
        text: 'Share Link', // Text for the button
        onPressed: () async {
          String link = textEditingController.text.trim();
          if (link.isNotEmpty) {
            // Share the link using FlutterShare
            await FlutterShare.share(
              title: 'Share Link',
              text: link,
              linkUrl: link,
              chooserTitle: 'Share Link with',
            );
          } else {
            // Show a message if the link is empty
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
    return const SizedBox(height: 20); // Adjust the height as needed
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
                // Column for transaction title and description
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
                // Text showing the amount of the transaction
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
