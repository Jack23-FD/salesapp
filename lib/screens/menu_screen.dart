import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/item_provider.dart';
import '../services/localization_service.dart';
import '../language_selection.dart';
import '../widgets/translatable_text.dart';
import '../utils/translation_utils.dart';
import '../widgets/notification_icon.dart';
import 'dart:async';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  // Helper method to convert language name to locale
  Locale _getLocaleFromLanguageName(String languageName) {
    switch (languageName) {
      case 'English':
        return const Locale('en', 'US');
      case 'Tamil':
        return const Locale('ta', 'IN');
      case 'German':
        return const Locale('de', 'DE');
      default:
        return const Locale('en', 'US');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isLoggedIn = authProvider.isAuthenticated;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header with title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  TranslatableText(
                    'menu.myAccount',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  const NotificationIcon(
                    iconColor: const Color(0xFFFF8A00),
                    useContainerBackground: false,
                  ),
                ],
              ),
            ),

            // Profile card
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // User avatar with gradient background
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8A00), Color(0xFFFFC04C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          user != null && user.name != null
                              ? user.name.substring(0, 1).toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user != null && user.name != null
                                ? user.name
                                : 'User Name',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'sample123@gmail.com',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Navigate to profile edit screen
                            },
                            icon: const Icon(Icons.edit, size: 16),
                            label: TranslatableText(
                              'menu.editProfile',
                              style: const TextStyle(
                                color: const Color(0xFFFF8A00),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF8A00),
                              side: const BorderSide(color: const Color(0xFFFF8A00)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Menu sections
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Account section
                  _buildSectionHeader(context, 'menu.sections.account'),
                  _buildMenuCard(
                    context,
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.person_outline,
                        title: 'menu.userProfile',
                        onTap: () {
                          // TODO: Navigate to user profile screen
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        context,
                        icon: Icons.business_outlined,
                        title: 'menu.companyDetails',
                        onTap: () {
                          // TODO: Navigate to company details screen
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        context,
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'menu.adminLogin',
                        onTap: () {
                          // TODO: Navigate to admin login screen
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Preferences section
                  _buildSectionHeader(context, 'menu.sections.preferences'),
                  _buildMenuCard(
                    context,
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.language_outlined,
                        title: 'menu.changeLanguage',
                        onTap: () async {
                          final selectedLanguage = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const LanguageSelectionScreen(
                                isFromMenu: true,
                              ),
                            ),
                          );

                          if (selectedLanguage != null && context.mounted) {
                            // Force UI refresh by updating the provider
                            final provider = Provider.of<LocalizationProvider>(context, listen: false);
                            
                            // Get locale from the selected language
                            final selectedLocale = _getLocaleFromLanguageName(selectedLanguage);
                            
                            // Apply the change again to ensure it takes effect
                            await provider.changeLanguage(selectedLocale);
                            
                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              AppTranslations.getTranslatedSnackBar(
                                'menu.languageChanged',
                              ),
                            );
                            
                            // Instead of replacing just this screen, pop to the main navigation
                            // controller and let it refresh with the new language
                            if (context.mounted) {
                              // Find the original navigation controller
                              final navKey = ItemProvider.navigatorKey;
                              if (navKey.currentState != null && navKey.currentContext != null) {
                                // Force rebuild of entire app by updating main provider
                                Provider.of<LocalizationProvider>(navKey.currentContext!, listen: false)
                                    .notifyListeners();
                              }
                            }
                          }
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        context,
                        icon: Icons.help_outline,
                        title: 'menu.helpSupport',
                        onTap: () {
                          Navigator.pushNamed(context, '/walkthrough');
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Sign out button
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showSignOutDialog(context);
                      },
                      icon: const Icon(Icons.logout),
                      label: TranslatableText('auth.signOut'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red[700],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        side: BorderSide(color: Colors.red[100]!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String titleKey) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: TranslatableText(
        titleKey,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context,
      {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                color: const Color(0xFFFF8A00),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            TranslatableText(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      endIndent: 16,
      color: Color(0xFFF0F0F0),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: TranslatableText('auth.signOut'),
        content: TranslatableText('auth.signOutConfirmation'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: TranslatableText('common.cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Close the confirmation dialog first
              Navigator.pop(dialogContext);

              try {
                // Sign out with timeout
                await authProvider.signOut().timeout(
                  const Duration(seconds: 3),
                  onTimeout: () {
                    print('Sign out timeout in menu screen');
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
                
                // Show error message if context is still mounted
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: TranslatableText(
                        'errors.signOutError',
                        params: {'error': e.toString()},
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: TranslatableText('auth.signOut'),
          ),
        ],
      ),
    );
  }
}
