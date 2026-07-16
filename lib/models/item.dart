import 'package:flutter/material.dart';

class Item {
  final String id;
  final String name;
  final String categoryId;
  final int quantity;
  final String unit;
  final double price;
  final String? barcode;
  final double? minLevel;
  final DateTime? dateAdded;
  final DateTime createdAt;
  final String type;
  final String? categoryName;
  final String? imageUrl;

  Item({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.quantity,
    required this.unit,
    required this.price,
    this.barcode,
    this.minLevel,
    this.dateAdded,
    required this.createdAt,
    this.type = 'inbound',
    this.categoryName,
    this.imageUrl,
  });

  factory Item.fromMap(Map<String, dynamic> map, String id) {
    return Item(
      id: id,
      name: map['name'] ?? '',
      categoryId: map['categoryId'] ?? '',
      quantity: map['quantity'] is int ? map['quantity'] : (map['quantity'] as num?)?.toInt() ?? 0,
      unit: map['unit'] ?? 'pcs',
      price: (map['price'] ?? 0.0).toDouble(),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      dateAdded: map['dateAdded'] != null 
          ? map['dateAdded'] is DateTime 
              ? map['dateAdded'] 
              : DateTime.parse(map['dateAdded'].toString())
          : DateTime.now(),
      barcode: map['barcode'],
      minLevel: map['minLevel'] != null ? (map['minLevel'] as num).toDouble() : null,
      type: map['type'] ?? 'inbound',
      categoryName: map['categoryName'],
      imageUrl: map['imageUrl'],
    );
  }

  double get totalValue => quantity * price;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'barcode': barcode,
      'minLevel': minLevel,
      'dateAdded': dateAdded?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'type': type,
      'imageUrl': imageUrl,
    };
  }

  Item copyWith({
    String? id,
    String? name,
    String? categoryId,
    int? quantity,
    String? unit,
    double? price,
    String? barcode,
    double? minLevel,
    DateTime? dateAdded,
    DateTime? createdAt,
    String? type,
    String? categoryName,
    String? imageUrl,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      barcode: barcode ?? this.barcode,
      minLevel: minLevel ?? this.minLevel,
      dateAdded: dateAdded ?? this.dateAdded,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      categoryName: categoryName ?? this.categoryName,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() {
    return 'Item{id: $id, name: $name, categoryId: $categoryId, quantity: $quantity, unit: $unit, price: $price, dateAdded: $dateAdded, createdAt: $createdAt, type: $type, imageUrl: $imageUrl}';
  }
}
