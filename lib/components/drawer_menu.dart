import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/localization_service.dart';
import '../utils/app_localizations.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.user?.isAdmin ?? false;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/images/default_avatar.png'),
                ),
                const SizedBox(height: 10),
                Text(
                  authProvider.user?.displayName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                Text(
                  authProvider.user?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: Text('navigation.dashboard'.tr),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
          ),
          ListTile(
            leading: const Icon(Icons.compare_arrows),
            title: Text('navigation.stock'.tr),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/inventory');
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: Text('navigation.categories'.tr),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/categories');
            },
          ),
          if (isAdmin) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: Text('adminDashboard.title'.tr),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/admin_dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: Text('staffManagement.title'.tr),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin/staff_management');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text('statistics.title'.tr),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin/statistics');
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text('navigation.profile'.tr),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: Text('navigation.help'.tr),
            onTap: () {
              Navigator.pop(context);
              // Navigate to help page
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text('auth.signOut'.tr),
            onTap: () {
              Navigator.pop(context);
              _showLogoutConfirmationDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('auth.logout'.tr),
          content: Text('auth.logoutConfirmation'.tr),
          actions: <Widget>[
            TextButton(
              child: Text('uiElements.cancel'.tr),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('auth.logout'.tr),
              onPressed: () async {
                // Close the confirmation dialog first
                Navigator.of(dialogContext).pop();
                
                try {
                  // Sign out with timeout
                  await Provider.of<AuthProvider>(context, listen: false).signOut().timeout(
                    const Duration(seconds: 3),
                    onTimeout: () {
                      throw Exception('Sign out is taking too long. Please try again.');
                    },
                  );
                  
                  // Navigate to sign in page
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/signin',
                      (route) => false,
                    );
                  }
                } catch (e) {
                  print('Error during sign out: $e');
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('errors.signOutError'.tr),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
} 