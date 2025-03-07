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
  CameraController? _cameraController;
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

    try {
      await _cameraController!.initialize();
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }

    if (mounted) {
      setState(() {});
    }
    _cameraController?.startImageStream(_processCameraImage);
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
          // Ensure the camera is still initialized before stopping the stream
          if (mounted && _cameraController != null && _cameraController!.value.isInitialized) {
            await _cameraController!.stopImageStream();
          }
          await _barcodeScanner.close();

          // Optional short delay for smoother transition
          await Future.delayed(const Duration(milliseconds: 300));
          // Directly return the scanned code without a popup
          Navigator.pop(context, code);
        }
      }
    } catch (e) {
      debugPrint("Error scanning QR: $e");
    } finally {
      _isProcessing = false;
    }
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
    _cameraController?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: _cameraController != null && _cameraController!.value.isInitialized
          ? Stack(
        children: [
          CameraPreview(_cameraController!),
          // Overlay for a scanning box
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white70, width: 3),
                borderRadius: BorderRadius.circular(12),
                color: Colors.black26,
              ),
            ),
          ),
          // Bottom instructions
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Align QR code within the box",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
