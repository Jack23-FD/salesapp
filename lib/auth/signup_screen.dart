import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import 'signin.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'auth_widgets.dart';
import '../navigation/role_based_navigation.dart';
import '../screens/admin/admin_dashboard.dart';
import '../main.dart'; // For MainNavigationController

class SignUpScreen extends StatefulWidget {
  final String selectedLanguage;

  // Static factory method to create the widget with error handling
  static Widget create({required String selectedLanguage}) {
    try {
      print("DEBUG: Creating SignUpScreen via static factory method");
      return SignUpScreen(selectedLanguage: selectedLanguage);
    } catch (e) {
      print("DEBUG: Error in SignUpScreen factory method: $e");
      return ErrorWidget("Failed to create SignUpScreen: $e");
    }
  }

  SignUpScreen({super.key, required this.selectedLanguage}) {
    print("DEBUG: SignUpScreen constructor called with language: $selectedLanguage");
  }

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  UserRole _selectedRole = UserRole.staff;

  @override
  void initState() {
    super.initState();
    print("DEBUG: SignUpScreen initState called");
    print("DEBUG: Selected language is: ${widget.selectedLanguage}");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    print("DEBUG: _signUp method called");
    if (_formKey.currentState!.validate()) {
      print("DEBUG: Form validation successful");
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print("DEBUG: Starting sign-up process with email: ${_emailController.text.trim()}");
      print("DEBUG: Selected role: ${_selectedRole == UserRole.admin ? 'ADMIN' : 'STAFF'}");
      print("DEBUG: Role enum value: $_selectedRole");
      print("DEBUG: Role string: ${describeEnum(_selectedRole)}");
      print("DEBUG: Is admin check: ${_selectedRole == UserRole.admin}");
      print("DEBUG: Admin enum value: ${UserRole.admin}");
      print("DEBUG: Staff enum value: ${UserRole.staff}");

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      print("DEBUG: AuthProvider obtained");
      try {
        print("DEBUG: Attempting to call authProvider.signUp");
        final success = await authProvider.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          companyName: _companyController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          role: _selectedRole,
        );
        print("DEBUG: authProvider.signUp completed with result: $success");

        if (mounted) {
          print("DEBUG: Widget is still mounted, updating state");
          setState(() {
            _isLoading = false;
          });

          if (success) {
            print("DEBUG: Signup was successful, attempting navigation");
            
            // Use simpler direct navigation to reduce complexity
            if (_selectedRole == UserRole.admin) {
              print("DEBUG: Navigating directly to AdminDashboard");
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboard()),
                (route) => false,
              );
            } else {
              print("DEBUG: Navigating directly to MainNavigationController");
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainNavigationController()),
                (route) => false,
              );
            }
          } else {
            print("DEBUG: Signup failed with provider error: ${authProvider.error}");
            setState(() {
              _errorMessage = authProvider.error ?? 'Unknown error occurred during signup';
            });
          }
        } else {
          print("DEBUG: Widget is no longer mounted, cannot update state");
        }
      } catch (e) {
        print("DEBUG: Exception caught during signup: $e");
        print("DEBUG: Stack trace: ${StackTrace.current}");
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.toString();
          });
        } else {
          print("DEBUG: Widget is no longer mounted after exception, cannot update state");
        }
      }
    } else {
      print("DEBUG: Form validation failed");
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle(role: _selectedRole);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Check user role for correct navigation
        final user = authProvider.user;
        if (user != null) {
          RoleBasedNavigation.navigateToHomeScreen(context, user);
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/main_navigation',
            (route) => false,
          );
        }
      } else {
        setState(() {
          _errorMessage = authProvider.error;
        });
      }
    }
  }

  void _signUpWithApple() {
    // Show a snackbar indicating Apple sign-in is not implemented yet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Apple Sign In is not implemented yet.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("DEBUG: SignUpScreen build method called");
    
    // Simplified layout with fixed constraints
    final size = MediaQuery.of(context).size;
    print("DEBUG: Screen size: ${size.width} x ${size.height}");
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        // Use LayoutBuilder to get proper constraints
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  minWidth: constraints.maxWidth,
                ),
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Welcome text
                        const Text(
                          'Sign up now to begin your journey',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00BBF9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create your account to get started',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Error message if any
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setState(() {
                                      _errorMessage = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),

                        // Name field
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email field
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Enter your email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Mobile Number field
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Mobile Number',
                          hint: 'Enter your mobile number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your mobile number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Company name field
                        _buildTextField(
                          controller: _companyController,
                          label: 'Company Name (Optional)',
                          hint: 'Enter your company name',
                          icon: Icons.business_outlined,
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Enter your password',
                          icon: Icons.lock_outline,
                          obscureText: !_isPasswordVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Role selection
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User Role',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedRole = UserRole.staff;
                                        });
                                        print("DEBUG: STAFF role selected - UserRole enum value: ${_selectedRole}");
                                        print("DEBUG: Is Staff role? ${_selectedRole == UserRole.staff}");
                                        print("DEBUG: Role as string: ${describeEnum(_selectedRole)}");
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _selectedRole == UserRole.staff
                                              ? const Color(0xFF00BBF9)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Staff',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: _selectedRole == UserRole.staff
                                                ? Colors.white
                                                : Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedRole = UserRole.admin;
                                        });
                                        print("DEBUG: ADMIN role selected - UserRole enum value: ${_selectedRole}");
                                        print("DEBUG: Is Admin role? ${_selectedRole == UserRole.admin}");
                                        print("DEBUG: Is Admin check: ${UserRole.admin == UserRole.admin}");
                                        print("DEBUG: Role as string: ${describeEnum(_selectedRole)}");
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _selectedRole == UserRole.admin
                                              ? const Color(0xFF00BBF9)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Admin',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: _selectedRole == UserRole.admin
                                                ? Colors.white
                                                : Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Sign up button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00BBF9),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Sign Up',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Or divider
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.grey[300],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Or sign up with',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.grey[300],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Social buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialButton(
                              icon: FontAwesomeIcons.google,
                              onTap: _signUpWithGoogle,
                            ),
                            const SizedBox(width: 24),
                            _buildSocialButton(
                              icon: FontAwesomeIcons.apple,
                              onTap: _signUpWithApple,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Already have an account
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(color: Colors.grey),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacementNamed(context, '/signin');
                              },
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: const Color(0xFF00BBF9),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper method to build text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: const Color(0xFF00BBF9)),
        ),
      ),
      validator: validator,
    );
  }

  // Helper method to build social buttons
  Widget _buildSocialButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: Colors.grey[700]),
      ),
    );
  }
}
