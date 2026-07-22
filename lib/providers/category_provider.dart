import 'package:flutter/material.dart';
import '../models/category.dart';
import '../utils/storage_utils.dart';
import '../models/category.dart' as app_models;
import '../services/api_service.dart';

class CategoryProvider extends ChangeNotifier {
  final List<Category> _categories = [];
  String _sortField = 'name';
  bool _sortAscending = true;
  final ApiService _apiService = ApiService();
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
    print('CategoryProvider initialized with PHP API');
    _loadCategoriesFromDatabase();
  }

  // Load categories from PHP API database
  Future<void> _loadCategoriesFromDatabase() async {
    try {
      _isLoading = true;
      if (!_hasInitialLoad) {
        notifyListeners(); // Notify loading state on first load
      }
      
      print('Loading categories from PHP API backend...');
      final categories = await _apiService.getCategories();

      _categories.clear();
      _categories.addAll(categories);
      _isLoading = false;
      _hasInitialLoad = true;
      print('Loaded ${_categories.length} categories from PHP API');
      notifyListeners();
    } catch (e) {
      print('Error loading categories from PHP API: $e');
      _isLoading = false;
      if (!e.toString().contains('not authenticated')) {
        _hasInitialLoad = true;
      }
      notifyListeners();
      // Fallback to local storage if API fails
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
        
        // No categories found anywhere, keep list empty
        print('No categories found anywhere');
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
  Future<void> addCategory(Category category) async {
    try {
      // Add to PHP API
      await _apiService.createCategory(category);
      
      // Add to local list
      _categories.add(category);
      
      // Also save to local storage as backup
      await StorageUtils.saveCategory(category);

      notifyListeners();
    } catch (e) {
      print('Error adding category: $e');
      // Fallback to just local storage
      _categories.add(category);
      await StorageUtils.saveCategory(category);
      notifyListeners();
    }
  }

  // Remove category
  Future<void> removeCategory(String id) async {
    try {
      // Remove from PHP API
      await _apiService.deleteCategory(id);
      
      // Remove from local list
      _categories.removeWhere((category) => category.id == id);
      
      // Remove from local storage
      await StorageUtils.deleteCategory(id);

      notifyListeners();
    } catch (e) {
      print('Error removing category: $e');
      // Fallback to just local storage
      _categories.removeWhere((category) => category.id == id);
      await StorageUtils.deleteCategory(id);
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

      // Save all categories to PHP API
      for (var category in updatedCategories) {
        await _apiService.createCategory(category);
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
