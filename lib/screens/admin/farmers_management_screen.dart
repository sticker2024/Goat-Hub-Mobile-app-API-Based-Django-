import '../../models/user.dart';
import '../../utils/helpers.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/farmer_provider.dart';
import '../../core/constants/colors.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/filter_chips.dart';

class FarmersManagementScreen extends StatefulWidget {
  const FarmersManagementScreen({super.key});

  @override
  State<FarmersManagementScreen> createState() => _FarmersManagementScreenState();
}

class _FarmersManagementScreenState extends State<FarmersManagementScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  String _selectedDistrict = 'all';
  String _selectedSort = 'newest';
  String _selectedView = 'grid'; // 'grid' or 'list'
  bool _showFilters = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _pageSize = 20;
  
  List<String> _districts = [];
  List<Farmer> _filteredFarmers = [];
  List<Farmer> _selectedFarmers = [];
  bool _isSelectionMode = false;

  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'newest', 'label': 'Newest First', 'icon': Icons.access_time},
    {'value': 'oldest', 'label': 'Oldest First', 'icon': Icons.history},
    {'value': 'name_asc', 'label': 'Name A-Z', 'icon': Icons.sort_by_alpha},
    {'value': 'name_desc', 'label': 'Name Z-A', 'icon': Icons.sort_by_alpha},
    {'value': 'consultations', 'label': 'Most Consultations', 'icon': Icons.chat},
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
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

  Future<void> _loadData() async {
    final farmerProvider = context.read<FarmerProvider>();
    await farmerProvider.loadFarmers();
    
    if (mounted) {
      setState(() {
        _districts = farmerProvider.getDistricts();
        _applyFilters();
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    
    // Simulate loading more data
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _isLoadingMore = false;
    });
  }

  void _applyFilters() {
    final farmerProvider = context.read<FarmerProvider>();
    var farmers = List<Farmer>.from(farmerProvider.farmers);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      farmers = farmers.where((f) {
        return f.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               f.idNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               f.phone.contains(_searchQuery) ||
               f.district.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Apply district filter
    if (_selectedDistrict != 'all') {
      farmers = farmers.where((f) => f.district == _selectedDistrict).toList();
    }
    
    // Apply sorting
    switch (_selectedSort) {
      case 'newest':
        farmers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        farmers.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'name_asc':
        farmers.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
      case 'name_desc':
        farmers.sort((a, b) => b.fullName.compareTo(a.fullName));
        break;
      case 'consultations':
        // This would require consultation count data
        break;
    }
    
    setState(() {
      _filteredFarmers = farmers;
    });
  }

  void _toggleSelection(Farmer farmer) {
    setState(() {
      if (_selectedFarmers.contains(farmer)) {
        _selectedFarmers.remove(farmer);
      } else {
        _selectedFarmers.add(farmer);
      }
      _isSelectionMode = _selectedFarmers.isNotEmpty;
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedFarmers.length == _filteredFarmers.length) {
        _selectedFarmers.clear();
        _isSelectionMode = false;
      } else {
        _selectedFarmers = List.from(_filteredFarmers);
        _isSelectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedFarmers.clear();
      _isSelectionMode = false;
    });
  }

  void _showBulkActions() {
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
            Text(
              'Bulk Actions (${_selectedFarmers.length} selected)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.email_outlined, color: Colors.blue),
              ),
              title: const Text('Send Email'),
              subtitle: Text('Send email to ${_selectedFarmers.length} farmers'),
              onTap: () {
                Navigator.pop(context);
                _showBulkEmailDialog();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.message_outlined, color: Colors.green),
              ),
              title: const Text('Send Notification'),
              subtitle: Text('Send push notification to ${_selectedFarmers.length} farmers'),
              onTap: () {
                Navigator.pop(context);
                _showBulkNotificationDialog();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline, color: Colors.red),
              ),
              title: const Text('Delete Selected'),
              subtitle: const Text('Permanently delete selected farmers'),
              onTap: () {
                Navigator.pop(context);
                _showBulkDeleteDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkEmailDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Bulk Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will send an email to all selected farmers.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
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
                'Emails sent successfully',
                type: SnackBarType.success,
              );
              _clearSelection();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showBulkNotificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Send a push notification to all selected farmers.'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
                'Notifications sent successfully',
                type: SnackBarType.success,
              );
              _clearSelection();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showBulkDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Farmers'),
        content: Text(
          'Are you sure you want to delete ${_selectedFarmers.length} farmers? This action cannot be undone.',
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
                'Farmers deleted successfully',
                type: SnackBarType.error,
              );
              _clearSelection();
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

  void _showFarmerDetails(Farmer farmer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _buildFarmerDetailsSheet(farmer, scrollController);
        },
      ),
    );
  }

  Widget _buildFarmerDetailsSheet(Farmer farmer, ScrollController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  Helpers.getInitials(farmer.fullName),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farmer.fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${farmer.idNumber}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          farmer.district,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Content
          Expanded(
            child: ListView(
              controller: controller,
              children: [
                // Personal Information
                _buildInfoSection(
                  'Personal Information',
                  Icons.person_outline,
                  [
                    _buildInfoRow('Full Name', farmer.fullName),
                    _buildInfoRow('ID Number', farmer.idNumber),
                    _buildInfoRow('Phone', farmer.phone),
                    _buildInfoRow('Email', farmer.email),
                    _buildInfoRow('District', farmer.district),
                    _buildInfoRow('Sector', farmer.sector),
                    _buildInfoRow('Member Since', DateFormat('MMM dd, yyyy').format(farmer.createdAt)),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Farm Details
                _buildInfoSection(
                  'Farm Details',
                  Icons.agriculture_outlined,
                  [
                    _buildInfoRow('Farm Type', farmer.farmType == 'individual' ? 'Individual Farmer' : 'Cooperative Member'),
                    if (farmer.cooperativeName != null)
                      _buildInfoRow('Cooperative', farmer.cooperativeName!),
                    _buildInfoRow('Farm Size', '${farmer.farmSize} goats'),
                    _buildInfoRow('Experience', '${farmer.farmingExperience} years'),
                    _buildInfoRow('Verified', farmer.isVerified ? 'Yes' : 'No'),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Statistics
                _buildStatisticsSection(farmer),
                const SizedBox(height: 16),
                
                // Recent Consultations
                _buildRecentConsultations(farmer),
              ],
            ),
          ),
          
          // Action Buttons
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showEditFarmerDialog(farmer);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(Farmer farmer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.blue, size: 18),
              SizedBox(width: 8),
              Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Consultations', '15', Icons.chat, Colors.blue),
              _buildStatItem('Replies', '8', Icons.reply, Colors.green),
              _buildStatItem('Last Active', '2d', Icons.access_time, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
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

  Widget _buildRecentConsultations(Farmer farmer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: Colors.green, size: 18),
              SizedBox(width: 8),
              Text(
                'Recent Consultations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.access_time, color: Colors.orange, size: 16),
            ),
            title: const Text('Respiratory issues'),
            subtitle: const Text('Pending • 2 days ago'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 16),
            ),
            title: const Text('Vaccination schedule'),
            subtitle: const Text('Replied • 1 week ago'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          ),
        ],
      ),
    );
  }

  void _showEditFarmerDialog(Farmer farmer) {
    final nameController = TextEditingController(text: farmer.fullName);
    final phoneController = TextEditingController(text: farmer.phone);
    final emailController = TextEditingController(text: farmer.email);
    final districtController = TextEditingController(text: farmer.district);
    final sectorController = TextEditingController(text: farmer.sector);
    final farmSizeController = TextEditingController(text: farmer.farmSize.toString());
    final experienceController = TextEditingController(text: farmer.farmingExperience.toString());
    String? farmType = farmer.farmType;
    String? cooperativeName = farmer.cooperativeName;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Farmer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: farmType,
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
                  farmType = value;
                },
              ),
              if (farmType == 'cooperative') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: TextEditingController(text: cooperativeName),
                  decoration: const InputDecoration(
                    labelText: 'Cooperative Name',
                    prefixIcon: Icon(Icons.people),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => cooperativeName = value,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: districtController,
                      decoration: const InputDecoration(
                        labelText: 'District',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: sectorController,
                      decoration: const InputDecoration(
                        labelText: 'Sector',
                        prefixIcon: Icon(Icons.map),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: farmSizeController,
                      decoration: const InputDecoration(
                        labelText: 'Farm Size',
                        prefixIcon: Icon(Icons.pets),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: experienceController,
                      decoration: const InputDecoration(
                        labelText: 'Experience',
                        prefixIcon: Icon(Icons.timeline),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Helpers.showSnackBar(
                context,
                'Farmer updated successfully',
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
    );
  }

  void _showDeleteConfirmation(Farmer farmer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Farmer'),
        content: Text('Are you sure you want to delete ${farmer.fullName}? This action cannot be undone.'),
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
                'Farmer deleted successfully',
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

  void _showExportOptions() {
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
              'Export Farmers',
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
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.file_download, color: Colors.green),
              ),
              title: const Text('Export as CSV'),
              subtitle: const Text('Download all farmers as CSV file'),
              onTap: () {
                Navigator.pop(context);
                Helpers.showSnackBar(
                  context,
                  'Export started',
                  type: SnackBarType.success,
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.picture_as_pdf, color: Colors.red),
              ),
              title: const Text('Export as PDF'),
              subtitle: const Text('Generate PDF report'),
              onTap: () {
                Navigator.pop(context);
                Helpers.showSnackBar(
                  context,
                  'PDF generation started',
                  type: SnackBarType.success,
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.print, color: Colors.blue),
              ),
              title: const Text('Print'),
              subtitle: const Text('Print farmers list'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement print
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      body: Consumer<FarmerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.farmers.isEmpty) {
            return const LoadingWidget(message: 'Loading farmers...');
          }

          if (provider.error != null) {
            return CustomErrorWidget(
              message: provider.error!,
              onRetry: _loadData,
            );
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // App Bar
                SliverAppBar(
                  expandedHeight: 120,
                  floating: true,
                  pinned: true,
                  backgroundColor: AppColors.admin,
                  flexibleSpace: FlexibleSpaceBar(
                    title: _isSelectionMode
                        ? Text('${_selectedFarmers.length} selected')
                        : const Text('Farmers Management'),
                    titlePadding: const EdgeInsets.only(left: 70, bottom: 16),
                  ),
                  leading: _isSelectionMode
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _clearSelection,
                        )
                      : IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => context.pop(),
                        ),
                  actions: [
                    if (_isSelectionMode)
                      IconButton(
                        icon: const Icon(Icons.select_all),
                        onPressed: _selectAll,
                        tooltip: 'Select All',
                      ),
                    if (_isSelectionMode)
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: _showBulkActions,
                        tooltip: 'Bulk Actions',
                      ),
                    if (!_isSelectionMode) ...[
                      IconButton(
                        icon: const Icon(Icons.view_module),
                        onPressed: () {
                          setState(() {
                            _selectedView = _selectedView == 'grid' ? 'list' : 'grid';
                          });
                        },
                        tooltip: _selectedView == 'grid' ? 'Switch to List' : 'Switch to Grid',
                      ),
                      IconButton(
                        icon: const Icon(Icons.file_download),
                        onPressed: _showExportOptions,
                        tooltip: 'Export',
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadData,
                        tooltip: 'Refresh',
                      ),
                    ],
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(80),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: 'Search farmers...',
                                      prefixIcon: const Icon(Icons.search, size: 20),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear, size: 20),
                                              onPressed: () {
                                                _searchController.clear();
                                              },
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                height: 45,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
                                    color: _showFilters ? AppColors.admin : Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showFilters = !_showFilters;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Filters
                if (_showFilters)
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Filters',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // District Filter
                          FilterChips(
                            label: 'District',
                            options: ['all', ..._districts],
                            selectedOption: _selectedDistrict,
                            onSelected: (value) {
                              setState(() {
                                _selectedDistrict = value;
                                _applyFilters();
                              });
                            },
                            optionLabel: (value) => value == 'all' ? 'All Districts' : value,
                          ),
                          const SizedBox(height: 12),
                          // Sort Options
                          const Text(
                            'Sort By',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _sortOptions.map((option) {
                                final isSelected = _selectedSort == option['value'];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    selected: isSelected,
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          option['icon'],
                                          size: 16,
                                          color: isSelected ? Colors.white : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(option['label']),
                                      ],
                                    ),
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedSort = option['value'];
                                        _applyFilters();
                                      });
                                    },
                                    selectedColor: AppColors.admin,
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ];
            },
            body: FadeTransition(
              opacity: _fadeAnimation,
              child: _filteredFarmers.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.people_outline,
                      title: 'No Farmers Found',
                      message: 'No farmers match your search criteria',
                      buttonText: 'Clear Filters',
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _selectedDistrict = 'all';
                          _applyFilters();
                        });
                      },
                    )
                  : _selectedView == 'grid'
                      ? _buildGridView()
                      : _buildListView(),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to add farmer
          context.go('/register?role=farmer');
        },
        backgroundColor: AppColors.admin,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Farmer'),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredFarmers.length,
      itemBuilder: (context, index) {
        final farmer = _filteredFarmers[index];
        final isSelected = _selectedFarmers.contains(farmer);
        
        return _buildFarmerGridCard(farmer, isSelected);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredFarmers.length,
      itemBuilder: (context, index) {
        final farmer = _filteredFarmers[index];
        final isSelected = _selectedFarmers.contains(farmer);
        
        return _buildFarmerListCard(farmer, isSelected);
      },
    );
  }

  Widget _buildFarmerGridCard(Farmer farmer, bool isSelected) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: AppColors.admin, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showFarmerDetails(farmer),
        onLongPress: () => _toggleSelection(farmer),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      Helpers.getInitials(farmer.fullName),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Name
                  Text(
                    farmer.fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // ID
                  Text(
                    'ID: ${farmer.idNumber}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // District
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, size: 10, color: AppColors.primary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          farmer.district,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildGridStat('15', 'Consults'),
                      _buildGridStat('8', 'Replies'),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.admin,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildFarmerListCard(Farmer farmer, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: AppColors.admin, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showFarmerDetails(farmer),
        onLongPress: () => _toggleSelection(farmer),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox for selection mode
              if (_isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(farmer),
                  activeColor: AppColors.admin,
                ),
              
              // Avatar
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  Helpers.getInitials(farmer.fullName),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            farmer.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: farmer.isVerified ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            farmer.isVerified ? 'Verified' : 'Unverified',
                            style: TextStyle(
                              fontSize: 9,
                              color: farmer.isVerified ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${farmer.idNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          farmer.phone,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          farmer.district,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${farmer.farmSize} goats',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${farmer.farmingExperience} yrs exp',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _showEditFarmerDialog(farmer),
                    color: AppColors.primary,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    onPressed: () => _showDeleteConfirmation(farmer),
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}