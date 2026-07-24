import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/item_provider.dart';
import '../services/localization_service.dart';
import '../language_selection.dart';
import '../widgets/translatable_text.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
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
            // Top Header: Profile / Staff Profile & Notification Bell
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile',
                        style: GoogleFonts.urbanist(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Staff Profile',
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const NotificationIcon(
                    iconColor: AppTheme.textPrimary,
                    useContainerBackground: false,
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  // Main Staff Profile Card (Mockup Image 2)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Avatar and Header Info
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar with Camera Edit Badge
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 42,
                                  backgroundColor: AppTheme.lightBlue,
                                  backgroundImage: (user?.profilePictureUrl != null && user!.profilePictureUrl!.isNotEmpty)
                                      ? NetworkImage(user.profilePictureUrl!) as ImageProvider
                                      : null,
                                  child: (user?.profilePictureUrl == null || user!.profilePictureUrl!.isEmpty)
                                      ? Text(
                                          user != null && user.name.isNotEmpty
                                              ? user.name.substring(0, 1).toUpperCase()
                                              : 'J',
                                          style: GoogleFonts.urbanist(
                                            color: AppTheme.primaryColor,
                                            fontSize: 34,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ProfileScreen(initialEditMode: true),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppTheme.borderColor, width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_outlined,
                                        size: 16,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),

                            // Name, Role Badge, and Details List
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? 'Jawahar D',
                                    style: GoogleFonts.urbanist(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Signature Light Blue Role Badge Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.lightBlue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      user?.displayRoleTitle ?? 'Sales Executive',
                                      style: GoogleFonts.urbanist(
                                        color: AppTheme.primaryColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Staff ID
                                  _buildDetailRow(Icons.badge_outlined, 'Staff ID', ': ${user?.displayStaffId ?? "STF-00024"}'),
                                  const SizedBox(height: 6),

                                  // Branch
                                  _buildDetailRow(Icons.account_balance_outlined, 'Branch', ': ${user?.displayBranch ?? "Chennai Main Branch"}'),
                                  const SizedBox(height: 6),

                                  // Phone
                                  _buildDetailRow(Icons.phone_outlined, 'Phone', ': ${user?.displayPhone ?? "+91 98765 43210"}'),
                                  const SizedBox(height: 6),

                                  // Email
                                  _buildDetailRow(Icons.mail_outline, 'Email', ': ${user?.email ?? "jawahar@gmail.com"}'),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Edit Profile Button
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfileScreen(initialEditMode: true),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryColor),
                            label: Text(
                              'Edit Profile',
                              style: GoogleFonts.urbanist(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.primaryColor, width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ACCOUNT Section Header
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'ACCOUNT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                  _buildMenuCard(
                    context,
                    children: [
                      _buildMenuItemWithSubtitle(
                        context,
                        icon: Icons.person_outline,
                        title: 'Personal Information',
                        subtitle: 'View and update your personal details',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(initialEditMode: false),
                            ),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItemWithSubtitle(
                        context,
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        subtitle: 'Update your account password',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(initialEditMode: true),
                            ),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItemWithSubtitle(
                        context,
                        icon: Icons.business_outlined,
                        title: 'Company Information',
                        subtitle: 'View company and branch details',
                        onTap: () {
                          _showCompanyDetailsDialog(context, user);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // PREFERENCES Section Header
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'PREFERENCES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                  _buildMenuCard(
                    context,
                    children: [
                      _buildMenuItemWithSubtitle(
                        context,
                        icon: Icons.language_outlined,
                        title: 'Language',
                        subtitle: 'Change app language',
                        onTap: () async {
                          final selectedLanguage = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LanguageSelectionScreen(isFromMenu: true),
                            ),
                          );
                          if (selectedLanguage != null && context.mounted) {
                            final provider = Provider.of<LocalizationProvider>(context, listen: false);
                            final selectedLocale = _getLocaleFromLanguageName(selectedLanguage);
                            await provider.changeLanguage(selectedLocale);
                          }
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItemWithSubtitle(
                        context,
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        subtitle: 'Get help and contact us',
                        onTap: () {
                          Navigator.pushNamed(context, '/walkthrough');
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => _showSignOutDialog(context),
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.red.shade200, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 65,
          child: Text(
            label,
            style: GoogleFonts.urbanist(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.urbanist(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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

  Widget _buildMenuItemWithSubtitle(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.urbanist(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.urbanist(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
              size: 20,
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

  void _showCompanyDetailsDialog(BuildContext context, user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.business, color: Color(0xFF00BBF9)),
            SizedBox(width: 10),
            Text('Company Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Company Name:', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            Text(user?.companyName?.isNotEmpty == true ? user!.companyName! : 'Default Company',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Text('Registered Email:', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            Text(user?.email ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            Text('User Role:', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            Text(user?.isAdmin == true ? 'Administrator' : 'Staff Member',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF00BBF9))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close', style: TextStyle(color: Color(0xFF00BBF9))),
          ),
        ],
      ),
    );
  }
}
