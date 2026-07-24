import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../screens/scanner/scanner_screen.dart';
import '../screens/notification_screen.dart';
import '../screens/add_stock_screen.dart';
import '../screens/use_stock_screen.dart';
import '../providers/notification_provider.dart';
import '../providers/item_provider.dart';
import '../providers/category_provider.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import 'components/date_selector.dart';
import 'components/inbound_card.dart';
import 'components/outbound_card.dart';
import '../utils/storage_utils.dart';
import '../services/localization_service.dart';
import '../utils/app_localizations.dart';
import '../components/dashboard_status_card.dart';
import '../utils/translation_utils.dart';
import '../widgets/notification_icon.dart';

class DashboardScreen extends StatefulWidget {
  final bool isInMainNavigation;

  const DashboardScreen({super.key, this.isInMainNavigation = false});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  bool isInboundExpanded = true;
  bool isOutboundExpanded = false;
  DateTime selectedDate = DateTime.now();
  
  // Statistics variables
  int inboundQuantity = 0;
  int inboundCategories = 0;
  double inboundValue = 0.0;
  int outboundQuantity = 0;
  int outboundCategories = 0;
  double outboundValue = 0.0;
  bool isLoadingStats = false;
  bool _initialLoadComplete = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    debugPrint("DashboardScreen: initState called, preventing unnecessary reloads");
    // Only load data when truly needed, not on every navigation
    if (!_initialLoadComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadData();
      });
    } else {
      debugPrint("DashboardScreen: Skipping data load as it's already loaded");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This helps keep the state when dependencies change (like providers)
    debugPrint("DashboardScreen: didChangeDependencies - maintaining state");
  }

  Future<void> _loadData() async {
    if (_initialLoadComplete) {
      debugPrint("Dashboard: Skip loading as data is already loaded");
      return;
    }

    try {
      debugPrint("Dashboard: Starting fast cached data load");
      
      // 1. Immediately display cached statistics (0ms delay)
      await _loadCachedStatistics();

      // 2. Fetch fresh database data in the background in parallel
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

      Future.wait([
        categoryProvider.reloadFromDatabase(),
        itemProvider.reloadFromDatabase(),
      ]).then((_) async {
        if (mounted) {
          await _loadStatistics();
          _initialLoadComplete = true;
          debugPrint("Dashboard: Background data loading complete");
        }
      }).catchError((e) {
        debugPrint('Error loading background data in dashboard: $e');
      });
    } catch (e) {
      debugPrint('Error in _loadData: $e');
    }
  }

  Future<void> _loadCachedStatistics() async {
    try {
      final key = '${formatDateForCacheKey(selectedDate)}';
      
      // Try to get cached values
      final inQuantity = await StorageUtils.getCachedIntValue('${key}_cached_inbound_quantity');
      final inCategories = await StorageUtils.getCachedIntValue('${key}_cached_inbound_categories');
      final inValue = await StorageUtils.getCachedDoubleValue('${key}_cached_inbound_value');
      final outQuantity = await StorageUtils.getCachedIntValue('${key}_cached_outbound_quantity');
      final outCategories = await StorageUtils.getCachedIntValue('${key}_cached_outbound_categories');
      final outValue = await StorageUtils.getCachedDoubleValue('${key}_cached_outbound_value');
      
      if (mounted) {
        setState(() {
          inboundQuantity = inQuantity ?? 0;
          inboundCategories = inCategories ?? 0;
          inboundValue = inValue ?? 0.0;
          outboundQuantity = outQuantity ?? 0;
          outboundCategories = outCategories ?? 0;
          outboundValue = outValue ?? 0.0;
        });
      }
      
      debugPrint('Loaded cached statistics for dashboard');
    } catch (e) {
      debugPrint('Error loading cached statistics: $e');
    }
  }

  String formatDateForCacheKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  Future<void> _loadStatistics() async {
    if (!mounted) return;
    
    // Only show loading spinner if no cached data exists
    if (inboundQuantity == 0 && outboundQuantity == 0) {
      setState(() {
        isLoadingStats = true;
      });
    }
    
    try {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      
      debugPrint("===== LOADING DASHBOARD STATISTICS FOR DATE: ${selectedDate.toString()} =====");
      
      // Execute all database queries concurrently in parallel instead of sequentially
      final results = await Future.wait([
        itemProvider.getTotalInboundQuantityFromDB(selectedDate),
        itemProvider.getTotalInboundCategoriesFromDB(selectedDate),
        itemProvider.getTotalInboundValueFromDB(selectedDate),
        itemProvider.getTotalOutboundQuantityFromDB(selectedDate),
        itemProvider.getTotalOutboundCategoriesFromDB(selectedDate),
        itemProvider.getTotalOutboundValueFromDB(selectedDate),
      ]);
      
      if (mounted) {
        setState(() {
          inboundQuantity = results[0] as int;
          inboundCategories = results[1] as int;
          inboundValue = (results[2] as num).toDouble();
          outboundQuantity = results[3] as int;
          outboundCategories = results[4] as int;
          outboundValue = (results[5] as num).toDouble();
          isLoadingStats = false;
        });
        
        debugPrint("Dashboard: Updated state with - Inbound: $inboundQuantity units, Outbound: $outboundQuantity units");
      }
    } catch (e) {
      debugPrint('Dashboard: Error getting statistics: $e');
      if (mounted) {
        setState(() {
          isLoadingStats = false;
        });
      }
    }
    
    // Return a completed future for the RefreshIndicator
    return Future.value();
  }

  void _onDateSelected(DateTime? date) {
    if (date != null) {
      setState(() {
        selectedDate = date;
      });
      _loadCachedStatistics(); // Load cached data immediately
      _loadStatistics();       // Then load fresh data
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: AppTheme.secondaryBackgroundColor,
      appBar: widget.isInMainNavigation 
        ? AppBar(
            title: Text(
              'navigation.dashboard'.tr,
              style: GoogleFonts.urbanist(
                fontSize: _calculateFontSize('navigation.dashboard'.tr, 20.0),
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            automaticallyImplyLeading: false,
            backgroundColor: AppTheme.backgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            actions: [
              NotificationIcon(
                useContainerBackground: false,
                iconColor: AppTheme.textPrimary,
              ),
            ],
          )
        : AppBar(
            title: Text(
              'navigation.dashboard'.tr,
              style: GoogleFonts.urbanist(
                fontSize: _calculateFontSize('navigation.dashboard'.tr, 20.0),
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: AppTheme.backgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'dashboard_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UseStockScreen()),
          );
        },
        backgroundColor: const Color(0xFFE0F2FE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF00BBF9)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStatistics,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                    AppBar().preferredSize.height - 
                    MediaQuery.of(context).padding.top,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Selector with Inventory Summary heading
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                          child: Text(
                            'inventory.itemDetails'.tr,
                            style: GoogleFonts.urbanist(
                              fontWeight: FontWeight.bold,
                              fontSize: _calculateFontSize('inventory.itemDetails'.tr, 18.0),
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        DateSelector(
                          selectedDate: selectedDate,
                          onDateSelected: _onDateSelected,
                        ),
                      ],
                    ),
                  ),

                  // Stock Status Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: isLoadingStats
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            children: [
                              InboundCard(
                                quantity: inboundQuantity,
                                categories: inboundCategories,
                                value: inboundValue,
                                isExpanded: isInboundExpanded,
                                onTap: () {
                                  setState(() {
                                    isInboundExpanded = !isInboundExpanded;
                                  });
                                },
                              ),
                              OutboundCard(
                                quantity: outboundQuantity,
                                categories: outboundCategories,
                                value: outboundValue,
                                isExpanded: isOutboundExpanded,
                                onTap: () {
                                  setState(() {
                                    isOutboundExpanded = !isOutboundExpanded;
                                  });
                                },
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 80),
                  // Your other dashboard content below...
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Add export dialog functionality
  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'dashboard.exportData'.translate(),
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00BBF9),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'dashboard.selectDataExport'.translate(),
              style: GoogleFonts.urbanist(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            _buildExportOption(dialogContext, 'dashboard.products'.translate(), Icons.inventory, () {
              _exportData(dialogContext, 'products');
            }),
            _buildExportOption(dialogContext, 'dashboard.categories'.translate(), Icons.category, () {
              _exportData(dialogContext, 'categories');
            }),
            _buildExportOption(dialogContext, 'dashboard.transactions'.translate(), Icons.receipt_long, () {
              _exportData(dialogContext, 'transactions');
            }),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: Text(
              'dashboard.cancel'.translate(),
              style: GoogleFonts.urbanist(
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF00BBF9),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _exportData(BuildContext context, String dataType) async {
    // Store the current context at the beginning
    final currentContext = context;
    
    // Close the export options dialog
    if (Navigator.canPop(currentContext)) {
      Navigator.pop(currentContext);
    }
    
    // Create a completer to control the process
    final completer = Completer<void>();
    
    // Show loading dialog with a safer approach
    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => WillPopScope(
        onWillPop: () async => false, // Prevent back button from closing dialog
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Flexible(
                child: Text(
                  'Preparing $dataType export...',
                  style: GoogleFonts.urbanist(),
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
    
    try {
      // Get the ItemProvider to fetch the data
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      
      // Perform the actual export based on data type
      switch (dataType) {
        case 'products':
          await itemProvider.exportProducts(selectedDate);
          break;
        case 'categories':
          await itemProvider.exportCategories();
          break;
        case 'transactions':
          await itemProvider.exportTransactions(selectedDate);
          break;
      }
      
      // Close dialog
      if (mounted && Navigator.of(currentContext, rootNavigator: true).canPop()) {
        Navigator.of(currentContext, rootNavigator: true).pop();
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('${dataType.capitalize()} data exported successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      // Complete the operation
      if (!completer.isCompleted) {
        completer.complete();
      }
    } catch (e) {
      // Close dialog on error
      if (mounted && Navigator.of(currentContext, rootNavigator: true).canPop()) {
        Navigator.of(currentContext, rootNavigator: true).pop();
      }
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      // Complete the operation even on error
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    
    // Return the completer's future to ensure this method waits appropriately
    return completer.future;
  }

  // Helper method to calculate font size based on text length
  double _calculateFontSize(String text, double baseSize) {
    // Keep original font size for English language
    if (LocalizationService.currentLocale.languageCode == 'en') {
      return baseSize;
    }
    
    // Adjust font size for other languages based on text length
    if (text.length <= 15) {
      return baseSize;
    } else if (text.length <= 25) {
      return baseSize - 2.0;
    } else if (text.length <= 35) {
      return baseSize - 3.0;
    } else {
      return baseSize - 4.0;
    }
  }
}

// Extension to capitalize first letter of a string
extension StringExtension on String {
  String capitalize() {
    return isNotEmpty ? "${this[0].toUpperCase()}${substring(1)}" : this;
  }
}
