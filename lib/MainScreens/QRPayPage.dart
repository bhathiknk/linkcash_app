import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';

class QRPayPage extends StatefulWidget {
  final int userId; // Current user's ID (assumed payer)

  const QRPayPage({Key? key, required this.userId}) : super(key: key);

  @override
  _QRPayPageState createState() => _QRPayPageState();
}

class _QRPayPageState extends State<QRPayPage> {
  String? qrCode;
  String? message;
  TextEditingController amountController = TextEditingController();
  TextEditingController whatsForController = TextEditingController();
  TextEditingController paymentRequestIdController = TextEditingController();

  // Replace with your backend base URL
  final String baseUrl = 'http://10.0.2.2:8080/api/qr';

  @override
  void initState() {
    super.initState();
    _generateQRCode();
  }

  /// 1) Generate or fetch the permanent QR code for the user
  Future<void> _generateQRCode() async {
    final url = Uri.parse('$baseUrl/generate');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": widget.userId}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        qrCode = data['qrCode'];
      });
    } else {
      setState(() {
        message = '❌ Error generating QR code: ${response.body}';
      });
    }
  }

  /// 2) Receiver creates a new payment request
  Future<void> _createPaymentRequest() async {
    final url = Uri.parse('$baseUrl/request');

    try {
      double amount = double.parse(amountController.text);
      if (amount <= 0) {
        setState(() {
          message = "⚠️ Please enter a valid amount.";
        });
        return;
      }

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "receiverUserId": widget.userId,
          "amount": amountController.text,
          "whatsFor": whatsForController.text
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          message = '✅ Payment request created. Request ID: ${data['qrPaymentRequestId']}';
        });
      } else {
        setState(() {
          message = '❌ Error creating payment request: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        message = '⚠️ Invalid amount entered.';
      });
    }
  }

  /// 3) Payer initiates a payment (creates PaymentIntent on the backend)
  Future<void> _initiatePayment() async {
    final url = Uri.parse('$baseUrl/pay');
    String paymentRequestIdText = paymentRequestIdController.text.trim();

    if (paymentRequestIdText.isEmpty) {
      setState(() {
        message = "⚠️ Please enter a valid Payment Request ID.";
      });
      return;
    }

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "payerUserId": widget.userId,
          "qrPaymentRequestId": int.parse(paymentRequestIdText),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final clientSecret = data['clientSecret'];

        setState(() {
          message = '✅ Payment initiated. Processing...';
        });

        // 4) Confirm the payment using Stripe Payment Sheet
        await _confirmPayment(clientSecret);
      } else {
        setState(() {
          message = '❌ Error initiating payment: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        message = '⚠️ Unexpected error: $e';
      });
    }
  }

  /// 4) Confirm the Payment using Stripe's Payment Sheet
  Future<void> _confirmPayment(String clientSecret) async {
    try {
      // Ensure Stripe is initialized before calling Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'LinkCash Payments',
        ),
      );

      // Present the Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // If successful, display success message
      setState(() {
        message = '✅ Payment completed successfully!';
      });
    } on StripeException catch (e) {
      setState(() {
        message = '❌ Payment failed: ${e.error.localizedMessage}';
      });
    } catch (e) {
      setState(() {
        message = '⚠️ Unexpected error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Pay'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Display user’s permanent QR code (for receiving)
              const Text(
                'Your Permanent QR Code:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              qrCode != null
                  ? SelectableText(qrCode!)
                  : const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Divider(),

              // Section for creating a Payment Request (Receive Payment)
              const Text(
                'Create Payment Request (Receive Payment):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount (GBP)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: whatsForController,
                decoration: const InputDecoration(labelText: 'What\'s For'),
              ),
              ElevatedButton(
                onPressed: _createPaymentRequest,
                child: const Text('Receive Payment'),
              ),
              const SizedBox(height: 20),
              const Divider(),

              // Section for Initiating Payment (Send Payment)
              const Text(
                'Initiate Payment (Send Payment):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: paymentRequestIdController,
                decoration: const InputDecoration(labelText: 'Payment Request ID'),
                keyboardType: TextInputType.number,
              ),
              ElevatedButton(
                onPressed: _initiatePayment,
                child: const Text('Send Payment'),
              ),
              const SizedBox(height: 20),

              // Display messages or errors
              if (message != null)
                Text(
                  message!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
