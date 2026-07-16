import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import 'add_stock_screen.dart';
import 'use_stock_screen.dart';
import '../services/localization_service.dart';

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
                    ? const Icon(Icons.check_circle, color: Color(0xFF333366))
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
                    ? const Icon(Icons.check_circle, color: Color(0xFF333366))
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
                    ? const Icon(Icons.check_circle, color: Color(0xFF333366))
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
                        color: const Color(0xFF333366).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.info_outline,
                          color: Color(0xFF333366), size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Tap on element to change from ascending to descending, and vice versa.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
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
                    const Text(
                      'Sort Selected',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Name (Ascending)',
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
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF333366),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Items',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.qr_code_scanner_outlined, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Path
                Text(
                  'Category / ${widget.category.name}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                // Filters
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFF333366),
                              width: 2.0,
                            ),
                          ),
                        ),
                        child: InkWell(
                          onTap: _showStatusFilterModal,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _activeFilter,
                                  style: const TextStyle(
                                    color: Color(0xFF333366),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFF333366),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFF333366),
                              width: 2.0,
                            ),
                          ),
                        ),
                        child: InkWell(
                          onTap: _showSortByModal,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _sortBy,
                                  style: const TextStyle(
                                    color: Color(0xFF333366),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFF333366),
                                ),
                              ],
                            ),
                          ),
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
                      color: Color(0xFF333366),
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
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Item Found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
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
                            backgroundColor: const Color(0xFF333366),
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
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
                                  color: const Color(0xFF333366),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: item.imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          item.imageUrl!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.inventory_2_outlined,
                                        color: Colors.white,
                                        size: 30,
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
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Show category name if available
                                    if (item.categoryName != null && item.categoryName != widget.category.name)
                                      Text(
                                        'Category: ${item.categoryName}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Quantity: ${item.quantity} ${item.unit}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Price: €${item.price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (item.barcode != null)
                                      Text(
                                        'Barcode: ${item.barcode}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // More Options
                              IconButton(
                                icon: const Icon(Icons.more_vert),
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
            backgroundColor: Colors.red,
            heroTag: 'outbound_fab',
            mini: true,
            child: const Icon(Icons.remove),
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
            backgroundColor: const Color(0xFF333366),
            heroTag: 'add_fab',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
