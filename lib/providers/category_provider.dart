import 'package:flutter/material.dart';
import '../models/category.dart';
import '../utils/storage_utils.dart';
import '../services/mysql_database_service.dart';
import '../models/category.dart' as app_models;

class CategoryProvider extends ChangeNotifier {
  final List<Category> _categories = [];
  String _sortField = 'name';
  bool _sortAscending = true;
  final MySqlDatabaseService _databaseService = MySqlDatabaseService();
  bool _isLoading = false;
  bool _hasInitialLoad = false;

  List<Category> get categories {
    final sortedList = List<Category>.from(_categories);
    _sortCategories(sortedList);
    return List.unmodifiable(sortedList);
  }

  bool get isLoading => _isLoading;
  bool get hasData => _categories.isNotEmpty;

  // Sort by field and direction
  void setSortOrder(String field, bool ascending) {
    _sortField = field;
    _sortAscending = ascending;
    notifyListeners();
  }

  // Helper method to sort categories
  void _sortCategories(List<Category> list) {
    list.sort((a, b) {
      int result;
      switch (_sortField) {
        case 'name':
          result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        default:
          result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return _sortAscending ? result : -result;
    });
  }

  CategoryProvider() {
    print('CategoryProvider initialized');
    _loadCategoriesFromDatabase();
  }

  // Load categories from MySQL database
  Future<void> _loadCategoriesFromDatabase() async {
    try {
      _isLoading = true;
      if (_hasInitialLoad) {
        // If we've already loaded once, don't block the UI with a notification
        // This is just a refresh
      } else {
        notifyListeners(); // Notify loading state on first load
      }
      
      print('Loading categories from MySQL database');
      final databaseCategories = await _databaseService.getCategories();

      // Even if we get empty results, update loading state to prevent endless loading
      _isLoading = false;
      _hasInitialLoad = true;

      if (databaseCategories.isNotEmpty) {
        _categories.clear();
        _categories.addAll(databaseCategories);
        print('Loaded ${databaseCategories.length} categories from MySQL database');
        notifyListeners();
      } else {
        print('No categories found in MySQL database');
        // Don't block on local storage if database returns empty
        _loadCategoriesFromStorage();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading categories from MySQL database: $e');
      _isLoading = false;
      _hasInitialLoad = true; // Mark as loaded even on error to prevent infinite loading
      notifyListeners();
      // Fallback to local storage if database fails
      _loadCategoriesFromStorage();
    }
  }

  // Legacy method to load from local storage as fallback
  Future<void> _loadCategoriesFromStorage() async {
    try {
      print('Loading categories from local storage as fallback');
      final storedCategories = await StorageUtils.getCategories();

      if (storedCategories.isNotEmpty) {
        _categories.clear();
        _categories.addAll(storedCategories);
        print('Loaded ${storedCategories.length} categories from local storage');
      } else {
        print('No categories found in local storage');
        
        // If no categories found anywhere, add a default category to prevent UI issues
        if (_categories.isEmpty) {
          final defaultCategory = app_models.Category(
            id: 'default_category',
            name: 'Default Category',
            description: 'Default category created automatically',
          );
          _categories.add(defaultCategory);
          print('Added default category as fallback');
        }
      }
      
      _isLoading = false;
      _hasInitialLoad = true;
      notifyListeners();
    } catch (e) {
      print('Error loading categories from local storage: $e');
      _isLoading = false;
      _hasInitialLoad = true;
      notifyListeners();
    }
  }

  // Add a new category
  void addCategory(Category category) async {
    try {
      // Add to MySQL database
      await _databaseService.addCategory(category);
      
      // Add to local list
      _categories.add(category);
      
      // Also save to local storage as backup
      StorageUtils.saveCategory(category);

      notifyListeners();
    } catch (e) {
      print('Error adding category: $e');
      // Fallback to just local storage
      _categories.add(category);
      StorageUtils.saveCategory(category);
      notifyListeners();
    }
  }

  // Remove category
  void removeCategory(String id) async {
    try {
      // Remove from MySQL database
      await _databaseService.deleteCategory(id);
      
      // Remove from local list
      _categories.removeWhere((category) => category.id == id);
      
      // Remove from local storage
      StorageUtils.deleteCategory(id);

      notifyListeners();
    } catch (e) {
      print('Error removing category: $e');
      // Fallback to just local storage
      _categories.removeWhere((category) => category.id == id);
      StorageUtils.deleteCategory(id);
      notifyListeners();
    }
  }

  // Get category by ID
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update all categories at once (useful for bulk operations)
  Future<void> updateCategories(List<Category> updatedCategories) async {
    try {
      _categories.clear();
      _categories.addAll(updatedCategories);

      // Save all categories to MySQL database
      for (var category in updatedCategories) {
        await _databaseService.updateCategory(category);
      }
      
      // Also save to local storage as backup
      await StorageUtils.saveCategories(updatedCategories);

      notifyListeners();
    } catch (e) {
      print('Error updating categories: $e');
      // Fallback to just local storage
      await StorageUtils.saveCategories(updatedCategories);
      notifyListeners();
    }
  }

  // Force reload from database
  Future<void> reloadFromDatabase() async {
    await _loadCategoriesFromDatabase();
  }

  // Legacy method for backward compatibility
  Future<void> reloadFromLocalStorage() async {
    await _loadCategoriesFromDatabase();
  }
}
