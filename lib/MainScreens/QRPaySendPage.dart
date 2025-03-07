import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'QRScannerPage.dart';
import '../config.dart';

class QRSendPayPage extends StatefulWidget {
  final int userId;

  const QRSendPayPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<QRSendPayPage> createState() => _QRSendPayPageState();
}

class _QRSendPayPageState extends State<QRSendPayPage> {
  String? scannedCode;
  String? message;
  double? requestAmount;
  String? requestWhatsFor;
  bool showPaymentSection = false;

  // Provided colors
  final Color primaryBlue = const Color(0xFF0054FF);
  final Color solidBackground = const Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: solidBackground,
      appBar: AppBar(
        title: const Text('Send Payment'),
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: solidBackground,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 32, 16, 16),
          // AnimatedSwitcher for attractive fade transition between scan and payment sections
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: showPaymentSection ? _buildPaymentSection() : _buildScanSection(),
          ),
        ),
      ),
    );
  }

  Widget _buildScanSection() {
    return Center(
      key: const ValueKey('scanSection'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Ready to make a payment?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              textStyle: const TextStyle(fontSize: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: _scanQr,
            child: const Text("Scan QR"),
          ),
          if (message != null) ...[
            const SizedBox(height: 20),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Center(
      key: const ValueKey('paymentSection'),
      child: Container(
        width: 350, // Fixed width for payment card
        child: Card(
          color: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Payment Details",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text("What's For: ",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Expanded(
                      child: Text(
                        requestWhatsFor ?? "",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text("Amount: ",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      "£${requestAmount?.toStringAsFixed(2) ?? '0.00'}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _initiatePayment,
                  child: const Text("Pay"),
                ),
                if (message != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Open camera, scan the QR => automatically fetch data
  Future<void> _scanQr() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerPage()),
    );

    if (code != null && code.isNotEmpty) {
      setState(() {
        scannedCode = code;
      });
      // Automatically fetch request info after scanning
      await _fetchRequestInfo(code);
    }
  }

  /// Fetch QR request details from backend
  Future<void> _fetchRequestInfo(String code) async {
    final url = Uri.parse('$baseUrl/api/qr/info/$code');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          requestAmount = (data['amount'] as num).toDouble();
          requestWhatsFor = data['whatsFor'].toString();
          showPaymentSection = true;
          message = null;
        });
      } else {
        setState(() {
          message = "Error fetching request info: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        message = "Error: $e";
      });
    }
  }

  /// Initiate Payment via Stripe using QR Code
  Future<void> _initiatePayment() async {
    if (scannedCode == null) return;
    final url = Uri.parse('$baseUrl/api/qr/paybycode');

    try {
      final body = jsonEncode({
        "payerUserId": widget.userId,
        "qrCode": scannedCode,
      });

      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data.containsKey("clientSecret")) {
          final clientSecret = data["clientSecret"];
          // Show Payment Sheet
          await _confirmPayment(clientSecret);
        } else {
          setState(() {
            message = "Unexpected response: $data";
          });
        }
      } else {
        setState(() {
          message = "Error initiating payment: ${resp.body}";
        });
      }
    } catch (e) {
      setState(() {
        message = "Error: $e";
      });
    }
  }

  /// Confirm Payment with Stripe Payment Sheet
  Future<void> _confirmPayment(String clientSecret) async {
    try {
      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'LinkCash Payments',
        ),
      );
      await stripe.Stripe.instance.presentPaymentSheet();
      setState(() {
        message = "Payment completed successfully!";
      });
    } on stripe.StripeException catch (e) {
      setState(() {
        message = "Payment failed: ${e.error.localizedMessage}";
      });
    } catch (e) {
      setState(() {
        message = "Unexpected error: $e";
      });
    }
  }
}
