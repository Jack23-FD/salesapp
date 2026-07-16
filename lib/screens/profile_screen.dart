import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../widgets/language_selector.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile.myProfile'.tr),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildUserInfoSection(context),
          const Divider(),
          _buildAccountSection(context),
          const Divider(),
          _buildPreferencesSection(context),
          const Divider(),
          // Add language selector
          const LanguageSelector(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'profile.myProfile'.tr,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const CircleAvatar(
              backgroundImage: AssetImage('assets/images/default_avatar.png'),
              radius: 30,
            ),
            title: Text('John Doe'),
            subtitle: Text('john.doe@example.com'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Handle edit profile
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.lock),
            title: Text('profile.changePassword'.tr),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Handle change password
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: Text('profile.securitySettings'.tr),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Handle security settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferences',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text('profile.notificationPreferences'.tr),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Handle notification preferences
            },
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: Text('profile.theme'.tr),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Handle theme settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: Text('profile.timeZone'.tr),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Handle time zone settings
            },
          ),
        ],
      ),
    );
  }
} 