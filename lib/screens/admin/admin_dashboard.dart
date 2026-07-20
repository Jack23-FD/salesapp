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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.w600,
            fontSize: 20.0,
            color: const Color(0xFF333366),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDatabaseStatistics,
            tooltip: 'Refresh statistics',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
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
              // Admin functions
              Text(
                'Admin Functions',
                style: GoogleFonts.urbanist(
                  fontWeight: FontWeight.w700,
                  fontSize: 18.0,
                  color: const Color(0xFF333366),
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
                children: [
                  // Staff Management Card
                  _buildAdminCard(
                    context,
                    title: 'Staff Management',
                    icon: Icons.people,
                    color: const Color(0xFF4CAF50),
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
                    icon: Icons.bar_chart,
                    color: const Color(0xFF2196F3),
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
                    icon: Icons.settings,
                    color: const Color(0xFF9C27B0),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('System Settings - Coming Soon'),
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
                    icon: Icons.download,
                    color: const Color(0xFFFF9800),
                    onTap: () async {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(
                            'Export Data',
                            style: GoogleFonts.urbanist(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF333366),
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
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildExportOption(dialogContext, 'Products', Icons.inventory, () {
                                _exportData(dialogContext, 'products');
                              }),
                              const SizedBox(height: 8),
                              _buildExportOption(dialogContext, 'Categories', Icons.category, () {
                                _exportData(dialogContext, 'categories');
                              }),
                              const SizedBox(height: 8),
                              _buildExportOption(dialogContext, 'Transactions', Icons.receipt_long, () {
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
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      );
                    },
                    requiresPermission: 'export_data',
                    user: currentUser,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Quick Statistics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Statistics',
                    style: GoogleFonts.urbanist(
                      fontWeight: FontWeight.w700,
                      fontSize: 18.0,
                      color: const Color(0xFF333366),
                    ),
                  ),
                  if (_isLoadingStats)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF333366)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildStatisticRow(
                      'Total Items',
                      '$_totalItems',
                      Icons.inventory,
                      const Color(0xFF2196F3),
                    ),
                    const Divider(),
                    _buildStatisticRow(
                      'Total Categories',
                      '$_totalCategories',
                      Icons.category,
                      const Color(0xFF4CAF50),
                    ),
                    const Divider(),
                    _buildStatisticRow(
                      'Items Added Today',
                      '$_itemsAddedToday',
                      Icons.add_circle,
                      const Color(0xFF9C27B0),
                    ),
                    const Divider(),
                    _buildStatisticRow(
                      'Items Removed Today',
                      '$_itemsRemovedToday',
                      Icons.remove_circle,
                      const Color(0xFFFF9800),
                    ),
                    const Divider(),
                    _buildStatisticRow(
                      'Net Value Change Today',
                      '€${_totalValueToday.toStringAsFixed(2)}',
                      Icons.monetization_on,
                      _totalValueToday >= 0 ? const Color(0xFF4CAF50) : Colors.red,
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.urbanist(
                fontWeight: FontWeight.w600,
                fontSize: 16.0,
                color: const Color(0xFF333366),
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
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.urbanist(
                fontSize: 16.0,
                color: Colors.grey[800],
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.urbanist(
              fontWeight: FontWeight.w700,
              fontSize: 18.0,
              color: const Color(0xFF333366),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessDeniedScreen(BuildContext context, String message) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Access Denied',
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.w600,
            fontSize: 20.0,
            color: const Color(0xFF333366),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF333366),
              ),
              child: const Text('Go Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFFF9800),
                size: 24,
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
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
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
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
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