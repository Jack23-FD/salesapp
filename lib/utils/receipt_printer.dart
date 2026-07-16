import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/item.dart';
import '../models/outbound_models.dart';
import 'package:intl/intl.dart';

class ReceiptPrinter {
  static String _generateReceiptNumber() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }

  static Future<void> printReceipt(OutboundTransaction transaction) async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

      // Format currency with Euro symbol
      String formatPrice(double price) => '${price.toStringAsFixed(2)} €';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'SALES RECEIPT',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),
                
                // Store Info
                pw.Center(
                  child: pw.Text(
                    'Your Store Name',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Store Address',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Phone: +1234567890',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.SizedBox(height: 5),
                
                // Transaction Details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Date:', style: pw.TextStyle(fontSize: 10)),
                    pw.Text(dateFormat.format(transaction.date), style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Receipt #:', style: pw.TextStyle(fontSize: 10)),
                    pw.Text(_generateReceiptNumber(), style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Divider(),
                
                // Item Details
                pw.Text('Item Details:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text(transaction.item.name, style: pw.TextStyle(fontSize: 10)),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Qty: ${transaction.quantity}', style: pw.TextStyle(fontSize: 10)),
                    pw.Text('Price: ${formatPrice(transaction.item.price)}', style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.SizedBox(height: 5),
                
                // Total
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      formatPrice(transaction.item.price * transaction.quantity),
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                
                // Footer
                pw.Center(
                  child: pw.Text(
                    'Thank you for your purchase!',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Please visit again',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    'This is a computer generated receipt',
                    style: pw.TextStyle(fontSize: 8),
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      debugPrint('Error printing receipt: $e');
      rethrow;
    }
  }

  static Future<void> printMultipleItemsReceipt(List<OutboundTransaction> transactions) async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
      final total = transactions.fold(0.0, (sum, t) => sum + (t.item.price * t.quantity));

      // Format currency with Euro symbol
      String formatPrice(double price) => '${price.toStringAsFixed(2)} €';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'SALES RECEIPT',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),
                
                // Store Info
                pw.Center(
                  child: pw.Text(
                    'Your Store Name',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Store Address',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Phone: +1234567890',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.SizedBox(height: 5),
                
                // Transaction Details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Date:', style: pw.TextStyle(fontSize: 10)),
                    pw.Text(dateFormat.format(DateTime.now()), style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Receipt #:', style: pw.TextStyle(fontSize: 10)),
                    pw.Text(_generateReceiptNumber(), style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Divider(),
                
                // Items List
                pw.Text('Items:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                ...transactions.map((transaction) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(transaction.item.name, style: pw.TextStyle(fontSize: 10)),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Qty: ${transaction.quantity}', style: pw.TextStyle(fontSize: 10)),
                        pw.Text('Price: ${formatPrice(transaction.item.price)}', style: pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Subtotal:', style: pw.TextStyle(fontSize: 10)),
                        pw.Text(
                          formatPrice(transaction.item.price * transaction.quantity),
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                  ],
                )),
                
                // Total
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      formatPrice(total),
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                
                // Footer
                pw.Center(
                  child: pw.Text(
                    'Thank you for your purchase!',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Please visit again',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    'This is a computer generated receipt',
                    style: pw.TextStyle(fontSize: 8),
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      debugPrint('Error printing receipt: $e');
      rethrow;
    }
  }
} 