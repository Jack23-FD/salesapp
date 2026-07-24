import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final bool initialEditMode;

  const ProfileScreen({
    Key? key,
    this.initialEditMode = true,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controllers for editing
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.displayPhone ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _selectedImagePath = user?.profilePictureUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Pick profile picture from Gallery or Camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
        });

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.updateProfile(profilePictureUrl: pickedFile.path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: Color(0xFF00B259),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Remove profile picture
  Future<void> _removeProfilePicture() async {
    setState(() {
      _selectedImagePath = '';
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.updateProfile(profilePictureUrl: '');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture removed'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  // Bottom Sheet for Profile Picture Options
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Profile Picture',
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2FE),
                    child: Icon(Icons.photo_library, color: AppTheme.primaryColor),
                  ),
                  title: Text('Choose from Gallery', style: GoogleFonts.urbanist(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2FE),
                    child: Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                  ),
                  title: Text('Take a Photo', style: GoogleFonts.urbanist(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                if (_selectedImagePath != null && _selectedImagePath!.isNotEmpty)
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFEBEE),
                      child: Icon(Icons.delete_outline, color: Colors.red),
                    ),
                    title: Text('Remove Photo', style: GoogleFonts.urbanist(color: Colors.red, fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfilePicture();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Save all profile changes
  Future<void> _saveProfileChanges() async {
    setState(() => _isSaving = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      profilePictureUrl: _selectedImagePath,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFF00B259),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    final imagePath = _selectedImagePath ?? user?.profilePictureUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.urbanist(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar & Header Section
              Center(child: _buildAvatarHeader(user, imagePath)),
              const SizedBox(height: 28),

              // Direct Profile Edit Form
              Text(
                'Personal Information',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // Full Name
              _buildEditableInputTile(
                icon: Icons.person_outline,
                label: 'Full Name',
                controller: _nameController,
              ),

              // Gmail / Email Address
              _buildEditableInputTile(
                icon: Icons.mail_outline,
                label: 'Gmail / Email Address',
                controller: _emailController,
              ),

              // Mobile Number
              _buildEditableInputTile(
                icon: Icons.phone_outlined,
                label: 'Mobile Number',
                controller: _phoneController,
              ),

              const SizedBox(height: 20),
              Text(
                'Address',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // Address
              _buildEditableInputTile(
                icon: Icons.location_on_outlined,
                label: 'Edit Address',
                controller: _addressController,
              ),

              const SizedBox(height: 36),

              // Full Width Update Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfileChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'Update Profile',
                          style: GoogleFonts.urbanist(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Avatar Widget with Camera Overlay Button
  Widget _buildAvatarHeader(user, String? imagePath) {
    ImageProvider? imageProvider;

    if (imagePath != null && imagePath.isNotEmpty) {
      if (imagePath.startsWith('http')) {
        imageProvider = NetworkImage(imagePath);
      } else if (File(imagePath).existsSync()) {
        imageProvider = FileImage(File(imagePath));
      }
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFFE0F2FE),
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? Text(
                        (user?.name.isNotEmpty == true ? user!.name[0] : 'U').toUpperCase(),
                        style: GoogleFonts.urbanist(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      )
                    : null,
              ),
            ),
            // Camera Button
            GestureDetector(
              onTap: _showImagePickerOptions,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          user?.name ?? 'User',
          style: GoogleFonts.urbanist(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user?.email ?? '',
          style: GoogleFonts.urbanist(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // REUSABLE EDITABLE INPUT TILE
  Widget _buildEditableInputTile({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: GoogleFonts.urbanist(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
          suffixIcon: const Icon(Icons.edit, color: Colors.grey, size: 18),
          labelText: label,
          labelStyle: GoogleFonts.urbanist(color: AppTheme.textSecondary, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}