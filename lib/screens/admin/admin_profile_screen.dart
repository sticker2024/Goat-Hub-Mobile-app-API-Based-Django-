import 'package:flutter/material.dart';
import 'package:goathub/providers/special_case_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/farmer_provider.dart';
import '../../providers/vet_provider.dart';
import '../../providers/consultation_provider.dart';
import '../../models/user.dart';
import '../../core/constants/colors.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../shared/widgets/loading_widget.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> with SingleTickerProviderStateMixin {
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
  final _departmentController = TextEditingController();
  final _positionController = TextEditingController();
  final _bioController = TextEditingController();

  // System settings
  bool _maintenanceMode = false;
  bool _allowNewRegistrations = true;
  bool _requireVetApproval = true;
  bool _enableNotifications = true;
  bool _enableEmailAlerts = true;
  String _selectedLanguage = 'English';
  String _selectedTimezone = 'Africa/Kigali';
  
  // Security settings
  bool _twoFactorAuth = false;
  bool _sessionTimeout = true;
  String _sessionTimeoutDuration = '30 minutes';

  final List<String> _languages = ['English', 'French', 'Kinyarwanda'];
  final List<String> _timezones = ['Africa/Kigali', 'UTC', 'Africa/Nairobi', 'Africa/Kampala'];
  final List<String> _timeoutOptions = ['15 minutes', '30 minutes', '1 hour', '2 hours', 'Never'];

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
    final user = authProvider.currentUser;
    
    if (user != null && user.userType == 'admin') {
      // Cast to Administrator to access admin-specific fields
      final admin = user as Administrator;
      _firstNameController.text = admin.firstName;
      _lastNameController.text = admin.lastName;
      _emailController.text = admin.email;
      _phoneController.text = admin.phone;
      _departmentController.text = admin.department;
      _positionController.text = 'Senior Administrator';
      _bioController.text = 'Platform administrator with experience in managing agricultural technology solutions.';
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
                backgroundColor: AppColors.admin,
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
              'Are you sure you want to delete your admin account? This action cannot be undone and will remove all your access.',
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

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Database'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_upload, color: Colors.blue, size: 50),
            const SizedBox(height: 16),
            const Text(
              'Create a backup of the entire database?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'This may take a few minutes depending on the database size.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
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
                'Backup started successfully',
                type: SnackBarType.success,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Start Backup'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cleaning_services, color: Colors.orange, size: 50),
            const SizedBox(height: 16),
            const Text(
              'Clear all system cache?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'This will free up storage space but may temporarily slow down the system.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
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
                'Cache cleared successfully',
                type: SnackBarType.success,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  void _showAuditLogDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Audit Log',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: 20,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: index % 2 == 0 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      child: Icon(
                        index % 2 == 0 ? Icons.person_add : Icons.settings,
                        color: index % 2 == 0 ? Colors.green : Colors.blue,
                      ),
                    ),
                    title: Text(index % 2 == 0 
                        ? 'New user registered' 
                        : 'System setting changed'),
                    subtitle: Text('${index + 1} hour${index > 0 ? 's' : ''} ago'),
                    trailing: Text(
                      'IP: 192.168.1.${100 + index}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

 @override
Widget build(BuildContext context) {
  final authProvider = Provider.of<AuthProvider>(context);
  final farmerProvider = Provider.of<FarmerProvider>(context);
  final vetProvider = Provider.of<VetProvider>(context);
  final consultationProvider = Provider.of<ConsultationProvider>(context);
  final specialCaseProvider = Provider.of<SpecialCaseProvider>(context);
  final user = authProvider.currentUser;
  
  if (user == null || user.userType != 'admin') {
    return const Center(child: Text('User not found'));
  }

  // Cast to Administrator for admin-specific fields
  final admin = user as Administrator;

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
                  backgroundColor: AppColors.admin,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Cover Image
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.admin, AppColors.adminDark],
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
                              
                              // User Info - Use admin instead of user
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      admin.fullName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      admin.department, // Now this works
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.admin_panel_settings,
                                          size: 14,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Administrator',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 12,
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
                      Tab(icon: Icon(Icons.settings), text: 'System'),
                      Tab(icon: Icon(Icons.security), text: 'Security'),
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
                  _buildProfileTab(admin), // Pass admin instead of user
                  _buildSystemTab(),
                  _buildSecurityTab(),
                ],
              ),
            ),
          ),
  );
}

  Widget _buildProfileTab(dynamic user) {
    // Cast to Administrator
    final admin = user as Administrator;
    
    // Get providers
    final farmerProvider = Provider.of<FarmerProvider>(context);
    final vetProvider = Provider.of<VetProvider>(context);
    final consultationProvider = Provider.of<ConsultationProvider>(context);
    final specialCaseProvider = Provider.of<SpecialCaseProvider>(context);

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
                      Icon(Icons.person_outline, color: AppColors.admin),
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
                  _buildInfoRow('First Name', admin.firstName, Icons.person),
                  _buildInfoRow('Last Name', admin.lastName, Icons.person),
                  _buildInfoRow('Email', admin.email, Icons.email),
                  _buildInfoRow('Phone', admin.phone, Icons.phone),
                  _buildInfoRow('Department', admin.department, Icons.business),
                  _buildInfoRow('Position', _positionController.text, Icons.work),
                  _buildInfoRow('Employee ID', admin.employeeId, Icons.badge),
                  _buildInfoRow('Admin ID', admin.adminId, Icons.admin_panel_settings),
                  _buildInfoRow('Member Since', 
                      DateFormat('MMMM dd, yyyy').format(admin.createdAt), 
                      Icons.calendar_today),
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
                      Icon(Icons.description, color: AppColors.admin),
                      SizedBox(width: 8),
                      Text(
                        'About',
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
          const SizedBox(height: 16),

          // Platform Statistics Card
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
                      Icon(Icons.bar_chart, color: AppColors.admin),
                      SizedBox(width: 8),
                      Text(
                        'Platform Overview',
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
                        'Farmers',
                        farmerProvider.farmers.length.toString(),
                        Icons.people,
                        AppColors.primary,
                      ),
                      _buildStatCard(
                        'Vets',
                        vetProvider.vets.length.toString(),
                        Icons.medical_services,
                        AppColors.vet,
                      ),
                      _buildStatCard(
                        'Consultations',
                        consultationProvider.consultations.length.toString(),
                        Icons.chat,
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        'Pending Vets',
                        vetProvider.getPendingCount().toString(),
                        Icons.pending,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Special Cases',
                        specialCaseProvider.specialCases.length.toString(),
                        Icons.warning,
                        Colors.red,
                      ),
                      _buildStatCard(
                        'Replies',
                        consultationProvider.replies.length.toString(),
                        Icons.reply,
                        Colors.green,
                      ),
                    ],
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

  Widget _buildSystemTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // System Settings
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
                    Icon(Icons.settings, color: AppColors.admin),
                    SizedBox(width: 8),
                    Text(
                      'System Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Maintenance Mode'),
                  subtitle: const Text('Put the platform in maintenance mode'),
                  value: _maintenanceMode,
                  onChanged: (value) {
                    setState(() {
                      _maintenanceMode = value;
                    });
                    if (value) {
                      _showMaintenanceDialog();
                    }
                  },
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.build, color: Colors.orange),
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Allow New Registrations'),
                  subtitle: const Text('Enable user registration'),
                  value: _allowNewRegistrations,
                  onChanged: (value) {
                    setState(() {
                      _allowNewRegistrations = value;
                    });
                  },
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add, color: Colors.green),
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Require Vet Approval'),
                  subtitle: const Text('Vets need admin approval to join'),
                  value: _requireVetApproval,
                  onChanged: (value) {
                    setState(() {
                      _requireVetApproval = value;
                    });
                  },
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.medical_services, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // System Health
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
                    Icon(Icons.health_and_safety, color: AppColors.admin),
                    SizedBox(width: 8),
                    Text(
                      'System Health',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildHealthMetric('Database', '98%', 'Operational', Colors.green),
                _buildHealthMetric('Storage', '45%', '42.3 GB / 94.2 GB', Colors.blue),
                _buildHealthMetric('Memory', '62%', 'Used', Colors.orange),
                _buildHealthMetric('API Response', '124ms', 'Average', Colors.green),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        'Backup DB',
                        Icons.backup,
                        Colors.blue,
                        _showBackupDialog,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        'Clear Cache',
                        Icons.cleaning_services,
                        Colors.orange,
                        _showClearCacheDialog,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Audit & Logs
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
                    Icon(Icons.history, color: AppColors.admin),
                    SizedBox(width: 8),
                    Text(
                      'Audit & Logs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.list_alt, color: Colors.purple),
                  ),
                  title: const Text('View Audit Log'),
                  subtitle: const Text('Track all system activities'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showAuditLogDialog,
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline, color: Colors.teal),
                  ),
                  title: const Text('Error Logs'),
                  subtitle: const Text('View system errors and warnings'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Helpers.showSnackBar(
                      context,
                      'Error logs feature coming soon',
                      type: SnackBarType.info,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Localization
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
                    Icon(Icons.language, color: AppColors.admin),
                    SizedBox(width: 8),
                    Text(
                      'Localization',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.language, color: Colors.blue),
                  ),
                  title: const Text('Default Language'),
                  trailing: DropdownButton<String>(
                    value: _selectedLanguage,
                    items: _languages.map((lang) {
                      return DropdownMenuItem(
                        value: lang,
                        child: Text(lang),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                    },
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.access_time, color: Colors.green),
                  ),
                  title: const Text('Timezone'),
                  trailing: DropdownButton<String>(
                    value: _selectedTimezone,
                    items: _timezones.map((tz) {
                      return DropdownMenuItem(
                        value: tz,
                        child: Text(tz),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTimezone = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthMetric(String label, String value, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildSecurityTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Account Security
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
                    Icon(Icons.security, color: AppColors.admin),
                    SizedBox(width: 8),
                    Text(
                      'Account Security',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline, color: Colors.orange),
                  ),
                  title: const Text('Change Password'),
                  subtitle: const Text('Update your password regularly'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showChangePasswordDialog,
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Two-Factor Authentication'),
                  subtitle: const Text('Add an extra layer of security'),
                  value: _twoFactorAuth,
                  onChanged: (value) {
                    setState(() {
                      _twoFactorAuth = value;
                    });
                    if (value) {
                      _showTwoFactorSetupDialog();
                    }
                  },
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user, color: Colors.blue),
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Session Timeout'),
                  subtitle: const Text('Automatically logout after inactivity'),
                  value: _sessionTimeout,
                  onChanged: (value) {
                    setState(() {
                      _sessionTimeout = value;
                    });
                  },
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.timer, color: Colors.purple),
                  ),
                ),
                if (_sessionTimeout)
                  Padding(
                    padding: const EdgeInsets.only(left: 72),
                    child: DropdownButton<String>(
                      value: _sessionTimeoutDuration,
                      isExpanded: true,
                      items: _timeoutOptions.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _sessionTimeoutDuration = value!;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Notification Settings
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
                    Icon(Icons.notifications, color: AppColors.admin),
                    SizedBox(width: 8),
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive notifications on this device'),
                  value: _enableNotifications,
                  onChanged: (value) {
                    setState(() {
                      _enableNotifications = value;
                    });
                  },
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications, color: Colors.blue),
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Email Alerts'),
                  subtitle: const Text('Receive important alerts via email'),
                  value: _enableEmailAlerts,
                  onChanged: (value) {
                    setState(() {
                      _enableEmailAlerts = value;
                    });
                  },
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.email, color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Login History
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
                    Icon(Icons.history, color: AppColors.admin),
                    SizedBox(width: 8),
                    Text(
                      'Login History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...List.generate(5, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: index == 0 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            index == 0 ? Icons.laptop : Icons.phone_android,
                            color: index == 0 ? Colors.green : Colors.grey,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                index == 0 ? 'Current Session' : 'Previous Login',
                                style: TextStyle(
                                  fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              Text(
                                'IP: 192.168.1.${100 + index}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          index == 0 ? 'Now' : '$index day${index > 1 ? 's' : ''} ago',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
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
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.logout, color: Colors.red),
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.red, size: 16),
                  onTap: _showLogoutDialog,
                ),
                const Divider(color: Color.fromARGB(255, 46, 13, 13)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text(
                    'Delete Account',
                    style: TextStyle(color: Colors.red),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.red, size: 16),
                  onTap: _showDeleteAccountDialog,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showMaintenanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maintenance Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.build, color: Colors.orange, size: 50),
            const SizedBox(height: 16),
            const Text(
              'Enable maintenance mode?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Users will not be able to access the platform until maintenance is complete.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Maintenance Message',
                hintText: 'Briefly explain the maintenance',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _maintenanceMode = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Helpers.showSnackBar(
                context,
                'Maintenance mode enabled',
                type: SnackBarType.warning,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _showTwoFactorSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup Two-Factor Authentication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_scanner, size: 100),
            const SizedBox(height: 16),
            const Text(
              'Scan this QR code with your authenticator app',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ABCD-EFGH-IJKL-MNOP',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _twoFactorAuth = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Helpers.showSnackBar(
                context,
                'Two-factor authentication enabled',
                type: SnackBarType.success,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
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
    _departmentController.dispose();
    _positionController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}