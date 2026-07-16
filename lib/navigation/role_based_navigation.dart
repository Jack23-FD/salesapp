import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../screens/admin/admin_dashboard.dart';
import '../dashboard/dashboard_screen.dart';
import '../services/rbac_service.dart';
import '../providers/auth_provider.dart';
import '../screens/admin/staff_management.dart';
import '../screens/admin/statistics_screen.dart';
import '../auth/signin.dart';
import '../main.dart'; // Import for MainNavigationController

/// A navigation manager that handles routing based on user roles
class RoleBasedNavigation {
  static final RbacService _rbacService = RbacService();

  /// Navigate to the appropriate home screen based on user role
  static void navigateToHomeScreen(BuildContext context, User user) {
    print("RoleBasedNavigation: navigating for role ${user.role}, isAdmin: ${user.isAdmin}");
    print("RoleBasedNavigation: User data - Name: ${user.name}, Email: ${user.email}, ID: ${user.id}");
    
    // Use direct navigation with MaterialPageRoute instead of named routes
    if (user.isAdmin) {
      print("RoleBasedNavigation: Navigating to AdminDashboard directly (user is admin)");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboard()),
        (route) => false,
      );
    } else {
      print("RoleBasedNavigation: Navigating to MainNavigationController directly (user is staff)");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationController()),
        (route) => false,
      );
    }
  }

  /// Get the appropriate home screen widget based on user role
  static Widget getHomeScreen(User user) {
    if (user.isAdmin) {
      return const AdminDashboard();
    } else {
      // Return the MainNavigationController instead of DashboardScreen directly
      // This will include the proper bottom navigation bar
      return const MainNavigationController();
    }
  }

  /// Check if a user can access a specific route
  static bool canAccessRoute(User user, String routeName) {
    return _rbacService.canAccessRoute(user, routeName);
  }

  /// Generate role-based routes
  static Map<String, WidgetBuilder> generateRoutes() {
    return {
      '/admin_dashboard': (context) => const AdminDashboard(),
      '/admin/staff_management': (context) => _buildProtectedRoute(
            context,
            'staff_management',
            const StaffManagementScreen(),
          ),
      '/admin/statistics': (context) => _buildProtectedRoute(
            context,
            'view_statistics',
            const StatisticsScreen(),
          ),
    };
  }

  /// Build a route that is protected by permission check
  static Widget _buildProtectedRoute(
    BuildContext context,
    String permission,
    Widget destination,
  ) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      // User not authenticated, redirect to login
      return const SignInScreen();
    }

    if (_rbacService.hasPermission(user, permission)) {
      return destination;
    } else {
      // User doesn't have permission, show access denied
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'You do not have permission to access this page',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }
} 