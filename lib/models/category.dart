import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String? description;
  final IconData? icon;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.icon,
  });

  // Convert category to a map for serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCodePoint': icon?.codePoint,
      'iconFontFamily': icon?.fontFamily,
      'iconFontPackage': icon?.fontPackage,
    };
  }

  // Create a category from a map
  factory Category.fromMap(Map<String, dynamic> map) {
    try {
      IconData? iconData;
      if (map['iconCodePoint'] != null) {
        // Instead of creating a dynamic IconData, use a lookup for predefined icons
        iconData = _getIconFromCodePoint(map['iconCodePoint']);
      }

      return Category(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        description: map['description'],
        icon: iconData,
      );
    } catch (e) {
      print('Error creating Category from map: $e');
      print('Map data: $map');

      // Create a fallback category with default values
      return Category(
        id: map['id'] ?? 'error-id-${DateTime.now().millisecondsSinceEpoch}',
        name: map['name'] ?? 'Error Category',
      );
    }
  }

  // Helper method to get constant IconData based on code point
  static IconData? _getIconFromCodePoint(int codePoint) {
    // This map should include all possible icons used in your app
    final Map<int, IconData> iconMap = {
      Icons.shopping_bag_outlined.codePoint: Icons.shopping_bag_outlined,
      Icons.fastfood_outlined.codePoint: Icons.fastfood_outlined,
      Icons.local_grocery_store_outlined.codePoint:
          Icons.local_grocery_store_outlined,
      Icons.card_giftcard_outlined.codePoint: Icons.card_giftcard_outlined,
      Icons.sports_esports_outlined.codePoint: Icons.sports_esports_outlined,
      Icons.medical_services_outlined.codePoint:
          Icons.medical_services_outlined,
      Icons.book_outlined.codePoint: Icons.book_outlined,
      Icons.devices_outlined.codePoint: Icons.devices_outlined,
      // Add more icons as needed
    };

    return iconMap[codePoint];
  }
}
