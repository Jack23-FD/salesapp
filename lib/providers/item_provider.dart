import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/outbound_models.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'notification_provider.dart';
import '../utils/storage_utils.dart';
import 'dart:collection';
import '../services/api_service.dart';

class ItemProvider extends ChangeNotifier {
  final Map<String, List<Item>> _itemsByCategory = {};
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final ApiService _apiService = ApiService();

  // Track outbound transactions
  final Map<String, List<OutboundTransaction>> _outboundTransactions = {};

  final List<Item> _items = [];
  final Set<String> _categories = {};
  bool _isLoading = false;
  bool _hasInitiallyLoaded = false;
  String? _error;

  // Cache for PHP API statistics to avoid redundant HTTP calls
  final Map<String, Map<String, dynamic>> _cachedStatsByDate = {};

  // Getters
  UnmodifiableListView<Item> get allItems => UnmodifiableListView(_items);
  UnmodifiableListView<String> get categories => UnmodifiableListView(_categories.toList());
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialLoad => !_hasInitiallyLoaded;

  ItemProvider() {
    print('ItemProvider initialized with PHP API');
    _loadItemsFromDatabase();
    _loadFromLocalStorage(); // Keep as fallback
  }

  Future<void> _loadFromLocalStorage() async {
    print('Loading from local storage as fallback...');
    await loadFromLocalStorage();
  }

  // Load items from PHP API database
  Future<void> _loadItemsFromDatabase() async {
    try {
      if (!_hasInitiallyLoaded) {
        _isLoading = true;
        notifyListeners();
      }
      
      print('Loading items from PHP API backend...');
      final products = await _apiService.getProducts();

      _itemsByCategory.clear();
      _items.clear();
      _categories.clear();
      
      for (var item in products) {
        if (!_items.any((existingItem) => existingItem.id == item.id)) {
          if (!_itemsByCategory.containsKey(item.categoryId)) {
            _itemsByCategory[item.categoryId] = [];
          }
          _itemsByCategory[item.categoryId]!.add(item);
          _items.add(item);
          _categories.add(item.categoryId);
        }
      }
      
      _isLoading = false;
      _hasInitiallyLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading items from PHP API: $e');
      _error = e.toString();
      _isLoading = false;
      _hasInitiallyLoaded = true; 
      notifyListeners();
      
      // Fallback: Populate mock items when offline
      if (_items.isEmpty) {
        print('Populating mock items for offline testing...');
        final mockItems = [
          Item(
            id: 'item_coke',
            name: 'Coca-Cola 330ml',
            categoryId: 'cat_beverages',
            quantity: 50,
            unit: 'pcs',
            price: 1.50,
            createdAt: DateTime.now(),
            categoryName: 'Beverages',
            barcode: '1234567890123',
          ),
        ];
        
        for (var item in mockItems) {
          if (!_itemsByCategory.containsKey(item.categoryId)) {
            _itemsByCategory[item.categoryId] = [];
          }
          _itemsByCategory[item.categoryId]!.add(item);
          _items.add(item);
          _categories.add(item.categoryId);
        }
        notifyListeners();
      }
    }
  }

  // Helper to fetch statistics with local in-memory cache caching
  Future<Map<String, dynamic>> _getOrFetchStats(DateTime date) async {
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (_cachedStatsByDate.containsKey(dateKey)) {
      return _cachedStatsByDate[dateKey]!;
    }
    
    try {
      final stats = await _apiService.getStats(dateKey);
      _cachedStatsByDate[dateKey] = stats;
      return stats;
    } catch (e) {
      debugPrint('Failed to get stats for $dateKey: $e');
      return {
        'inbound': {'units': 0, 'categories': 0, 'value': 0.0},
        'outbound': {'units': 0, 'categories': 0, 'value': 0.0}
      };
    }
  }

  Future<int> getTotalInboundQuantityFromDB(DateTime date) async {
    final stats = await _getOrFetchStats(date);
    return stats['inbound']['units'] as int;
  }

  Future<int> getTotalInboundCategoriesFromDB(DateTime date) async {
    final stats = await _getOrFetchStats(date);
    return stats['inbound']['categories'] as int;
  }

  Future<double> getTotalInboundValueFromDB(DateTime date) async {
    final stats = await _getOrFetchStats(date);
    return (stats['inbound']['value'] as num).toDouble();
  }
  
  Future<int> getTotalOutboundQuantityFromDB(DateTime date) async {
    final stats = await _getOrFetchStats(date);
    return stats['outbound']['units'] as int;
  }
  
  Future<int> getTotalOutboundCategoriesFromDB(DateTime date) async {
    final stats = await _getOrFetchStats(date);
    return stats['outbound']['categories'] as int;
  }
  
  Future<double> getTotalOutboundValueFromDB(DateTime date) async {
    final stats = await _getOrFetchStats(date);
    return (stats['outbound']['value'] as num).toDouble();
  }

  List<OutboundTransaction> getOutboundTransactionsByDate(DateTime date) {
    final List<OutboundTransaction> transactions = [];
    for (final categoryTransactions in _outboundTransactions.values) {
      transactions.addAll(categoryTransactions.where((t) =>
          t.date.year == date.year && t.date.month == date.month && t.date.day == date.day));
    }
    return transactions;
  }

  List<Item> getItemsByCategory(String categoryId) {
    return _itemsByCategory[categoryId] ?? [];
  }

  Future<List<Item>> getItemsByBarcode(String barcode) async {
    return _items.where((item) => item.barcode == barcode).toList();
  }

  Future<Item?> getItemByBarcode(String barcode) async {
    final items = await getItemsByBarcode(barcode);
    return items.isNotEmpty ? items.first : null;
  }

  // Add a new item
  Future<void> addItem(Item item) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _apiService.createProduct(item);
      
      // Reload product listing from API
      await _loadItemsFromDatabase();
    } catch (e) {
      print('Error adding item to API: $e');
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to add item: $e');
    }
  }

  // Update item details
  Future<void> updateItem(Item updatedItem) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _apiService.updateProduct(updatedItem);
      await _loadItemsFromDatabase();
    } catch (e) {
      print('Error updating item on API: $e');
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to update item: $e');
    }
  }

  // Delete product
  Future<void> deleteItem(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _apiService.deleteProduct(id);
      await _loadItemsFromDatabase();
    } catch (e) {
      print('Error deleting product from API: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Record an outbound transaction
  Future<void> recordOutboundTransaction(Item item, int quantity) async {
    if (quantity <= 0) return;
    if (quantity > item.quantity) {
      throw Exception('Cannot outbound more than available stock');
    }

    try {
      final res = await _apiService.recordTransaction(item.id, quantity, 'outbound');
      final newQty = res['newQuantity'] as int;

      // Update local state quantity
      if (_itemsByCategory.containsKey(item.categoryId)) {
        final itemIndex = _itemsByCategory[item.categoryId]!.indexWhere((i) => i.id == item.id);
        if (itemIndex != -1) {
          _itemsByCategory[item.categoryId]![itemIndex] = 
              _itemsByCategory[item.categoryId]![itemIndex].copyWith(quantity: newQty);
        }
      }
      final allIndex = _items.indexWhere((i) => i.id == item.id);
      if (allIndex != -1) {
        _items[allIndex] = _items[allIndex].copyWith(quantity: newQty);
      }

      // Clear cache stats key for today
      _cachedStatsByDate.clear();
      notifyListeners();
      
      if (navigatorKey.currentContext != null) {
        _checkStockLevels(navigatorKey.currentContext!);
      }
    } catch (e) {
      debugPrint('Error recording outbound transaction: $e');
      throw Exception('Failed to record outbound transaction: $e');
    }
  }

  // Record an inbound transaction
  Future<void> recordInboundTransaction(Item item, int quantity) async {
    if (quantity <= 0) return;

    try {
      final res = await _apiService.recordTransaction(item.id, quantity, 'inbound');
      final newQty = res['newQuantity'] as int;

      if (_itemsByCategory.containsKey(item.categoryId)) {
        final itemIndex = _itemsByCategory[item.categoryId]!.indexWhere((i) => i.id == item.id);
        if (itemIndex != -1) {
          _itemsByCategory[item.categoryId]![itemIndex] = 
              _itemsByCategory[item.categoryId]![itemIndex].copyWith(quantity: newQty);
        }
      }
      final allIndex = _items.indexWhere((i) => i.id == item.id);
      if (allIndex != -1) {
        _items[allIndex] = _items[allIndex].copyWith(quantity: newQty);
      }

      _cachedStatsByDate.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error recording inbound transaction: $e');
      throw Exception('Failed to record inbound transaction: $e');
    }
  }

  void _checkStockLevels(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    notificationProvider.checkStockLevels(_items);
  }

  // Public reload actions
  Future<void> reloadFromDatabase() async {
    await _loadItemsFromDatabase();
  }

  Future<void> loadFromLocalStorage() async {
    // Keep fallback method signatures intact
    await _loadItemsFromDatabase();
  }

  Future<void> reloadFromLocalStorage() async {
    await _loadItemsFromDatabase();
  }

  Future<void> refreshCategoryItems(String categoryId) async {
    await _loadItemsFromDatabase();
  }

  Future<void> refreshTransactionData() async {
    _cachedStatsByDate.clear();
    await _loadItemsFromDatabase();
  }

  // --- BACKWARD COMPATIBILITY HELPER METHODS ---

  Future<void> forceRegenerateTransactionData() async {
    await refreshTransactionData();
  }

  int getTotalInboundQuantity(DateTime date) {
    return 0;
  }

  int getTotalInboundCategories(DateTime date) {
    return 0;
  }

  double getTotalInboundValue(DateTime date) {
    return 0.0;
  }

  Future<void> exportProducts(DateTime date) async {
    // PDF / CSV export placeholder
  }

  Future<void> exportCategories() async {
    // PDF / CSV export placeholder
  }

  Future<void> exportTransactions(DateTime date) async {
    // PDF / CSV export placeholder
  }

  Future<void> deleteItemsInCategory(String categoryId) async {
    final items = getItemsByCategory(categoryId);
    for (var item in items) {
      await deleteItem(item.id);
    }
  }

  List<Item> getItemsByCategoryId(String categoryId) {
    return getItemsByCategory(categoryId);
  }

  List<String> getAllCategoryIds() {
    return _itemsByCategory.keys.toList();
  }

  List<Item> getItemsForCategory(String categoryId) {
    return getItemsByCategory(categoryId);
  }

  List<Item> getAllItems() {
    return allItems;
  }

  Map<String, dynamic>? checkItemExistsInAnyCategory(String name, String? barcode) {
    try {
      final existing = _items.firstWhere((item) => 
          item.name.toLowerCase() == name.toLowerCase() || 
          (barcode != null && item.barcode == barcode));
      return {
        'message': 'Product "${existing.name}" already exists in category "${existing.categoryName ?? existing.categoryId}"'
      };
    } catch (e) {
      return null;
    }
  }

  Future<void> removeItem(String categoryId, String itemId) async {
    await deleteItem(itemId);
  }
}
