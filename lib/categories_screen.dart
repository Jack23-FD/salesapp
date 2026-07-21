import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'new_category_screen.dart';
import 'providers/category_provider.dart';
import 'providers/item_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/items_screen.dart';
import 'models/category.dart';
import 'screens/scanner/scanner_screen.dart';
import 'screens/notification_screen.dart';
import 'services/localization_service.dart';
import 'widgets/notification_icon.dart';
import 'theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _activeFilter = 'Active Category';
  String _sortBy = 'Sort by';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    // Load categories from local storage when screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
      
      // Add a timeout to prevent infinite loading
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && context.read<CategoryProvider>().isLoading) {
          print('Category loading timeout - forcing UI update');
          setState(() {
            // Force UI refresh after timeout
          });
        }
      });
    });
  }

  Future<void> _loadCategories() async {
    try {
      final categoryProvider =
          Provider.of<CategoryProvider>(context, listen: false);
      
      // Force reload from database to ensure we have the latest data
      await categoryProvider.reloadFromDatabase().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('Category loading timed out');
          return;
        },
      );
      
      if (!mounted) return;
      
      // Also force reload items to get fresh category references
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      await itemProvider.reloadFromDatabase().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('Item loading timed out');
          return;
        },
      );
      
      if (!mounted) return;
      
      setState(() {
        // Refresh UI after loading categories
      });
    } catch (e) {
      print('Error loading categories in categories screen: $e');
      if (mounted) {
        setState(() {
          // Refresh UI even on error
        });
      }
    }
  }

  void _confirmDeleteCategory(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(LocalizationService.translate('categoryScreen.deleteCategory')),
          content: Text(
              LocalizationService.translate('categoryScreen.deleteConfirmation').replaceAll('{name}', category.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LocalizationService.translate('common.cancel')),
            ),
            TextButton(
              onPressed: () async {
                // Delete all items in the category first
                await context.read<ItemProvider>().deleteItemsInCategory(category.id);
                // Then delete the category
                await context.read<CategoryProvider>().removeCategory(category.id);
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(
                LocalizationService.translate('common.delete'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showStatusFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LocalizationService.translate('categoryScreen.status'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Options
              ListTile(
                title: Text(LocalizationService.translate('categoryScreen.allCategory')),
                trailing: _activeFilter == 'All Category'
                    ? const Icon(Icons.check_circle, color: const Color(0xFFFF8A00))
                    : null,
                onTap: () {
                  setState(() {
                    _activeFilter = 'All Category';
                  });
                  Navigator.pop(context);
                },
              ),

              ListTile(
                title: Text(LocalizationService.translate('categoryScreen.activeCategory')),
                trailing: _activeFilter == 'Active Category' ||
                        _activeFilter == 'Active'
                    ? const Icon(Icons.check_circle, color: const Color(0xFFFF8A00))
                    : null,
                onTap: () {
                  setState(() {
                    _activeFilter = 'Active Category';
                  });
                  Navigator.pop(context);
                },
              ),

              ListTile(
                title: Text(LocalizationService.translate('categoryScreen.lowStockCategory')),
                trailing: _activeFilter == 'Low Stock Category'
                    ? const Icon(Icons.check_circle, color: const Color(0xFFFF8A00))
                    : null,
                onTap: () {
                  setState(() {
                    _activeFilter = 'Low Stock Category';
                  });
                  Navigator.pop(context);
                },
              ),

              ListTile(
                title: Text(LocalizationService.translate('categoryScreen.emptyCategory')),
                trailing: _activeFilter == 'Empty Category'
                    ? const Icon(Icons.check_circle, color: const Color(0xFFFF8A00))
                    : null,
                onTap: () {
                  setState(() {
                    _activeFilter = 'Empty Category';
                  });
                  Navigator.pop(context);
                },
              ),

              ListTile(
                title: Text(LocalizationService.translate('categoryScreen.inactiveCategory')),
                trailing: _activeFilter == 'Inactive Category'
                    ? const Icon(Icons.check_circle, color: const Color(0xFFFF8A00))
                    : null,
                onTap: () {
                  setState(() {
                    _activeFilter = 'Inactive Category';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSortByModal() {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LocalizationService.translate('categoryScreen.sortBy'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Name option
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationService.translate('categoryScreen.name'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _sortAscending = !_sortAscending;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ListTile(
                          title: Text(LocalizationService.translate('categoryScreen.createdTime')),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _sortAscending 
                                  ? LocalizationService.translate('categoryScreen.ascending') 
                                  : LocalizationService.translate('categoryScreen.descending'),
                                style: const TextStyle(color: Colors.grey)
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                size: 16,
                                color: Colors.grey.shade600
                              ),
                            ],
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          dense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tap on element info
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.info_outline,
                          color: const Color(0xFFFF8A00), size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        LocalizationService.translate('categoryScreen.tapToChangeSortInfo'),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),

              // Sort selected button
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LocalizationService.translate('categoryScreen.sortSelected'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${LocalizationService.translate('categoryScreen.name')} (${_sortAscending ? LocalizationService.translate('categoryScreen.ascending') : LocalizationService.translate('categoryScreen.descending')})',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _sortBy = 'Name';
                    });
                    // Update the provider's sort settings
                    categoryProvider.setSortOrder('name', _sortAscending);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A00),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(LocalizationService.translate('categoryScreen.sort')),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Add a helper method to translate the filter name
  String _getTranslatedFilterName(String filter) {
    switch (filter) {
      case 'All Category':
        return LocalizationService.translate('categoryScreen.allCategory');
      case 'Active Category':
      case 'Active':
        return LocalizationService.translate('categoryScreen.activeCategory');
      case 'Low Stock Category':
        return LocalizationService.translate('categoryScreen.lowStockCategory');
      case 'Empty Category':
        return LocalizationService.translate('categoryScreen.emptyCategory');
      case 'Inactive Category':
        return LocalizationService.translate('categoryScreen.inactiveCategory');
      default:
        return filter;
    }
  }

  // Add a helper method to translate the sort mode
  String _getTranslatedSortMode(String sortMode) {
    if (sortMode == 'Sort by') {
      return LocalizationService.translate('categoryScreen.sortBy');
    } else if (sortMode == 'Name') {
      return LocalizationService.translate('categoryScreen.name');
    }
    return sortMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.secondaryBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderColor, width: 1),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Text(
                          LocalizationService.translate('categoryScreen.title'),
                          style: GoogleFonts.urbanist(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        NotificationIcon(
                          useContainerBackground: false,
                          iconColor: AppTheme.textPrimary,
                        ),
                      ],
                    ),
                  ),

                  // Filter Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: _showStatusFilterModal,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    _getTranslatedFilterName(_activeFilter),
                                    style: GoogleFonts.urbanist(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _showSortByModal,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getTranslatedSortMode(_sortBy),
                                  style: GoogleFonts.urbanist(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Categories List or Empty State
            Expanded(
              child: Consumer2<CategoryProvider, ItemProvider>(
                builder: (context, categoryProvider, itemProvider, child) {
                  // Show loading indicator while categories are being loaded - with a timeout
                  if (categoryProvider.isLoading && categoryProvider.categories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadCategories,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(LocalizationService.translate('categoryScreen.retryLoading')),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final allCategories = categoryProvider.categories;
                  
                  // Debug info
                  print('Categories found: ${allCategories.length}');
                  for (var cat in allCategories) {
                    print('Category: ${cat.name} (${cat.id})');
                  }
                  
                  // Also debug the items to check category references
                  final allItems = itemProvider.allItems;
                  print('Total items: ${allItems.length}');
                  for (var item in allItems.take(5)) { // Show just first 5 for brevity
                    print('Item: ${item.name}, Category ID: ${item.categoryId}, Category Name: ${item.categoryName ?? "Unknown"}');
                  }
                  
                  List<Category> filteredCategories = List.from(allCategories);
                  
                  // Filter categories based on selected filter
                  if (_activeFilter == 'Low Stock Category') {
                    // Get categories that have items with low stock
                    final lowStockCategories = allCategories.where((category) {
                      final categoryItems = itemProvider.getItemsByCategoryId(category.id);
                      // Check if any item in the category has low stock
                      return categoryItems.any((item) => 
                        item.minLevel != null && item.quantity <= item.minLevel!);
                    }).toList();
                    filteredCategories = lowStockCategories;
                  } else if (_activeFilter == 'Empty Category') {
                    // Get categories that have no items
                    filteredCategories = allCategories.where((category) {
                      final categoryItems = itemProvider.getItemsByCategoryId(category.id);
                      return categoryItems.isEmpty;
                    }).toList();
                  } else if (_activeFilter == 'Inactive Category') {
                    filteredCategories = allCategories.where((category) {
                      return false; // Placeholder
                    }).toList();
                  } else if (_activeFilter == 'All Category') {
                    filteredCategories = allCategories;
                  } else if (_activeFilter == 'Active Category' || _activeFilter == 'Active') {
                    filteredCategories = allCategories;
                  }
                  
                  if (filteredCategories.isEmpty) {
                    // Get proper message based on filter
                    String messageKey = 'categoryScreen.noCategoriesFound';
                    if (_activeFilter == 'Active Category' || _activeFilter == 'Active') {
                      messageKey = 'categoryScreen.noActiveCategoriesFound';
                    } else if (_activeFilter == 'Low Stock Category') {
                      messageKey = 'categoryScreen.noLowStockCategoriesFound';
                    } else if (_activeFilter == 'Empty Category') {
                      messageKey = 'categoryScreen.noEmptyCategoriesFound';
                    } else if (_activeFilter == 'Inactive Category') {
                      messageKey = 'categoryScreen.noInactiveCategoriesFound';
                    }
                    
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/box.jpg',
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            LocalizationService.translate(messageKey),
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NewCategoryScreen(),
                                ),
                              ).then((_) => _loadCategories()); // Reload after adding
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            child: Text(LocalizationService.translate('categoryScreen.addCategory')),
                          ),
                        ],
                      ),
                    );
                  }

                  return Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: _loadCategories,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredCategories.length,
                          itemBuilder: (context, index) {
                            final category = filteredCategories[index];
                            // Get item count for this category
                            final categoryItems = itemProvider.getItemsByCategoryId(category.id);
                            final itemCount = categoryItems.length;
                            
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ItemsScreen(category: category),
                                  ),
                                ).then((_) => _loadCategories()); // Reload after returning
                              },
                              onLongPress: () =>
                                  _confirmDeleteCategory(context, category),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackgroundColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.borderColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.01),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.lightOrange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      category.icon ?? Icons.star_outline,
                                      color: AppTheme.primaryColor,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    category.name,
                                    style: GoogleFonts.urbanist(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '$itemCount ${LocalizationService.translate('categoryScreen.items')}',
                                    style: GoogleFonts.urbanist(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton(
                          heroTag: 'categories_fab',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NewCategoryScreen(),
                              ),
                            ).then((_) => _loadCategories()); // Reload after adding
                          },
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
