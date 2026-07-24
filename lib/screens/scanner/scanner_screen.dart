import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as mobile_scanner;
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../providers/item_provider.dart';
import '../../models/item.dart';
import '../add_stock_screen.dart';
import 'scanner_controller.dart';
import 'scanner_widgets.dart';

class ScannerScreen extends StatefulWidget {
  final bool isFromAddStock;

  const ScannerScreen({
    super.key,
    this.isFromAddStock = false,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late final ScannerController _controller;
  String? _scannedBarcode;
  bool _showResult = false;
  bool _isChecking = false;
  bool _notFound = false;
  Item? _existingItem;
  final TextEditingController _quantityController = TextEditingController();
  late final TextEditingController _manualBarcodeController;

  @override
  void initState() {
    super.initState();
    _controller = ScannerController();
    _controller.initialize();
    _manualBarcodeController = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _quantityController.dispose();
    _manualBarcodeController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(String barcode) {
    setState(() {
      _scannedBarcode = barcode;
      _showResult = true;
      _notFound = false;
      _existingItem = null;
      _isChecking = false;
      _quantityController.clear();
    });
  }

  Future<void> _handleGalleryScanning() async {
    final (barcode, wasImageSelected) = await _controller.scanFromGallery();
    if (barcode != null) {
      _onBarcodeDetected(barcode);
    } else if (wasImageSelected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No barcode found in the selected image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _checkProduct() async {
    setState(() {
      _isChecking = true;
    });

    final itemProvider = Provider.of<ItemProvider>(context, listen: false);

    try {
      final item = await itemProvider.getItemByBarcode(_scannedBarcode!);

      if (mounted) {
        setState(() {
          _isChecking = false;
          _existingItem = item;
          _notFound = item == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _existingItem = null;
          _notFound = true;
        });
      }
    }
  }

  void _rescan() {
    _controller.dispose();
    setState(() {
      _showResult = false;
      _scannedBarcode = null;
      _notFound = false;
      _existingItem = null;
      _isChecking = false;
      _quantityController.clear();
    });
    _controller.initialize();
  }

  void _linkProduct() {
    if (widget.isFromAddStock) {
      Navigator.pop(context, _scannedBarcode);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddStockScreen(
            initialBarcode: _scannedBarcode,
          ),
        ),
      );
    }
  }

  void _addQuantity() {
    if (_quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a quantity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final int additionalQuantity = int.tryParse(_quantityController.text) ?? 0;
    if (additionalQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid quantity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Recording transaction...'),
              ],
            ),
          ),
        );
      },
    );
    
    // Record inbound transaction
    itemProvider.recordInboundTransaction(_existingItem!, additionalQuantity).then((_) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inbound transaction recorded for ${_existingItem!.name}'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Close the scanner screen
      Navigator.pop(context);
    }).catchError((error) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: const Color(0xFF00BBF9)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan Barcode',
          style: TextStyle(
            color: const Color(0xFF00BBF9),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _showResult ? _buildResultView() : _buildScannerView(),
      resizeToAvoidBottomInset: true,
    );
  }

  Widget _buildScannerView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter Barcode Manually',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _manualBarcodeController,
                          decoration: InputDecoration(
                            hintText: 'Enter barcode number',
                            hintStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(Icons.qr_code, color: Color(0xFF00BBF9)),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFF00BBF9), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            if (value.length >= 8) {
                              _onBarcodeDetected(value);
                            }
                          },
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              _onBarcodeDetected(value);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BBF9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00BBF9).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          if (_manualBarcodeController.text.isNotEmpty) {
                            _onBarcodeDetected(_manualBarcodeController.text);
                          }
                        },
                        icon: const Icon(Icons.search, color: Colors.white),
                        tooltip: 'Process barcode',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR Scan with Camera',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: MediaQuery.of(context).size.height * 0.38,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!, width: 1.5),
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18.5),
              child: Stack(
                children: [
                  mobile_scanner.MobileScanner(
                    controller: _controller.controller,
                    onDetect: (capture) {
                      final List<mobile_scanner.Barcode> barcodes =
                          capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null && !_showResult) {
                          _onBarcodeDetected(barcode.rawValue!);
                        }
                      }
                    },
                  ),
                  const ScannerFrame(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Place the barcode inside the frame',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[100]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ScannerControlButton(
                  icon: _controller.isTorchOn ? Icons.flash_off : Icons.flash_on,
                  label: _controller.isTorchOn ? 'Flash Off' : 'Flash On',
                  onTap: () {
                    setState(() {
                      _controller.toggleTorch();
                    });
                  },
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.grey.shade200,
                ),
                ScannerControlButton(
                  icon: _controller.isBackCamera
                      ? Icons.camera_front
                      : Icons.camera_rear,
                  label: _controller.isBackCamera ? 'Front' : 'Back',
                  onTap: () {
                    setState(() {
                      _controller.switchCamera();
                    });
                  },
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.grey.shade200,
                ),
                ScannerControlButton(
                  icon: Icons.image_outlined,
                  label: 'Gallery',
                  onTap: _handleGalleryScanning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + 16.0;

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Scanned Barcode',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00BBF9),
                ),
              ),
              const SizedBox(height: 32),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_scannedBarcode != null) ...[
                      BarcodeWidget(
                        barcode: Barcode.code128(),
                        data: _scannedBarcode!,
                        width: 240,
                        height: 80,
                        drawText: false,
                      ),
                      const SizedBox(height: 16),
                      SelectableText(
                        _scannedBarcode!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: const Color(0xFF00BBF9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_isChecking)
                const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(const Color(0xFF00BBF9)),
                  ),
                )
              else if (_existingItem != null)
                _buildProductFoundCard()
              else if (_notFound)
                _buildProductNotFoundCard(),
              const SizedBox(height: 32),
              if (_notFound) ...[
                ActionButton(
                  label: 'Link Product',
                  onPressed: _linkProduct,
                  isPrimary: true,
                ),
                const SizedBox(height: 16),
              ],
              if (_existingItem == null && !_isChecking && !_notFound) ...[
                ActionButton(
                  label: 'Check Product',
                  onPressed: _checkProduct,
                  isPrimary: true,
                ),
                const SizedBox(height: 16),
              ],
              ActionButton(
                label: 'Scan Another',
                onPressed: _rescan,
                isPrimary: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductFoundCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 32,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  _existingItem!.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00BBF9),
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Quantity',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '${_existingItem!.quantity} ${_existingItem!.unit}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF00BBF9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '\$${_existingItem!.price}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF00BBF9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Add Quantity',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixText: _existingItem!.unit,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _addQuantity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BBF9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductNotFoundCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: const [
          Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            'Barcode Scanner Success',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This barcode is unique and available to link to a new product.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
