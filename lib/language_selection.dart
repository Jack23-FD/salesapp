import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'services/localization_service.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final bool skipAuth;
  final bool isFromMenu;

  const LanguageSelectionScreen({
    super.key,
    this.skipAuth = false,
    this.isFromMenu = false,
  });

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLanguage = 'English'; // Default selected language
  bool _isDropdownOpen = false;
  final List<Map<String, dynamic>> _languages = [
    {'name': 'English', 'locale': const Locale('en', 'US')},
    {'name': 'Tamil', 'locale': const Locale('ta', 'IN')},
    {'name': 'German', 'locale': const Locale('de', 'DE')},
  ];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    final currentLocale = LocalizationService.currentLocale;
    
    // Find the language name that corresponds to the current locale
    final currentLanguage = _languages.firstWhere(
      (lang) => lang['locale'].languageCode == currentLocale.languageCode,
      orElse: () => _languages.first,
    );
    
    setState(() {
      _selectedLanguage = currentLanguage['name'];
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    setState(() {
      _isDropdownOpen = !_isDropdownOpen;
    });
  }

  void _selectLanguage(Map<String, dynamic> language) {
    setState(() {
      _selectedLanguage = language['name'];
      _isDropdownOpen = false;
    });
  }

  Future<void> _saveLanguagePreference() async {
    try {
      // Find the locale for the selected language
      final selectedLanguageData = _languages.firstWhere(
        (lang) => lang['name'] == _selectedLanguage,
        orElse: () => _languages.first,
      );
      
      final Locale selectedLocale = selectedLanguageData['locale'];
      
      // Change the app language using LocalizationService
      final provider = Provider.of<LocalizationProvider>(context, listen: false);
      await provider.changeLanguage(selectedLocale);
      
      // Also save the selected language name for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedLanguage', _selectedLanguage);

      if (widget.isFromMenu) {
        // Return the selected language to the menu screen
        if (mounted) {
          Navigator.pop(context, _selectedLanguage);
        }
      } else {
        // Mark onboarding as complete
        await _markOnboardingComplete();

        if (!mounted) return;

        if (widget.skipAuth) {
          // Navigate to sign in screen if skipAuth is true
          Navigator.pushReplacementNamed(context, '/signin');
        } else {
          // Navigate to sign up screen
          Navigator.pushReplacementNamed(
            context,
            '/signup',
            arguments: {'selectedLanguage': _selectedLanguage.toLowerCase()},
          );
        }
      }
    } catch (e) {
      print('Error saving language preference: $e');
    }
  }

  // Mark onboarding as completed in SharedPreferences
  Future<void> _markOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboardingComplete', true);
      print('Onboarding marked as complete (from language screen)');
    } catch (e) {
      print('Error marking onboarding as complete: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
            onPressed: () => Navigator.pop(context),
          ),
          title: Image.asset(
            'assets/images/logo.png',
            height: 32,
            fit: BoxFit.contain,
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pick a language and dive right in!'.tr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 24),

                // Language Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _toggleDropdown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isDropdownOpen
                                  ? 'Select Language'.tr
                                  : _selectedLanguage,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 16,
                              ),
                            ),
                            Icon(
                              _isDropdownOpen
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: const Color(0xFF00BBF9),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isDropdownOpen)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Search box
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search'.tr,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  isDense: true,
                                ),
                              ),
                            ),

                            // Language options
                            ..._languages
                                .map((language) => GestureDetector(
                                      onTap: () => _selectLanguage(language),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: _selectedLanguage == language['name']
                                              ? const Color(0xFF00BBF9)
                                                  .withOpacity(0.1)
                                              : Colors.transparent,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.shade200,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              language['name'],
                                              style:
                                                  const TextStyle(fontSize: 16),
                                            ),
                                            if (_selectedLanguage == language['name'])
                                              const Icon(
                                                Icons.check_circle,
                                                color: const Color(0xFF00BBF9),
                                                size: 20,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ],
                        ),
                      ),
                  ],
                ),

                const Spacer(),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saveLanguagePreference,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BBF9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Continue'.tr),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
