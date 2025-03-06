import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../config.dart'; // Adjust if needed

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
              // If we have NOT scanned a QR code yet:
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
              // If we HAVE scanned a code and fetched request info:
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

  /// 1) Open camera, scan the QR => returns 'code'
  Future<void> _scanQr() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerPage()),
    );

    // If user scanned a valid QR
    if (code != null && code.isNotEmpty) {
      setState(() {
        scannedCode = code;
      });
      // 2) Fetch request info from backend (e.g. 'whatsFor', 'amount')
      await _fetchRequestInfo(code);
    }
  }

  /// 2) GET /api/qr/info/{qrCode}
  Future<void> _fetchRequestInfo(String code) async {
    final url = Uri.parse('$baseUrl/api/qr/info/$code');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          requestAmount = (data['amount'] as num).toDouble();
          requestWhatsFor = data['whatsFor'].toString();
          showPaymentSection = true; // Show the pay button & info
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

  /// 3) POST /api/qr/paybycode => returns clientSecret => Stripe PaymentSheet
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
          // 4) Show Payment Sheet
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

  /// 4) Present Payment Sheet with the returned clientSecret
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

// =================== QR SCANNER PAGE WITH UI ENHANCEMENTS ===================
class QRScannerPage extends StatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
  }

  /// Initialize the back camera
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController.initialize();
    _cameraController.startImageStream(_processCameraImage);
  }

  /// Process each camera frame with Google ML Kit
  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.yuv420,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: metadata,
      );

      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        // We only care about the first barcode
        final String code = barcodes.first.rawValue ?? 'Unknown';
        // Stop scanning
        _cameraController.stopImageStream();
        _barcodeScanner.close();

        // Return the scanned code to the previous page
        Navigator.pop(context, code);
      }
    } catch (e) {
      debugPrint('Error scanning QR: $e');
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              return snapshot.connectionState == ConnectionState.done
                  ? CameraPreview(_cameraController)
                  : const Center(child: CircularProgressIndicator());
            },
          ),
          // Overlay with Square for QR Code alignment
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 4),
              ),
            ),
          ),
          // Instruction text at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(16),
              child: const Text(
                "Align QR code within the square",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
