import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  late CameraController _cameraController;
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _isProcessing = false;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  /// Initialize the camera with correct configurations
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21, // Ensures correct format
    );

    await _cameraController.initialize();
    if (mounted) {
      setState(() {});
    }
    _cameraController.startImageStream(_processCameraImage);
  }

  /// Process each camera frame to detect QR codes
  Future<void> _processCameraImage(CameraImage image) async {
    if (!_isScanning || _isProcessing) return;
    _isProcessing = true;

    try {
      final inputImage = _convertCameraImage(image);
      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        final String? code = barcodes.first.rawValue;

        if (code != null && code.isNotEmpty) {
          _isScanning = false;
          _cameraController.stopImageStream();
          await _barcodeScanner.close();

          // Show scanned data in a dialog
          _showScannedDataDialog(code);
        }
      }
    } catch (e) {
      debugPrint('Error scanning QR: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Show scanned QR code data in a dialog
  void _showScannedDataDialog(String scannedData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Scanned QR Code"),
          content: Text(scannedData, style: const TextStyle(fontSize: 18)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.pop(context, scannedData); // Return scanned data
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  /// Convert CameraImage to InputImage correctly
  InputImage _convertCameraImage(CameraImage image) {
    final WriteBuffer buffer = WriteBuffer();
    for (final Plane plane in image.planes) {
      buffer.putUint8List(plane.bytes);
    }
    final Uint8List bytes = buffer.done().buffer.asUint8List();

    final InputImageMetadata metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: InputImageRotation.rotation0deg,
      format: InputImageFormat.nv21, // Proper format for ML Kit
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
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
          if (_cameraController.value.isInitialized)
            CameraPreview(_cameraController)
          else
            const Center(child: CircularProgressIndicator()),
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
