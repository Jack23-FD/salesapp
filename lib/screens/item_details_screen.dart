import 'package:flutter/material.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../providers/category_provider.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';

class ItemDetailsScreen extends StatefulWidget {
  final Item item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    
    // Get the category name
    final category = categoryProvider.getCategoryById(widget.item.categoryId);
    final categoryName = category?.name ?? 'Unknown Category';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'itemDetails.title'.tr,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item header with image and basic info
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Item image or placeholder
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF333366),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: widget.item.imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          widget.item.imageUrl!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.inventory_2_outlined,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                              ),
                              const SizedBox(width: 16),
                              // Item name and category
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.item.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.category_outlined,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          categoryName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Price
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.euro_outlined,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${widget.item.price.toStringAsFixed(2)} €',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF333366),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Inventory status
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'itemDetails.inventoryStatus'.tr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'itemDetails.inStock'.tr,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${widget.item.quantity} ${widget.item.unit}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: widget.item.quantity > 0 ? Colors.green[700] : Colors.red[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Show minimum level if set
                              if (widget.item.minLevel != null)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'itemDetails.minLevel'.tr,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${widget.item.minLevel} ${widget.item.unit}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Status indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _getStockStatus(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Item details
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'itemDetails.details'.tr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // ID
                          _buildDetailRow(
                            'itemDetails.id'.tr,
                            widget.item.id,
                          ),
                          const SizedBox(height: 12),
                          // Barcode if available
                          if (widget.item.barcode != null && widget.item.barcode!.isNotEmpty)
                            _buildDetailRow(
                              'Barcode'.tr,
                              widget.item.barcode!,
                            ),
                          if (widget.item.barcode != null && widget.item.barcode!.isNotEmpty)
                            const SizedBox(height: 12),
                          // Created at
                          _buildDetailRow(
                            'itemDetails.createdAt'.tr,
                            _formatDate(widget.item.createdAt),
                          ),
                          const SizedBox(height: 12),
                          // Unit
                          _buildDetailRow(
                            'Unit'.tr,
                            widget.item.unit,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Transaction History
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'itemDetails.stockValue'.tr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'itemDetails.totalValue'.tr,
                            '${(widget.item.price * widget.item.quantity).toStringAsFixed(2)} €',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _getStatusColor() {
    if (widget.item.quantity <= 0) {
      return Colors.red;
    } else if (widget.item.minLevel != null && widget.item.quantity <= widget.item.minLevel!) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _getStockStatus() {
    if (widget.item.quantity <= 0) {
      return 'itemDetails.outOfStock'.tr;
    } else if (widget.item.minLevel != null && widget.item.quantity <= widget.item.minLevel!) {
      return 'itemDetails.lowStock'.tr;
    } else {
      return 'itemDetails.inStock'.tr;
    }
  }
} 