import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/consultation_provider.dart';
import '../../models/user.dart';
import '../../core/constants/colors.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../shared/widgets/loading_widget.dart';
import 'package:intl/intl.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> with SingleTickerProviderStateMixin {
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
  final _farmSizeController = TextEditingController();
  final _experienceController = TextEditingController();
  final _cooperativeController = TextEditingController();
  String? _farmType = 'individual';
  
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
    final user = authProvider.currentUser as Farmer?;
    
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
      _districtController.text = user.district;
      _sectorController.text = user.sector;
      _farmSizeController.text = user.farmSize.toString();
      _experienceController.text = user.farmingExperience.toString();
      _farmType = user.farmType;
      _cooperativeController.text = user.cooperativeName ?? '';
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

  Future<void> _changePassword() async {
    // This will be handled in a dialog
    _showChangePasswordDialog();
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
                backgroundColor: AppColors.primary,
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
              'Are you sure you want to delete your account? This action cannot be undone.',
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
                'Account deleted successfully',
                type: SnackBarType.error,
              );
              context.go('/role-select');
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

  void _showEditFarmDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Farm Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Farm Type
                DropdownButtonFormField<String>(
                  initialValue: _farmType,
                  decoration: const InputDecoration(
                    labelText: 'Farm Type',
                    prefixIcon: Icon(Icons.agriculture),
                    border: OutlineInputBorder(),
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
                const SizedBox(height: 12),
                
                // Cooperative Name (if applicable)
                if (_farmType == 'cooperative')
                  TextFormField(
                    controller: _cooperativeController,
                    decoration: const InputDecoration(
                      labelText: 'Cooperative Name',
                      prefixIcon: Icon(Icons.people),
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (_farmType == 'cooperative') const SizedBox(height: 12),
                
                // Farm Size
                TextFormField(
                  controller: _farmSizeController,
                  decoration: const InputDecoration(
                    labelText: 'Farm Size (Number of Goats)',
                    prefixIcon: Icon(Icons.pets),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                
                // Experience
                TextFormField(
                  controller: _experienceController,
                  decoration: const InputDecoration(
                    labelText: 'Years of Experience',
                    prefixIcon: Icon(Icons.timeline),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
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
                Navigator.pop(context);
                Helpers.showSnackBar(
                  context,
                  'Farm details updated',
                  type: SnackBarType.success,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Notification Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Consultation Replies'),
              subtitle: const Text('Get notified when vets reply'),
              value: true,
              onChanged: (value) {},
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.reply, color: Colors.blue),
              ),
            ),
            SwitchListTile(
              title: const Text('Educational Resources'),
              subtitle: const Text('New articles and videos'),
              value: false,
              onChanged: (value) {},
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school, color: Colors.green),
              ),
            ),
            SwitchListTile(
              title: const Text('Promotions'),
              subtitle: const Text('Special offers and updates'),
              value: false,
              onChanged: (value) {},
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_offer, color: Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacySettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Privacy Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.visibility, color: Colors.purple),
              ),
              title: const Text('Profile Visibility'),
              subtitle: const Text('Who can see your profile'),
              trailing: DropdownButton<String>(
                value: 'public',
                items: const [
                  DropdownMenuItem(value: 'public', child: Text('Public')),
                  DropdownMenuItem(value: 'private', child: Text('Private')),
                ],
                onChanged: (value) {},
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share, color: Colors.teal),
              ),
              title: const Text('Data Sharing'),
              subtitle: const Text('Share anonymized data for research'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
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
    final consultationProvider = Provider.of<ConsultationProvider>(context);
    final user = authProvider.currentUser as Farmer?;
    
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
                    backgroundColor: AppColors.primary,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Cover Image
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryDark],
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
                                        user.fullName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Farmer ID: ${user.idNumber}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 14,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              user.district,
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.9),
                                                fontSize: 12,
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
                        Tab(icon: Icon(Icons.agriculture), text: 'Farm'),
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
                    _buildProfileTab(user),
                    _buildFarmTab(user),
                    _buildSettingsTab(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileTab(Farmer user) {
  final consultationProvider = Provider.of<ConsultationProvider>(context);
  
  // Calculate total replies from all consultations
  int totalReplies = 0;
  for (var consultation in consultationProvider.consultations) {
    totalReplies += consultation.replies.length;
  }

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
                    Icon(Icons.person_outline, color: AppColors.primary),
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
                if (user.isVerified)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Verified Farmer',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                    Icon(Icons.bar_chart, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Account Statistics',
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
                      totalReplies.toString(), // Use calculated total
                      Icons.reply,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Days Active',
                      DateTime.now().difference(user.createdAt).inDays.toString(),
                      Icons.calendar_today,
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Recent Activity
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
                    Icon(Icons.history, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...List.generate(3, (index) {
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat, color: Colors.blue, size: 16),
                    ),
                    title: const Text('Consultation submitted'),
                    subtitle: Text('${index + 1} day${index > 0 ? 's' : ''} ago'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  );
                }),
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
          padding: const EdgeInsets.all(10),
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildFarmTab(Farmer user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Farm Details Card
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
                          Icon(Icons.agriculture, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Farm Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.primary),
                        onPressed: _showEditFarmDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFarmInfoRow(
                    'Farm Type',
                    user.farmType == 'individual' ? 'Individual Farmer' : 'Cooperative Member',
                    Icons.agriculture,
                  ),
                  if (user.farmType == 'cooperative')
                    _buildFarmInfoRow(
                      'Cooperative',
                      user.cooperativeName ?? 'Not specified',
                      Icons.people,
                    ),
                  _buildFarmInfoRow(
                    'Farm Size',
                    '${user.farmSize} goats',
                    Icons.pets,
                  ),
                  _buildFarmInfoRow(
                    'Experience',
                    '${user.farmingExperience} years',
                    Icons.timeline,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Livestock Information
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
                      Icon(Icons.pets, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Livestock Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFarmInfoRow('Total Goats', user.farmSize.toString(), Icons.pets),
                  _buildFarmInfoRow('Breeds', 'Local, Improved', Icons.category),
                  _buildFarmInfoRow('Last Vaccination', '2024-01-15', Icons.vaccines),
                  _buildFarmInfoRow('Next Checkup', '2024-03-15', Icons.calendar_today),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick Actions
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Add Goats',
                  Icons.add,
                  Colors.green,
                  () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Update Records',
                  Icons.edit_note,
                  Colors.blue,
                  () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFarmInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
                    Icon(Icons.settings, color: AppColors.primary),
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
                  _showNotificationSettings,
                ),
                _buildDivider(),
                _buildSettingsTile(
                  'Privacy Settings',
                  Icons.privacy_tip_outlined,
                  Colors.purple,
                  _showPrivacySettings,
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
                    Icon(Icons.support_agent, color: AppColors.primary),
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
                  'Report a Problem',
                  Icons.flag_outlined,
                  Colors.orange,
                  () {},
                ),
                _buildDivider(),
                _buildSettingsTile(
                  'Rate the App',
                  Icons.star_outline,
                  Colors.amber,
                  () {},
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // About
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
                    Icon(Icons.info_outline, color: AppColors.primary),
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
                const SizedBox(height: 16),
                _buildSettingsTile(
                  'Terms of Service',
                  Icons.description_outlined,
                  Colors.grey,
                  () {},
                ),
                _buildDivider(),
                _buildSettingsTile(
                  'Privacy Policy',
                  Icons.privacy_tip_outlined,
                  Colors.grey,
                  () {},
                ),
                _buildDivider(),
                _buildSettingsTile(
                  'App Version',
                  Icons.info_outline,
                  Colors.grey,
                  () {},
                  trailing: const Text('1.0.0'),
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
    _farmSizeController.dispose();
    _experienceController.dispose();
    _cooperativeController.dispose();
    super.dispose();
  }
}