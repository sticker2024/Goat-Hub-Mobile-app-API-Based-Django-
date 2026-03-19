import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../core/constants/colors.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';

class RegisterScreen extends StatefulWidget {
  final String? role;
  const RegisterScreen({super.key, this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Text Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _districtController = TextEditingController();
  final _sectorController = TextEditingController();
  
  // Farmer specific
  final _idNumberController = TextEditingController();
  final _farmSizeController = TextEditingController();
  final _experienceController = TextEditingController();
  String? _farmType = 'individual';
  String? _cooperativeName;
  
  // Vet specific
  final _licenseNumberController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  String? _specialization = 'general';
  final _yearsExperienceController = TextEditingController();
  
  // Admin specific
  final _employeeIdController = TextEditingController();
  final _departmentController = TextEditingController();
  
  // UI State
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  int _currentStep = 0;
  File? _profileImage;
  File? _idDocument;
  File? _certificate;
  bool _termsAccepted = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _rwandanDistricts = [
    'Kigali', 'Bugesera', 'Gatsibo', 'Gicumbi', 'Gisagara', 'Huye',
    'Kamonyi', 'Karongi', 'Kayonza', 'Kirehe', 'Muhanga', 'Musanze',
    'Ngoma', 'Nyarugenge', 'Rubavu', 'Ruhango', 'Rulindo', 'Rusizi',
    'Rutsiro', 'Nyabihu', 'Nyagatare', 'Nyamagabe', 'Nyamasheke',
    'Nyanza', 'Nyaruguru', 'Gasabo', 'Kicukiro', 'Burera', 'Gakenke',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
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

  List<Step> _getSteps() {
    return [
      Step(
        title: const Text('Personal Info'),
        content: _buildPersonalInfoStep(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Account Details'),
        content: _buildAccountDetailsStep(),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Verification'),
        content: _buildVerificationStep(),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
    ];
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      children: [
        // Profile Image
        Center(
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                  border: Border.all(color: _roleColor, width: 2),
                ),
                child: _profileImage != null
                    ? ClipOval(
                        child: Image.file(
                          _profileImage!,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        ),
                      )
                    : Icon(
                        _roleIcon,
                        size: 50,
                        color: _roleColor.withOpacity(0.5),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _roleColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Name Fields
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name *',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: Validators.required,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name *',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: Validators.required,
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Email
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email Address *',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: Validators.email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Phone
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Phone Number *',
            prefixIcon: const Icon(Icons.phone_outlined),
            hintText: '+250 788 123 456',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: Validators.phone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Location Fields
        Row(
          children: [
            Expanded(
              child: _buildDistrictDropdown(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _sectorController,
                decoration: InputDecoration(
                  labelText: 'Sector *',
                  prefixIcon: const Icon(Icons.map_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: Validators.required,
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Role-specific fields
        if (widget.role == 'farmer') _buildFarmerFields(),
        if (widget.role == 'vet') _buildVetFields(),
        if (widget.role == 'admin') _buildAdminFields(),
      ],
    );
  }

  Widget _buildDistrictDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _districtController.text.isNotEmpty ? _districtController.text : null,
      decoration: InputDecoration(
        labelText: 'District *',
        prefixIcon: const Icon(Icons.location_on_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      items: _rwandanDistricts.map((district) {
        return DropdownMenuItem(
          value: district,
          child: Text(district),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _districtController.text = value ?? '';
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a district';
        }
        return null;
      },
    );
  }

  Widget _buildFarmerFields() {
    return Column(
      children: [
        // ID Number
        TextFormField(
          controller: _idNumberController,
          decoration: InputDecoration(
            labelText: 'National ID Number *',
            prefixIcon: const Icon(Icons.badge_outlined),
            hintText: '16 digits',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: Validators.idNumber,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Farm Type
        DropdownButtonFormField<String>(
          initialValue: _farmType,
          decoration: InputDecoration(
            labelText: 'Farm Type *',
            prefixIcon: const Icon(Icons.agriculture_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'individual', child: Text('Individual Farmer')),
            DropdownMenuItem(value: 'cooperative', child: Text('Cooperative Member')),
          ],
          onChanged: (value) {
            setState(() {
              _farmType = value;
            });
          },
        ),
        const SizedBox(height: 16),

        // Cooperative Name (if applicable)
        if (_farmType == 'cooperative')
          TextFormField(
            controller: TextEditingController(text: _cooperativeName),
            decoration: InputDecoration(
              labelText: 'Cooperative Name *',
              prefixIcon: const Icon(Icons.people_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) => _cooperativeName = value,
            validator: Validators.required,
            textInputAction: TextInputAction.next,
          ),
        
        if (_farmType == 'cooperative') const SizedBox(height: 16),

        // Farm Size
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _farmSizeController,
                decoration: InputDecoration(
                  labelText: 'Number of Goats',
                  prefixIcon: const Icon(Icons.pets_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) => Validators.positiveNumber(value, required: false),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _experienceController,
                decoration: InputDecoration(
                  labelText: 'Years Experience',
                  prefixIcon: const Icon(Icons.timeline_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) => Validators.positiveNumber(value, required: false),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVetFields() {
    return Column(
      children: [
        // License Number
        TextFormField(
          controller: _licenseNumberController,
          decoration: InputDecoration(
            labelText: 'License Number *',
            prefixIcon: const Icon(Icons.badge_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: Validators.licenseNumber,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Specialization
        DropdownButtonFormField<String>(
          initialValue: _specialization,
          decoration: InputDecoration(
            labelText: 'Specialization *',
            prefixIcon: const Icon(Icons.medical_services_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'general', child: Text('General Veterinary')),
            DropdownMenuItem(value: 'surgery', child: Text('Surgery')),
            DropdownMenuItem(value: 'reproduction', child: Text('Reproduction')),
            DropdownMenuItem(value: 'nutrition', child: Text('Nutrition')),
            DropdownMenuItem(value: 'preventive', child: Text('Preventive Care')),
          ],
          onChanged: (value) {
            setState(() {
              _specialization = value;
            });
          },
        ),
        const SizedBox(height: 16),

        // Years Experience
        TextFormField(
          controller: _yearsExperienceController,
          decoration: InputDecoration(
            labelText: 'Years of Experience *',
            prefixIcon: const Icon(Icons.timeline_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: (value) => Validators.positiveNumber(value),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Clinic Name
        TextFormField(
          controller: _clinicNameController,
          decoration: InputDecoration(
            labelText: 'Clinic/Hospital Name *',
            prefixIcon: const Icon(Icons.local_hospital_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: Validators.required,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Clinic Address
        TextFormField(
          controller: _clinicAddressController,
          decoration: InputDecoration(
            labelText: 'Clinic Address *',
            prefixIcon: const Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: Validators.required,
          maxLines: 3,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildAdminFields() {
    return Column(
      children: [
        // Employee ID
        TextFormField(
          controller: _employeeIdController,
          decoration: InputDecoration(
            labelText: 'Employee ID *',
            prefixIcon: const Icon(Icons.badge_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: Validators.employeeId,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Department
        TextFormField(
          controller: _departmentController,
          decoration: InputDecoration(
            labelText: 'Department *',
            prefixIcon: const Icon(Icons.business_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: Validators.required,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildAccountDetailsStep() {
    return Column(
      children: [
        // Username
        TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: 'Username *',
            prefixIcon: const Icon(Icons.person_outline),
            helperText: 'Choose a unique username',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: (value) => Validators.minLength(value, 3, 'Username'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Password
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Password *',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            helperText: 'Minimum 6 characters with uppercase and number',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: Validators.password,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Confirm Password
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Confirm Password *',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: (value) => Validators.confirmPassword(value, _passwordController.text),
          textInputAction: TextInputAction.done,
        ),

        // Password strength indicator
        const SizedBox(height: 16),
        _buildPasswordStrength(),
      ],
    );
  }

  Widget _buildPasswordStrength() {
    final password = _passwordController.text;
    int strength = 0;
    
    if (password.length >= 6) strength++;
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
              style: TextStyle(color: Colors.grey.shade600),
            ),
            Text(
              getText(),
              style: TextStyle(
                color: getColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: strength / 4,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(getColor()),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildVerificationStep() {
    return Column(
      children: [
        // ID Document Upload
        _buildDocumentUpload(
          title: 'Upload ID Document *',
          subtitle: 'National ID, Passport, or Driver\'s License',
          icon: Icons.badge_outlined,
          file: _idDocument,
          onTap: () => _pickDocument('id'),
        ),
        const SizedBox(height: 20),

        // Certificate Upload (for vets)
        if (widget.role == 'vet')
          Column(
            children: [
              _buildDocumentUpload(
                title: 'Veterinary Certificate *',
                subtitle: 'License certificate or registration document',
                icon: Icons.card_membership_outlined,
                file: _certificate,
                onTap: () => _pickDocument('certificate'),
              ),
              const SizedBox(height: 20),
            ],
          ),

        // Terms and Conditions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'I agree to the Terms and Conditions and Privacy Policy *',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  Checkbox(
                    value: _termsAccepted,
                    onChanged: (value) {
                      setState(() {
                        _termsAccepted = value ?? false;
                      });
                    },
                    activeColor: _roleColor,
                  ),
                ],
              ),
              if (widget.role == 'vet')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Veterinarian accounts require admin approval before you can access the platform.',
                            style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentUpload({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? file,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: file != null ? Colors.green : Colors.grey.shade300,
            width: file != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: file != null ? Colors.green.shade50 : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (file != null ? Colors.green : _roleColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                file != null ? Icons.check_circle : icon,
                color: file != null ? Colors.green : _roleColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: file != null ? Colors.green : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    file != null ? file.path.split('/').last : subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: file != null ? Colors.green.shade700 : Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (file != null)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  setState(() {
                    if (title.contains('ID')) {
                      _idDocument = null;
                    } else {
                      _certificate = null;
                    }
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickDocument(String type) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 70,
    );
    
    if (pickedFile != null) {
      setState(() {
        if (type == 'id') {
          _idDocument = File(pickedFile.path);
        } else {
          _certificate = File(pickedFile.path);
        }
      });
    }
  }

  Map<String, dynamic> _buildUserData() {
    final baseData = {
      'role': widget.role,
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'username': _usernameController.text.trim(),
      'password': _passwordController.text,
      'district': _districtController.text,
      'sector': _sectorController.text.trim(),
    };

    switch (widget.role) {
      case 'farmer':
        return {
          ...baseData,
          'id_number': _idNumberController.text.trim(),
          'farm_type': _farmType,
          'cooperative_name': _cooperativeName,
          'farm_size': int.tryParse(_farmSizeController.text) ?? 0,
          'farming_experience': int.tryParse(_experienceController.text) ?? 0,
        };
      case 'vet':
        return {
          ...baseData,
          'license_number': _licenseNumberController.text.trim(),
          'specialization': _specialization,
          'years_experience': int.tryParse(_yearsExperienceController.text) ?? 0,
          'clinic_name': _clinicNameController.text.trim(),
          'clinic_address': _clinicAddressController.text.trim(),
        };
      case 'admin':
        return {
          ...baseData,
          'employee_id': _employeeIdController.text.trim(),
          'department': _departmentController.text.trim(),
        };
      default:
        return baseData;
    }
  }

  Future<void> _handleRegister() async {
    if (!_termsAccepted) {
      Helpers.showSnackBar(
        context,
        'Please accept the Terms and Conditions',
        type: SnackBarType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = _buildUserData();

    final success = await authProvider.register(userData);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Helpers.showSnackBar(
        context,
        widget.role == 'vet'
            ? 'Registration successful! Your account is pending approval.'
            : 'Registration successful! Please login.',
        type: SnackBarType.success,
      );
      
      // Navigate to login
      context.go('/login?role=${widget.role}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
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
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Row(
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
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Register as $_roleTitle',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Create your account',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _roleIcon,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Stepper Form
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Stepper(
                              type: StepperType.horizontal,
                              currentStep: _currentStep,
                              onStepContinue: _currentStep < 2
                                  ? () {
                                      if (_formKey.currentState!.validate()) {
                                        setState(() {
                                          _currentStep++;
                                        });
                                      }
                                    }
                                  : null,
                              onStepCancel: _currentStep > 0
                                  ? () {
                                      setState(() {
                                        _currentStep--;
                                      });
                                    }
                                  : null,
                              onStepTapped: (step) {
                                setState(() {
                                  _currentStep = step;
                                });
                              },
                              steps: _getSteps(),
                              controlsBuilder: (context, details) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Row(
                                    children: [
                                      if (_currentStep > 0)
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: details.onStepCancel,
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: _roleColor,
                                              side: BorderSide(color: _roleColor),
                                              padding: const EdgeInsets.symmetric(vertical: 15),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const Text('Back'),
                                          ),
                                        ),
                                      if (_currentStep > 0) const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _currentStep == 2
                                              ? _handleRegister
                                              : details.onStepContinue,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _roleColor,
                                            padding: const EdgeInsets.symmetric(vertical: 15),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Text(
                                            _currentStep == 2 ? 'Register' : 'Next',
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Loading overlay
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const LoadingWidget(message: 'Creating account...'),
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _districtController.dispose();
    _sectorController.dispose();
    _idNumberController.dispose();
    _farmSizeController.dispose();
    _experienceController.dispose();
    _licenseNumberController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _yearsExperienceController.dispose();
    _employeeIdController.dispose();
    _departmentController.dispose();
    super.dispose();
  }
}