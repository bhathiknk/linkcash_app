import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON encoding/decoding

import 'package:connectivity_plus/connectivity_plus.dart';
import '../ConnectionCheck/No_Internet_Ui.dart';
import '../ConnectionCheck/connectivity_service.dart';
import '../WidgetsCom/bottom_navigation_bar.dart';
import '../WidgetsCom/dark_mode_handler.dart';
import '../WidgetsCom/gradient_button_fb4.dart';
import 'Pay_Quick_Payment_History.dart';
import '../config.dart';

/// A simple model class to represent a payment link item.
class PaymentLinkItem {
  final String title;
  final String paymentUrl;
  final double amount;
  // The backend might also have "used" or "paid" property if you want to store it here.
  // final bool used; // (Optional) if you want to keep track of paid/unpaid in the model

  PaymentLinkItem({
    required this.title,
    required this.paymentUrl,
    required this.amount,
  });

  factory PaymentLinkItem.fromJson(Map<String, dynamic> json) {
    return PaymentLinkItem(
      title: json['title'],
      paymentUrl: json['paymentUrl'],
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

class PayQuickPage extends StatefulWidget {
  const PayQuickPage({super.key});

  @override
  _PayQuickPageState createState() => _PayQuickPageState();
}

class _PayQuickPageState extends State<PayQuickPage> {
  // Controllers for the input fields.
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  bool isConnected = true;
  bool _isLoading = false;
  String? paymentLink; // Latest created payment link.

  final ConnectivityService _connectivityService = ConnectivityService();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    // Listen to connectivity changes.
    _connectivityService.connectivityStream
        .listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results.first);
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult =
    await _connectivityService.checkInitialConnectivity();
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
    final String apiUrl = "$baseUrl/api/one-time-payments/create";
    final Map<String, dynamic> payload = {
      "userId": int.parse(userId),
      "title": title,
      "description": description,
      "amount": amount,
    };

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      setState(() => _isLoading = false);

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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create link: ${response.body}")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error occurred while creating link!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: DarkModeHandler.getBackgroundColor(),
      body: isConnected ? _buildMainContent() : const NoInternetUI(),
      bottomNavigationBar: _buildBottomNavigationBar(),
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
    return SingleChildScrollView(
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

          // Create Payment Link button
          _buildCreateLinkButton(context),

          // History button (navigate to Pay_Quick_Payment_History)
          const SizedBox(height: 20),
          Center(
            child: GradientButtonFb4(
              text: 'History',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PayQuickPaymentHistoryPage(),
                  ),
                );
              },
              backgroundColor: Colors.white,
              textColor: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  // Shows the newly created (or last created) link at top.
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
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : paymentLink == null
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
                const SnackBar(
                    content:
                    Text("Payment link copied to clipboard!")),
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
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
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
