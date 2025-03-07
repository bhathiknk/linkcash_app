import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!showPaymentSection) ...[
              const Spacer(),
              Center(
                child: ElevatedButton(
                  onPressed: _scanQr,
                  child: const Text("Scan QR"),
                ),
              ),
              const Spacer(),
              if (message != null)
                Text(
                  message!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
            ] else ...[
              Text(
                "What's For: $requestWhatsFor",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                "Amount: £${requestAmount?.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initiatePayment,
                child: const Text("Pay"),
              ),
              if (message != null) ...[
                const SizedBox(height: 10),
                Text(
                  message!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ],
          ],
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

  /// Fetch QR request details
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
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'LinkCash Payments',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      setState(() {
        message = "Payment completed successfully!";
      });
    } on StripeException catch (e) {
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
