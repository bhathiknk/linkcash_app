import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:qr_flutter/qr_flutter.dart';
import '../config.dart';


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

  @override
  Widget build(BuildContext context) {
    // If showPopup is true, we block going back by overriding WillPopScope
    return WillPopScope(
      onWillPop: () async {
        // If the popup is open, we do not allow back
        return !showPopup;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Receive Payment'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // What's For
              TextField(
                controller: whatsForController,
                decoration: const InputDecoration(labelText: "What's For"),
              ),
              const SizedBox(height: 16),

              // Amount
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: "Amount (GBP)"),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // Create QR Code button
              ElevatedButton(
                onPressed: _createPaymentRequest,
                child: const Text("Create QR Code"),
              ),

              const SizedBox(height: 16),
              if (message != null) ...[
                Text(
                  message!,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],

              // If popup is open, show it as a full-screen Dialog
              if (showPopup && generatedQrCode != null)
                _buildQrCodeDialog(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createPaymentRequest() async {
    final url = Uri.parse('$baseUrl/request');
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
          showPopup = true; // show the popup
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

  // A "dialog" that covers the screen so user cannot go back unless they press "Close"
  Widget _buildQrCodeDialog() {
    return Container(
      // This container covers the entire screen
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "QR Code Generated",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Show the actual QR code
                QrImageView(
                  data: generatedQrCode!,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
                const SizedBox(height: 16),
                // "Close" button
                ElevatedButton(
                  onPressed: () {
                    // Reset everything
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
