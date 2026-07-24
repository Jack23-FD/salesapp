import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import 'add_stock_screen.dart';
import 'use_stock_screen.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ItemsScreen extends StatefulWidget {
  final Category category;

  const ItemsScreen({super.key, required this.category});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  String _activeFilter = 'Active';
  String _sortBy = 'Sort by';

  @override
  void initState() {
    super.initState();
    // Load items for this category from database when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadItems();
    });
  }

  Future<void> _loadItems() async {
    try {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      
      // First check if we need to load all items or just for this category
      if (itemProvider.isInitialLoad) {
        await itemProvider.reloadFromDatabase();
      } else {
        // If items are already loaded, just refresh category items
        await itemProvider.refreshCategoryItems(widget.category.id);
      }
      
      // Print debug information
      final items = itemProvider.getItemsForCategory(widget.category.id);
      print('Loaded ${items.length} items for category ${widget.category.name}');
      for (var item in items.take(5)) { // Only show first 5 for brevity
        print('Item: ${item.name}, Quantity: ${item.quantity}, Price: ${item.price}, Category: ${item.categoryName ?? "Unknown"}');
      }
    } catch (e) {
      print('Error loading items in items screen: $e');
    }
  }

  void _showItemOptions(BuildContext context, Item item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Item'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddStockScreen(
                        selectedCategory: widget.category,
                        itemToEdit: item,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete Item',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteItem(context, item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteItem(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(LocalizationService.translate('inventory.deleteItem')),
          content: Text(LocalizationService.translate('inventory.confirmDelete')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LocalizationService.translate('common.cancel')),
            ),
            TextButton(
              onPressed: () async {
                // Close the dialog first
                Navigator.pop(context);
                
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(LocalizationService.translate('inventory.deletingItem')),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
                
                // Delete the item
                final itemProvider = context.read<ItemProvider>();
                itemProvider.removeItem(widget.category.id, item.id);
                
                // Give the provider time to update
                await Future.delayed(Duration(milliseconds: 500));
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(LocalizationService.translate('inventory.itemDeleted')),
                    backgroundColor: Colors.green,
                  ),
                );
                
                // Force refresh of UI
                setState(() {});
              },
              child: Text(
                LocalizationService.translate('common.delete'),
                style: TextStyle(color: Colors.red),
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
                    const Text(
                      'Status',
                      style: TextStyle(
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
                title: const Text('All Items'),
                trailing: _activeFilter == 'All Items'
                    ? const Icon(Icons.check_circle, color: const Color(0xFF00BBF9))
                    : null,
                onTap: () {
                  setState(() {
                    _activeFilter = 'All Items';
                  });
                  Navigator.pop(context);
                },
              ),

              ListTile(
                title: const Text('Active Items'),
                trailing: _activeFilter == 'Active Items' ||
                        _activeFilter == 'Active'
                    ? const Icon(Icons.check_circle, color: const Color(0xFF00BBF9))
                    : null,
                onTap: () {
                  setState(() {
                    _activeFilter = 'Active Items';
                  });
                  Navigator.pop(context);
                },
              ),

              ListTile(
                title: const Text('Low Stock Items'),
                trailing: _activeFilter == 'Low Stock Items'
                    ? const Icon(Icons.check_circle, color: const Color(0xFF00BBF9))
                    : null,
                onTap: () {
                  setState(() {
                    _activeFilter = 'Low Stock Items';
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
                    const Text(
                      'Sort by',
                      style: TextStyle(
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
                    const Text(
                      'Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListTile(
                        title: const Text('Created Time'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Descending',
                                style: TextStyle(color: Colors.grey)),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_downward,
                                size: 16, color: Colors.grey.shade600),
                          ],
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        dense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListTile(
                        title: const Text('Price'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Descending',
                                style: TextStyle(color: Colors.grey)),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_downward,
                                size: 16, color: Colors.grey.shade600),
                          ],
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        dense: true,
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
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.info_outline,
                          color: AppTheme.primaryColor, size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Tap on element to change from ascending to descending, and vice versa.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
                      'Sort Selected',
                      style: GoogleFonts.urbanist(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Name (Ascending)',
                      style: GoogleFonts.urbanist(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
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
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Sort'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.secondaryBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category.name,
          style: GoogleFonts.urbanist(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                            Text(
                              _activeFilter,
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
                              _sortBy,
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
              ],
            ),
          ),

          // Items List
          Expanded(
            child: Consumer<ItemProvider>(
              builder: (context, itemProvider, child) {
                // Show loading indicator if items are being loaded
                if (itemProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  );
                }
                
                final items =
                    itemProvider.getItemsForCategory(widget.category.id);

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/box.jpg',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Item Found',
                          style: TextStyle(
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
                                builder: (context) => AddStockScreen(
                                    selectedCategory: widget.category),
                              ),
                            ).then((_) => _loadItems());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Add Item'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadItems,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final bool isLowStock = item.quantity <= (item.minLevel ?? 5);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppTheme.borderColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Item Image
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppTheme.lightOrange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: item.imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          item.imageUrl!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.inventory_2_outlined,
                                        color: AppTheme.primaryColor,
                                        size: 26,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              // Item Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: GoogleFonts.urbanist(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Show category name if available
                                    if (item.categoryName != null && item.categoryName != widget.category.name)
                                      Text(
                                        'Category: ${item.categoryName}',
                                        style: GoogleFonts.urbanist(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Text(
                                                'Qty: ${item.quantity} ${item.unit}',
                                                style: GoogleFonts.urbanist(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: isLowStock ? AppTheme.warning : AppTheme.textSecondary,
                                                ),
                                              ),
                                              if (isLowStock) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.warningBackground,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'LOW',
                                                    style: GoogleFonts.urbanist(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.warning,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '€${item.price.toStringAsFixed(2)}',
                                          style: GoogleFonts.urbanist(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (item.barcode != null && item.barcode!.isNotEmpty)
                                      Text(
                                        'Barcode: ${item.barcode}',
                                        style: GoogleFonts.urbanist(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // More Options
                              IconButton(
                                icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                                onPressed: () => _showItemOptions(context, item),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Outbound (remove stock) button
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UseStockScreen(),
                ),
              ).then((_) => _loadItems()); // Reload items after returning
            },
            backgroundColor: AppTheme.warning,
            heroTag: 'outbound_fab',
            mini: true,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.remove, color: Colors.white),
          ),
          const SizedBox(height: 10),
          // Add stock button
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddStockScreen(selectedCategory: widget.category),
                ),
              ).then((_) => _loadItems()); // Reload items after returning
            },
            backgroundColor: AppTheme.primaryColor,
            heroTag: 'add_fab',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
