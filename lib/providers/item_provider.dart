import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/outbound_models.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'notification_provider.dart';
import '../utils/storage_utils.dart';
import 'dart:collection';
import '../services/mysql_database_service.dart';
import 'package:uuid/uuid.dart';

class ItemProvider extends ChangeNotifier {
  final Map<String, List<Item>> _itemsByCategory = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  final MySqlDatabaseService _databaseService = MySqlDatabaseService();

  // Track outbound transactions
  final Map<String, List<OutboundTransaction>> _outboundTransactions = {};

  final List<Item> _items = [];
  final Set<String> _categories = {};
  bool _isLoading = false;
  bool _hasInitiallyLoaded = false;
  String? _error;

  // Getters
  UnmodifiableListView<Item> get allItems => UnmodifiableListView(_items);
  UnmodifiableListView<String> get categories => UnmodifiableListView(_categories.toList());
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialLoad => !_hasInitiallyLoaded;

  ItemProvider() {
    print('ItemProvider initialized');
    _initializeDatabase();
    _loadItemsFromDatabase();
    _loadFromLocalStorage(); // Keep as fallback
  }

  Future<void> _initializeDatabase() async {
    try {
      await _databaseService.initializeDatabase();
      debugPrint('Database initialized successfully');
    } catch (e) {
      debugPrint('Error initializing database: $e');
    }
  }

  Future<void> _loadFromLocalStorage() async {
    print('Loading from local storage as fallback...');
    await loadFromLocalStorage();
  }

  // New method to load from MySQL database with optimization
  Future<void> _loadItemsFromDatabase() async {
    try {
      // Only set loading state if this is first load
      if (!_hasInitiallyLoaded) {
        _isLoading = true;
        notifyListeners();
      }
      
      // Clear existing data only on first load
      if (_items.isEmpty) {
        _itemsByCategory.clear();
        _items.clear();
      }
      
      // Make sure missing transactions are created if needed
      await _ensureProductsHaveTransactions();
      
      // Get all products from MySQL database with proper category information
      final products = await _databaseService.getAllProductsWithCategories()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        print('Database query timeout - returning empty list');
        return [];
      });
      
      for (var item in products) {
        // Avoid duplicates
        if (!_items.any((existingItem) => existingItem.id == item.id)) {
          if (!_itemsByCategory.containsKey(item.categoryId)) {
            _itemsByCategory[item.categoryId] = [];
          }
          _itemsByCategory[item.categoryId]!.add(item);
          _items.add(item);
        }
      }
      
      // Debug current transaction data after loading
      await _databaseService.debugTodaysTransactions();
      
      _isLoading = false;
      _hasInitiallyLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading items from MySQL database: $e');
      _error = e.toString();
      _isLoading = false;
      _hasInitiallyLoaded = true; // Mark as loaded even on error
      notifyListeners();
    }
  }
  
  // Make sure all products have at least one inbound transaction
  Future<void> _ensureProductsHaveTransactions() async {
    try {
      await _databaseService.migrateExistingProductsToTransactions();
    } catch (e) {
      debugPrint('Error ensuring products have transactions: $e');
    }
  }

  // Load remaining data in background
  Future<void> _loadRemainingDataInBackground() async {
    try {
      // Get all products without the initial ones
      final remainingProducts = await _databaseService.getRemainingProducts(100);
      
      // Add remaining products to the lists
      for (var item in remainingProducts) {
        // Check for duplicates before adding
        bool isDuplicate = _items.any((existingItem) => existingItem.id == item.id);
        if (!isDuplicate) {
          if (!_itemsByCategory.containsKey(item.categoryId)) {
            _itemsByCategory[item.categoryId] = [];
          }
          _itemsByCategory[item.categoryId]!.add(item);
          _items.add(item);
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading remaining items: $e');
    }
  }

  Future<void> _loadItemsFromFirestore() async {
    try {
      final QuerySnapshot result = await _firestore.collection('items').get();
      for (var doc in result.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final item = Item(
          id: doc.id,
          name: data['name'] as String,
          categoryId: data['categoryId'] as String,
          quantity: (data['quantity'] as num).toInt(),
          unit: data['unit'] as String,
          price: (data['price'] as num).toDouble(),
          barcode: data['barcode'] as String?,
          minLevel: data['minLevel'] != null
              ? (data['minLevel'] as num).toDouble()
              : null,
          dateAdded: data['dateAdded'] != null
              ? DateTime.parse(data['dateAdded'] as String)
              : DateTime.now(),
          createdAt: DateTime.now(),
          type: data['type'] ?? 'inbound',
        );

        // Check for duplicates before adding
        bool isDuplicate = _items.any((existingItem) => existingItem.id == item.id);
        if (!isDuplicate) {
          if (!_itemsByCategory.containsKey(item.categoryId)) {
            _itemsByCategory[item.categoryId] = [];
          }
          _itemsByCategory[item.categoryId]!.add(item);
          _items.add(item);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading items from Firestore: $e');
    }
  }

  List<Item> getItemsForCategory(String categoryId) {
    return _itemsByCategory[categoryId] ?? [];
  }

  // Method to get items by category ID (alias for getItemsForCategory)
  List<Item> getItemsByCategoryId(String categoryId) {
    return getItemsForCategory(categoryId);
  }

  // Get all category IDs
  List<String> getAllCategoryIds() {
    return _itemsByCategory.keys.toList();
  }

  // Get all items for a specific date
  List<Item> getItemsByDate(DateTime date) {
    final Map<String, Item> uniqueItems = {};
    try {
      for (final categoryItems in _itemsByCategory.values) {
        for (final item in categoryItems) {
          if (item.dateAdded?.year == date.year &&
              item.dateAdded?.month == date.month &&
              item.dateAdded?.day == date.day) {
            // Use item name as the key to avoid duplicates
            if (!uniqueItems.containsKey(item.name)) {
              uniqueItems[item.name] = item;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting items by date: $e');
    }
    return uniqueItems.values.toList();
  }

  // Cache keys
  static const String _cachedInboundQuantityKey = 'cached_inbound_quantity';
  static const String _cachedInboundCategoriesKey = 'cached_inbound_categories';
  static const String _cachedInboundValueKey = 'cached_inbound_value';
  static const String _cachedOutboundQuantityKey = 'cached_outbound_quantity';
  static const String _cachedOutboundCategoriesKey = 'cached_outbound_categories';
  static const String _cachedOutboundValueKey = 'cached_outbound_value';
  
  // Get total inbound quantity for a date - Database version with cache
  Future<int> getTotalInboundQuantityFromDB(DateTime date) async {
    try {
      final inboundQty = await _databaseService.getTotalInboundQuantityByDate(date);
      
      // Cache the result
      final key = '${formatDateForCacheKey(date)}_$_cachedInboundQuantityKey';
      await StorageUtils.cacheIntValue(key, inboundQty);
      
      return inboundQty;
    } catch (e) {
      debugPrint('Error getting inbound quantity from database: $e');
      
      // Try to get from cache first
      final key = '${formatDateForCacheKey(date)}_$_cachedInboundQuantityKey';
      final cachedValue = await StorageUtils.getCachedIntValue(key);
      if (cachedValue != null) {
        debugPrint('Using cached inbound quantity value: $cachedValue');
        return cachedValue;
      }
      
      // Fall back to in-memory calculation if database query fails and no cache
      return getTotalInboundQuantity(date);
    }
  }

  // Get total inbound categories for a date - Database version with cache
  Future<int> getTotalInboundCategoriesFromDB(DateTime date) async {
    try {
      final inboundCats = await _databaseService.getInboundCategoriesCountByDate(date);
      
      // Cache the result
      final key = '${formatDateForCacheKey(date)}_$_cachedInboundCategoriesKey';
      await StorageUtils.cacheIntValue(key, inboundCats);
      
      return inboundCats;
    } catch (e) {
      debugPrint('Error getting inbound categories from database: $e');
      
      // Try to get from cache first
      final key = '${formatDateForCacheKey(date)}_$_cachedInboundCategoriesKey';
      final cachedValue = await StorageUtils.getCachedIntValue(key);
      if (cachedValue != null) {
        debugPrint('Using cached inbound categories value: $cachedValue');
        return cachedValue;
      }
      
      // Fall back to in-memory calculation if database query fails and no cache
      return getTotalInboundCategories(date);
    }
  }

  // Get total inbound value for a date - Database version with cache
  Future<double> getTotalInboundValueFromDB(DateTime date) async {
    try {
      final inboundVal = await _databaseService.getTotalInboundValueByDate(date);
      
      // Cache the result
      final key = '${formatDateForCacheKey(date)}_$_cachedInboundValueKey';
      await StorageUtils.cacheDoubleValue(key, inboundVal);
      
      return inboundVal;
    } catch (e) {
      debugPrint('Error getting inbound value from database: $e');
      
      // Try to get from cache first
      final key = '${formatDateForCacheKey(date)}_$_cachedInboundValueKey';
      final cachedValue = await StorageUtils.getCachedDoubleValue(key);
      if (cachedValue != null) {
        debugPrint('Using cached inbound value: $cachedValue');
        return cachedValue;
      }
      
      // Fall back to in-memory calculation if database query fails and no cache
      return getTotalInboundValue(date);
    }
  }
  
  // Get total outbound quantity for a date - Database version with cache
  Future<int> getTotalOutboundQuantityFromDB(DateTime date) async {
    try {
      debugPrint("ItemProvider: Getting outbound quantity from database for ${date.toString()}");
      final outboundQty = await _databaseService.getTotalOutboundQuantityByDate(date);
      debugPrint("ItemProvider: Received outbound quantity from database: $outboundQty");
      
      // Cache the result
      final key = '${formatDateForCacheKey(date)}_$_cachedOutboundQuantityKey';
      await StorageUtils.cacheIntValue(key, outboundQty);
      
      return outboundQty;
    } catch (e) {
      debugPrint('Error getting outbound quantity from database: $e');
      
      // Try to get from cache first
      final key = '${formatDateForCacheKey(date)}_$_cachedOutboundQuantityKey';
      final cachedValue = await StorageUtils.getCachedIntValue(key);
      if (cachedValue != null) {
        debugPrint('Using cached outbound quantity value: $cachedValue');
        return cachedValue;
      }
      
      // Fall back to in-memory calculation if database query fails and no cache
      return getTotalOutboundQuantity(date);
    }
  }
  
  // Get total outbound categories for a date - Database version with cache
  Future<int> getTotalOutboundCategoriesFromDB(DateTime date) async {
    try {
      final outboundCats = await _databaseService.getOutboundCategoriesCountByDate(date);
      
      // Cache the result
      final key = '${formatDateForCacheKey(date)}_$_cachedOutboundCategoriesKey';
      await StorageUtils.cacheIntValue(key, outboundCats);
      
      return outboundCats;
    } catch (e) {
      debugPrint('Error getting outbound categories from database: $e');
      
      // Try to get from cache first
      final key = '${formatDateForCacheKey(date)}_$_cachedOutboundCategoriesKey';
      final cachedValue = await StorageUtils.getCachedIntValue(key);
      if (cachedValue != null) {
        debugPrint('Using cached outbound categories value: $cachedValue');
        return cachedValue;
      }
      
      // Fall back to in-memory calculation if database query fails and no cache
      return getTotalOutboundCategories(date);
    }
  }
  
  // Get total outbound value for a date - Database version with cache
  Future<double> getTotalOutboundValueFromDB(DateTime date) async {
    try {
      final outboundVal = await _databaseService.getTotalOutboundValueByDate(date);
      
      // Cache the result
      final key = '${formatDateForCacheKey(date)}_$_cachedOutboundValueKey';
      await StorageUtils.cacheDoubleValue(key, outboundVal);
      
      return outboundVal;
    } catch (e) {
      debugPrint('Error getting outbound value from database: $e');
      
      // Try to get from cache first
      final key = '${formatDateForCacheKey(date)}_$_cachedOutboundValueKey';
      final cachedValue = await StorageUtils.getCachedDoubleValue(key);
      if (cachedValue != null) {
        debugPrint('Using cached outbound value: $cachedValue');
        return cachedValue;
      }
      
      // Fall back to in-memory calculation if database query fails and no cache
      return getTotalOutboundValue(date);
    }
  }

  // Format date for cache key
  String formatDateForCacheKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  // Get outbound transactions for a date
  List<OutboundTransaction> getOutboundTransactionsByDate(DateTime date) {
    final List<OutboundTransaction> transactions = [];
    try {
      for (final categoryTransactions in _outboundTransactions.values) {
        transactions.addAll(categoryTransactions.where((transaction) {
          return transaction.date.year == date.year &&
              transaction.date.month == date.month &&
              transaction.date.day == date.day;
        }));
      }
    } catch (e) {
      debugPrint('Error getting outbound transactions by date: $e');
    }
    return transactions;
  }

  // Original in-memory methods kept for compatibility and fallback

  // Get total inbound quantity for a date
  int getTotalInboundQuantity(DateTime date) {
    final filteredItems = _items.where(
      (item) => 
          item.type == 'inbound' && 
          item.createdAt.year == date.year &&
          item.createdAt.month == date.month &&
          item.createdAt.day == date.day
    );
    
    return filteredItems.fold(0, (sum, item) => sum + item.quantity);
  }

  // Get total inbound categories for a date
  int getTotalInboundCategories(DateTime date) {
    final filteredItems = _items.where(
      (item) => 
          item.type == 'inbound' && 
          item.createdAt.year == date.year &&
          item.createdAt.month == date.month &&
          item.createdAt.day == date.day
    );
    
    return filteredItems.map((item) => item.categoryId).toSet().length;
  }

  // Get total inbound value for a date
  double getTotalInboundValue(DateTime date) {
    final filteredItems = _items.where(
      (item) => 
          item.type == 'inbound' && 
          item.createdAt.year == date.year &&
          item.createdAt.month == date.month &&
          item.createdAt.day == date.day
    );
    
    return filteredItems.fold(0.0, (sum, item) => sum + item.totalValue);
  }

  // Get total outbound quantity for a date
  int getTotalOutboundQuantity(DateTime date) {
    final filteredItems = _items.where(
      (item) => 
          item.type == 'outbound' && 
          item.createdAt.year == date.year &&
          item.createdAt.month == date.month &&
          item.createdAt.day == date.day
    );
    
    return filteredItems.fold(0, (sum, item) => sum + item.quantity);
  }

  // Get total outbound categories for a date
  int getTotalOutboundCategories(DateTime date) {
    final filteredItems = _items.where(
      (item) => 
          item.type == 'outbound' && 
          item.createdAt.year == date.year &&
          item.createdAt.month == date.month &&
          item.createdAt.day == date.day
    );
    
    return filteredItems.map((item) => item.categoryId).toSet().length;
  }

  // Get total outbound value for a date
  double getTotalOutboundValue(DateTime date) {
    final filteredItems = _items.where(
      (item) => 
          item.type == 'outbound' && 
          item.createdAt.year == date.year &&
          item.createdAt.month == date.month &&
          item.createdAt.day == date.day
    );
    
    return filteredItems.fold(0.0, (sum, item) => sum + item.totalValue);
  }

  // Get all items across all categories
  List<Item> getAllItems() {
    final List<Item> allItems = [];
    for (final items in _itemsByCategory.values) {
      allItems.addAll(items);
    }
    return allItems;
  }

  // Check stock levels and notify if needed
  void _checkStockLevels(BuildContext context) {
    final notificationProvider = context.read<NotificationProvider>();
    final allItems = getAllItems();
    notificationProvider.checkStockLevels(allItems);
  }

  // Add a new item to a category
  Future<void> addItem(Item item) async {
    bool databaseSuccess = false;
    try {
      // First add to MySQL database with retry mechanism
      await _addProductWithRetry(item);
      databaseSuccess = true;
      
      // Set the dateAdded field explicitly for the item
      final itemWithDate = item.copyWith(
        dateAdded: DateTime.now(),
        createdAt: DateTime.now()
      );
      
      // Verify the product exists before adding transaction
      final verificationResult = await _verifyAndAddTransaction(item);
      
      if (!verificationResult) {
        debugPrint('Warning: Transaction verification failed but product was added; continuing');
      }
      
      // Update local collections regardless of transaction outcome
      if (!_itemsByCategory.containsKey(item.categoryId)) {
        _itemsByCategory[item.categoryId] = [];
      }
      
      _itemsByCategory[item.categoryId]!.add(itemWithDate);
      _items.add(itemWithDate);
      
      // Also save to Firestore as a fallback
      try {
        await _firestore.collection('items').doc(item.id).set(itemWithDate.toMap());
      } catch (e) {
        print('Error saving to Firestore (not critical): $e');
      }
      
      notifyListeners();
    } catch (e) {
      print('Error adding item: $e');
      // Only throw an exception if the database operation failed
      // This prevents UI errors from showing the "Failed to save" message
      if (!databaseSuccess) {
        throw Exception('Failed to add item to database: $e');
      }
    }
  }
  
  // Helper method to add product with retry
  Future<void> _addProductWithRetry(Item item) async {
    int retries = 0;
    const maxRetries = 3;
    Exception? lastException;
    
    while (retries < maxRetries) {
      try {
        await _databaseService.addProduct(item);
        debugPrint('Successfully added product ${item.id} to database on attempt ${retries + 1}');
        return; // Success, exit the loop
      } catch (e) {
        // If this is a duplicate entry error, the product already exists in the database
        // so we can consider this a success
        if (e.toString().contains('Duplicate entry')) {
          debugPrint('Product ${item.id} already exists in database, considering as success');
          return;
        }
        
        lastException = Exception('Failed to add product on attempt ${retries + 1}: $e');
        debugPrint(lastException.toString());
        retries++;
        
        // Wait before retrying
        await Future.delayed(Duration(milliseconds: 300 * retries));
      }
    }
    
    // If we get here, all retries failed
    throw lastException ?? Exception('Failed to add product after $maxRetries attempts');
  }
  
  // Helper method to verify product exists and add transaction
  Future<bool> _verifyAndAddTransaction(Item item) async {
    int retries = 0;
    const maxRetries = 3;
    
    while (retries < maxRetries) {
      try {
        // Wait to ensure the product is properly saved
        await Future.delayed(Duration(milliseconds: 300 * (retries + 1)));
        
        // Verify the product exists
        final productExists = await _databaseService.doesProductExist(item.id);
        if (!productExists) {
          debugPrint('Warning: Product ${item.id} not found after adding (attempt ${retries + 1})');
          retries++;
          continue; // Try again
        }
        
        // Generate a unique transaction ID
        final transactionId = const Uuid().v4();
        
        // Record an inbound transaction for this item
        await _databaseService.addInboundTransaction(
          transactionId,
          item.id,
          item.quantity,
          DateTime.now()
        );
        
        debugPrint('Successfully recorded inbound transaction $transactionId for item ${item.id}');
        
        // Debug today's transactions
        await _databaseService.debugTodaysTransactions();
        
        return true; // Success
      } catch (e) {
        debugPrint('Error in transaction processing (attempt ${retries + 1}): $e');
        retries++;
      }
    }
    
    debugPrint('Warning: Failed to process transaction after $maxRetries attempts; product may still have been added');
    return false;
  }

  // Update an existing item
  Future<void> updateItem(Item updatedItem) async {
    bool databaseSuccess = false;
    try {
      // First update in MySQL database
      await _databaseService.updateProduct(updatedItem);
      databaseSuccess = true;
      
      // Then update local lists
      if (_itemsByCategory.containsKey(updatedItem.categoryId)) {
        final index = _itemsByCategory[updatedItem.categoryId]!.indexWhere(
          (item) => item.id == updatedItem.id,
        );
        
        if (index != -1) {
          _itemsByCategory[updatedItem.categoryId]![index] = updatedItem;
        } else {
          _itemsByCategory[updatedItem.categoryId]!.add(updatedItem);
        }
      } else {
        _itemsByCategory[updatedItem.categoryId] = [updatedItem];
      }
      
      // Update in main items list
      final allItemIndex = _items.indexWhere((item) => item.id == updatedItem.id);
      if (allItemIndex != -1) {
        _items[allItemIndex] = updatedItem;
      } else {
        _items.add(updatedItem);
      }
      
      // Also update in Firestore as a fallback
      try {
        await _firestore.collection('items').doc(updatedItem.id).set(updatedItem.toMap());
      } catch (e) {
        print('Error updating in Firestore (not critical): $e');
      }
      
      notifyListeners();
    } catch (e) {
      print('Error updating item: $e');
      // Only throw if database operation failed
      if (!databaseSuccess) {
        throw Exception('Failed to update item in database: $e');
      }
      
      // Fallback to just local update if database operation succeeded but there was another error
      if (_itemsByCategory.containsKey(updatedItem.categoryId)) {
        final index = _itemsByCategory[updatedItem.categoryId]!.indexWhere(
          (item) => item.id == updatedItem.id,
        );
        
        if (index != -1) {
          _itemsByCategory[updatedItem.categoryId]![index] = updatedItem;
        } else {
          _itemsByCategory[updatedItem.categoryId]!.add(updatedItem);
        }
      } else {
        _itemsByCategory[updatedItem.categoryId] = [updatedItem];
      }
      
      // Update in main items list
      final allItemIndex = _items.indexWhere((item) => item.id == updatedItem.id);
      if (allItemIndex != -1) {
        _items[allItemIndex] = updatedItem;
      } else {
        _items.add(updatedItem);
      }
      
      notifyListeners();
    }
  }

  void removeItem(String categoryId, String itemId) async {
    try {
      // Set loading state
      _isLoading = true;
      notifyListeners();
      
      debugPrint('Removing item $itemId from category $categoryId');
      
      // First remove from MySQL database
      await _databaseService.deleteProduct(itemId);
      
      // Then update local collections
      if (_itemsByCategory.containsKey(categoryId)) {
        _itemsByCategory[categoryId]!.removeWhere((item) => item.id == itemId);
        debugPrint('Removed item from category collection, remaining items: ${_itemsByCategory[categoryId]!.length}');
      }
      
      _items.removeWhere((item) => item.id == itemId);
      debugPrint('Removed item from main collection, remaining items: ${_items.length}');
      
      // Double-check that the item is gone from the database
      bool stillExists = await _databaseService.doesProductExist(itemId);
      if (stillExists) {
        debugPrint('WARNING: Item $itemId still exists in database after deletion!');
        // Try deletion again
        await _databaseService.deleteProduct(itemId);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing item: $e');
      
      // Fallback to just updating local collections
      if (_itemsByCategory.containsKey(categoryId)) {
        _itemsByCategory[categoryId]!.removeWhere((item) => item.id == itemId);
      }
      _items.removeWhere((item) => item.id == itemId);
      
      _isLoading = false;
      notifyListeners();
    }
  }

  void deleteItemsInCategory(String categoryId) async {
    try {
      // Get all items in the category
      final items = _itemsByCategory[categoryId] ?? [];
      
      // Delete each item from MySQL database
      for (var item in items) {
        await _databaseService.deleteProduct(item.id);
      }
      
      // Then update local collections
      _itemsByCategory.remove(categoryId);
      _items.removeWhere((item) => item.categoryId == categoryId);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting items in category: $e');
      
      // Fallback to just updating local collections
      _itemsByCategory.remove(categoryId);
      _items.removeWhere((item) => item.categoryId == categoryId);
      
      notifyListeners();
    }
  }

  // Force reload from database with timeout
  Future<void> reloadFromDatabase() async {
    try {
      await _loadItemsFromDatabase().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('Database reload timeout');
          _isLoading = false;
          _hasInitiallyLoaded = true;
          notifyListeners();
        },
      );
      
      // Debug transaction data after reloading
      await _databaseService.debugTodaysTransactions();
    } catch (e) {
      debugPrint('Error reloading from database: $e');
      _isLoading = false;
      _hasInitiallyLoaded = true;
      notifyListeners();
    }
  }
  
  // Keep legacy method for backward compatibility
  Future<void> loadFromLocalStorage() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _loadItemsFromDatabase();
    } catch (e) {
      debugPrint('Error loading data from database: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Public method to force reload data from local storage (kept for compatibility)
  Future<void> reloadFromLocalStorage() async {
    print('Forcing reload from database');
    // Clear existing data first
    _itemsByCategory.clear();
    _items.clear();
    await _loadItemsFromDatabase();
  }

  // Method to force regenerate transaction data
  Future<void> forceRegenerateTransactionData() async {
    try {
      debugPrint('Regenerating missing transaction data...');
      
      // Instead of deleting all transactions, find products that don't have transactions
      final conn = await _databaseService.connection;
      
      // Find products with no inbound transactions
      final productsWithNoInbound = await conn.query('''
        SELECT p.* FROM products p
        LEFT JOIN (
          SELECT DISTINCT item_id FROM inbound_transactions
        ) t ON p.id = t.item_id
        WHERE t.item_id IS NULL
      ''');
      
      debugPrint('Found ${productsWithNoInbound.length} products with no inbound transactions');
      
      // Create inbound transactions only for products that don't have any
      for (var row in productsWithNoInbound) {
        try {
          final productId = row['id'].toString();
          final quantity = row['quantity'] != null ? int.parse(row['quantity'].toString()) : 1;
          
          // Create a new transaction with current timestamp
          final transactionId = const Uuid().v4();
          await _databaseService.addInboundTransaction(
            transactionId,
            productId,
            quantity,
            DateTime.now()
          );
          
          debugPrint('Created missing inbound transaction for product $productId');
        } catch (e) {
          debugPrint('Error creating transaction for product ${row['id']}: $e');
        }
      }
      
      debugPrint('Transaction data regeneration completed');
    } catch (e) {
      debugPrint('Error regenerating transaction data: $e');
    }
  }

  // Check if an item with the same name or barcode already exists in any category
  Map<String, dynamic>? checkItemExistsInAnyCategory(String name, String? barcode) {
    if (barcode != null && barcode.isNotEmpty) {
      // First check if the barcode exists
      for (final categoryId in _itemsByCategory.keys) {
        final categoryItems = _itemsByCategory[categoryId]!;
        
        for (final item in categoryItems) {
          if (item.barcode == barcode) {
            return {
              'exists': true,
              'categoryId': categoryId,
              'item': item,
              'message': 'An item with this barcode already exists in another category'
            };
          }
        }
      }
    }
    
    // Then check if the name exists (case insensitive)
    final normalizedName = name.trim().toLowerCase();
    for (final categoryId in _itemsByCategory.keys) {
      final categoryItems = _itemsByCategory[categoryId]!;
      
      for (final item in categoryItems) {
        if (item.name.trim().toLowerCase() == normalizedName) {
          return {
            'exists': true,
            'categoryId': categoryId,
            'item': item,
            'message': 'An item with this name already exists in another category'
          };
        }
      }
    }
    
    return null; // Item doesn't exist in any category
  }

  Future<bool> checkBarcodeExists(String barcode) async {
    try {
      // First check local items
      for (final categoryItems in _itemsByCategory.values) {
        if (categoryItems.any((item) => item.barcode == barcode)) {
          return true;
        }
      }

      // Then check Firestore
      final QuerySnapshot result = await _firestore
          .collection('items')
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();

      return result.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking barcode: $e');
      return false;
    }
  }

  Future<List<Item>> getItemsByBarcode(String barcode) async {
    List<Item> matchingItems = [];
    try {
      // First check local items
      for (final categoryId in _itemsByCategory.keys) {
        final categoryItems = _itemsByCategory[categoryId]!;
        final items =
            categoryItems.where((item) => item.barcode == barcode).toList();
        matchingItems.addAll(items);
      }

      // If no items found locally, check Firestore
      if (matchingItems.isEmpty) {
        final QuerySnapshot result = await _firestore
            .collection('items')
            .where('barcode', isEqualTo: barcode)
            .get();

        for (var doc in result.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final item = Item(
            id: doc.id,
            name: data['name'] ?? '',
            categoryId: data['categoryId'] ?? '',
            quantity: (data['quantity'] ?? 0) is int ? (data['quantity'] ?? 0) : (data['quantity'] ?? 0).toInt(),
            unit: data['unit'] ?? 'pcs',
            price: (data['price'] ?? 0.0).toDouble(),
            barcode: data['barcode'],
            minLevel: data['minLevel'] != null
                ? (data['minLevel'] as num).toDouble()
                : null,
            dateAdded: data['dateAdded'] != null
                ? DateTime.parse(data['dateAdded'] as String)
                : DateTime.now(),
            createdAt: DateTime.now(),
            type: data['type'] ?? 'inbound',
          );
          matchingItems.add(item);
        }
      }

      return matchingItems;
    } catch (e) {
      debugPrint('Error getting items by barcode: $e');
      return [];
    }
  }

  // Keep the old method for backward compatibility but make it use the new one
  Future<Item?> getItemByBarcode(String barcode) async {
    final items = await getItemsByBarcode(barcode);
    return items.isNotEmpty ? items.first : null;
  }

  // Record an outbound transaction
  Future<void> recordOutboundTransaction(Item item, int quantity) async {
    // Validation check - ensure we're not outbounding more than available
    if (quantity <= 0) {
      debugPrint('Invalid outbound quantity: $quantity');
      return;
    }
    
    if (quantity > item.quantity) {
      debugPrint('Cannot outbound more than available: $quantity > ${item.quantity}');
      throw Exception('Cannot outbound more than available stock');
    }
    
    // Create the transaction record
    final transaction = OutboundTransaction(
      item: item,
      quantity: quantity,
      date: DateTime.now(),
    );
    
    // Generate a unique ID for the transaction
    final transactionId = const Uuid().v4();

    // Add to transactions list
    if (!_outboundTransactions.containsKey(item.categoryId)) {
      _outboundTransactions[item.categoryId] = [];
    }
    _outboundTransactions[item.categoryId]!.add(transaction);
    
    // Create transaction in database
    try {
      // Add the outbound transaction record
      await _databaseService.addOutboundTransaction(
        transactionId,
        item.id,
        quantity,
        DateTime.now()
      );
      
      debugPrint('Successfully recorded outbound transaction $transactionId for item ${item.id}');
      
      // Debug today's transactions
      await _databaseService.debugTodaysTransactions();
    } catch (e) {
      debugPrint('Error recording outbound transaction to database: $e');
      // Continue with quantity update even if transaction recording fails
    }

    // Update the item's quantity in our local state
    if (_itemsByCategory.containsKey(item.categoryId)) {
      final itemIndex = _itemsByCategory[item.categoryId]!.indexWhere((i) => i.id == item.id);
      if (itemIndex != -1) {
        final updatedItem = _itemsByCategory[item.categoryId]![itemIndex];
        final newQuantity = (updatedItem.quantity - quantity).clamp(0, double.infinity).toInt();
        
        // Update local item object
        _itemsByCategory[item.categoryId]![itemIndex] = updatedItem.copyWith(quantity: newQuantity);
        
        // Also update in the main items list
        final allItemIndex = _items.indexWhere((i) => i.id == item.id);
        if (allItemIndex != -1) {
          _items[allItemIndex] = _items[allItemIndex].copyWith(quantity: newQuantity);
        }
        
        // Update in database
        try {
          await _databaseService.updateProductQuantity(item.id, newQuantity);
          debugPrint('Updated quantity in database for ${item.name}: $newQuantity');
        } catch (e) {
          debugPrint('Error updating product quantity in database: $e');
          throw Exception('Failed to update quantity in database: $e');
        }
      } else {
        debugPrint('Item not found in category: ${item.id}');
        throw Exception('Item not found in category');
      }
    } else {
      debugPrint('Category not found: ${item.categoryId}');
      throw Exception('Category not found');
    }

    // Save to local storage
    StorageUtils.saveOutboundTransaction(item, quantity);

    notifyListeners();
    
    // Check stock levels after recording outbound transaction
    try {
      if (navigatorKey.currentContext != null) {
        _checkStockLevels(navigatorKey.currentContext!);
      }
    } catch (e) {
      debugPrint('Error checking stock levels: $e');
    }
  }

  // Record an inbound transaction 
  Future<void> recordInboundTransaction(Item item, int quantity) async {
    // Validation check
    if (quantity <= 0) {
      debugPrint('Invalid inbound quantity: $quantity');
      return;
    }
    
    // Generate a unique ID for the transaction
    final transactionId = const Uuid().v4();
    
    // Create transaction in database
    try {
      // Add the inbound transaction record
      await _databaseService.addInboundTransaction(
        transactionId,
        item.id,
        quantity,
        DateTime.now()
      );
      
      debugPrint('Successfully recorded inbound transaction $transactionId for item ${item.id}');
      
      // Debug today's transactions
      await _databaseService.debugTodaysTransactions();
    } catch (e) {
      debugPrint('Error recording inbound transaction to database: $e');
      throw Exception('Failed to record inbound transaction: $e');
    }

    // Update the item's quantity in our local state
    if (_itemsByCategory.containsKey(item.categoryId)) {
      final itemIndex = _itemsByCategory[item.categoryId]!.indexWhere((i) => i.id == item.id);
      if (itemIndex != -1) {
        final updatedItem = _itemsByCategory[item.categoryId]![itemIndex];
        final newQuantity = updatedItem.quantity + quantity;
        
        // Update local item object
        _itemsByCategory[item.categoryId]![itemIndex] = updatedItem.copyWith(quantity: newQuantity);
        
        // Also update in the main items list
        final allItemIndex = _items.indexWhere((i) => i.id == item.id);
        if (allItemIndex != -1) {
          _items[allItemIndex] = _items[allItemIndex].copyWith(quantity: newQuantity);
        }
        
        // Update in database
        try {
          await _databaseService.updateProductQuantity(item.id, newQuantity);
          debugPrint('Updated quantity in database for ${item.name}: $newQuantity');
        } catch (e) {
          debugPrint('Error updating product quantity in database: $e');
          throw Exception('Failed to update quantity in database: $e');
        }
      } else {
        debugPrint('Item not found in category: ${item.id}');
        throw Exception('Item not found in category');
      }
    } else {
      debugPrint('Category not found: ${item.categoryId}');
      throw Exception('Category not found');
    }

    notifyListeners();
  }

  // Get all items with the same name and barcode across all categories
  List<Item> getAllItemsWithSameNameAndBarcode(Item referenceItem) {
    List<Item> matchingItems = [];

    for (final categoryId in _itemsByCategory.keys) {
      final categoryItems = _itemsByCategory[categoryId]!;
      final items = categoryItems
          .where((item) =>
              item.name == referenceItem.name &&
              item.barcode == referenceItem.barcode)
          .toList();

      matchingItems.addAll(items);
    }

    return matchingItems;
  }

  // New method to refresh items for a specific category
  Future<void> refreshCategoryItems(String categoryId) async {
    try {
      final items = await _databaseService.getProductsByCategory(categoryId);
      
      // Update only the items for this category
      if (_itemsByCategory.containsKey(categoryId)) {
        // Remove existing items for this category from the main list
        _items.removeWhere((item) => item.categoryId == categoryId);
        
        // Replace the category's items with new ones
        _itemsByCategory[categoryId] = items;
        
        // Add new items to the main list
        _items.addAll(items);
      } else {
        // If the category doesn't exist yet, just add the items
        _itemsByCategory[categoryId] = items;
        _items.addAll(items);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing category items: $e');
    }
  }

  // Public method to check and fix transaction data
  Future<void> refreshTransactionData() async {
    try {
      debugPrint('Refreshing transaction data...');
      
      // Check for products with no inbound transactions
      await _databaseService.migrateExistingProductsToTransactions();
      
      // Debug current transaction data
      await _databaseService.debugTodaysTransactions();
      
      // Force reload dashboard data
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing transaction data: $e');
    }
  }

  // Add export functionality methods
  Future<void> exportProducts(DateTime date) async {
    try {
      // Get all products
      if (_items.isEmpty) {
        await reloadFromDatabase();
      }
      
      // Create CSV data
      final csvData = StringBuffer();
      
      // Add header
      csvData.writeln('ID,Name,Category,Quantity,Unit,Price,Barcode,Minimum Level,Date Added');
      
      // Add rows
      for (var item in _items) {
        csvData.writeln(
          '${item.id},${item.name.replaceAll(',', ' ')},${item.categoryName ?? 'Unknown'},${item.quantity},${item.unit},${item.price},${item.barcode ?? ''},${item.minLevel ?? ''},${item.dateAdded?.toIso8601String() ?? ''}'
        );
      }
      
      // Log completion 
      debugPrint('Products data ready for export: ${_items.length} items');
      
      // Export would typically save to a file here
      // For now, we'll just simulate a successful export
      
      return Future.value();
    } catch (e) {
      debugPrint('Error exporting products: $e');
      throw Exception('Failed to export products: $e');
    }
  }
  
  Future<void> exportCategories() async {
    try {
      // Access categories through BuildContext in the calling method
      // Simulating category data since we don't have direct access to CategoryProvider
      final List<Map<String, dynamic>> categoryData = [];
      
      // Get unique category IDs from our items
      final categoryIds = getAllCategoryIds();
      
      // Create fake category data based on items we have
      for (var categoryId in categoryIds) {
        final items = getItemsForCategory(categoryId);
        if (items.isNotEmpty) {
          final categoryName = items.first.categoryName ?? 'Unknown Category';
          categoryData.add({
            'id': categoryId,
            'name': categoryName,
            'description': '',
            'itemCount': items.length
          });
        }
      }
      
      // Create CSV data
      final csvData = StringBuffer();
      
      // Add header
      csvData.writeln('ID,Name,Item Count');
      
      // Add rows
      for (var category in categoryData) {
        csvData.writeln(
          '${category['id']},${category['name'].toString().replaceAll(',', ' ')},${category['itemCount']}'
        );
      }
      
      // Log completion
      debugPrint('Categories data ready for export: ${categoryData.length} categories');
      
      // Export would typically save to a file here
      // For now, we'll just simulate a successful export
      
      return Future.value();
    } catch (e) {
      debugPrint('Error exporting categories: $e');
      throw Exception('Failed to export categories: $e');
    }
  }
  
  Future<void> exportTransactions(DateTime date) async {
    try {
      // Get transactions for the date
      final inboundCount = await getTotalInboundQuantityFromDB(date);
      final outboundCount = await getTotalOutboundQuantityFromDB(date);
      
      // Create CSV data
      final csvData = StringBuffer();
      
      // Add header
      csvData.writeln('Date,Type,Inbound Quantity,Outbound Quantity,Inbound Categories,Outbound Categories');
      
      // Add transaction summary
      final inboundCategories = await getTotalInboundCategoriesFromDB(date);
      final outboundCategories = await getTotalOutboundCategoriesFromDB(date);
      csvData.writeln(
        '${date.toIso8601String()},Summary,$inboundCount,$outboundCount,$inboundCategories,$outboundCategories'
      );
      
      // Log completion
      debugPrint('Transactions data ready for export for date: ${date.toIso8601String()}');
      
      // Export would typically save to a file here
      // For now, we'll just simulate a successful export
      
      return Future.value();
    } catch (e) {
      debugPrint('Error exporting transactions: $e');
      throw Exception('Failed to export transactions: $e');
    }
  }
}
