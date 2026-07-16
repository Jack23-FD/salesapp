import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<User> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final QuerySnapshot snapshot = await _firestore.collection('users').get();
      
      final List<User> users = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return User.fromMap(data, doc.id);
      }).toList();
      
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load users: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserRole(User user, UserRole newRole) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final success = await authProvider.updateUserRole(user.id, newRole);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated ${user.name} to ${describeEnum(newRole)}'),
            backgroundColor: Colors.green,
          ),
        );
        
        setState(() {
          final index = _users.indexWhere((u) => u.id == user.id);
          if (index != -1) {
            _users[index] = user.copyWith(role: newRole);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update ${user.name}\'s role'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteUser(User user) async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User'),
        content: Text('Are you sure you want to remove ${user.name} from staff?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Delete user from Firestore
      await _firestore.collection('users').doc(user.id).delete();
      
      // Update local list
      setState(() {
        _users.removeWhere((u) => u.id == user.id);
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} has been removed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Staff Management',
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.w600,
            fontSize: 20.0,
            color: const Color(0xFF333366),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _users.isEmpty
                  ? const Center(child: Text('No users found'))
                  : ListView.builder(
                      itemCount: _users.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return _buildUserCard(user);
                      },
                    ),
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRoleColor(user.role),
                  radius: 24,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.urbanist(
                          fontWeight: FontWeight.w700,
                          fontSize: 18.0,
                          color: const Color(0xFF333366),
                        ),
                      ),
                      Text(
                        user.email,
                        style: GoogleFonts.urbanist(
                          fontSize: 14.0,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    describeEnum(user.role),
                    style: GoogleFonts.urbanist(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.0,
                      color: _getRoleColor(user.role),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                  onPressed: () => _deleteUser(user),
                  tooltip: 'Remove staff',
                ),
              ],
            ),
            if (user.companyName != null && user.companyName!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    user.companyName!,
                    style: GoogleFonts.urbanist(
                      fontSize: 14.0,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    user.phoneNumber!,
                    style: GoogleFonts.urbanist(
                      fontSize: 14.0,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Change Role:',
                  style: GoogleFonts.urbanist(
                    fontSize: 14.0,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 8),
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
      ),
    );
  }

  Widget _buildRoleButton(User user, UserRole role, bool isSelected) {
    return ElevatedButton(
      onPressed: isSelected
          ? null
          : () => _updateUserRole(user, role),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? _getRoleColor(role)
            : _getRoleColor(role).withOpacity(0.1),
        foregroundColor: isSelected ? Colors.white : _getRoleColor(role),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: isSelected ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        describeEnum(role),
        style: GoogleFonts.urbanist(
          fontWeight: FontWeight.w600,
          fontSize: 14.0,
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFF9C27B0); // Purple
      case UserRole.staff:
        return const Color(0xFF2196F3); // Blue
      default:
        return Colors.grey;
    }
  }
}

// Helper function to convert enum to string
String describeEnum(Object enumEntry) {
  final String description = enumEntry.toString();
  final int indexOfDot = description.indexOf('.');
  assert(indexOfDot != -1 && indexOfDot < description.length - 1);
  return description.substring(indexOfDot + 1);
} 