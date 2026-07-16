import 'package:flutter/material.dart';
import 'dashboard/dashboard_screen.dart' as dashboard;

class DashboardScreen extends StatelessWidget {
  final bool isInMainNavigation;

  const DashboardScreen({super.key, this.isInMainNavigation = false});

  @override
  Widget build(BuildContext context) {
    // This is a wrapper that delegates to the actual implementation
    return dashboard.DashboardScreen(isInMainNavigation: isInMainNavigation);
  }
}
