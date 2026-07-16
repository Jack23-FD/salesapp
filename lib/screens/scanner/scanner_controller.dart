import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as mobile_scanner;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class ScannerController {
  late mobile_scanner.MobileScannerController _scannerController;
  final ImagePicker _imagePicker = ImagePicker();
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  bool _isTorchOn = false;
  bool _isBackCamera = true;

  bool get isTorchOn => _isTorchOn;
  bool get isBackCamera => _isBackCamera;

  void initialize() {
    _scannerController = mobile_scanner.MobileScannerController(
      facing: mobile_scanner.CameraFacing.back,
      torchEnabled: false,
    );
  }

  void dispose() {
    _scannerController.dispose();
    _barcodeScanner.close();
  }

  mobile_scanner.MobileScannerController get controller => _scannerController;

  void toggleTorch() {
    _isTorchOn = !_isTorchOn;
    _scannerController.toggleTorch();
  }

  void switchCamera() {
    _isBackCamera = !_isBackCamera;
    _scannerController.switchCamera();
  }

  Future<(String?, bool)> scanFromGallery() async {
    try {
      // Request permission for Android 13 and above
      if (Platform.isAndroid) {
        final status = await Permission.photos.request();
        if (status.isDenied) {
          return (null, false);
        }
        if (status.isPermanentlyDenied) {
          debugPrint('Photos permission permanently denied');
          return (null, false);
        }
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Reduce image quality to improve processing speed
      );

      if (image == null) return (null, false); // User cancelled

      final inputImage = InputImage.fromFile(File(image.path));
      final List<Barcode> barcodes =
          await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
        return (barcodes.first.rawValue, true);
      }
      return (null, true); // Image selected but no barcode found
    } catch (e) {
      debugPrint('Error scanning from gallery: $e');
      return (null, true); // Error occurred while processing
    }
  }
}
