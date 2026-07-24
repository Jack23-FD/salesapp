import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/user.dart';
import '../../services/rbac_service.dart';
import '../../services/mysql_database_service.dart';
import 'staff_management.dart';
import 'statistics_screen.dart';
import 'company_settings_screen.dart';
import '../../theme/app_theme.dart';
import 'dart:async';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final RbacService _rbacService = RbacService();
  final MySqlDatabaseService _dbService = MySqlDatabaseService();
  
  bool _isLoadingStats = false;
  int _totalItems = 0;
  int _totalCategories = 0;
  int _itemsAddedToday = 0;
  int _itemsRemovedToday = 0;
  double _totalValueToday = 0;
  
  // Add cache variables with expiration
  bool _hasCachedStats = false;
  DateTime? _cacheTime;
  final _cacheValidDuration = const Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    print("Admin Dashboard: initState called");
    _loadDatabaseStatistics();
  }
  
  bool get _isCacheValid {
    if (!_hasCachedStats || _cacheTime == null) return false;
    final now = DateTime.now();
    return now.difference(_cacheTime!) < _cacheValidDuration;
  }
  
  Future<void> _loadDatabaseStatistics() async {
    // If we have valid cached data, don't reload
    if (_isCacheValid) {
      print('Admin Dashboard: Using cached statistics');
      return;
    }
    
    setState(() {
      _isLoadingStats = true;
    });
    
    try {
      // Get today's date for stats
      final today = DateTime.now();
      
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

      // Force reload to get latest data from API backend
      await itemProvider.reloadFromDatabase();
      await categoryProvider.reloadFromDatabase();

      final totalItems = itemProvider.getAllItems().length;
      final totalCategories = categoryProvider.categories.length;

      final itemsAddedToday = await itemProvider.getTotalInboundQuantityFromDB(today);
      final itemsRemovedToday = await itemProvider.getTotalOutboundQuantityFromDB(today);
      final inboundValue = await itemProvider.getTotalInboundValueFromDB(today);
      final outboundValue = await itemProvider.getTotalOutboundValueFromDB(today);
      
      setState(() {
        _totalItems = totalItems;
        _totalCategories = totalCategories;
        _itemsAddedToday = itemsAddedToday;
        _itemsRemovedToday = itemsRemovedToday;
        _totalValueToday = inboundValue - outboundValue;
        _isLoadingStats = false;
        _hasCachedStats = true;
        _cacheTime = DateTime.now();
      });
      
      print('Admin Dashboard: Statistics loaded from API backend');
      print('Total Items: $_totalItems, Categories: $_totalCategories');
      print('Today - Added: $_itemsAddedToday, Removed: $_itemsRemovedToday, Value: $_totalValueToday');
      
    } catch (e) {
      print('Error loading database statistics: $e');
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Admin Dashboard: build method called");
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    if (currentUser == null) {
      print("Admin Dashboard: Access denied - User is null");
      return _buildAccessDeniedScreen(context, "User is not authenticated");
    }
    
    print("Admin Dashboard: Current user - ${currentUser.toString()}");
    print("Admin Dashboard: Is admin? ${currentUser.isAdmin}, Role: ${currentUser.role}");
    
    if (!currentUser.isAdmin) {
      print("Admin Dashboard: Access denied - User is not admin: ${currentUser.role}");
      return _buildAccessDeniedScreen(context, "You do not have admin privileges");
    }

    print("Admin Dashboard: Rendering for admin user: ${currentUser.name}");

    return Scaffold(
      backgroundColor: AppTheme.secondaryBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.textPrimary),
            onPressed: _loadDatabaseStatistics,
            tooltip: 'Refresh statistics',
          ),
          IconButton(
            icon: Icon(Icons.logout, color: AppTheme.textPrimary),
            onPressed: () async {
              await authProvider.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/signin', 
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting Section
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppTheme.lightOrange,
                      child: Text(
                        currentUser.name.isNotEmpty ? currentUser.name.substring(0, 1).toUpperCase() : 'A',
                        style: GoogleFonts.urbanist(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          currentUser.name,
                          style: GoogleFonts.urbanist(
                            fontSize: 20,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Admin functions
              Text(
                'Admin Functions',
                style: GoogleFonts.urbanist(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Admin function cards
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.1,
                children: [
                  // Staff Management Card
                  _buildAdminCard(
                    context,
                    title: 'Staff Management',
                    icon: Icons.people_outline,
                    color: AppTheme.success,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StaffManagementScreen(),
                        ),
                      );
                    },
                    requiresPermission: 'staff_management',
                    user: currentUser,
                  ),

                  // Statistics Card
                  _buildAdminCard(
                    context,
                    title: 'Statistics',
                    icon: Icons.bar_chart_outlined,
                    color: AppTheme.secondaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StatisticsScreen(),
                        ),
                      );
                    },
                    requiresPermission: 'view_statistics',
                    user: currentUser,
                  ),

                  // System Settings Card
                  _buildAdminCard(
                    context,
                    title: 'System Settings',
                    icon: Icons.settings_outlined,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CompanySettingsScreen(),
                        ),
                      );
                    },
                    requiresPermission: 'system_settings',
                    user: currentUser,
                  ),

                  // Export Data Card
                  _buildAdminCard(
                    context,
                    title: 'Export Data',
                    icon: Icons.download_outlined,
                    color: AppTheme.primaryColor,
                    onTap: () async {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          backgroundColor: AppTheme.backgroundColor,
                          surfaceTintColor: AppTheme.backgroundColor,
                          title: Text(
                            'Export Data',
                            style: GoogleFonts.urbanist(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select data to export:',
                                style: GoogleFonts.urbanist(
                                  fontSize: 16,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildExportOption(dialogContext, 'Products', Icons.inventory_2_outlined, () {
                                _exportData(dialogContext, 'products');
                              }),
                              const SizedBox(height: 8),
                              _buildExportOption(dialogContext, 'Categories', Icons.category_outlined, () {
                                _exportData(dialogContext, 'categories');
                              }),
                              const SizedBox(height: 8),
                              _buildExportOption(dialogContext, 'Transactions', Icons.receipt_long_outlined, () {
                                _exportData(dialogContext, 'transactions');
                              }),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                              },
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.urbanist(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      );
                    },
                    requiresPermission: 'export_data',
                    user: currentUser,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Quick Statistics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Statistics',
                    style: GoogleFonts.urbanist(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (_isLoadingStats)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildStatisticRow(
                      'Total Items',
                      '$_totalItems',
                      Icons.inventory_2_outlined,
                      AppTheme.secondaryColor,
                    ),
                    Divider(color: AppTheme.dividerColor),
                    _buildStatisticRow(
                      'Total Categories',
                      '$_totalCategories',
                      Icons.category_outlined,
                      AppTheme.success,
                    ),
                    Divider(color: AppTheme.dividerColor),
                    _buildStatisticRow(
                      'Items Added Today',
                      '$_itemsAddedToday',
                      Icons.add_circle_outline,
                      Colors.purple,
                    ),
                    Divider(color: AppTheme.dividerColor),
                    _buildStatisticRow(
                      'Items Removed Today',
                      '$_itemsRemovedToday',
                      Icons.remove_circle_outline,
                      AppTheme.primaryColor,
                    ),
                    Divider(color: AppTheme.dividerColor),
                    _buildStatisticRow(
                      'Net Value Change Today',
                      '€${_totalValueToday.toStringAsFixed(2)}',
                      Icons.monetization_on_outlined,
                      _totalValueToday >= 0 ? AppTheme.success : AppTheme.warning,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String requiresPermission,
    required User user,
  }) {
    final bool hasPermission = _rbacService.hasPermission(user, requiresPermission);

    if (!hasPermission) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.urbanist(
                fontWeight: FontWeight.bold,
                fontSize: 15.0,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticRow(
      String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.urbanist(
                fontSize: 15.0,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.urbanist(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessDeniedScreen(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: AppTheme.secondaryBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Access Denied',
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warningBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                  child: const Text('Go Back to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportOption(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.lightOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _exportData(BuildContext context, String dataType) async {
    // Get item provider early before any navigation change
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    
    // Close the first dialog first
    Navigator.of(context).pop();
    
    // Show a simple snackbar to indicate the export is starting
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting ${dataType.capitalize()}...'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    
    try {
      // Simple switch statement for different export types
      switch (dataType) {
        case 'products':
          await itemProvider.exportProducts(DateTime.now());
          break;
        case 'categories': 
          await itemProvider.exportCategories();
          break;
        case 'transactions':
          await itemProvider.exportTransactions(DateTime.now());
          break;
        default:
          throw Exception('Unknown data type: $dataType');
      }
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${dataType.capitalize()} data exported successfully'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      print('Error exporting $dataType: $e');
      
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: ${e.toString()}'),
            backgroundColor: AppTheme.warning,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}

// Extension to capitalize first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 