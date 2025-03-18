import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config.dart';

class QRReceivePage extends StatefulWidget {
  final int userId;

  const QRReceivePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<QRReceivePage> createState() => _QRReceivePageState();
}

class _QRReceivePageState extends State<QRReceivePage> {
  final TextEditingController whatsForController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  String? message;
  String? generatedQrCode;
  bool showPopup = false;

  // Define UI Colors
  final Color primaryBlue = const Color(0xFF0054FF);
  final Color solidBackground = const Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !showPopup,
      child: Scaffold(
        backgroundColor: solidBackground,
        appBar: AppBar(
          title: const Text('Receive Payment'),
          backgroundColor: Colors.white,
          foregroundColor: primaryBlue,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // "What's For" text field with white background and rounded corners
              TextField(
                controller: whatsForController,
                decoration: InputDecoration(
                  labelText: "What's For",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // "Amount" text field with white background and rounded corners
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: "Amount (GBP)",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              // Create QR Code button styled in blue
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _createPaymentRequest,
                child: const Text("Create QR Code"),
              ),
              const SizedBox(height: 16),
              if (message != null)
                Text(
                  message!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              // QR Code dialog popup without a grey overlay background
              if (showPopup && generatedQrCode != null) _buildQrCodeDialog(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createPaymentRequest() async {
    final url = Uri.parse('$baseUrl/api/qr/request');
    final whatsFor = whatsForController.text.trim();
    final amountStr = amountController.text.trim();

    if (whatsFor.isEmpty || amountStr.isEmpty) {
      setState(() {
        message = "Please fill in both fields.";
      });
      return;
    }

    try {
      double amount = double.parse(amountStr);
      if (amount <= 0) {
        setState(() {
          message = "Amount must be greater than 0.";
        });
        return;
      }
      setState(() {
        message = null;
      });

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "receiverUserId": widget.userId,
          "amount": amountStr,
          "whatsFor": whatsFor,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final qrCode = data['qrCode'];
        setState(() {
          generatedQrCode = qrCode;
          showPopup = true; // Show the popup
        });
      } else {
        setState(() {
          message = "Error: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        message = "Invalid input: $e";
      });
    }
  }

  // Full-screen dialog displaying the generated QR Code with enhanced design,
  // but without the grey (black54) overlay background.
  Widget _buildQrCodeDialog() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryBlue.withOpacity(0.8),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Card(
          margin: EdgeInsets.zero,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "QR Code Generated",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 16),
                // QR code container with shadow for added depth
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: generatedQrCode!,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    // Reset everything when closing
                    setState(() {
                      showPopup = false;
                      generatedQrCode = null;
                      whatsForController.clear();
                      amountController.clear();
                      message = null;
                    });
                  },
                  child: const Text("Close"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
