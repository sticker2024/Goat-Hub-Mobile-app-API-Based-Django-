import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import '../../providers/vet_provider.dart';
import '../../providers/consultation_provider.dart';
import '../../core/constants/colors.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/filter_chips.dart';

class VeterinariansManagementScreen extends StatefulWidget {
  const VeterinariansManagementScreen({super.key});

  @override
  State<VeterinariansManagementScreen> createState() => _VeterinariansManagementScreenState();
}

class _VeterinariansManagementScreenState extends State<VeterinariansManagementScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedSpecialty = 'all';
  String _selectedSort = 'newest';
  String _selectedView = 'grid'; // 'grid' or 'list'
  bool _showFilters = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _pageSize = 20;
  
  List<String> _specialties = [];
  List<Veterinarian> _filteredVets = [];
  List<Veterinarian> _selectedVets = [];
  bool _isSelectionMode = false;

  final List<Map<String, dynamic>> _statusOptions = [
    {'value': 'all', 'label': 'All', 'color': Colors.grey},
    {'value': 'approved', 'label': 'Approved', 'color': Colors.green},
    {'value': 'pending', 'label': 'Pending', 'color': Colors.orange},
    {'value': 'rejected', 'label': 'Rejected', 'color': Colors.red},
  ];

  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'newest', 'label': 'Newest First', 'icon': Icons.access_time},
    {'value': 'oldest', 'label': 'Oldest First', 'icon': Icons.history},
    {'value': 'name_asc', 'label': 'Name A-Z', 'icon': Icons.sort_by_alpha},
    {'value': 'name_desc', 'label': 'Name Z-A', 'icon': Icons.sort_by_alpha},
    {'value': 'experience', 'label': 'Most Experienced', 'icon': Icons.timeline},
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
    final vetProvider = context.read<VetProvider>();
    await vetProvider.loadVets();
    
    if (mounted) {
      setState(() {
        _specialties = vetProvider.getSpecializations();
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
    final vetProvider = context.read<VetProvider>();
    var vets = List<Veterinarian>.from(vetProvider.vets);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      vets = vets.where((v) {
        return v.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               v.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               v.phone.contains(_searchQuery) ||
               v.district.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               v.specialization.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Apply status filter
    if (_selectedStatus != 'all') {
      if (_selectedStatus == 'approved') {
        vets = vets.where((v) => v.isApproved).toList();
      } else if (_selectedStatus == 'pending') {
        vets = vets.where((v) => !v.isApproved).toList();
      } else if (_selectedStatus == 'rejected') {
        // Would need a rejected status field
      }
    }
    
    // Apply specialty filter
    if (_selectedSpecialty != 'all') {
      vets = vets.where((v) => v.specialization == _selectedSpecialty).toList();
    }
    
    // Apply sorting
    switch (_selectedSort) {
      case 'newest':
        vets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        vets.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'name_asc':
        vets.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
      case 'name_desc':
        vets.sort((a, b) => b.fullName.compareTo(a.fullName));
        break;
      case 'experience':
        vets.sort((a, b) => b.yearsExperience.compareTo(a.yearsExperience));
        break;
    }
    
    setState(() {
      _filteredVets = vets;
    });
  }

  void _toggleSelection(Veterinarian vet) {
    setState(() {
      if (_selectedVets.contains(vet)) {
        _selectedVets.remove(vet);
      } else {
        _selectedVets.add(vet);
      }
      _isSelectionMode = _selectedVets.isNotEmpty;
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedVets.length == _filteredVets.length) {
        _selectedVets.clear();
        _isSelectionMode = false;
      } else {
        _selectedVets = List.from(_filteredVets);
        _isSelectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedVets.clear();
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
              'Bulk Actions (${_selectedVets.length} selected)',
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
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, color: Colors.green),
              ),
              title: const Text('Approve Selected'),
              subtitle: Text('Approve ${_selectedVets.length} veterinarians'),
              onTap: () {
                Navigator.pop(context);
                _showBulkApproveDialog();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_outlined, color: Colors.red),
              ),
              title: const Text('Reject Selected'),
              subtitle: Text('Reject ${_selectedVets.length} veterinarians'),
              onTap: () {
                Navigator.pop(context);
                _showBulkRejectDialog();
              },
            ),
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
              subtitle: Text('Send email to ${_selectedVets.length} veterinarians'),
              onTap: () {
                Navigator.pop(context);
                _showBulkEmailDialog();
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
              subtitle: const Text('Permanently delete selected veterinarians'),
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

  void _showBulkApproveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Veterinarians'),
        content: Text('Are you sure you want to approve ${_selectedVets.length} veterinarians?'),
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
                'Veterinarians approved successfully',
                type: SnackBarType.success,
              );
              _clearSelection();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showBulkRejectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Veterinarians'),
        content: Text('Are you sure you want to reject ${_selectedVets.length} veterinarians?'),
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
                'Veterinarians rejected',
                type: SnackBarType.error,
              );
              _clearSelection();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
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
            const Text('This will send an email to all selected veterinarians.'),
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
              backgroundColor: AppColors.vet,
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
        title: const Text('Delete Veterinarians'),
        content: Text(
          'Are you sure you want to delete ${_selectedVets.length} veterinarians? This action cannot be undone.',
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
                'Veterinarians deleted successfully',
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

  void _showVetDetails(Veterinarian vet) {
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
          return _buildVetDetailsSheet(vet, scrollController);
        },
      ),
    );
  }

  Widget _buildVetDetailsSheet(Veterinarian vet, ScrollController controller) {
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
                backgroundColor: AppColors.vet.withOpacity(0.1),
                child: Text(
                  Helpers.getInitials('Dr. ${vet.fullName}'),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.vet,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${vet.fullName}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: vet.isApproved 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        vet.isApproved ? 'Approved' : 'Pending Approval',
                        style: TextStyle(
                          color: vet.isApproved ? Colors.green : Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                // Professional Information
                _buildInfoSection(
                  'Professional Information',
                  Icons.medical_services_outlined,
                  [
                    _buildInfoRow('License Number', vet.licenseNumber),
                    _buildInfoRow('Specialization', vet.specializationDisplay),
                    _buildInfoRow('Experience', '${vet.yearsExperience} years'),
                    _buildInfoRow('Clinic', vet.clinicName),
                    _buildInfoRow('Clinic Address', vet.clinicAddress),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Personal Information
                _buildInfoSection(
                  'Personal Information',
                  Icons.person_outline,
                  [
                    _buildInfoRow('Full Name', vet.fullName),
                    _buildInfoRow('Email', vet.email),
                    _buildInfoRow('Phone', vet.phone),
                    _buildInfoRow('District', vet.district),
                    _buildInfoRow('Sector', vet.sector),
                    _buildInfoRow('Member Since', DateFormat('MMM dd, yyyy').format(vet.createdAt)),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Statistics
                _buildStatisticsSection(vet),
                const SizedBox(height: 16),
                
                // Documents
                _buildDocumentsSection(vet),
                const SizedBox(height: 16),
                
                // Approval Actions (if pending)
                if (!vet.isApproved) _buildApprovalActions(vet),
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
                    _showEditVetDialog(vet);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vet,
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
              Icon(icon, color: AppColors.vet, size: 18),
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
              value.isEmpty ? 'Not provided' : value,
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

  Widget _buildStatisticsSection(Veterinarian vet) {
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
                'Performance Statistics',
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
              _buildStatItem('Consultations', '45', Icons.chat, Colors.blue),
              _buildStatItem('Replies', '38', Icons.reply, Colors.green),
              _buildStatItem('Response Time', '2.4h', Icons.timer, Colors.orange),
              _buildStatItem('Rating', '4.8', Icons.star, Colors.amber),
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

  Widget _buildDocumentsSection(Veterinarian vet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.folder_outlined, color: Colors.purple, size: 18),
              SizedBox(width: 8),
              Text(
                'Documents',
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
                color: Colors.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.badge_outlined, color: Colors.purple, size: 20),
            ),
            title: const Text('License Certificate'),
            subtitle: Text(vet.licenseNumber),
            trailing: IconButton(
              icon: const Icon(Icons.visibility_outlined),
              onPressed: () {
                // View document
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalActions(Veterinarian vet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.hourglass_empty, color: Colors.orange, size: 18),
              SizedBox(width: 8),
              Text(
                'Pending Approval',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'This veterinarian is waiting for approval to access the platform.',
            style: TextStyle(color: Colors.orange),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _rejectVet(vet);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _approveVet(vet);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _approveVet(Veterinarian vet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Veterinarian'),
        content: Text('Are you sure you want to approve Dr. ${vet.fullName}?'),
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
                'Veterinarian approved successfully',
                type: SnackBarType.success,
              );
              // Update local state
              setState(() {
                // Create a new list with updated vet
                int index = _filteredVets.indexWhere((v) => v.vetId == vet.vetId);
                if (index != -1) {
                  // This is a workaround since we can't modify the object directly
                  // In a real app, you'd refresh from the provider
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectVet(Veterinarian vet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Veterinarian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject Dr. ${vet.fullName}?'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Rejection Reason (Optional)',
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
                'Veterinarian rejected',
                type: SnackBarType.error,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showEditVetDialog(Veterinarian vet) {
    final nameController = TextEditingController(text: vet.fullName);
    final emailController = TextEditingController(text: vet.email);
    final phoneController = TextEditingController(text: vet.phone);
    final districtController = TextEditingController(text: vet.district);
    final sectorController = TextEditingController(text: vet.sector);
    final clinicController = TextEditingController(text: vet.clinicName);
    final addressController = TextEditingController(text: vet.clinicAddress);
    final experienceController = TextEditingController(text: vet.yearsExperience.toString());
    String? specialization = vet.specialization;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Veterinarian'),
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
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: specialization,
                decoration: const InputDecoration(
                  labelText: 'Specialization',
                  prefixIcon: Icon(Icons.medical_services),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('General Veterinary')),
                  DropdownMenuItem(value: 'surgery', child: Text('Surgery')),
                  DropdownMenuItem(value: 'reproduction', child: Text('Reproduction')),
                  DropdownMenuItem(value: 'nutrition', child: Text('Nutrition')),
                  DropdownMenuItem(value: 'preventive', child: Text('Preventive Care')),
                ],
                onChanged: (value) {
                  specialization = value;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: experienceController,
                decoration: const InputDecoration(
                  labelText: 'Years Experience',
                  prefixIcon: Icon(Icons.timeline),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: clinicController,
                decoration: const InputDecoration(
                  labelText: 'Clinic Name',
                  prefixIcon: Icon(Icons.local_hospital),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Clinic Address',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
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
                'Veterinarian updated successfully',
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
    );
  }

  void _showDeleteConfirmation(Veterinarian vet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Veterinarian'),
        content: Text('Are you sure you want to delete Dr. ${vet.fullName}? This action cannot be undone.'),
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
                'Veterinarian deleted successfully',
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
              'Export Veterinarians',
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
              subtitle: const Text('Download all veterinarians as CSV file'),
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
              subtitle: const Text('Print veterinarians list'),
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
      body: Consumer<VetProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.vets.isEmpty) {
            return const LoadingWidget(message: 'Loading veterinarians...');
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
                        ? Text('${_selectedVets.length} selected')
                        : const Text('Veterinarians Management'),
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
                                      hintText: 'Search veterinarians...',
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
                          // Status Filter
                          const Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _statusOptions.map((option) {
                                final isSelected = _selectedStatus == option['value'];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    selected: isSelected,
                                    label: Text(option['label']),
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedStatus = option['value'];
                                        _applyFilters();
                                      });
                                    },
                                    selectedColor: option['color'],
                                    checkmarkColor: Colors.white,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Specialty Filter
                          FilterChips(
                            label: 'Specialty',
                            options: ['all', ..._specialties],
                            selectedOption: _selectedSpecialty,
                            onSelected: (value) {
                              setState(() {
                                _selectedSpecialty = value;
                                _applyFilters();
                              });
                            },
                            optionLabel: (value) => value == 'all' ? 'All Specialties' : value,
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
              child: _filteredVets.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.medical_services_outlined,
                      title: 'No Veterinarians Found',
                      message: 'No veterinarians match your search criteria',
                      buttonText: 'Clear Filters',
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _selectedStatus = 'all';
                          _selectedSpecialty = 'all';
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
          // Navigate to add vet - you'll need to create this screen
          // context.go('/admin-add-vet');
          Helpers.showSnackBar(
            context,
            'Add vet feature coming soon',
            type: SnackBarType.info,
          );
        },
        backgroundColor: AppColors.admin,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Veterinarian'),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredVets.length,
      itemBuilder: (context, index) {
        final vet = _filteredVets[index];
        final isSelected = _selectedVets.contains(vet);
        
        return _buildVetGridCard(vet, isSelected);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredVets.length,
      itemBuilder: (context, index) {
        final vet = _filteredVets[index];
        final isSelected = _selectedVets.contains(vet);
        
        return _buildVetListCard(vet, isSelected);
      },
    );
  }

  Widget _buildVetGridCard(Veterinarian vet, bool isSelected) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: AppColors.admin, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showVetDetails(vet),
        onLongPress: () => _toggleSelection(vet),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Status Indicator
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: vet.isApproved 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        vet.isApproved ? 'Approved' : 'Pending',
                        style: TextStyle(
                          color: vet.isApproved ? Colors.green : Colors.orange,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Avatar
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: AppColors.vet.withOpacity(0.1),
                    child: Text(
                      Helpers.getInitials('Dr. ${vet.fullName}'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.vet,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Name
                  Text(
                    'Dr. ${vet.fullName}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Specialty
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.vet.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      vet.specializationDisplay,
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.vet,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildGridStat('${vet.yearsExperience}y', 'Exp'),
                      _buildGridStat('45', 'Consults'),
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

  Widget _buildVetListCard(Veterinarian vet, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: AppColors.admin, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showVetDetails(vet),
        onLongPress: () => _toggleSelection(vet),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox for selection mode
              if (_isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(vet),
                  activeColor: AppColors.admin,
                ),
              
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.vet.withOpacity(0.1),
                child: Text(
                  Helpers.getInitials('Dr. ${vet.fullName}'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.vet,
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
                            'Dr. ${vet.fullName}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: vet.isApproved 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            vet.isApproved ? 'Approved' : 'Pending',
                            style: TextStyle(
                              color: vet.isApproved ? Colors.green : Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vet.specializationDisplay,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.email, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            vet.email,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          vet.phone,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.timeline, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${vet.yearsExperience} years',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
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
                  if (!vet.isApproved)
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => _approveVet(vet),
                      tooltip: 'Approve',
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.vet),
                    onPressed: () => _showEditVetDialog(vet),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(vet),
                    tooltip: 'Delete',
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