import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizationProvider = Provider.of<LocalizationProvider>(context);
    final currentLocale = localizationProvider.locale;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'profile.language'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildLanguageOption(
              context: context,
              title: 'English',
              locale: const Locale('en', 'US'),
              isSelected: currentLocale.languageCode == 'en',
              onTap: () => _changeLanguage(context, const Locale('en', 'US')),
            ),
            const Divider(),
            _buildLanguageOption(
              context: context,
              title: 'தமிழ்', // Tamil
              locale: const Locale('ta', 'IN'),
              isSelected: currentLocale.languageCode == 'ta',
              onTap: () => _changeLanguage(context, const Locale('ta', 'IN')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String title,
    required Locale locale,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
          ],
        ),
      ),
    );
  }

  void _changeLanguage(BuildContext context, Locale locale) async {
    final provider = Provider.of<LocalizationProvider>(context, listen: false);
    await provider.changeLanguage(locale);
    
    // Show a confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Language changed successfully'.tr),
        duration: const Duration(seconds: 2),
      ),
    );
  }
} 