import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/item_provider.dart';
import '../models/item.dart';
import '../providers/category_provider.dart';
import '../utils/debouncer.dart';
import 'invoice_screen.dart';
import '../models/outbound_models.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../utils/translation_utils.dart';
import '../services/localization_service.dart';
import 'package:flutter/services.dart';
import '../utils/receipt_printer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class UseStockScreen extends StatefulWidget {
  const UseStockScreen({super.key});

  @override
  State<UseStockScreen> createState() => _UseStockScreenState();
}

class _UseStockScreenState extends State<UseStockScreen> {
  MobileScannerController? _scannerController;
  Map<String, OutboundItem> _outboundItems = {};
  // Controller for manual barcode input
  final TextEditingController _barcodeController = TextEditingController();
  // Controllers for payment
  final TextEditingController _amountReceivedController = TextEditingController();
  // Debouncer for barcode input to handle external scanners
  final Debouncer _barcodeDebouncer = Debouncer(delay: const Duration(milliseconds: 500));
  
  double _subtotal = 0.0;
  double _total = 0.0;
  double _change = 0.0;
  bool _showBillSummary = false;

  @override
  void initState() {
    super.initState();
    _loadProviders();
    _initializeScanner();
    
    // Listen for changes to barcode input field
    _barcodeController.addListener(_onBarcodeInputChanged);
    // Listen for changes to amount received field
    _amountReceivedController.addListener(_calculateChange);
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _barcodeController.removeListener(_onBarcodeInputChanged);
    _barcodeController.dispose();
    _amountReceivedController.removeListener(_calculateChange);
    _amountReceivedController.dispose();
    super.dispose();
  }

  void _onBarcodeInputChanged() {
    // Get current input
    final barcode = _barcodeController.text.trim();
    
    // Only process if barcode is reasonably long (most barcodes are at least 8 chars)
    if (barcode.length >= 8) {
      // Process after debounce to allow for complete external scanner input
      _barcodeDebouncer.call(() {
        _checkAndAddItem(barcode);
        _barcodeController.clear();
      });
    }
  }

  void _loadProviders() {
    //Initialize providers
    Provider.of<ItemProvider>(context, listen: false);
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [BarcodeFormat.all],
      returnImage: false,
    );
  }

  void _checkAndAddItem(String barcode) async {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    // find the item by barcode (using existing getItemsByBarcode method)
    final items = await itemProvider.getItemsByBarcode(barcode);

    if (items.isNotEmpty) {
      _showQuantityDialog(items.first);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService.translate("item_not_found"),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue == null) {
        debugPrint('Failed to scan Barcode');
      } else {
        // Process the barcode
        _checkAndAddItem(barcode.rawValue!);
      }
    }
  }

  Future<void> _showQuantityDialog(Item item) async {
    if (!mounted) return;

    final TextEditingController quantityController =
        TextEditingController(text: '1');
    final int maxQuantity = item.quantity.toInt();

    final int? quantity = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                    // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                      'useStockScreen.quantity'.tr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF8A00),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Item: ${item.name}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                Text(
                          '${'useStockScreen.available'.tr} ${item.quantity} ${item.unit}',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                  ),
                        ),
                        Text(
                          'Price: ${item.price.toStringAsFixed(2)} €',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                ),
                const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: quantityController,
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              labelStyle: const TextStyle(color: const Color(0xFFFF8A00)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: const Color(0xFFFF8A00)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: const Color(0xFFFF8A00), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 16),
                            ),
                            keyboardType: TextInputType.number,
                            autofocus: true,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18),
                            onChanged: (value) {
                              // Validate input is a number
                              if (value.isNotEmpty && int.tryParse(value) == null) {
                                quantityController.text = '1';
                                quantityController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: quantityController.text.length)
                                );
                              }
                              // Force rebuild of ValueListenableBuilder
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Show unit price and total
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'MRP:',
                                style: GoogleFonts.urbanist(
                                  fontSize: 15,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                '${item.price.toStringAsFixed(2)} €',
                                style: GoogleFonts.urbanist(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFF8A00),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total:',
                                style: GoogleFonts.urbanist(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                '${(item.price * (int.tryParse(quantityController.text) ?? 1)).toStringAsFixed(2)} €',
                                style: GoogleFonts.urbanist(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFF8A00),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFF8A00),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                          child: Text(
                            'useStockScreen.cancel'.tr,
                            style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        int? quantity = int.tryParse(quantityController.text);
                        if (quantity != null &&
                            quantity > 0 &&
                            quantity <= maxQuantity) {
                          Navigator.pop(context, quantity);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                quantity == null || quantity <= 0
                                        ? 'useStockScreen.enterValidQuantity'.tr
                                        : 'useStockScreen.quantityExceedsStock'.tr,
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                          child: Text(
                            'useStockScreen.confirm'.tr,
                            style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
            );
          },
        );
      },
    );

    if (quantity != null && quantity > 0) {
      _addOutboundItem(item, quantity);
    }
  }

  void _addOutboundItem(Item item, int quantity) {
    // Validate quantity against stock
    if (quantity > item.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('useStockScreen.cannotExceedStock'.tr),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      final existingItem = _outboundItems[item.id];

      if (existingItem != null) {
        // Update existing item
        final newTotal = existingItem.quantity + quantity;
        
        if (newTotal <= item.quantity) {
          existingItem.quantity = newTotal;
          // Show confirmation of update
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} quantity updated to ${existingItem.quantity}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('useStockScreen.cannotExceedStockFor'.tr.replaceAll('{item}', item.name)),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Add new item
        _outboundItems[item.id] = OutboundItem(item: item, quantity: quantity);
        
        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} added to outbound'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      
      // Recalculate totals
      _calculateTotals();
    });
  }

  void _updateItemQuantity(OutboundItem outboundItem, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        // Remove item if quantity becomes zero or negative
        _outboundItems.remove(outboundItem.item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${outboundItem.item.name} removed from outbound'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 1),
          ),
        );
      } else if (newQuantity <= outboundItem.item.quantity) {
        // Only allow if new quantity is within available stock
        outboundItem.quantity = newQuantity;
        // Show a subtle confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${outboundItem.item.name} quantity updated to $newQuantity'),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 800),
          ),
        );
      } else {
        // Show error if exceeds available stock
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('useStockScreen.cannotExceedStock'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      // Recalculate totals
      _calculateTotals();
    });
  }

  void _removeItem(String itemId) {
    setState(() {
      _outboundItems.remove(itemId);
      _calculateTotals();
    });
  }
  
  void _calculateTotals() {
    double subtotal = 0.0;
    
    for (var item in _outboundItems.values) {
      subtotal += item.item.price * item.quantity;
    }
    
    setState(() {
      _subtotal = subtotal;
      _total = subtotal; // For now, total equals subtotal (no tax, etc.)
    });
  }

  void _calculateChange() {
    if (_amountReceivedController.text.isEmpty) {
      setState(() {
        _change = 0.0;
      });
      return;
    }
    
    try {
      final amountReceived = double.parse(_amountReceivedController.text);
      setState(() {
        _change = amountReceived - _total;
      });
    } catch (e) {
      setState(() {
        _change = 0.0;
      });
    }
  }

  Future<void> _processOutbound() async {
    if (_outboundItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('useStockScreen.addItemsToOutbound'.tr),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate all items first
    for (var outboundItem in _outboundItems.values) {
      if (outboundItem.quantity > outboundItem.item.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('useStockScreen.cannotExceedStockFor'.tr.replaceAll('{item}', outboundItem.item.name)),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Show bill summary immediately
    setState(() {
      _showBillSummary = true;
      // Initialize amount received with total for convenience
      _amountReceivedController.text = _total.toStringAsFixed(2);
      _calculateChange();
    });

    // Then process the outbound transactions in the background
    final itemProvider = context.read<ItemProvider>();
    bool hasError = false;
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Process each outbound item
      for (var outboundItem in _outboundItems.values) {
        if (outboundItem.quantity > 0) {
          try {
            // Get fresh item data to ensure we have latest quantities
            final freshItems = await itemProvider.getItemsByBarcode(outboundItem.item.barcode ?? '');
            Item freshItem;
            
            if (freshItems.isNotEmpty) {
              final matchingItem = freshItems.where((item) => item.id == outboundItem.item.id).toList();
              if (matchingItem.isNotEmpty) {
                freshItem = matchingItem.first;
              } else {
                freshItem = outboundItem.item;
              }
            } else {
              freshItem = outboundItem.item;
            }
            
            // Additional validation with fresh data
            if (outboundItem.quantity > freshItem.quantity) {
              hasError = true;
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('useStockScreen.notEnoughStockFor'.tr
                      .replaceAll('{name}', freshItem.name)
                      .replaceAll('{quantity}', freshItem.quantity.toString())),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              continue;
            }
            
            // Record the outbound transaction
            await itemProvider.recordOutboundTransaction(
              freshItem,
              outboundItem.quantity,
            );
          } catch (e) {
            hasError = true;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('useStockScreen.errorUpdating'.tr
                    .replaceAll('{name}', outboundItem.item.name)
                    .replaceAll('{error}', e.toString())),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } finally {
      // Close loading indicator
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }

    if (!hasError && mounted) {
      // Reload item provider data
      await itemProvider.reloadFromDatabase();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('useStockScreen.stockRemovedSuccess'.tr),
          backgroundColor: Colors.green,
        ),
      );
    } else if (hasError && mounted) {
      // If there was an error, go back to the outbound screen
      setState(() {
        _showBillSummary = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: const Color(0xFFFF8A00)),
          onPressed: () {
            if (_showBillSummary) {
              // Return to the main outbound screen from bill summary
              setState(() {
                _showBillSummary = false;
                _outboundItems.clear();
                _calculateTotals();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _showBillSummary ? 'Bill Summary' : 'useStockScreen.title'.tr,
          style: const TextStyle(
            color: const Color(0xFFFF8A00),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _showBillSummary ? _buildBillSummary() : _buildOutboundScreen(),
    );
  }

  Widget _buildOutboundScreen() {
    return Column(
      children: [
        // Scanner area
        Container(
          height: 160, // Reduced height to avoid overflow
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onBarcodeDetected,
            ),
          ),
        ),
        
        // Barcode input field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: _barcodeController,
            decoration: InputDecoration(
              labelText: LocalizationService.translate("barcode"),
              hintText: LocalizationService.translate("scan_or_enter_barcode"),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  if (_barcodeController.text.isNotEmpty) {
                    _checkAndAddItem(_barcodeController.text);
                    _barcodeController.clear();
                  }
                },
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                _checkAndAddItem(value);
                _barcodeController.clear();
              }
            },
          ),
        ),

        // Table header
        Container(
          margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFF8A00),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Product Name',
                  style: GoogleFonts.urbanist(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Qty',
                  style: GoogleFonts.urbanist(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'MRP',
                  style: GoogleFonts.urbanist(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Total',
                  style: GoogleFonts.urbanist(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 40), // For delete button space
            ],
          ),
        ),

        // Table content - Outbound items list
        Expanded(
          child: _buildOutboundItemsTable(),
        ),
        
        // Order summary
        if (_outboundItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal:',
                      style: GoogleFonts.urbanist(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_subtotal.toStringAsFixed(2)} €',
                      style: GoogleFonts.urbanist(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: GoogleFonts.urbanist(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF8A00),
                      ),
                    ),
                    Text(
                      '${_total.toStringAsFixed(2)} €',
                      style: GoogleFonts.urbanist(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF8A00),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _processOutbound,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                ),
                      elevation: 0,
              ),
              child: Text(
                      'Confirm Bill',
                style: GoogleFonts.urbanist(
                        fontSize: 16,
                  fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ],
            ),
          ),
      ],
    );
  }

  Widget _buildBillSummary() {
    // Payment method selection
    String _selectedPaymentMethod = 'cash';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8A00),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Payment Receipt',
                    style: GoogleFonts.urbanist(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            
          const SizedBox(height: 20),
            
            // Bill items
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                ),
              ],
            ),
              child: Column(
                children: [
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Product',
                            style: GoogleFonts.urbanist(
                              fontWeight: FontWeight.w600,
                        color: const Color(0xFFFF8A00),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Qty',
                            style: GoogleFonts.urbanist(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF8A00),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Price',
                            style: GoogleFonts.urbanist(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF8A00),
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Table content - improved look
                  for (final outboundItem in _outboundItems.values)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                      children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              outboundItem.item.name,
                              style: GoogleFonts.urbanist(
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (outboundItem.quantity > 1) {
                                      setState(() {
                                        _updateItemQuantity(outboundItem, outboundItem.quantity - 1);
                                      });
                                    }
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.remove, size: 16),
                                  ),
                                ),
                                Container(
                                  width: 40,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${outboundItem.quantity}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (outboundItem.quantity < outboundItem.item.quantity) {
                                      setState(() {
                                        _updateItemQuantity(outboundItem, outboundItem.quantity + 1);
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Cannot exceed available stock of ${outboundItem.item.quantity}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.add, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${(outboundItem.item.price * outboundItem.quantity).toStringAsFixed(2)} €',
                              style: GoogleFonts.urbanist(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFFF8A00),
                              ),
                              textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
                  
                  // Totals
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
          Text(
                              'Subtotal:',
                              style: GoogleFonts.urbanist(
              fontWeight: FontWeight.w500,
            ),
                            ),
                            Text(
                              '${_subtotal.toStringAsFixed(2)} €',
                              style: GoogleFonts.urbanist(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: GoogleFonts.urbanist(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFF8A00),
                              ),
                            ),
                            Text(
                              '${_total.toStringAsFixed(2)} €',
                              style: GoogleFonts.urbanist(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFF8A00),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Payment methods section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                ),
              ],
            ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    'Payment Method',
                    style: GoogleFonts.urbanist(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF8A00),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Payment method options
                  StatefulBuilder(
                    builder: (context, setMethodState) {
                      return Column(
                        children: [
                          // Cash option
                InkWell(
                            onTap: () {
                              setMethodState(() {
                                _selectedPaymentMethod = 'cash';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _selectedPaymentMethod == 'cash' 
                                  ? const Color(0xFFFFF3E0)
                                  : Colors.white,
                                border: Border.all(
                                  color: _selectedPaymentMethod == 'cash' 
                                    ? const Color(0xFFFF8A00)
                                    : Colors.grey[300]!,
                                  width: 1,
                                ),
                  borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                      children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _selectedPaymentMethod == 'cash'
                                        ? const Color(0xFFFF8A00)
                                        : Colors.white,
                                      border: Border.all(
                                        color: _selectedPaymentMethod == 'cash'
                                          ? const Color(0xFFFF8A00)
                                          : Colors.grey[400]!,
                                        width: 2,
                                      ),
                                    ),
                                    child: _selectedPaymentMethod == 'cash'
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : null,
                                  ),
                                  const SizedBox(width: 12),
                        Icon(
                                    Icons.payments_outlined,
                                    color: _selectedPaymentMethod == 'cash'
                                      ? const Color(0xFFFF8A00)
                                      : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                        Text(
                                    'Cash',
                                    style: GoogleFonts.urbanist(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedPaymentMethod == 'cash'
                                        ? const Color(0xFFFF8A00)
                                        : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                          
                          const SizedBox(height: 12),
                          
                          // Card option (disabled for now)
                          Opacity(
                            opacity: 0.6,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.grey[300]!,
                  width: 1,
                                ),
                  borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                      children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(
                                        color: Colors.grey[400]!,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.credit_card_outlined, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                        Text(
                                          'Card',
                                          style: GoogleFonts.urbanist(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          'Coming soon',
                                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // UPI option (disabled for now)
                          Opacity(
                            opacity: 0.6,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                  borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                      children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(
                                        color: Colors.grey[400]!,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.smartphone_outlined, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                        Text(
                                          'UPI',
                                          style: GoogleFonts.urbanist(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          'Coming soon',
                                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                  ),
                ),
              ],
            ),
          ),
                          ),
                        ],
                      );
                    }
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // Payment details - only shown for cash
                        Container(
              padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                    'Payment Details',
                    style: GoogleFonts.urbanist(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF8A00),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Amount received
                  TextField(
                    controller: _amountReceivedController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount Received',
                      labelStyle: TextStyle(color: const Color(0xFFFF8A00)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: const Color(0xFFFF8A00)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: const Color(0xFFFF8A00), width: 2),
                      ),
                      suffixText: '€',
                      prefixIcon: const Icon(Icons.euro, color: const Color(0xFFFF8A00)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Change to return
                  Container(
                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                      color: _change >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                        color: _change >= 0 ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Change to Return:',
                          style: GoogleFonts.urbanist(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                        Text(
                          '${_change.toStringAsFixed(2)} €',
                          style: GoogleFonts.urbanist(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _change >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                              ),
                            ],
                          ),
                        ),
            
            const SizedBox(height: 24),
            
            // Print and Complete buttons in a row
            Row(
              children: [
                // Print button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        // Convert OutboundItems to OutboundTransactions
                        final transactions = _outboundItems.values.map((item) => OutboundTransaction(
                          item: item.item,
                          quantity: item.quantity,
                          date: DateTime.now(),
                        )).toList();
                        
                        // Print the receipt
                        await ReceiptPrinter.printMultipleItemsReceipt(transactions);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Receipt printed successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error printing receipt: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.print),
                    label: Text('Print Receipt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A00),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                // Complete transaction button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Complete the transaction and go back to main screen
                      setState(() {
                        _showBillSummary = false;
                        _outboundItems.clear();
                        _calculateTotals();
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Transaction completed successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: Icon(Icons.check_circle_outline),
                    label: Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutboundItemsTable() {
    if (_outboundItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              LocalizationService.translate("no_items_in_outbound"),
              style: GoogleFonts.urbanist(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan items to add to your bill',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                color: Colors.grey[500],
            ),
          ),
        ],
      ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
          boxShadow: [
            BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
      child: ListView.separated(
        itemCount: _outboundItems.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _outboundItems.values.elementAt(index);
          final totalPrice = item.item.price * item.quantity;
          
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                // Product name
                Expanded(
                  flex: 3,
                  child: Text(
                    item.item.name,
                    style: GoogleFonts.urbanist(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Quantity
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.quantity}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.urbanist(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                // MRP (Unit Price)
                Expanded(
                  flex: 2,
                  child: Text(
                    '${item.item.price.toStringAsFixed(2)} €',
                    style: GoogleFonts.urbanist(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                
                // Total Price
                Expanded(
                  flex: 2,
                  child: Text(
                    '${totalPrice.toStringAsFixed(2)} €',
                    style: GoogleFonts.urbanist(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF8A00),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                
                // Delete button
                SizedBox(
                  width: 40,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => _removeItem(item.item.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

