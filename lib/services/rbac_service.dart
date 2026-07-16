import 'package:flutter/material.dart';
import '../models/user.dart';

/// Service for handling Role-Based Access Control (RBAC) functionality
class RbacService {
  /// Singleton instance
  static final RbacService _instance = RbacService._internal();
  
  /// Factory constructor that returns the singleton instance
  factory RbacService() => _instance;
  
  /// Private constructor
  RbacService._internal();

  /// Define permissions for each role
  final Map<UserRole, Set<String>> _rolePermissions = {
    UserRole.admin: {
      'staff_management',
      'view_statistics',
      'manage_items',
      'view_items',
      'manage_categories',
      'export_data',
      'system_settings',
    },
    
    UserRole.staff: {
      'view_items',
      'manage_items',
      'view_categories',
    },
  };

  /// Check if the user has a specific permission
  bool hasPermission(User user, String permission) {
    final permissions = _rolePermissions[user.role];
    return permissions?.contains(permission) ?? false;
  }

  /// Get all permissions for a role
  Set<String> getPermissionsForRole(UserRole role) {
    return _rolePermissions[role] ?? {};
  }

  /// Check if the user is allowed to access a specific route
  bool canAccessRoute(User user, String routeName) {
    // Define route permissions mapping
    final Map<String, Set<String>> routePermissions = {
      '/admin/staff_management': {'staff_management'},
      '/admin/statistics': {'view_statistics'},
      '/admin/settings': {'system_settings'},
      '/items': {'view_items'},
      '/categories': {'view_categories', 'manage_categories'},
    };

    // Get required permissions for the route
    final requiredPermissions = routePermissions[routeName];
    
    // If no specific permissions are defined for this route, allow access
    if (requiredPermissions == null || requiredPermissions.isEmpty) {
      return true;
    }
    
    // Check if user has any of the required permissions
    return requiredPermissions.any((permission) => hasPermission(user, permission));
  }

  /// Check if a user is an admin
  bool isAdmin(User user) => user.role == UserRole.admin;

  /// Create a widget based on permission
  Widget permissionBuilder({
    required User user,
    required String permission,
    required Widget granted,
    Widget? denied,
  }) {
    if (hasPermission(user, permission)) {
      return granted;
    } else {
      return denied ?? const SizedBox.shrink();
    }
  }
} 