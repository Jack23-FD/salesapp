import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';
import '../models/category.dart';
import '../models/outbound_models.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InboundItemData {
  final Map<String, dynamic> item;
  final DateTime date;

  InboundItemData({
    required this.item,
    required this.date,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() => {
        'item': item,
        'date': date.toIso8601String(),
      };

  // Create from JSON
  factory InboundItemData.fromJson(Map<String, dynamic> json) {
    return InboundItemData(
      item: json['item'],
      date: DateTime.parse(json['date']),
    );
  }
}

class StorageUtils {
  static const String _inboundItemsKey = 'inbound_items';
  static const String _outboundTransactionsKey = 'outbound_transactions';
  static const String _categoriesKey = 'categories';
  static const String _userRoleKey = 'user_role';
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userKey = 'user';

  // Get current user ID from Firebase Auth
  static String? _getCurrentUserId() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  // Get user-specific key
  static String _getUserKey(String baseKey) {
    String? userId = _getCurrentUserId();
    return userId != null ? '${userId}_$baseKey' : baseKey;
  }

  // Save inbound item to local storage
  static Future<void> saveInboundItem(Item item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedItems = prefs.getStringList(_getUserKey(_inboundItemsKey)) ?? [];

      // Create inbound data using item's toMap method
      final inboundData = InboundItemData(
        item: item.toMap(),
        date: DateTime.now(),
      );

      // Add to the list
      savedItems.add(jsonEncode(inboundData.toJson()));

      // Save the updated list
      await prefs.setStringList(_getUserKey(_inboundItemsKey), savedItems);
    } catch (e) {
      print('Error saving inbound item to local storage: $e');
    }
  }

  // Get all inbound items
  static Future<List<InboundItemData>> getInboundItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedItems = prefs.getStringList(_getUserKey(_inboundItemsKey)) ?? [];

      List<InboundItemData> result = [];
      for (String itemStr in savedItems) {
        try {
          final Map<String, dynamic> itemJson = jsonDecode(itemStr);
          result.add(InboundItemData.fromJson(itemJson));
        } catch (e) {
          print('Error decoding inbound item: $e');
          print('Problematic item string: $itemStr');
          // Continue with next item
        }
      }
      return result;
    } catch (e) {
      print('Error retrieving inbound items from local storage: $e');
      return [];
    }
  }

  // Get inbound items for a specific date
  static Future<List<InboundItemData>> getInboundItemsByDate(
      DateTime date) async {
    try {
      final allItems = await getInboundItems();
      return allItems.where((inboundData) {
        return inboundData.date.year == date.year &&
            inboundData.date.month == date.month &&
            inboundData.date.day == date.day;
      }).toList();
    } catch (e) {
      print('Error retrieving inbound items by date: $e');
      return [];
    }
  }

  // Save outbound transaction
  static Future<void> saveOutboundTransaction(Item item, int quantity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedTransactions =
          prefs.getStringList(_getUserKey(_outboundTransactionsKey)) ?? [];

      // Create transaction using item's toMap method
      final transaction = OutboundTransactionStorage(
        item: item.toMap(),
        quantity: quantity,
        date: DateTime.now(),
      );

      // Add to the list
      savedTransactions.add(jsonEncode(transaction.toJson()));

      // Save the updated list
      await prefs.setStringList(_getUserKey(_outboundTransactionsKey), savedTransactions);
    } catch (e) {
      print('Error saving outbound transaction to local storage: $e');
    }
  }

  // Get all outbound transactions
  static Future<List<OutboundTransactionStorage>> getOutboundTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedTransactions =
          prefs.getStringList(_getUserKey(_outboundTransactionsKey)) ?? [];

      List<OutboundTransactionStorage> result = [];
      for (String transactionStr in savedTransactions) {
        try {
          final Map<String, dynamic> transactionJson =
              jsonDecode(transactionStr);
          result.add(OutboundTransactionStorage.fromJson(transactionJson));
        } catch (e) {
          print('Error decoding outbound transaction: $e');
          print('Problematic transaction string: $transactionStr');
          // Continue with next transaction
        }
      }
      return result;
    } catch (e) {
      print('Error retrieving outbound transactions from local storage: $e');
      return [];
    }
  }

  // Get outbound transactions for a specific date
  static Future<List<OutboundTransactionStorage>> getOutboundTransactionsByDate(
      DateTime date) async {
    try {
      final allTransactions = await getOutboundTransactions();
      return allTransactions.where((transaction) {
        return transaction.date.year == date.year &&
            transaction.date.month == date.month &&
            transaction.date.day == date.day;
      }).toList();
    } catch (e) {
      print('Error retrieving outbound transactions by date: $e');
      return [];
    }
  }

  // Clear all local storage (for testing or reset)
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getUserKey(_inboundItemsKey));
      await prefs.remove(_getUserKey(_outboundTransactionsKey));
    } catch (e) {
      print('Error clearing local storage: $e');
    }
  }

  // Save categories to local storage
  static Future<void> saveCategories(List<Category> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> serializedCategories =
          categories.map((category) => jsonEncode(category.toMap())).toList();

      await prefs.setStringList(_getUserKey(_categoriesKey), serializedCategories);
      print('Saved ${categories.length} categories to local storage');
    } catch (e) {
      print('Error saving categories to local storage: $e');
    }
  }

  // Save a single category to local storage
  static Future<void> saveCategory(Category category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedCategories = prefs.getStringList(_getUserKey(_categoriesKey)) ?? [];

      // Check if category already exists (by id) and update it, or add new
      bool categoryExists = false;
      List<String> updatedCategories = [];

      for (String savedCategoryStr in savedCategories) {
        try {
          final Map<String, dynamic> savedCategoryMap =
              jsonDecode(savedCategoryStr);
          if (savedCategoryMap['id'] == category.id) {
            // Replace with updated category
            updatedCategories.add(jsonEncode(category.toMap()));
            categoryExists = true;
          } else {
            // Keep existing category
            updatedCategories.add(savedCategoryStr);
          }
        } catch (e) {
          // If there's an error, keep the original string
          updatedCategories.add(savedCategoryStr);
          print('Error decoding saved category: $e');
        }
      }

      // If category doesn't exist, add it
      if (!categoryExists) {
        updatedCategories.add(jsonEncode(category.toMap()));
      }

      // Save updated list
      await prefs.setStringList(_getUserKey(_categoriesKey), updatedCategories);
      print('Saved/updated category ${category.name} to local storage');
    } catch (e) {
      print('Error saving category to local storage: $e');
    }
  }

  // Get all categories from local storage
  static Future<List<Category>> getCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedCategories = prefs.getStringList(_getUserKey(_categoriesKey)) ?? [];

      List<Category> result = [];
      for (String categoryStr in savedCategories) {
        try {
          final Map<String, dynamic> categoryJson = jsonDecode(categoryStr);
          result.add(Category.fromMap(categoryJson));
        } catch (e) {
          print('Error decoding category: $e');
          print('Problematic category string: $categoryStr');
        }
      }
      print('Retrieved ${result.length} categories from local storage');
      return result;
    } catch (e) {
      print('Error retrieving categories from local storage: $e');
      return [];
    }
  }

  // Delete a category from local storage
  static Future<void> deleteCategory(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedCategories = prefs.getStringList(_getUserKey(_categoriesKey)) ?? [];

      List<String> updatedCategories = [];
      for (String savedCategoryStr in savedCategories) {
        try {
          final Map<String, dynamic> savedCategoryMap =
              jsonDecode(savedCategoryStr);
          if (savedCategoryMap['id'] != categoryId) {
            updatedCategories.add(savedCategoryStr);
          }
        } catch (e) {
          // If there's an error, keep the original string
          updatedCategories.add(savedCategoryStr);
        }
      }

      // Save updated list
      await prefs.setStringList(_getUserKey(_categoriesKey), updatedCategories);
      print('Deleted category with id $categoryId from local storage');
    } catch (e) {
      print('Error deleting category from local storage: $e');
    }
  }

  // Debug method to check what's stored in SharedPreferences
  static Future<void> debugStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      try {
        // Check inbound items
        var inboundItems = prefs.getStringList(_getUserKey(_inboundItemsKey));
        print('Inbound items found: ${inboundItems?.length ?? 0}');
        if (inboundItems != null && inboundItems.isNotEmpty) {
          print(
              'First inbound item: ${inboundItems.first.substring(0, min(100, inboundItems.first.length))}...');
        }
      } catch (e) {
        print('Error checking inbound items: $e');
      }

      try {
        // Check outbound transactions
        List<String>? outboundTransactions =
            prefs.getStringList(_getUserKey(_outboundTransactionsKey));
        print(
            'Outbound transactions found: ${outboundTransactions?.length ?? 0}');
        if (outboundTransactions != null && outboundTransactions.isNotEmpty) {
          print(
              'First outbound transaction: ${outboundTransactions.first.substring(0, min(100, outboundTransactions.first.length))}...');
        }
      } catch (e) {
        print('Error checking outbound transactions: $e');
      }

      try {
        // Check categories
        List<String>? categories = prefs.getStringList(_getUserKey(_categoriesKey));
        print('Categories found: ${categories?.length ?? 0}');
        if (categories != null && categories.isNotEmpty) {
          print(
              'First category: ${categories.first.substring(0, min(100, categories.first.length))}...');
        }
      } catch (e) {
        print('Error checking categories: $e');
      }

      // Check all keys
      print('All SharedPreferences keys:');
      prefs.getKeys().forEach((key) {
        print('- $key');
      });
    } catch (e) {
      print('Error debugging storage: $e');
    }
  }

  // Check if data exists in storage
  static Future<bool> hasData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? inboundItems = prefs.getStringList(_getUserKey(_inboundItemsKey));
      List<String>? outboundTransactions =
          prefs.getStringList(_getUserKey(_outboundTransactionsKey));

      return (inboundItems != null && inboundItems.isNotEmpty) ||
          (outboundTransactions != null && outboundTransactions.isNotEmpty);
    } catch (e) {
      print('Error checking if data exists: $e');
      return false;
    }
  }

  // Migrate data from global keys to user-specific keys
  static Future<void> migrateToUserSpecificData() async {
    try {
      final String? userId = _getCurrentUserId();
      if (userId == null) {
        print('Cannot migrate data: No user ID available');
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      
      // Migrate categories
      final List<String> categories = prefs.getStringList(_categoriesKey) ?? [];
      if (categories.isNotEmpty) {
        await prefs.setStringList(_getUserKey(_categoriesKey), categories);
        print('Migrated ${categories.length} categories to user-specific storage');
      }
      
      // Migrate inbound items
      final List<String> inboundItems = prefs.getStringList(_inboundItemsKey) ?? [];
      if (inboundItems.isNotEmpty) {
        await prefs.setStringList(_getUserKey(_inboundItemsKey), inboundItems);
        print('Migrated ${inboundItems.length} inbound items to user-specific storage');
      }
      
      // Migrate outbound transactions
      final List<String> outboundTransactions = prefs.getStringList(_outboundTransactionsKey) ?? [];
      if (outboundTransactions.isNotEmpty) {
        await prefs.setStringList(_getUserKey(_outboundTransactionsKey), outboundTransactions);
        print('Migrated ${outboundTransactions.length} outbound transactions to user-specific storage');
      }
    } catch (e) {
      print('Error migrating data to user-specific storage: $e');
    }
  }

  // Delete an inbound item from local storage
  static Future<void> deleteInboundItem(String itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedItems = prefs.getStringList(_getUserKey(_inboundItemsKey)) ?? [];

      List<String> updatedItems = [];
      for (String savedItemStr in savedItems) {
        try {
          final Map<String, dynamic> inboundDataJson = jsonDecode(savedItemStr);
          final Map<String, dynamic> itemData = inboundDataJson['item'];
          if (itemData['id'] != itemId) {
            updatedItems.add(savedItemStr);
          }
        } catch (e) {
          // If there's an error, keep the original string
          updatedItems.add(savedItemStr);
          print('Error processing item during deletion: $e');
        }
      }

      // Save updated list
      await prefs.setStringList(_getUserKey(_inboundItemsKey), updatedItems);
      print('Deleted inbound item with id $itemId from local storage');
    } catch (e) {
      print('Error deleting inbound item from local storage: $e');
    }
  }

  // Delete outbound transactions for a specific item
  static Future<void> deleteOutboundTransactionsForItem(String itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedTransactions = prefs.getStringList(_getUserKey(_outboundTransactionsKey)) ?? [];

      List<String> updatedTransactions = [];
      for (String transactionStr in savedTransactions) {
        try {
          final Map<String, dynamic> transactionJson = jsonDecode(transactionStr);
          final Map<String, dynamic> itemData = transactionJson['item'];
          if (itemData['id'] != itemId) {
            updatedTransactions.add(transactionStr);
          }
        } catch (e) {
          // If there's an error, keep the original string
          updatedTransactions.add(transactionStr);
          print('Error processing transaction during deletion: $e');
        }
      }

      // Save updated list
      await prefs.setStringList(_getUserKey(_outboundTransactionsKey), updatedTransactions);
      print('Deleted outbound transactions for item with id $itemId from local storage');
    } catch (e) {
      print('Error deleting outbound transactions from local storage: $e');
    }
  }
  
  // Delete all outbound transactions for a category
  static Future<void> deleteOutboundTransactionsForCategory(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedTransactions = prefs.getStringList(_getUserKey(_outboundTransactionsKey)) ?? [];

      List<String> updatedTransactions = [];
      for (String transactionStr in savedTransactions) {
        try {
          final Map<String, dynamic> transactionJson = jsonDecode(transactionStr);
          final Map<String, dynamic> itemData = transactionJson['item'];
          if (itemData['categoryId'] != categoryId) {
            updatedTransactions.add(transactionStr);
          }
        } catch (e) {
          // If there's an error, keep the original string
          updatedTransactions.add(transactionStr);
          print('Error processing transaction during category deletion: $e');
        }
      }

      // Save updated list
      await prefs.setStringList(_getUserKey(_outboundTransactionsKey), updatedTransactions);
      print('Deleted outbound transactions for category with id $categoryId from local storage');
    } catch (e) {
      print('Error deleting category outbound transactions from local storage: $e');
    }
  }

  // Cache integer value
  static Future<void> cacheIntValue(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_getUserKey(key), value);
    } catch (e) {
      print('Error caching int value: $e');
    }
  }
  
  // Get cached integer value
  static Future<int?> getCachedIntValue(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_getUserKey(key));
    } catch (e) {
      print('Error retrieving cached int value: $e');
      return null;
    }
  }
  
  // Cache double value
  static Future<void> cacheDoubleValue(String key, double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_getUserKey(key), value);
    } catch (e) {
      print('Error caching double value: $e');
    }
  }
  
  // Get cached double value
  static Future<double?> getCachedDoubleValue(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_getUserKey(key));
    } catch (e) {
      print('Error retrieving cached double value: $e');
      return null;
    }
  }

  // Cache string value
  static Future<void> cacheStringValue(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_getUserKey(key), value);
    } catch (e) {
      print('Error caching string value: $e');
    }
  }
  
  // Get cached string value
  static Future<String?> getCachedStringValue(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_getUserKey(key));
    } catch (e) {
      print('Error retrieving cached string value: $e');
      return null;
    }
  }

  // Clear authentication cache
  static Future<void> clearAuthCache() async {
    try {
      print('StorageUtils: Clearing auth cache');
      final prefs = await SharedPreferences.getInstance();
      
      // Clear user role cache
      await prefs.remove(_userRoleKey);
      
      // Clear login state
      await prefs.remove(_isLoggedInKey);
      
      // Clear any cached user data
      await prefs.remove(_userKey);
      
      print('StorageUtils: Auth cache cleared successfully');
    } catch (e) {
      print('StorageUtils: Error clearing auth cache: $e');
    }
  }
}
