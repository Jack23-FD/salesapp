import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'auth_widgets.dart';
import 'signup_screen.dart';
import '../navigation/role_based_navigation.dart';

// Define the AuthMethod enum
enum AuthMethod { email, google, apple, sso }

// Add debug prints to check imports
void _debugImports() {
  print("DEBUG: Checking imports in signin.dart");
  try {
    print("DEBUG: SignUpScreen import successful");
  } catch (e) {
    print("DEBUG: Error with SignUpScreen import: $e");
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  @override
  void initState() {
    super.initState();
    print("DEBUG: SignInScreen initState called");
    _debugImports();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool('remember_me') ?? false;
      final savedEmail = prefs.getString('saved_email') ?? '';

      if (rememberMe && savedEmail.isNotEmpty) {
        setState(() {
          _rememberMe = true;
          _emailController.text = savedEmail;
        });
      }
    } catch (e) {
      print("Error loading saved credentials: $e");
    }
  }

  Future<void> _handleRememberMeState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool('remember_me', true);
        await prefs.setString('saved_email', _emailController.text.trim());
      } else {
        await prefs.setBool('remember_me', false);
        await prefs.remove('saved_email');
      }
    } catch (e) {
      print("Error saving credentials: $e");
    }
  }

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;
  AuthMethod _selectedAuthMethod = AuthMethod.email;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (success) {
            await _handleRememberMeState();
            
            // Get the user model for role check
            final user = authProvider.user;
            
            if (user != null) {
              // Use RoleBasedNavigation for proper role-based redirection
              RoleBasedNavigation.navigateToHomeScreen(context, user);
            } else {
              // Fallback to main navigation
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/dashboard',
                (route) => false,
              );
            }
          } else {
            setState(() {
              _errorMessage = authProvider.error;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signInWithGoogle();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          // Get the user model for role check
          final user = authProvider.user;
          
          if (user != null) {
            // Use RoleBasedNavigation for proper role-based redirection
            RoleBasedNavigation.navigateToHomeScreen(context, user);
          } else {
            // Fallback to dashboard if user data couldn't be loaded
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/dashboard',
              (route) => false,
            );
          }
        } else {
          setState(() {
            _errorMessage = authProvider.error;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    final resetFormKey = GlobalKey<FormState>();
    bool isResetting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.lock_reset, color: Color(0xFF00BBF9)),
                  SizedBox(width: 10),
                  Text('Forgot Password?'),
                ],
              ),
              content: Form(
                key: resetFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter your registered email address and we will send you a password reset link.',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: AuthStyles.inputDecoration(
                        labelText: 'Email Address',
                        hintText: 'Enter your email',
                        prefixIcon: Icons.email_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        final emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailPattern.hasMatch(value.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isResetting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BBF9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isResetting
                      ? null
                      : () async {
                          if (resetFormKey.currentState!.validate()) {
                            setDialogState(() => isResetting = true);
                            final targetEmail = resetEmailController.text.trim();
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            bool success = await authProvider.resetPassword(targetEmail);

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            if (mounted) {
                              if (success) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: const Row(
                                      children: [
                                        Icon(Icons.mark_email_read, color: Color(0xFF00B259)),
                                        SizedBox(width: 10),
                                        Text('Check Your Email'),
                                      ],
                                    ),
                                    content: Text(
                                      'A password reset link has been sent to:\n$targetEmail\n\n'
                                      '📌 Note: If you do not see the email in your Inbox within 2 minutes, please check your SPAM / JUNK folder.',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('OK', style: TextStyle(color: Color(0xFF00B259), fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(authProvider.error ?? 'Failed to send password reset email.'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            }
                          }
                        },
                  child: isResetting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Send Reset Link', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _signInWithApple() {
    // Show a snackbar indicating Apple sign-in is not implemented yet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Apple Sign In is not implemented yet.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _signInWithSSO() {
    // Show a snackbar indicating SSO sign-in is not implemented yet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SSO Sign In is not implemented yet.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  bool _validateForm() {
    if (_formKey.currentState!.validate()) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo and back button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        size: 20,
                        color: Colors.black54,
                      ),
                    ),
                    Image.asset(
                      'assets/images/logo.png',
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 20),
                  ],
                ),

                const SizedBox(height: 30),

                // Title and subtitle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00BBF9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Main content
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error message
                      if (_errorMessage != null)
                        ErrorMessage(
                          message: _errorMessage!,
                          onClose: () {
                            setState(() {
                              _errorMessage = null;
                            });
                          },
                        ),

                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: AuthStyles.inputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email',
                          prefixIcon: Icons.email_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          final emailPattern = RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailPattern.hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: AuthStyles.inputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF00BBF9),
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible =
                                    !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Remember me and Forgot password
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: const Color(0xFF00BBF9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Remember me',
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: _showForgotPasswordDialog,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF00BBF9),
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Sign In button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          style: AuthStyles.primaryButtonStyle(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Or continue with divider
                      const OrDivider(),

                      const SizedBox(height: 24),

                      // Social login buttons
                      Column(
                        children: [
                          SocialLoginButton(
                            text: 'Sign in with Google',
                            icon: FontAwesomeIcons.google,
                            iconSize: 18,
                            onPressed:
                                _isLoading ? null : _signInWithGoogle,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: 16),
                          SocialLoginButton(
                            text: 'Sign in with Apple',
                            icon: FontAwesomeIcons.apple,
                            iconSize: 22,
                            onPressed:
                                _isLoading ? null : _signInWithApple,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: 16),
                          SocialLoginButton(
                            text: 'Sign in with SSO',
                            icon: FontAwesomeIcons.building,
                            iconSize: 18,
                            onPressed:
                                _isLoading ? null : _signInWithSSO,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Create account link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Don\'t have an account? ',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              try {
                                print("DEBUG: Create account button clicked - using simpler navigation");
                                
                                // Use pushNamed to go through the routes system
                                Navigator.of(context).pushNamed('/signup');
                                
                                print("DEBUG: Navigation request sent");
                              } catch (e) {
                                print("DEBUG: Error navigating to signup screen: $e");
                                
                                // Show error message to user
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error opening signup screen: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              'Create account',
                              style: TextStyle(
                                color: const Color(0xFF00BBF9),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Add spacing at the bottom
                      const SizedBox(height: 40),
                    ],
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
