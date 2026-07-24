import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({Key? key}) : super(key: key);

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  String? _error;

  static const Color primaryBlue = AppTheme.primaryColor;
  static const Color bgLight = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final users = await authProvider.getStaffList();
      
      if (!mounted) return;
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load users: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserRole(User user, UserRole newRole) async {
    final updatedUser = user.copyWith(role: newRole);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.updateStaffUser(updatedUser);

    setState(() {
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = updatedUser;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Role updated to ${describeEnum(newRole)} for ${user.name}'),
          backgroundColor: const Color(0xFF00B259),
        ),
      );
    }
  }

  void _showEditUserDialog(User user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phoneNumber ?? '+91 98765 43210');
    final staffIdController = TextEditingController(text: user.displayStaffId);
    final branchController = TextEditingController(text: user.displayBranch);
    final roleTitleController = TextEditingController(text: user.displayRoleTitle);
    UserRole selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_note, color: primaryBlue),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Staff Details',
                    style: GoogleFonts.urbanist(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField('Full Name', nameController, Icons.person_outline),
                    const SizedBox(height: 12),
                    _buildTextField('Email Address', emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _buildTextField('Mobile Number', phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _buildTextField('Staff ID', staffIdController, Icons.badge_outlined),
                    const SizedBox(height: 12),
                    _buildTextField('Branch Name', branchController, Icons.storefront_outlined),
                    const SizedBox(height: 12),
                    _buildTextField('Role Title (e.g. Sales Executive)', roleTitleController, Icons.work_outline),
                    const SizedBox(height: 16),
                    Text(
                      'System Permission Role',
                      style: GoogleFonts.urbanist(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Center(
                              child: Text(
                                'Staff',
                                style: TextStyle(
                                  color: selectedRole == UserRole.staff ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            selected: selectedRole == UserRole.staff,
                            selectedColor: primaryBlue,
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() {
                                  selectedRole = UserRole.staff;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: Center(
                              child: Text(
                                'Admin',
                                style: TextStyle(
                                  color: selectedRole == UserRole.admin ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            selected: selectedRole == UserRole.admin,
                            selectedColor: const Color(0xFF9333EA),
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() {
                                  selectedRole = UserRole.admin;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final updatedUser = user.copyWith(
                      name: nameController.text.trim(),
                      email: emailController.text.trim(),
                      phoneNumber: phoneController.text.trim(),
                      staffId: staffIdController.text.trim(),
                      branch: branchController.text.trim(),
                      roleTitle: roleTitleController.text.trim(),
                      role: selectedRole,
                    );

                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    await authProvider.updateStaffUser(updatedUser);

                    setState(() {
                      final index = _users.indexWhere((u) => u.id == user.id);
                      if (index != -1) {
                        _users[index] = updatedUser;
                      }
                    });

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Staff details updated successfully!'),
                          backgroundColor: Color(0xFF00B259),
                        ),
                      );
                    }
                  },
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            prefixIcon: Icon(icon, size: 18, color: primaryBlue),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Staff Member'),
        content: Text('Are you sure you want to remove ${user.name} from the staff directory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _users.removeWhere((u) => u.id == user.id);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} removed from staff list'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: Text(
          'Staff Management',
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
            color: primaryBlue,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryBlue),
            onPressed: _loadUsers,
            tooltip: 'Refresh Staff List',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : _error != null
              ? Center(child: Text(_error!))
              : _users.isEmpty
                  ? Center(
                      child: Text(
                        'No staff members found',
                        style: GoogleFonts.urbanist(
                          fontSize: 16.0,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return _buildUserCard(user);
                      },
                    ),
    );
  }

  Widget _buildUserCard(User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Circle
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE0F2FE),
                child: Text(
                  user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U',
                  style: GoogleFonts.urbanist(
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name and Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: GoogleFonts.urbanist(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.0,
                              color: const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Role Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: user.isAdmin
                                ? const Color(0xFFF3E8FF)
                                : const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            describeEnum(user.role),
                            style: GoogleFonts.urbanist(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.0,
                              color: user.isAdmin ? const Color(0xFF9333EA) : primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      style: GoogleFonts.urbanist(
                        fontSize: 14.0,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Edit & Delete Action Buttons
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: primaryBlue, size: 22),
                onPressed: () => _showEditUserDialog(user),
                tooltip: 'Edit staff details',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 22),
                onPressed: () => _deleteUser(user),
                tooltip: 'Remove staff',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Extra details grid - 2x2 layout with perfect alignment & neat sizing
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1: Staff ID & Phone Number
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Text(
                          user.displayStaffId,
                          style: GoogleFonts.urbanist(
                            fontSize: 14.0,
                            color: const Color(0xFF1E293B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user.displayPhone,
                            style: GoogleFonts.urbanist(
                              fontSize: 14.0,
                              color: const Color(0xFF1E293B),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Column 2: Branch & Role Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.storefront_outlined, size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user.displayBranch,
                            style: GoogleFonts.urbanist(
                              fontSize: 14.0,
                              color: const Color(0xFF1E293B),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.work_outline, size: 18, color: primaryBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user.displayRoleTitle,
                            style: GoogleFonts.urbanist(
                              fontSize: 14.0,
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Change Role Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Change System Role:',
                style: GoogleFonts.urbanist(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              Row(
                children: [
                  _buildRoleButton(
                    user,
                    UserRole.staff,
                    user.role == UserRole.staff,
                  ),
                  const SizedBox(width: 8),
                  _buildRoleButton(
                    user,
                    UserRole.admin,
                    user.role == UserRole.admin,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton(User user, UserRole role, bool isSelected) {
    final color = role == UserRole.admin ? const Color(0xFF9333EA) : primaryBlue;
    final bgActiveColor = role == UserRole.admin ? const Color(0xFFF3E8FF) : const Color(0xFFE0F2FE);
    
    return InkWell(
      onTap: isSelected ? null : () => _updateUserRole(user, role),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? bgActiveColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFCBD5E1),
            width: isSelected ? 1.6 : 1.2,
          ),
        ),
        child: Text(
          describeEnum(role),
          style: GoogleFonts.urbanist(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13.5,
            color: isSelected ? color : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

// Helper function to convert enum to string
String describeEnum(Object enumEntry) {
  final String description = enumEntry.toString();
  final int indexOfDot = description.indexOf('.');
  assert(indexOfDot != -1 && indexOfDot < description.length - 1);
  return description.substring(indexOfDot + 1);
}