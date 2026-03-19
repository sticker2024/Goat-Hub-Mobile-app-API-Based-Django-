import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../shared/widgets/loading_widget.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? role;
  const ForgotPasswordScreen({super.key, this.role});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  bool _useEmail = true;
  int _currentStep = 0;
  String? _resetToken;
  String? _verificationCode;

  final List<Map<String, dynamic>> _resetMethods = [
    {'id': 'email', 'label': 'Email', 'icon': Icons.email, 'color': Colors.blue},
    {'id': 'sms', 'label': 'SMS', 'icon': Icons.sms, 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
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

  Future<void> _requestReset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _currentStep = 1;
    });

    Helpers.showSnackBar(
      context,
      _useEmail
          ? 'Reset code sent to your email'
          : 'Reset code sent to your phone',
      type: SnackBarType.success,
    );
  }

  Future<void> _verifyCode() async {
    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _currentStep = 2;
    });

    Helpers.showSnackBar(
      context,
      'Code verified successfully',
      type: SnackBarType.success,
    );
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    Helpers.showSnackBar(
      context,
      'Password reset successful! Please login with your new password.',
      type: SnackBarType.success,
    );

    // Navigate back to login
    context.go('/login?role=${widget.role}');
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStep(1, 'Request', _currentStep >= 0),
        Expanded(child: Container(height: 2, color: Colors.grey.shade300)),
        _buildStep(2, 'Verify', _currentStep >= 1),
        Expanded(child: Container(height: 2, color: Colors.grey.shade300)),
        _buildStep(3, 'Reset', _currentStep >= 2),
      ],
    );
  }

  Widget _buildStep(int step, String label, bool isActive) {
    final isCompleted = _currentStep >= step;
    final color = isCompleted ? _roleColor : Colors.grey.shade400;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    step.toString(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_roleColor, _roleColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: _isLoading
                ? const LoadingWidget(message: 'Processing...')
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Header with back button
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => context.pop(),
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
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Icon and title
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock_reset,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Reset Password',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'for $_roleTitle account',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Step indicator
                            _buildStepIndicator(),
                            const SizedBox(height: 40),

                            // Form card
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: _buildCurrentStep(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildRequestStep();
      case 1:
        return _buildVerificationStep();
      case 2:
        return _buildResetStep();
      default:
        return _buildRequestStep();
    }
  }

  Widget _buildRequestStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reset Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Method selector
          Row(
            children: _resetMethods.map((method) {
              final isSelected = _useEmail == (method['id'] == 'email');
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _useEmail = method['id'] == 'email';
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? method['color'].withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? method['color']
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          method['icon'],
                          color: isSelected ? method['color'] : Colors.grey,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          method['label'],
                          style: TextStyle(
                            color: isSelected ? method['color'] : Colors.grey,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Input field
          if (_useEmail) ...[
            const Text(
              'Email Address',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Enter your email address',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
          ] else ...[
            const Text(
              'Phone Number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                hintText: '+250 788 123 456',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
            ),
          ],
          const SizedBox(height: 24),

          // Info message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _useEmail
                        ? 'We\'ll send a password reset code to your email address'
                        : 'We\'ll send a password reset code to your phone number via SMS',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Action button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _requestReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: _roleColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Send Reset Code',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStep() {
    final codeControllers = List.generate(6, (index) => TextEditingController());
    final focusNodes = List.generate(6, (index) => FocusNode());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter Verification Code',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _useEmail
              ? 'We\'ve sent a 6-digit code to ${_emailController.text}'
              : 'We\'ve sent a 6-digit code to ${_phoneController.text}',
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),

        // Code input fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 45,
              height: 55,
              child: TextFormField(
                controller: codeControllers[index],
                focusNode: focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    focusNodes[index + 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 16),

        // Timer and resend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Code expires in 05:00',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            TextButton(
              onPressed: () {
                Helpers.showSnackBar(
                  context,
                  'New code sent',
                  type: SnackBarType.success,
                );
              },
              child: const Text('Resend Code'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Info message
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: const Row(
            children: [
              Icon(Icons.timer, color: Colors.orange),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Please enter the 6-digit code sent to your device. The code will expire in 5 minutes.',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),

        // Action button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _verifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: _roleColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Verify Code',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetStep() {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;

    return StatefulBuilder(
      builder: (context, setState) => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create New Password',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your new password must be different from previously used passwords',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),

            // New Password
            TextFormField(
              controller: newPasswordController,
              obscureText: obscureNew,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureNew ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      obscureNew = !obscureNew;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: Validators.password,
            ),
            const SizedBox(height: 16),

            // Confirm Password
            TextFormField(
              controller: confirmPasswordController,
              obscureText: obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      obscureConfirm = !obscureConfirm;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) => Validators.confirmPassword(value, newPasswordController.text),
            ),
            const SizedBox(height: 16),

            // Password strength indicator
            _buildPasswordStrengthIndicator(newPasswordController.text),
            const SizedBox(height: 24),

            // Password requirements
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Password must contain:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRequirement(
                    'At least 8 characters',
                    newPasswordController.text.length >= 8,
                  ),
                  _buildRequirement(
                    'At least one uppercase letter',
                    newPasswordController.text.contains(RegExp(r'[A-Z]')),
                  ),
                  _buildRequirement(
                    'At least one number',
                    newPasswordController.text.contains(RegExp(r'[0-9]')),
                  ),
                  _buildRequirement(
                    'At least one special character',
                    newPasswordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Action button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _roleColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Reset Password',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    Color getColor() {
      if (strength <= 1) return Colors.red;
      if (strength <= 2) return Colors.orange;
      if (strength <= 3) return Colors.blue;
      return Colors.green;
    }

    String getText() {
      if (strength <= 1) return 'Weak';
      if (strength <= 2) return 'Fair';
      if (strength <= 3) return 'Good';
      return 'Strong';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password Strength:',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            Text(
              getText(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: getColor(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: strength / 4,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(getColor()),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isMet ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isMet ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}