import 'package:flutter/material.dart';
import 'package:goathub/models/user.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/colors.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../services/storage/local_storage.dart';
class LoginScreen extends StatefulWidget {
  final String? role;
  const LoginScreen({super.key, this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkForPrefilledId();
    _loadSavedCredentials();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  Future<void> _loadSavedCredentials() async {
    if (widget.role == 'farmer') {
      final savedUserId = await LocalStorage.getString('saved_farmer_id');
      final savedPassword = await LocalStorage.getString('saved_farmer_password');
      if (savedUserId != null && savedPassword != null) {
        setState(() {
          _userIdController.text = savedUserId;
          _passwordController.text = savedPassword;
          _rememberMe = true;
        });
      }
    }
  }

  void _checkForPrefilledId() {
    try {
      final queryParams = GoRouterState.of(context).uri.queryParameters;
      final prefillId = queryParams['id'];
      if (prefillId != null && prefillId.isNotEmpty) {
        _userIdController.text = prefillId;
        Helpers.showSnackBar(
          context,
          'Your $_idLabel has been pre-filled',
          type: SnackBarType.info,
        );
      }
    } catch (e) {
      debugPrint('Error checking for pre-filled ID: $e');
    }
  }

  String get _roleTitle {
    switch (widget.role) {
      case 'farmer':
        return 'Farmer';
      case 'vet':
        return 'Veterinarian';
      case 'admin':
        return 'Administrator';
      default:
        return 'User';
    }
  }

  Color get _roleColor {
    switch (widget.role) {
      case 'vet':
        return AppColors.vet;
      case 'admin':
        return AppColors.admin;
      default:
        return AppColors.primary;
    }
  }

  LinearGradient get _roleGradient {
    switch (widget.role) {
      case 'vet':
        return const LinearGradient(
          colors: [AppColors.vet, AppColors.vetDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'admin':
        return const LinearGradient(
          colors: [AppColors.admin, AppColors.adminDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  String get _idLabel {
    switch (widget.role) {
      case 'farmer':
        return 'Farmer ID / ID Number';
      case 'vet':
        return 'License Number / Vet ID';
      case 'admin':
        return 'Admin ID / Employee ID';
      default:
        return 'User ID';
    }
  }

  String get _idHint {
    switch (widget.role) {
      case 'farmer':
        return 'e.g., FARM12345 or 1200199012345678';
      case 'vet':
        return 'e.g., VET2024001 or LICENSE001';
      case 'admin':
        return 'e.g., ADMIN001 or EMP001';
      default:
        return 'Enter your ID';
    }
  }

  IconData get _roleIcon {
    switch (widget.role) {
      case 'farmer':
        return Icons.person_outline;
      case 'vet':
        return Icons.medical_services_outlined;
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.person_outline;
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      print('🔵 LoginScreen: Attempting login with:');
      print('   Role: ${widget.role}');
      print('   UserID: ${_userIdController.text.trim()}');
      
      // Hide keyboard
      FocusScope.of(context).unfocus();
      
      final success = await authProvider.login(
        widget.role ?? 'farmer',
        _userIdController.text.trim(),
        _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        // Save credentials if remember me is checked
        if (_rememberMe && widget.role == 'farmer') {
          await LocalStorage.setString('saved_farmer_id', _userIdController.text.trim());
          await LocalStorage.setString('saved_farmer_password', _passwordController.text);
        }
        
        final user = authProvider.currentUser;
        print('🔵 LoginScreen: Login successful for user: ${user?.fullName}');
        
        Helpers.showSnackBar(
          context,
          'Welcome back, ${user?.fullName}!',
          type: SnackBarType.success,
        );
        
        // Navigate based on user type
        String destination;
        switch (user?.userType) {
          case 'farmer':
            destination = '/farmer-dashboard';
            break;
          case 'vet':
            // Check if vet is approved
            if (user is Veterinarian && !user.isApproved) {
              _showPendingApprovalDialog();
              return;
            }
            destination = '/vet-dashboard';
            break;
          case 'admin':
            destination = '/admin-dashboard';
            break;
          default:
            destination = '/role-select';
        }
        
        context.go(destination);
      } else {
        print('🔴 LoginScreen: Login failed');
        // Error is already shown via AuthProvider
      }
    }
  }

  void _showPendingApprovalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Account Pending Approval'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_empty,
                size: 60,
                color: Colors.orange.shade700,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your veterinarian account is pending admin approval. '
                'You will be able to access the platform once approved.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This usually takes 1-2 business days.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/role-select');
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter your email address to receive password reset instructions.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Enter your registered email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(context);
                  _handleForgotPassword(emailController.text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _roleColor,
              ),
              child: const Text('Send Reset Link'),
            ),
          ],
        );
      },
    );
  }

  void _handleForgotPassword(String email) {
    // TODO: Implement forgot password API call
    Helpers.showSnackBar(
      context,
      'Password reset link sent to $email',
      type: SnackBarType.success,
    );
  }

  void _fillDemoCredentials() {
    if (widget.role == 'farmer') {
      _userIdController.text = 'FARM001';
      _passwordController.text = 'farmer123';
    } else if (widget.role == 'vet') {
      _userIdController.text = 'VET001';
      _passwordController.text = 'vet123';
    } else {
      _userIdController.text = 'ADMIN001';
      _passwordController.text = 'admin123';
    }
    
    Helpers.showSnackBar(
      context,
      'Demo credentials filled',
      type: SnackBarType.info,
    );
  }

  void _showQuickTips() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: _roleColor),
                const SizedBox(width: 8),
                const Text(
                  'Quick Tips',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTip(
              'Your $_idLabel was provided during registration',
            ),
            _buildTip(
              'Password is case-sensitive',
            ),
            _buildTip(
              'Contact support if you forgot your credentials',
            ),
            if (widget.role == 'vet')
              _buildTip(
                'Vet accounts require admin approval',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: _roleColor, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(tip)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Show error if any
          if (authProvider.error != null && !_isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Helpers.showSnackBar(
                context,
                authProvider.error!,
                type: SnackBarType.error,
              );
              authProvider.clearError();
            });
          }

          return Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: _roleGradient,
                ),
              ),
              
              // Main content
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back button
                          IconButton(
                            onPressed: () => context.canPop() 
                                ? context.pop() 
                                : context.go('/role-select'),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Header
                          Center(
                            child: Column(
                              children: [
                                // Role icon
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _roleIcon,
                                    size: 50,
                                    color: _roleColor,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                
                                // Welcome text
                                Text(
                                  'Welcome $_roleTitle',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Login to your account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Login form card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // User ID field
                                  TextFormField(
                                    controller: _userIdController,
                                    decoration: InputDecoration(
                                      labelText: _idLabel,
                                      hintText: _idHint,
                                      prefixIcon: Icon(_roleIcon, color: _roleColor),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: _roleColor, width: 2),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: Colors.red),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your $_idLabel';
                                      }
                                      if (widget.role == 'farmer' && value.length < 4) {
                                        return 'Farmer ID must be at least 4 characters';
                                      }
                                      return null;
                                    },
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 16),

                                  // Password field
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: !_isPasswordVisible,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible 
                                              ? Icons.visibility_off 
                                              : Icons.visibility,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible = !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: _roleColor, width: 2),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: Colors.red),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _handleLogin(),
                                  ),
                                  const SizedBox(height: 16),

                                  // Remember me and forgot password
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _rememberMe,
                                            onChanged: (value) {
                                              setState(() {
                                                _rememberMe = value ?? false;
                                              });
                                            },
                                            activeColor: _roleColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                          const Text('Remember me'),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: _showForgotPasswordDialog,
                                        child: Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: _roleColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Login button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _roleColor,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            )
                                          : const Text(
                                              'Login',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Register link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text("Don't have an account? "),
                                      TextButton(
                                        onPressed: () {
                                          context.go('/register?role=${widget.role}');
                                        },
                                        child: Text(
                                          'Register',
                                          style: TextStyle(
                                            color: _roleColor,
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
                          const SizedBox(height: 20),

                          // Quick tips button
                          Center(
                            child: TextButton.icon(
                              onPressed: _showQuickTips,
                              icon: Icon(Icons.lightbulb_outline, color: Colors.white),
                              label: Text(
                                'Quick Tips',
                                style: TextStyle(color: Colors.white.withOpacity(0.9)),
                              ),
                            ),
                          ),

                          // Demo credentials (for testing)
                          if (widget.role != 'admin')
                            Container(
                              margin: const EdgeInsets.only(top: 20),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.science_outlined,
                                        color: Colors.white.withOpacity(0.9),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Demo Credentials',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (widget.role == 'farmer')
                                    const Text(
                                      'ID: FARM001 • Password: farmer123',
                                      style: TextStyle(color: Colors.white70),
                                    )
                                  else if (widget.role == 'vet')
                                    const Text(
                                      'ID: VET001 • Password: vet123',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  const SizedBox(height: 4),
                                  TextButton(
                                    onPressed: _fillDemoCredentials,
                                    child: const Text(
                                      'Tap to auto-fill',
                                      style: TextStyle(
                                        color: Colors.white,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}