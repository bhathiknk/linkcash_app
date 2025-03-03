import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
// 1) Import mobile_scanner
import 'package:mobile_scanner/mobile_scanner.dart';
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
  bool showPaymentSection = false; // show the pay button & details after scanning

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // If we haven't scanned yet, show "Scan QR" button
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
              // We have scanned => show the request info + "Pay" button
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

  /// 1) Scan the QR code with camera
  Future<void> _scanQr() async {
    // Navigate to a separate scanner page that uses mobile_scanner
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const _MobileScannerPage()),
    );

    if (code != null && code.isNotEmpty) {
      setState(() {
        scannedCode = code;
      });
      // 2) Fetch request info from backend
      await _fetchRequestInfo(code);
    }
  }

  /// 2) GET /api/qr/info/{qrCode} => we get { amount, whatsFor, status }
  Future<void> _fetchRequestInfo(String code) async {
    final url = Uri.parse('$baseUrl/info/$code');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final amt = (data['amount'] as num).toDouble();
        final wf = data['whatsFor'].toString();
        setState(() {
          requestAmount = amt;
          requestWhatsFor = wf;
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

  /// 3) POST /api/qr/paybycode => returns clientSecret => show Payment Sheet
  Future<void> _initiatePayment() async {
    if (scannedCode == null) return;
    final url = Uri.parse('$baseUrl/paybycode');
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
          setState(() {
            message = "Payment initiated. Opening Payment Sheet...";
          });
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

  /// 4) Confirm Payment with Stripe Payment Sheet
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

// ============ A separate page for scanning the QR code ============
// 2) Using mobile_scanner v6.x
class _MobileScannerPage extends StatefulWidget {
  const _MobileScannerPage({Key? key}) : super(key: key);

  @override
  State<_MobileScannerPage> createState() => _MobileScannerPageState();
}

class _MobileScannerPageState extends State<_MobileScannerPage> {
  // Optionally control the scanner (e.g. toggle torch)
  final MobileScannerController _cameraController = MobileScannerController();

  bool _scannedAlready = false; // so we only pop once

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code"),
        actions: [
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _cameraController.switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // MobileScanner no longer has 'allowDuplicates' or 'onDetect' with two parameters
          MobileScanner(
            controller: _cameraController,
            // The new onDetect signature => onDetect: (BarcodeCapture capture)
            onDetect: (capture) {
              if (_scannedAlready) return;
              final barcodes = capture.barcodes;

              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code != null && code.isNotEmpty) {
                  _scannedAlready = true;
                  Navigator.pop(context, code);
                  break;
                }
              }
            },
          ),
          // Optionally, add an overlay or instructions
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black45,
              padding: const EdgeInsets.all(16),
              child: const Text(
                "Point the camera at a QR code",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
