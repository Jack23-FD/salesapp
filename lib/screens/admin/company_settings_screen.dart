import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _branchController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCompanySettings();
  }

  Future<void> _loadCompanySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _nameController.text = prefs.getString('company_name') ?? 'Supermarket POS';
        _branchController.text = prefs.getString('company_branch') ?? 'Chennai Main Branch';
        _phoneController.text = prefs.getString('company_phone') ?? '+91 98765 43210';
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading company settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCompanySettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('company_name', _nameController.text.trim());
        await prefs.setString('company_branch', _branchController.text.trim());
        await prefs.setString('company_phone', _phoneController.text.trim());

        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Company details saved successfully!'),
              backgroundColor: Color(0xFF00B259),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save company details: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _branchController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Company Details',
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BBF9).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF00BBF9).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFF00BBF9)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Company details configured here will automatically appear on staff sales receipts and customer invoices.',
                              style: GoogleFonts.urbanist(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Company Name
                    Text(
                      'Company Name',
                      style: GoogleFonts.urbanist(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter company name',
                        prefixIcon: const Icon(Icons.business_rounded, color: Color(0xFF00BBF9)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter company name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Branch Name / Address
                    Text(
                      'Branch Name / Store Address',
                      style: GoogleFonts.urbanist(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _branchController,
                      decoration: InputDecoration(
                        hintText: 'Enter branch name or store address',
                        prefixIcon: const Icon(Icons.storefront_rounded, color: Color(0xFF00BBF9)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter branch name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Company Mobile Number
                    Text(
                      'Company Mobile Number',
                      style: GoogleFonts.urbanist(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Enter company phone or mobile number',
                        prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF00BBF9)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter mobile number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 36),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BBF9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isSaving ? null : _saveCompanySettings,
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Save Company Details',
                                style: GoogleFonts.urbanist(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
