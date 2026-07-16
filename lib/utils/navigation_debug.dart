import 'package:flutter/foundation.dart';

/// Helper utility to manage navigation debugging
class NavigationDebug {
  /// Whether to show navigation debug messages in the console
  static bool enableDebugLogs = false;
  
  /// Log a navigation event with optional details
  static void log(String event, [String? details]) {
    if (!enableDebugLogs) return;
    
    final message = details != null 
        ? 'NAVIGATION: $event - $details'
        : 'NAVIGATION: $event';
        
    debugPrint(message);
  }
  
  /// Log a route push event
  static void logPush(String routeName) {
    log('Pushed route', routeName);
  }
  
  /// Log a route pop event
  static void logPop(String routeName) {
    log('Popped route', routeName);
  }
  
  /// Log a route replacement event
  static void logReplace(String oldRoute, String newRoute) {
    log('Replaced route', '$oldRoute → $newRoute');
  }
  
  /// Log general navigation information
  static void logInfo(String message) {
    log('Info', message);
  }
  
  /// Log a navigation error
  static void logError(String message) {
    if (kDebugMode) {
      debugPrint('❌ NAVIGATION ERROR: $message');
    }
  }
} 