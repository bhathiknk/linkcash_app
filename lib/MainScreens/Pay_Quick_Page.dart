import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON encoding/decoding

import '../ConnectionCheck/No_Internet_Ui.dart';
import '../ConnectionCheck/connectivity_service.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/dark_mode_handler.dart';
import '../WidgetsCom/gradient_button_fb4.dart';

// A simple model class to represent a payment link item.
class PaymentLinkItem {
  final String title;
  final String paymentUrl;
  final double amount;

  PaymentLinkItem({required this.title, required this.paymentUrl, required this.amount});

  factory PaymentLinkItem.fromJson(Map<String, dynamic> json) {
    return PaymentLinkItem(
      title: json['title'],
      paymentUrl: json['paymentUrl'],
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

class PayQuickPage extends StatefulWidget {
  const PayQuickPage({Key? key}) : super(key: key);

  @override
  _PayQuickPageState createState() => _PayQuickPageState();
}

class _PayQuickPageState extends State<PayQuickPage> {
  // Controllers for the input fields.
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  // Scroll controller to detect scroll changes.
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  bool isConnected = true;
  String? paymentLink; // Latest created payment link.

  // For filtering the list: false = Unpaid, true = Paid.
  bool filterPaid = false;
  List<PaymentLinkItem> paymentLinkItems = [];

  final ConnectivityService _connectivityService = ConnectivityService();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivityService.connectivityStream.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results.first);
    });
    // Initially fetch list for default filter (Unpaid).
    fetchPaymentLinkList();

    // Listen to scroll changes.
    _scrollController.addListener(() {
      // Debug print to check offset:
      // print("Scroll offset: ${_scrollController.offset}");
      if (_scrollController.offset > 300 && !_showScrollToTop) {
        setState(() {
          _showScrollToTop = true;
        });
      } else if (_scrollController.offset <= 300 && _showScrollToTop) {
        setState(() {
          _showScrollToTop = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await _connectivityService.checkInitialConnectivity();
    _updateConnectionStatus(connectivityResult as ConnectivityResult);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      isConnected = result != ConnectivityResult.none;
    });
  }

  // Create the payment link by calling the backend API.
  Future<void> _createPaymentLink(BuildContext context) async {
    final String title = titleController.text.trim();
    final String description = descriptionController.text.trim();
    final String amountText = amountController.text.trim();

    if (title.isEmpty || description.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    String? userId = await secureStorage.read(key: 'User_ID');
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: User is not logged in!")),
      );
      return;
    }

    double amount = double.tryParse(amountText) ?? 0.0;
    final String apiUrl = "http://10.0.2.2:8080/api/one-time-payments/create";
    final Map<String, dynamic> payload = {
      "userId": int.parse(userId),
      "title": title,
      "description": description,
      "amount": amount,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        setState(() {
          paymentLink = responseData['paymentUrl'];
          titleController.clear();
          descriptionController.clear();
          amountController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment Link created successfully!")),
        );
        fetchPaymentLinkList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create link: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error occurred while creating link!")),
      );
    }
  }

  // Fetch the list of payment links filtered by paid/unpaid.
  Future<void> fetchPaymentLinkList() async {
    final String apiUrl =
        "http://10.0.2.2:8080/api/one-time-payment-links/list?used=$filterPaid";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<PaymentLinkItem> items =
        data.map((json) => PaymentLinkItem.fromJson(json)).toList();
        setState(() {
          paymentLinkItems = items;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch link list: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error occurred while fetching link list!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: DarkModeHandler.getBackgroundColor(),
      body: isConnected ? _buildMainContent() : NoInternetUI(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton(
        onPressed: () {
          _scrollController.animateTo(0.0,
              duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
        },
        child: const Icon(Icons.arrow_upward, color: Colors.black),
        backgroundColor: const Color(0xFF83B6B9),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      resizeToAvoidBottomInset: true,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: DarkModeHandler.getAppBarColor(),
      title: const Text(
        "Pay Quick",
        style: TextStyle(fontSize: 20, color: Colors.black),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      color: DarkModeHandler.getBackgroundColor(),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOneTimeLinkSection(),
              const SizedBox(height: 15),
              _buildLabel("Enter Title"),
              _buildTextField(
                controller: titleController,
                hint: 'Enter title...',
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 15),
              _buildLabel("Enter Description"),
              _buildTextField(
                controller: descriptionController,
                hint: 'Enter description...',
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 15),
              _buildLabel("Enter Amount"),
              _buildTextField(
                controller: amountController,
                hint: 'Enter amount...',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _buildCreateLinkButton(context),
              const SizedBox(height: 20),
              _buildPaymentListSection(),
            ],
          ),
        ),
      ),
    );
  }

  // Top white section always visible.
  Widget _buildOneTimeLinkSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: paymentLink == null
          ? const Text(
        "Your one-time payment link will appear here after creation.",
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
        textAlign: TextAlign.center,
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "One-time Link:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DarkModeHandler.getMainContainersTextColor(),
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(
            paymentLink!,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: paymentLink!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Payment link copied to clipboard!")),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text("Copy Link"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Enhanced Payment List Section with a clean, professional look.
  /// This section uses only three colours:
  /// - Color(0xFF83B6B9) (accent)
  /// - Color(0xFFE3F2FD) (light blue)
  /// - Colors.white
  Widget _buildPaymentListSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Light blue background.
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title and filter toggles.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF83B6B9), // Primary accent.
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Payment Links",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text("Unpaid"),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: filterPaid == false ? const Color(0xFF83B6B9) : const Color(0xFF83B6B9).withOpacity(0.6),
                      ),
                      selected: filterPaid == false,
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFFE3F2FD),
                      onSelected: (bool selected) {
                        setState(() {
                          filterPaid = false;
                        });
                        fetchPaymentLinkList();
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text("Paid"),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: filterPaid == true ? const Color(0xFF83B6B9) : const Color(0xFF83B6B9).withOpacity(0.6),
                      ),
                      selected: filterPaid == true,
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFFE3F2FD),
                      onSelected: (bool selected) {
                        setState(() {
                          filterPaid = true;
                        });
                        fetchPaymentLinkList();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          // Divider (using the light blue color)
          Container(height: 1, color: const Color(0xFFE3F2FD)),
          const SizedBox(height: 15),
          // List of payment link items.
          paymentLinkItems.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                "No links found for the selected filter.",
                style: const TextStyle(
                  color: Color(0xFF83B6B9),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: paymentLinkItems.length,
            itemBuilder: (context, index) {
              final item = paymentLinkItems[index];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE3F2FD), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      item.paymentUrl,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0054FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Amount: \$${item.amount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF83B6B9),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: item.paymentUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Link copied!")),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16, color: Colors.black),
                        label: const Text("Copy"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE3F2FD),
                          foregroundColor: const Color(0xFF83B6B9),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: DarkModeHandler.getMainContainersTextColor(),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: _inputBoxDecoration(),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: DarkModeHandler.getInputTypeTextColor()),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color:Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        ),
      ),
    );
  }

  BoxDecoration _inputBoxDecoration() {
    return BoxDecoration(
      color: DarkModeHandler.getMainContainersColor(),
      borderRadius: BorderRadius.circular(10.0),
    );
  }

  Widget _buildCreateLinkButton(BuildContext context) {
    return Center(
      child: GradientButtonFb4(
        text: 'Create Payment Link',
        onPressed: () => _createPaymentLink(context),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBarWithFab(
      currentIndex: 0,
      onTap: (index) {
        // Handle navigation if needed.
      },
    );
  }
}
