import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category.dart';
import 'package:provider/provider.dart';
import '../providers/item_provider.dart';
import '../providers/category_provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification_item.dart';
import 'package:uuid/uuid.dart';
import '../models/item.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'scanner/scanner_screen.dart';
import '../new_category_screen.dart';
import '../theme/typography.dart';
import '../services/mysql_database_service.dart';
import '../utils/translation_utils.dart';
import '../services/localization_service.dart';
import 'package:image_picker/image_picker.dart';
import 'items_screen.dart';

class AddStockScreen extends StatefulWidget {
  final Category? selectedCategory;
  final Item? itemToEdit;
  final String? initialBarcode;

  const AddStockScreen({
    super.key,
    this.selectedCategory,
    this.itemToEdit,
    this.initialBarcode,
  });

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _minLevelController = TextEditingController();
  final FocusNode _barcodeNode = FocusNode();
  final FocusNode _itemNameFocus = FocusNode();
  final FocusNode _quantityFocus = FocusNode();
  final FocusNode _priceFocus = FocusNode();
  final FocusNode _minLevelFocus = FocusNode();

  String selectedUnit = 'pcs';
  double _totalValue = 0.0;
  Category? selectedCategory;
  bool _isLoading = false;

  final List<Map<String, dynamic>> units = [
    {'label': 'Pieces', 'value': 'pcs'},
    {'label': 'Kilograms', 'value': 'kg'},
    {'label': 'Grams', 'value': 'g'},
    {'label': 'Liters', 'value': 'l'},
    {'label': 'Milliliters', 'value': 'ml'},
  ];

  // Define app theme colors
  final Color primaryColor = const Color(0xFF333366);
  final Color secondaryColor = const Color(0xFF6466B3);
  final Color lightGray = const Color(0xFFF5F5F7);
  final Color borderColor = const Color(0xFFE0E0E0);

  // Define consistent sizing
  final double sectionSpacing = 20.0;
  final double inputHeight = 52.0;
  final double borderRadius = 12.0;

  // Helper method to ensure the unit is valid
  String validateUnitValue(String unitValue) {
    // Check if the unit value exists in our units list
    bool unitExists = units.any((unit) => unit['value'] == unitValue);
    return unitExists ? unitValue : 'pcs'; // Default to 'pcs' if unit is invalid
  }

  @override
  void initState() {
    super.initState();
    if (widget.selectedCategory != null) {
      selectedCategory = widget.selectedCategory;
    }

    // Initialize controllers with existing item data if editing
    if (widget.itemToEdit != null) {
      _itemNameController.text = widget.itemToEdit!.name;
      _quantityController.text = widget.itemToEdit!.quantity.toString();
      _priceController.text = widget.itemToEdit!.price.toString();
      
      // Validate unit value
      selectedUnit = validateUnitValue(widget.itemToEdit!.unit);
      
      if (widget.itemToEdit!.barcode != null) {
        _barcodeController.text = widget.itemToEdit!.barcode!;
      }
      if (widget.itemToEdit!.minLevel != null) {
        _minLevelController.text = widget.itemToEdit!.minLevel.toString();
      }
    } else {
      // Set default quantity to 1 for new items
      _quantityController.text = '1';
    }

    // Set barcode from scanner if provided
    if (widget.initialBarcode != null) {
      _barcodeController.text = widget.initialBarcode!;
    }

    _quantityController.addListener(_updateTotalValue);
    _priceController.addListener(_updateTotalValue);
    
    // Force reload categories from database
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }
  
  Future<void> _loadCategories() async {
    try {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      await categoryProvider.reloadFromDatabase();
      print('Categories loaded: ${categoryProvider.categories.length}');
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  void _updateTotalValue() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    setState(() {
      _totalValue = quantity * price;
    });
  }

  void _selectCategory(Category category) {
    setState(() {
      selectedCategory = category;
    });
    Navigator.pop(context);
  }

  void _showCategorySelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Consumer<CategoryProvider>(
            builder: (context, categoryProvider, child) {
              final categories = categoryProvider.categories;
              print('Categories in dropdown: ${categories.length}');
              
              if (categories.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocalizationService.translate('addStockScreen.noCategoriesFound'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: inputHeight,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NewCategoryScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                            ),
                          ),
                          child: Text(
                            LocalizationService.translate('addStockScreen.addCategory'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationService.translate('addStockScreen.selectCategory'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return CheckboxListTile(
                            value: selectedCategory?.id == category.id,
                            onChanged: (bool? value) {
                              // Use setModalState to update UI within the modal
                              setModalState(() {
                                if (value == true) {
                                  selectedCategory = category;
                                } else {
                                  selectedCategory = null;
                                }
                              });

                              // Also update the parent state
                              setState(() {});
                            },
                            title: Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            activeColor: primaryColor,
                            checkColor: Colors.white,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: inputHeight,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                          ),
                        ),
                        child: Text(
                          LocalizationService.translate('addStockScreen.done'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                  ],
                ),
              );
            },
          );
        });
      },
    );
  }

  void _saveItem() {
    // First validate that all required fields are filled
    if (_itemNameController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _priceController.text.isEmpty ||
        selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.translate('messages.fillAllFields')),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
      return;
    }
    
    // Require barcode for new items
    if (widget.itemToEdit == null && _barcodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.translate('messages.barcodeRequired')),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
      return;
    }

    // Validate that minimum level is not higher than quantity
    final double quantity = double.parse(_quantityController.text);
    final double? minLevel = _minLevelController.text.isNotEmpty
        ? double.parse(_minLevelController.text)
        : null;
        
    if (minLevel != null && minLevel > quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.translate('messages.minimumLevelError')),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
      return;
    }

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text(LocalizationService.translate('addStockScreen.savingItem')),
              ],
            ),
          ),
        );
      },
    );

    final itemProvider = context.read<ItemProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    // Use a Future to handle database operations
    Future<void> saveItemOperation() async {
      try {
    // Check if we're creating a new item (not editing)
    if (widget.itemToEdit == null) {
      // Check if an item with the same name or barcode already exists in another category
      final existingItemInfo = itemProvider.checkItemExistsInAnyCategory(
        _itemNameController.text.trim(),
        _barcodeController.text.isEmpty ? null : _barcodeController.text,
      );

      if (existingItemInfo != null) {
            // Close the loading dialog first
            Navigator.of(context).pop();
            
        // Show an alert dialog to inform the user
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(LocalizationService.translate('messages.itemAlreadyExists')),
            content: Text(
              '${existingItemInfo['message']}. ${LocalizationService.translate('messages.singleCategory')}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(LocalizationService.translate('common.ok')),
              ),
            ],
          ),
        );
        return;
      }
    }

    if (widget.itemToEdit != null) {
      // Update existing item
      final updatedItem = Item(
        id: widget.itemToEdit!.id,
        name: _itemNameController.text.trim(),
        categoryId: selectedCategory!.id,
        quantity: int.parse(_quantityController.text),
        unit: validateUnitValue(selectedUnit),
        price: double.parse(_priceController.text),
        type: 'inbound',
        minLevel: _minLevelController.text.isNotEmpty
            ? double.parse(_minLevelController.text)
            : null,
        barcode:
            _barcodeController.text.isEmpty ? null : _barcodeController.text,
        dateAdded: widget.itemToEdit!.dateAdded,
        createdAt: widget.itemToEdit!.createdAt,
      );
      
      // Update the item in the provider which will save to MySQL
          await itemProvider.updateItem(updatedItem);

      // Check if stock is below minimum level
      if (updatedItem.minLevel != null &&
          updatedItem.quantity <= updatedItem.minLevel!) {
        notificationProvider.addNotification(
          NotificationItem(
            id: 'low_stock_${updatedItem.id}',
            title: 'Low Stock Alert',
            message:
                '${updatedItem.name} is running low on stock (${updatedItem.quantity} ${updatedItem.unit} remaining).',
            timestamp: DateTime.now(),
            actionType: 'item',
            actionId: updatedItem.id,
          ),
        );
      }
    } else {
      // Create a single new item with the selected category
      final item = Item(
        id: const Uuid().v4(),
        name: _itemNameController.text.trim(),
        categoryId: selectedCategory!.id,
        quantity: int.parse(_quantityController.text),
        unit: validateUnitValue(selectedUnit),
        price: double.parse(_priceController.text),
        type: 'inbound',
        minLevel: _minLevelController.text.isNotEmpty
            ? double.parse(_minLevelController.text)
            : null,
        barcode:
            _barcodeController.text.isEmpty ? null : _barcodeController.text,
        dateAdded: DateTime.now(),
        createdAt: DateTime.now(),
      );
      
      // Add the item through the provider which will save to MySQL
          await itemProvider.addItem(item);

      // Check if stock is below minimum level
      if (item.minLevel != null && item.quantity <= item.minLevel!) {
        notificationProvider.addNotification(
          NotificationItem(
            id: 'low_stock_${item.id}',
            title: 'Low Stock Alert',
            message:
                '${item.name} is running low on stock (${item.quantity} ${item.unit} remaining).',
            timestamp: DateTime.now(),
            actionType: 'item',
            actionId: item.id,
          ),
        );
      }
    }

        // Close loading dialog
        Navigator.of(context).pop();

        // Reset loading state
        setState(() {
          _isLoading = false;
        });

        // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.itemToEdit == null 
                  ? LocalizationService.translate('messages.itemSaved')
                  : LocalizationService.translate('messages.itemUpdated')
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );

        // Navigate to the category screen if it's a new item
        if (widget.itemToEdit == null && selectedCategory != null) {
          // Import the items screen if not already imported
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ItemsScreen(category: selectedCategory!),
            ),
          );
        } else {
          // Return to previous screen for edits
          Navigator.pop(context);
        }
      } catch (e) {
        // Close loading dialog
        Navigator.of(context).pop();
        
        // Show detailed error message with better handling
        debugPrint('Error saving item: $e');

        if (e.toString().contains('barcode already exists')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('A product with this barcode already exists.'),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(10),
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        // Check if this is a duplicate entry error - in this case the item
        // is likely already in the database, so just navigate to category
        if (e.toString().contains('Duplicate entry')) {
          // Navigate to the category screen since the item is likely there
          if (widget.itemToEdit == null && selectedCategory != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ItemsScreen(category: selectedCategory!),
              ),
            );
          } else {
            Navigator.pop(context);
          }
          return;
        }
        
        // Only show error message if it's a real database issue, not a duplicate entry
        if (e.toString().contains('database') || 
            e.toString().contains('MySQL') ||
            e.toString().contains('connection') ||
            e.toString().contains('Failed to')) {
          
          // Don't show error if it's a duplicate entry error
          if (!e.toString().contains('Duplicate entry')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(LocalizationService.translate('messages.failedToSave')),
                backgroundColor: Colors.red[700],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(10),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
        
        // Always try to navigate to the category screen as the item might 
        // have been saved successfully despite the error
        if (widget.itemToEdit == null && selectedCategory != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ItemsScreen(category: selectedCategory!),
            ),
          );
        } else {
          Navigator.pop(context);
        }
      }
    }

    // Execute the save operation
    saveItemOperation();
  }

  // Create consistent text field decoration
  InputDecoration _getInputDecoration({
    String? hint,
    Widget? prefixIcon,
    String? suffixText,
    String? prefixText,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
      prefixIcon: prefixIcon,
      prefixText: prefixText,
      suffixText: suffixText,
      contentPadding:
          EdgeInsets.symmetric(horizontal: prefixIcon == null ? 16 : 0, vertical: 0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: Colors.red),
      ),
      constraints: BoxConstraints(
        minHeight: inputHeight,
        maxHeight: inputHeight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          LocalizationService.translate('addStockScreen.title'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Name
              _buildSectionTitle(LocalizationService.translate('addStockScreen.itemName'), null),
              const SizedBox(height: 8),
              SizedBox(
                height: inputHeight,
                child: TextField(
                  controller: _itemNameController,
                  decoration: _getInputDecoration(
                    hint: LocalizationService.translate('addStockScreen.enterItemName'),
                    prefixIcon: Icon(Icons.inventory_2_outlined,
                        color: primaryColor, size: 20),
                  ),
                ),
              ),
              SizedBox(height: sectionSpacing),

              // Category Section
              _buildSectionTitle(LocalizationService.translate('addStockScreen.category'), null),
              const SizedBox(height: 8),

              InkWell(
                onTap: _showCategorySelection,
                child: Container(
                  height: inputHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        color: primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedCategory == null
                              ? LocalizationService.translate('addStockScreen.selectCategory')
                              : selectedCategory!.name,
                          style: TextStyle(
                            color: selectedCategory == null
                                ? Colors.grey[600]
                                : Colors.black87,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Quantity and Min Level
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(LocalizationService.translate('addStockScreen.quantity'), null),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: SizedBox(
                                height: inputHeight,
                                child: TextField(
                                  controller: _quantityController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: _getInputDecoration(
                                    hint: '0',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: inputHeight,
                                child: DropdownButtonFormField<String>(
                                  key: UniqueKey(),
                                  value: selectedUnit,
                                  isExpanded: true,
                                  icon: Icon(Icons.arrow_drop_down,
                                      color: primaryColor, size: 20),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 0),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(borderRadius),
                                      borderSide:
                                          BorderSide(color: borderColor),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(borderRadius),
                                      borderSide:
                                          BorderSide(color: borderColor),
                                    ),
                                    constraints: BoxConstraints(
                                      minHeight: inputHeight,
                                      maxHeight: inputHeight,
                                    ),
                                  ),
                                  items: units
                                      .map<DropdownMenuItem<String>>((unit) {
                                    return DropdownMenuItem<String>(
                                      value: unit['value'] as String,
                                      child: Text(
                                        unit['label'] as String,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedUnit = value;
                                      });
                                    }
                                  },
                                  dropdownColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(LocalizationService.translate('addStockScreen.minimumLevel'), null),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: inputHeight,
                          child: TextField(
                            controller: _minLevelController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _getInputDecoration(
                              hint: LocalizationService.translate('addStockScreen.setMinimum'),
                              prefixIcon: Icon(Icons.warning_amber_rounded,
                                  color: Colors.amber, size: 20),
                              suffixText: selectedUnit,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: sectionSpacing),

              // Price and Total Value
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(LocalizationService.translate('addStockScreen.price'), null),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: inputHeight,
                    child: TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: _getInputDecoration(
                        hint: '0.00',
                        prefixText: '€ ',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(LocalizationService.translate('addStockScreen.totalValue'), null),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${LocalizationService.translate('addStockScreen.value')} € ${_totalValue.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: sectionSpacing),

              // QR / Barcode
              _buildSectionTitle(LocalizationService.translate('addStockScreen.qrBarcode'), null),
              const SizedBox(height: 8),
              if (_barcodeController.text.isEmpty)
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ScannerScreen(isFromAddStock: true),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _barcodeController.text = result;
                      });
                    }
                  },
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(borderRadius),
                      color: lightGray,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.qr_code_scanner,
                              color: primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocalizationService.translate('addStockScreen.scanQrBarcode'),
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                LocalizationService.translate('addStockScreen.tapToScan'),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(borderRadius),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      BarcodeWidget(
                        barcode: Barcode.code128(),
                        data: _barcodeController.text,
                        width: double.infinity,
                        height: 70,
                        drawText: false,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              _barcodeController.text,
                              style: const TextStyle(
                                fontSize: 14,
                                letterSpacing: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ScannerScreen(isFromAddStock: true),
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              _barcodeController.text = result;
                            });
                          }
                        },
                        icon: Icon(Icons.qr_code_scanner,
                            color: primaryColor, size: 16),
                        label: Text(
                          LocalizationService.translate('addStockScreen.rescan'),
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 14,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: sectionSpacing),

              // Add space at the bottom to prevent content from being hidden behind the bottom navigation bar
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: primaryColor),
                  ),
                ),
                child: Text(
                  LocalizationService.translate('common.cancel'),
                  style: TextStyle(color: primaryColor, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  LocalizationService.translate('common.save'),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String? subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (subtitle != null) const SizedBox(height: 2),
        if (subtitle != null)
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _barcodeController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _minLevelController.dispose();
    super.dispose();
  }
}

// Class is kept but no longer used in the updated UI
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({
    this.color = Colors.black,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    final double dashWidth = 5;

    // Top line
    double startX = 0;
    while (startX < size.width) {
      path.moveTo(startX, 0);
      path.lineTo(startX + dashWidth, 0);
      startX += dashWidth + gap;
    }

    // Right line
    double startY = 0;
    while (startY < size.height) {
      path.moveTo(size.width, startY);
      path.lineTo(size.width, startY + dashWidth);
      startY += dashWidth + gap;
    }

    // Bottom line
    startX = size.width;
    while (startX > 0) {
      path.moveTo(startX, size.height);
      path.lineTo(startX - dashWidth, size.height);
      startX -= dashWidth + gap;
    }

    // Left line
    startY = size.height;
    while (startY > 0) {
      path.moveTo(0, startY);
      path.lineTo(0, startY - dashWidth);
      startY -= dashWidth + gap;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
