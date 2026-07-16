import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../models/outbound_models.dart';
import 'package:uuid/uuid.dart';
import 'package:open_file/open_file.dart';

class InvoiceService {
  static Future<Uint8List> generateInvoice({
    required List<OutboundItemForInvoice> items,
    String? customerName = 'Customer',
    String? customerAddress,
    String? phoneNumber,
    String? email,
    double discountPercentage = 0,
    String? notes,
  }) async {
    final pdf = pw.Document();
    final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 8)}';
    final date = DateTime.now();
    final dueDate = date.add(const Duration(days: 30));
    
    // Calculate totals
    double subtotal = 0;
    for (var item in items) {
      subtotal += item.price * item.quantity;
    }
    
    final discountAmount = subtotal * (discountPercentage / 100);
    final taxRate = 0.10; // 10% tax
    final taxAmount = (subtotal - discountAmount) * taxRate;
    final total = subtotal - discountAmount + taxAmount;
    
    // Use default font instead of loading from assets
    // final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    // final ttf = pw.Font.ttf(fontData);
    
    // Add page to the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(invoiceNumber, date, dueDate),
            pw.SizedBox(height: 30),
            _buildInvoiceInfo(customerName, customerAddress, phoneNumber, email),
            pw.SizedBox(height: 30),
            _buildItemsTable(items),
            pw.SizedBox(height: 20),
            _buildTotal(subtotal, discountPercentage, discountAmount, taxRate, taxAmount, total),
            pw.SizedBox(height: 20),
            if (notes != null) _buildNotes(notes),
            pw.SizedBox(height: 20),
            _buildFooter(),
          ];
        },
      ),
    );
    
    return pdf.save();
  }
  
  static pw.Widget _buildHeader(String invoiceNumber, DateTime date, DateTime dueDate) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo900,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Invoice #: $invoiceNumber',
                  style: pw.TextStyle(
                    fontSize: 12,
                  ),
                ),
                pw.Text(
                  'Date: ${DateFormat('dd/MM/yyyy').format(date)}',
                  style: pw.TextStyle(
                    fontSize: 12,
                  ),
                ),
                pw.Text(
                  'Due Date: ${DateFormat('dd/MM/yyyy').format(dueDate)}',
                  style: pw.TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Sales App',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo900,
                  ),
                ),
                pw.Text(
                  'Praskla',
                  style: pw.TextStyle(
                    fontSize: 14,
                  ),
                ),
                pw.Text(
                  '123 Business Street',
                  style: pw.TextStyle(
                    fontSize: 12,
                  ),
                ),
                pw.Text(
                  'Phone: (123) 456-7890',
                  style: pw.TextStyle(
                    fontSize: 12,
                  ),
                ),
                pw.Text(
                  'Email: info@salesapp.com',
                  style: pw.TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(
          color: PdfColors.grey600,
          thickness: 1,
        ),
      ],
    );
  }
  
  static pw.Widget _buildInvoiceInfo(
    String? customerName,
    String? customerAddress,
    String? phoneNumber,
    String? email,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Bill To:',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          customerName ?? 'Customer',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (customerAddress != null)
          pw.Text(
            customerAddress,
            style: pw.TextStyle(
              fontSize: 12,
            ),
          ),
        if (phoneNumber != null)
          pw.Text(
            'Phone: $phoneNumber',
            style: pw.TextStyle(
              fontSize: 12,
            ),
          ),
        if (email != null)
          pw.Text(
            'Email: $email',
            style: pw.TextStyle(
              fontSize: 12,
            ),
          ),
      ],
    );
  }
  
  static pw.Widget _buildItemsTable(List<OutboundItemForInvoice> items) {
    const tableHeaders = ['Item', 'Unit', 'Quantity', 'Unit Price', 'Total'];
    
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey400,
        width: 0.5,
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        // Table header
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.indigo100,
          ),
          children: List.generate(
            tableHeaders.length,
            (index) => pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                tableHeaders[index],
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: index >= 2 ? pw.TextAlign.right : pw.TextAlign.left,
              ),
            ),
          ),
        ),
        // Table data
        ...items.map(
          (item) => pw.TableRow(
            children: [
              // Item name
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  item.name,
                ),
              ),
              // Unit
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  item.unit,
                ),
              ),
              // Quantity
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  item.quantity.toString(),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              // Unit Price
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '€${item.price.toStringAsFixed(2)}',
                  textAlign: pw.TextAlign.right,
                ),
              ),
              // Total
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '€${(item.price * item.quantity).toStringAsFixed(2)}',
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  static pw.Widget _buildTotal(
    double subtotal,
    double discountPercentage,
    double discountAmount,
    double taxRate,
    double taxAmount,
    double total,
  ) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _buildTotalRow('Subtotal', '€${subtotal.toStringAsFixed(2)}'),
          if (discountPercentage > 0) 
            _buildTotalRow('Discount (${discountPercentage.toStringAsFixed(0)}%)', '-€${discountAmount.toStringAsFixed(2)}'),
          _buildTotalRow('Tax (${(taxRate * 100).toStringAsFixed(0)}%)', '€${taxAmount.toStringAsFixed(2)}'),
          pw.Divider(
            color: PdfColors.grey600,
            thickness: 0.5,
          ),
          _buildTotalRow(
            'Total',
            '€${total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildTotalRow(
    String title,
    String value, {
    bool isTotal = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            width: 120,
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
                fontSize: isTotal ? 14 : 12,
              ),
            ),
          ),
          pw.Container(
            width: 120,
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
                fontSize: isTotal ? 14 : 12,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildNotes(String notes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Notes:',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          notes,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey800,
          ),
        ),
      ],
    );
  }
  
  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(
          color: PdfColors.grey600,
          thickness: 0.5,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Thank you for your business!',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.indigo900,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Payment is due within 30 days. Please make checks payable to SalesApp or pay online.',
          style: pw.TextStyle(
            fontSize: 10,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }
  
  static Future<String> saveAndOpenInvoice(Uint8List pdfBytes) async {
    try {
      // Get the downloads directory path
      final directory = await _getDownloadsDirectory();
      final invoiceName = 'invoice_${const Uuid().v4()}.pdf';
      final file = File('${directory.path}/$invoiceName');
      
      // Create log message before saving
      final logMessage = 'Attempting to save invoice to: ${file.path}';
      print(logMessage);
      
      // Ensure directory exists
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        print('Created directory: ${directory.path}');
      }
      
      await file.writeAsBytes(pdfBytes);
      
      print('🔍 INVOICE SAVED SUCCESSFULLY TO:');
      print('📁 ${file.path}');
      print('📝 Filename: $invoiceName');
      print('📊 File size: ${(pdfBytes.length / 1024).toStringAsFixed(2)} KB');
      
      // Open the PDF
      try {
        await OpenFile.open(file.path);
        print('Opened invoice file with default viewer');
      } catch (e) {
        print('Unable to open PDF automatically: $e');
        print('Invoice is still saved at: ${file.path}');
      }
      
      return file.path; // Return the file path
    } catch (e) {
      print('❌ Error saving invoice: $e');
      // Try fallback location
      return await _saveToFallbackLocation(pdfBytes);
    }
  }
  
  // Fallback method if the downloads directory isn't accessible
  static Future<String> _saveToFallbackLocation(Uint8List pdfBytes) async {
    try {
      // Save to app documents directory as fallback
      final directory = await getApplicationDocumentsDirectory();
      final invoiceName = 'invoice_fallback_${const Uuid().v4()}.pdf';
      final file = File('${directory.path}/$invoiceName');
      
      print('Attempting to save invoice to fallback location: ${file.path}');
      await file.writeAsBytes(pdfBytes);
      
      print('💾 INVOICE SAVED TO FALLBACK LOCATION:');
      print('📁 ${file.path}');
      
      try {
        await OpenFile.open(file.path);
      } catch (e) {
        print('Unable to open fallback PDF: $e');
      }
      
      return file.path; // Return the fallback file path
    } catch (e) {
      print('❌ Error saving to fallback location: $e');
      return "Could not save the invoice. Check logs for details.";
    }
  }
  
  // Helper method to get downloads directory
  static Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      try {
        // Try direct path to Download folder first for Android 10+
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          print('Using direct Downloads path: ${downloadsDir.path}');
          return downloadsDir;
        }
      } catch (e) {
        print('Error accessing direct Downloads path: $e');
      }
      
      // Use external storage directory for Android
      final directory = await getExternalStorageDirectory();
      
      // Navigate to the downloads directory
      String downloadsPath = "";
      if (directory != null) {
        // Try to find the Downloads directory by navigating up and then into Downloads
        final String androidPath = directory.path;
        print('Android base path: $androidPath');
        final List<String> paths = androidPath.split("/");
        
        // Find the path up to Android/data
        for (int i = 0; i < paths.length; i++) {
          if (paths[i] == "Android" && i > 0) {
            downloadsPath = paths.sublist(0, i).join("/") + "/Download";
            print('Constructed Downloads path: $downloadsPath');
            break;
          }
        }
        
        // If we found a valid download path
        if (downloadsPath.isNotEmpty) {
          final downloadsDir = Directory(downloadsPath);
          
          // Check if directory exists
          final exists = await downloadsDir.exists();
          print('Downloads directory exists: $exists at ${downloadsDir.path}');
          
          // Create directory if it doesn't exist
          if (!exists) {
            try {
              await downloadsDir.create(recursive: true);
              print('Created Downloads directory: ${downloadsDir.path}');
            } catch (e) {
              print('Error creating Downloads directory: $e');
              return await getApplicationDocumentsDirectory();
            }
          }
          
          return downloadsDir;
        }
      } else {
        print('External storage directory is null');
      }
      
      // Fallback to app's documents directory if can't access downloads
      print('Falling back to app documents directory');
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isIOS) {
      // For iOS, use the Documents directory as iOS doesn't have a centralized Downloads folder
      final Directory directory = await getApplicationDocumentsDirectory();
      print('iOS Documents directory: ${directory.path}');
      return directory;
    } else {
      // Fallback for other platforms
      print('Unsupported platform, using app documents directory');
      return await getApplicationDocumentsDirectory();
    }
  }
} 