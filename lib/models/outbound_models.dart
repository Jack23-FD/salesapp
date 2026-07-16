import 'item.dart';
import 'dart:convert';

// Class used for outbound transactions
class OutboundItem {
  final Item item;
  int quantity;

  OutboundItem({required this.item, required this.quantity});
}

// Class used for generating invoices
class OutboundItemForInvoice {
  final String name;
  final String unit;
  final int quantity;
  final double price;
  
  OutboundItemForInvoice({
    required this.name,
    required this.unit,
    required this.quantity,
    required this.price,
  });
  
  factory OutboundItemForInvoice.fromItem(Item item, int quantity) {
    return OutboundItemForInvoice(
      name: item.name,
      unit: item.unit,
      quantity: quantity,
      price: item.price,
    );
  }
}

// Class used for tracking outbound transactions with full Item objects
class OutboundTransaction {
  final Item item;
  final int quantity;
  final DateTime date;

  OutboundTransaction({
    required this.item,
    required this.quantity,
    required this.date,
  });
}

// Class used for storage of outbound transactions
class OutboundTransactionStorage {
  final Map<String, dynamic> item;
  final int quantity;
  final DateTime date;

  OutboundTransactionStorage({
    required this.item,
    required this.quantity,
    required this.date,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    'item': item,
    'quantity': quantity,
    'date': date.toIso8601String(),
  };

  // Create from JSON
  factory OutboundTransactionStorage.fromJson(Map<String, dynamic> json) {
    return OutboundTransactionStorage(
      item: json['item'],
      quantity: json['quantity'],
      date: DateTime.parse(json['date']),
    );
  }
} 