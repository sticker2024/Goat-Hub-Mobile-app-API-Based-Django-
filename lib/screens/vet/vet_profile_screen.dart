import '../../models/user.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/consultation_provider.dart';
import '../../core/constants/colors.dart';
import '../../shared/widgets/loading_widget.dart';

class VetProfileScreen extends StatefulWidget {
  const VetProfileScreen({super.key});

  @override
  State<VetProfileScreen> createState() => _VetProfileScreenState();
}

class _VetProfileScreenState extends State<VetProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = false;
  File? _profileImage;
  
  // Profile form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _districtController = TextEditingController();
  final _sectorController = TextEditingController();
  
  // Professional info controllers
  final _licenseNumberController = TextEditingController();
  final _yearsExperienceController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _bioController = TextEditingController();
  final _qualificationsController = TextEditingController();
  
  String? _specialization = 'general';
  final List<String> _selectedSpecialties = [];
  
  final List<String> _rwandanDistricts = [
    'Kigali', 'Bugesera', 'Gatsibo', 'Gicumbi', 'Gisagara', 'Huye',
    'Kamonyi', 'Karongi', 'Kayonza', 'Kirehe', 'Muhanga', 'Musanze',
    'Ngoma', 'Nyarugenge', 'Rubavu', 'Ruhango', 'Rulindo', 'Rusizi',
    'Rutsiro', 'Nyabihu', 'Nyagatare', 'Nyamagabe', 'Nyamasheke',
    'Nyanza', 'Nyaruguru', 'Gasabo', 'Kicukiro', 'Burera', 'Gakenke',
  ];

  final List<Map<String, dynamic>> _specializations = [
    {'value': 'general', 'label': 'General Veterinary', 'icon': Icons.medical_services},
    {'value': 'surgery', 'label': 'Surgery', 'icon': Icons.content_cut},
    {'value': 'reproduction', 'label': 'Reproduction', 'icon': Icons.pregnant_woman},
    {'value': 'nutrition', 'label': 'Nutrition', 'icon': Icons.restaurant},
    {'value': 'preventive', 'label': 'Preventive Care', 'icon': Icons.health_and_safety},
    {'value': 'emergency', 'label': 'Emergency Care', 'icon': Icons.warning},
    {'value': 'dentistry', 'label': 'Dentistry', 'icon': Icons.medical_information},
  ];

  final List<Map<String, dynamic>> _workingHours = [
    {'day': 'Monday', 'start': '08:00', 'end': '17:00', 'enabled': true},
    {'day': 'Tuesday', 'start': '08:00', 'end': '17:00', 'enabled': true},
    {'day': 'Wednesday', 'start': '08:00', 'end': '17:00', 'enabled': true},
    {'day': 'Thursday', 'start': '08:00', 'end': '17:00', 'enabled': true},
    {'day': 'Friday', 'start': '08:00', 'end': '17:00', 'enabled': true},
    {'day': 'Saturday', 'start': '09:00', 'end': '13:00', 'enabled': true},
    {'day': 'Sunday', 'start': 'Closed', 'end': 'Closed', 'enabled': false},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initAnimations();
    _loadUserData();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser as Veterinarian?;
    
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
      _districtController.text = user.district;
      _sectorController.text = user.sector;
      _licenseNumberController.text = user.licenseNumber;
      _yearsExperienceController.text = user.yearsExperience.toString();
      _clinicNameController.text = user.clinicName;
      _clinicAddressController.text = user.clinicAddress;
      _specialization = user.specialization;
      _bioController.text = 'Experienced veterinarian specializing in goat health and disease management.';
      _qualificationsController.text = 'DVM - University of Rwanda\nCertificate in Livestock Management';
    }
  }

  Future<void> _pickImage() async {
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

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _isLoading = false);
    
    Helpers.showSnackBar(
      context,
      'Profile updated successfully',
      type: SnackBarType.success,
    );
  }

  void _showChangePasswordDialog() {
    final formKey = GlobalKey<FormState>();
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool isCurrentVisible = false;
    bool isNewVisible = false;
    bool isConfirmVisible = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current Password
                  TextFormField(
                    controller: currentController,
                    obscureText: !isCurrentVisible,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isCurrentVisible ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            isCurrentVisible = !isCurrentVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: Validators.required,
                  ),
                  const SizedBox(height: 12),
                  
                  // New Password
                  TextFormField(
                    controller: newController,
                    obscureText: !isNewVisible,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isNewVisible ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            isNewVisible = !isNewVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 12),
                  
                  // Confirm Password
                  TextFormField(
                    controller: confirmController,
                    obscureText: !isConfirmVisible,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isConfirmVisible ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            isConfirmVisible = !isConfirmVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) => Validators.confirmPassword(value, newController.text),
                  ),
                  
                  // Password strength indicator
                  const SizedBox(height: 16),
                  _buildPasswordStrengthIndicator(newController.text),
                ],
              ),
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
                  Helpers.showSnackBar(
                    context,
                    'Password changed successfully',
                    type: SnackBarType.success,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vet,
              ),
              child: const Text('Update'),
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

  void _showAvailabilityDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Set Availability'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _workingHours.length,
              itemBuilder: (context, index) {
                final day = _workingHours[index];
                return CheckboxListTile(
                  title: Text(day['day']),
                  subtitle: day['enabled']
                      ? Text('${day['start']} - ${day['end']}')
                      : const Text('Closed'),
                  value: day['enabled'],
                  onChanged: (value) {
                    setState(() {
                      _workingHours[index]['enabled'] = value!;
                    });
                  },
                  secondary: day['enabled']
                      ? IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _showEditHoursDialog(index);
                          },
                        )
                      : null,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Helpers.showSnackBar(
                  context,
                  'Availability updated',
                  type: SnackBarType.success,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vet,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditHoursDialog(int index) {
    final day = _workingHours[index];
    final startController = TextEditingController(text: day['start']);
    final endController = TextEditingController(text: day['end']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Hours - ${day['day']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: startController,
              decoration: const InputDecoration(
                labelText: 'Start Time',
                hintText: 'HH:MM',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: endController,
              decoration: const InputDecoration(
                labelText: 'End Time',
                hintText: 'HH:MM',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _workingHours[index]['start'] = startController.text;
                _workingHours[index]['end'] = endController.text;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vet,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (mounted) {
                context.go('/role-select');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.warning_amber, color: Colors.red, size: 50),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Delete Account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Enter your password to confirm',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Helpers.showSnackBar(
                context,
                'Account deletion requested',
                type: SnackBarType.error,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final consultationProvider = Provider.of<ConsultationProvider>(context);
    final user = authProvider.currentUser as Veterinarian?;
    
    if (user == null) {
      return const Center(child: Text('User not found'));
    }

    return Scaffold(
      body: _isLoading
          ? const LoadingWidget(message: 'Updating profile...')
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 200,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppColors.vet,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Cover Image
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.vet, AppColors.vetDark],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          
                          // Profile Header Content
                          Positioned(
                            bottom: 60,
                            left: 16,
                            right: 16,
                            child: Row(
                              children: [
                                // Profile Image
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: _profileImage != null
                                              ? Image.file(
                                                  _profileImage!,
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.network(
                                                  'https://via.placeholder.com/150',
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // User Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Dr. ${user.fullName}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user.specializationDisplay,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: user.isApproved 
                                                  ? Colors.green 
                                                  : Colors.orange,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              user.isApproved ? 'Approved' : 'Pending Approval',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _updateProfile,
                      ),
                    ],
                    bottom: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(icon: Icon(Icons.person), text: 'Profile'),
                        Tab(icon: Icon(Icons.medical_services), text: 'Professional'),
                        Tab(icon: Icon(Icons.settings), text: 'Settings'),
                      ],
                    ),
                  ),
                ];
              },
              body: FadeTransition(
                opacity: _fadeAnimation,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                   _buildProfileTab(user, consultationProvider),
                    _buildProfessionalTab(user),
                    _buildSettingsTab(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileTab(Veterinarian user, dynamic consultationProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Personal Information Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_outline, color: AppColors.vet),
                      SizedBox(width: 8),
                      Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('First Name', user.firstName, Icons.person),
                  _buildInfoRow('Last Name', user.lastName, Icons.person),
                  _buildInfoRow('Email', user.email, Icons.email),
                  _buildInfoRow('Phone', user.phone, Icons.phone),
                  _buildInfoRow('District', user.district, Icons.location_on),
                  _buildInfoRow('Sector', user.sector, Icons.map),
                  _buildInfoRow('Member Since', 
                      DateFormat('MMMM dd, yyyy').format(user.createdAt), 
                      Icons.calendar_today),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Statistics Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bar_chart, color: AppColors.vet),
                      SizedBox(width: 8),
                      Text(
                        'Performance Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        'Consultations',
                        consultationProvider.consultations.length.toString(),
                        Icons.chat,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Replies',
                        consultationProvider.replies.length.toString(),
                        Icons.reply,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Response Time',
                        '2.4h',
                        Icons.timer,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Rating',
                        '4.8',
                        Icons.star,
                        Colors.amber,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bio Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.description, color: AppColors.vet),
                      SizedBox(width: 8),
                      Text(
                        'About Me',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _bioController.text,
                    style: const TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalTab(Veterinarian user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // License Information
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.badge, color: AppColors.vet),
                      SizedBox(width: 8),
                      Text(
                        'License Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildProfInfoRow('License Number', user.licenseNumber, Icons.numbers),
                  _buildProfInfoRow('Specialization', user.specializationDisplay, Icons.medical_services),
                  _buildProfInfoRow('Experience', '${user.yearsExperience} years', Icons.timeline),
                  _buildProfInfoRow('Status', user.isApproved ? 'Approved' : 'Pending', 
                      user.isApproved ? Icons.check_circle : Icons.pending,
                      color: user.isApproved ? Colors.green : Colors.orange),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Clinic Information
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.local_hospital, color: AppColors.vet),
                      SizedBox(width: 8),
                      Text(
                        'Clinic Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildProfInfoRow('Clinic Name', user.clinicName, Icons.business),
                  _buildProfInfoRow('Address', user.clinicAddress, Icons.location_on),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Qualifications
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.school, color: AppColors.vet),
                      SizedBox(width: 8),
                      Text(
                        'Qualifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._qualificationsController.text.split('\n').map((q) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(q)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Working Hours
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.access_time, color: AppColors.vet),
                          SizedBox(width: 8),
                          Text(
                            'Working Hours',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _showAvailabilityDialog,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._workingHours.where((day) => day['enabled']).map((day) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            day['day'],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          child: Text('${day['start']} - ${day['end']}'),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfInfoRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? AppColors.vet),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Account Settings
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.settings, color: AppColors.vet),
                    SizedBox(width: 8),
                    Text(
                      'Account Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  'Change Password',
                  Icons.lock_outline,
                  Colors.orange,
                  _showChangePasswordDialog,
                ),
                _buildDivider(),
                _buildSettingsTile(
                  'Notification Settings',
                  Icons.notifications_outlined,
                  Colors.blue,
                  () {},
                ),
                _buildDivider(),
                _buildSettingsTile(
                  'Privacy Settings',
                  Icons.privacy_tip_outlined,
                  Colors.purple,
                  () {},
                ),
                _buildDivider(),
                _buildSettingsTile(
                  'Language',
                  Icons.language,
                  Colors.teal,
                  () {},
                  trailing: const Text('English'),
                ),
                _buildDivider(),
                _buildSettingsTile(
                  'Theme',
                  Icons.dark_mode,
                  Colors.indigo,
                  () {},
                  trailing: const Text('Light'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Professional Settings
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.medical_services, color: AppColors.vet),
                    SizedBox(width: 8),
                    Text(
                      'Professional Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  'Consultation Fees',
                  Icons.attach_money,
                  Colors.green,
                  () {},
                  trailing: const Text('RWF 5,000'),
                ),
                _buildDivider(),
                _buildSettingsTile(
                  'Service Areas',
                  Icons.map,
                  Colors.blue,
                  () {},
                ),
                _buildDivider(),
                _buildSettingsTile(
                  'Specialties',
                  Icons.star,
                  Colors.amber,
                  () {},
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Support
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.support_agent, color: AppColors.vet),
                    SizedBox(width: 8),
                    Text(
                      'Support',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  'Help Center',
                  Icons.help_outline,
                  Colors.green,
                  () {},
                ),
                _buildDivider(),
                _buildSettingsTile(
                  'Contact Us',
                  Icons.email_outlined,
                  Colors.blue,
                  () {},
                ),
                _buildDivider(),
                _buildSettingsTile(
                  'Terms of Service',
                  Icons.description_outlined,
                  Colors.grey,
                  () {},
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Danger Zone
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Danger Zone',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  'Logout',
                  Icons.logout,
                  Colors.red,
                  _showLogoutDialog,
                ),
                _buildDivider(color: Colors.red.shade200),
                _buildSettingsTile(
                  'Delete Account',
                  Icons.delete_outline,
                  Colors.red,
                  _showDeleteAccountDialog,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(String title, IconData icon, Color color, VoidCallback onTap, {Widget? trailing}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildDivider({Color? color}) {
    return Divider(
      height: 1,
      color: color ?? Colors.grey.shade200,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _districtController.dispose();
    _sectorController.dispose();
    _licenseNumberController.dispose();
    _yearsExperienceController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _bioController.dispose();
    _qualificationsController.dispose();
    super.dispose();
  }
}