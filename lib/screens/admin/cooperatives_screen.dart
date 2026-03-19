import '../../models/cooperative.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/cooperative_provider.dart';
import '../../core/constants/colors.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/filter_chips.dart';

class CooperativesScreen extends StatefulWidget {
  const CooperativesScreen({super.key});

  @override
  State<CooperativesScreen> createState() => _CooperativesScreenState();
}

class _CooperativesScreenState extends State<CooperativesScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  String _selectedDistrict = 'all';
  String _selectedStatus = 'all';
  String _selectedSize = 'all';
  String _selectedSort = 'newest';
  String _selectedView = 'grid'; // 'grid' or 'list'
  bool _showFilters = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _pageSize = 20;
  
  List<String> _districts = [];
  List<Cooperative> _filteredCooperatives = [];
  List<Cooperative> _selectedCooperatives = [];
  bool _isSelectionMode = false;

  final List<Map<String, dynamic>> _statusOptions = [
    {'value': 'all', 'label': 'All', 'color': Colors.grey},
    {'value': 'active', 'label': 'Active', 'color': Colors.green},
    {'value': 'inactive', 'label': 'Inactive', 'color': Colors.red},
    {'value': 'verified', 'label': 'Verified', 'color': Colors.blue},
  ];

  final List<Map<String, dynamic>> _sizeOptions = [
    {'value': 'all', 'label': 'All Sizes'},
    {'value': 'small', 'label': 'Small (1-10)'},
    {'value': 'medium', 'label': 'Medium (11-30)'},
    {'value': 'large', 'label': 'Large (30+)'},
  ];

  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'newest', 'label': 'Newest First', 'icon': Icons.access_time},
    {'value': 'oldest', 'label': 'Oldest First', 'icon': Icons.history},
    {'value': 'name_asc', 'label': 'Name A-Z', 'icon': Icons.sort_by_alpha},
    {'value': 'name_desc', 'label': 'Name Z-A', 'icon': Icons.sort_by_alpha},
    {'value': 'members', 'label': 'Most Members', 'icon': Icons.people},
    {'value': 'goats', 'label': 'Most Goats', 'icon': Icons.pets},
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
    final cooperativeProvider = context.read<CooperativeProvider>();
    await cooperativeProvider.loadCooperatives();
    
    if (mounted) {
      setState(() {
        _districts = cooperativeProvider.cooperatives
            .map((c) => c.district)
            .where((d) => d.isNotEmpty)
            .toSet()
            .toList();
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
    final cooperativeProvider = context.read<CooperativeProvider>();
    var cooperatives = List<Cooperative>.from(cooperativeProvider.cooperatives);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      cooperatives = cooperatives.where((c) {
        return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               c.leaderName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               c.district.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (c.registrationNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }
    
    // Apply district filter
    if (_selectedDistrict != 'all') {
      cooperatives = cooperatives.where((c) => c.district == _selectedDistrict).toList();
    }
    
    // Apply status filter
    if (_selectedStatus != 'all') {
      if (_selectedStatus == 'active') {
        cooperatives = cooperatives.where((c) => c.isActive).toList();
      } else if (_selectedStatus == 'inactive') {
        cooperatives = cooperatives.where((c) => !c.isActive).toList();
      } else if (_selectedStatus == 'verified') {
        cooperatives = cooperatives.where((c) => c.isVerified).toList();
      }
    }
    
    // Apply size filter
    if (_selectedSize != 'all') {
      if (_selectedSize == 'small') {
        cooperatives = cooperatives.where((c) => c.totalMembers <= 10).toList();
      } else if (_selectedSize == 'medium') {
        cooperatives = cooperatives.where((c) => c.totalMembers > 10 && c.totalMembers <= 30).toList();
      } else if (_selectedSize == 'large') {
        cooperatives = cooperatives.where((c) => c.totalMembers > 30).toList();
      }
    }
    
    // Apply sorting
    switch (_selectedSort) {
      case 'newest':
        cooperatives.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        cooperatives.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'name_asc':
        cooperatives.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_desc':
        cooperatives.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'members':
        cooperatives.sort((a, b) => b.totalMembers.compareTo(a.totalMembers));
        break;
      case 'goats':
        cooperatives.sort((a, b) => b.totalGoats.compareTo(a.totalGoats));
        break;
    }
    
    setState(() {
      _filteredCooperatives = cooperatives;
    });
  }

  void _toggleSelection(Cooperative cooperative) {
    setState(() {
      if (_selectedCooperatives.contains(cooperative)) {
        _selectedCooperatives.remove(cooperative);
      } else {
        _selectedCooperatives.add(cooperative);
      }
      _isSelectionMode = _selectedCooperatives.isNotEmpty;
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedCooperatives.length == _filteredCooperatives.length) {
        _selectedCooperatives.clear();
        _isSelectionMode = false;
      } else {
        _selectedCooperatives = List.from(_filteredCooperatives);
        _isSelectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedCooperatives.clear();
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
              'Bulk Actions (${_selectedCooperatives.length} selected)',
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
              title: const Text('Activate Selected'),
              subtitle: Text('Activate ${_selectedCooperatives.length} cooperatives'),
              onTap: () {
                Navigator.pop(context);
                _showBulkActivateDialog();
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
              title: const Text('Deactivate Selected'),
              subtitle: Text('Deactivate ${_selectedCooperatives.length} cooperatives'),
              onTap: () {
                Navigator.pop(context);
                _showBulkDeactivateDialog();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_outlined, color: Colors.blue),
              ),
              title: const Text('Verify Selected'),
              subtitle: Text('Verify ${_selectedCooperatives.length} cooperatives'),
              onTap: () {
                Navigator.pop(context);
                _showBulkVerifyDialog();
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
              subtitle: const Text('Permanently delete selected cooperatives'),
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

  void _showBulkActivateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activate Cooperatives'),
        content: Text('Are you sure you want to activate ${_selectedCooperatives.length} cooperatives?'),
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
                'Cooperatives activated successfully',
                type: SnackBarType.success,
              );
              _clearSelection();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }

  void _showBulkDeactivateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Cooperatives'),
        content: Text('Are you sure you want to deactivate ${_selectedCooperatives.length} cooperatives?'),
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
                'Cooperatives deactivated',
                type: SnackBarType.error,
              );
              _clearSelection();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _showBulkVerifyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Cooperatives'),
        content: Text('Are you sure you want to verify ${_selectedCooperatives.length} cooperatives?'),
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
                'Cooperatives verified successfully',
                type: SnackBarType.success,
              );
              _clearSelection();
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

  void _showBulkDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cooperatives'),
        content: Text(
          'Are you sure you want to delete ${_selectedCooperatives.length} cooperatives? This action cannot be undone.',
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
                'Cooperatives deleted successfully',
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

  void _showAddCooperativeDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final regNumberController = TextEditingController();
    final districtController = TextEditingController();
    final sectorController = TextEditingController();
    final cellController = TextEditingController();
    final villageController = TextEditingController();
    final leaderNameController = TextEditingController();
    final leaderPhoneController = TextEditingController();
    final leaderEmailController = TextEditingController();
    final leaderIdController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? registrationDate = DateTime.now();
    bool isActive = true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Cooperative'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Basic Information
                const Text(
                  'Basic Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Cooperative Name *',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: regNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Registration Number',
                    prefixIcon: Icon(Icons.numbers),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Location
                const Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: districtController,
                        decoration: const InputDecoration(
                          labelText: 'District *',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: sectorController,
                        decoration: const InputDecoration(
                          labelText: 'Sector *',
                          prefixIcon: Icon(Icons.map),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: cellController,
                        decoration: const InputDecoration(
                          labelText: 'Cell',
                          prefixIcon: Icon(Icons.location_city),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: villageController,
                        decoration: const InputDecoration(
                          labelText: 'Village',
                          prefixIcon: Icon(Icons.home),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Leadership
                const Text(
                  'Leadership',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: leaderNameController,
                  decoration: const InputDecoration(
                    labelText: 'Leader Name *',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: leaderPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Leader Phone *',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        validator: Validators.phone,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: leaderEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Leader Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: Validators.email,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: leaderIdController,
                  decoration: const InputDecoration(
                    labelText: 'Leader ID Number',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Details
                const Text(
                  'Additional Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: DateFormat('yyyy-MM-dd').format(registrationDate!),
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Registration Date',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: registrationDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            registrationDate = date;
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (value) {
                    isActive = value;
                  },
                  activeThumbColor: Colors.green,
                ),
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
                  'Cooperative added successfully',
                  type: SnackBarType.success,
                );
                // TODO: Implement API call
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Add Cooperative'),
          ),
        ],
      ),
    );
  }

  void _showCooperativeDetails(Cooperative cooperative) {
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
          return _buildCooperativeDetailsSheet(cooperative, scrollController);
        },
      ),
    );
  }

  Widget _buildCooperativeDetailsSheet(Cooperative cooperative, ScrollController controller) {
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
                backgroundColor: Colors.orange.withOpacity(0.1),
                child: Text(
                  Helpers.getInitials(cooperative.name),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cooperative.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: cooperative.isActive 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            cooperative.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: cooperative.isActive ? Colors.green : Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (cooperative.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Verified',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 11,
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
          const SizedBox(height: 24),
          
          // Content
          Expanded(
            child: ListView(
              controller: controller,
              children: [
                // Basic Information
                _buildInfoSection(
                  'Basic Information',
                  Icons.info_outline,
                  [
                    _buildInfoRow('Registration Number', cooperative.registrationNumber ?? 'Not provided'),
                    _buildInfoRow('Registration Date', DateFormat('MMM dd, yyyy').format(cooperative.registrationDate)),
                    _buildInfoRow('Total Members', cooperative.totalMembers.toString()),
                    _buildInfoRow('Total Goats', cooperative.totalGoats.toString()),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Location
                _buildInfoSection(
                  'Location',
                  Icons.location_on_outlined,
                  [
                    _buildInfoRow('District', cooperative.district),
                    _buildInfoRow('Sector', cooperative.sector),
                    _buildInfoRow('Cell', cooperative.cell ?? 'Not provided'),
                    _buildInfoRow('Village', cooperative.village ?? 'Not provided'),
                    _buildInfoRow('Full Address', cooperative.fullAddress),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Leadership
                _buildInfoSection(
                  'Leadership',
                  Icons.people_outline,
                  [
                    _buildInfoRow('Leader Name', cooperative.leaderName),
                    _buildInfoRow('Leader Phone', cooperative.leaderPhone),
                    _buildInfoRow('Leader Email', cooperative.leaderEmail ?? 'Not provided'),
                    _buildInfoRow('Leader ID', cooperative.leaderIdNumber ?? 'Not provided'),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Description
                if (cooperative.description != null)
                  _buildInfoSection(
                    'Description',
                    Icons.description_outlined,
                    [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(cooperative.description!),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                
                // Members Preview
                _buildMembersPreview(cooperative),
                const SizedBox(height: 16),
                
                // Statistics
                _buildStatisticsSection(cooperative),
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
                    _showEditCooperativeDialog(cooperative);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
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
              Icon(icon, color: Colors.orange, size: 18),
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
            width: 120,
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

  Widget _buildMembersPreview(Cooperative cooperative) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.people, color: Colors.purple, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Members',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showManageMembersDialog(cooperative);
                },
                child: const Text('Manage'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(5, (index) {
            if (index >= cooperative.totalMembers) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.purple.withOpacity(0.1),
                    child: Text(
                      'M${index + 1}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Member ${index + 1}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Role: Member',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (cooperative.totalMembers > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  'And ${cooperative.totalMembers - 5} more members',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(Cooperative cooperative) {
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
              Icon(Icons.bar_chart, color: Colors.green, size: 18),
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
              _buildStatItem('Members', cooperative.totalMembers.toString(), Icons.people, Colors.green),
              _buildStatItem('Goats', cooperative.totalGoats.toString(), Icons.pets, Colors.orange),
              _buildStatItem('Consultations', '23', Icons.chat, Colors.blue),
              _buildStatItem('Replies', '18', Icons.reply, Colors.purple),
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

  void _showManageMembersDialog(Cooperative cooperative) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manage Members - ${cooperative.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Add Member Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showAddMemberDialog(cooperative);
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Add Member'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
              const SizedBox(height: 16),
              
              // Members List
              Expanded(
                child: ListView.builder(
                  itemCount: cooperative.totalMembers,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        child: Text(
                          'M${index + 1}',
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                      title: Text('Member ${index + 1}'),
                      subtitle: const Text('Joined: Jan 2024'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMemberDialog(Cooperative cooperative) {
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final idNumberController = TextEditingController();
    final farmSizeController = TextEditingController();
    String selectedRole = 'member';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Member to ${cooperative.name}'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: Validators.required,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: Validators.required,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: Validators.email,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: idNumberController,
                  decoration: const InputDecoration(
                    labelText: 'ID Number',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: farmSizeController,
                        decoration: const InputDecoration(
                          labelText: 'Farm Size (goats)',
                          prefixIcon: Icon(Icons.pets),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role *',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'member', child: Text('Member')),
                          DropdownMenuItem(value: 'secretary', child: Text('Secretary')),
                          DropdownMenuItem(value: 'treasurer', child: Text('Treasurer')),
                          DropdownMenuItem(value: 'vice_leader', child: Text('Vice Leader')),
                          DropdownMenuItem(value: 'leader', child: Text('Leader')),
                        ],
                        onChanged: (value) {
                          selectedRole = value!;
                        },
                      ),
                    ),
                  ],
                ),
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
                  'Member added successfully',
                  type: SnackBarType.success,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Add Member'),
          ),
        ],
      ),
    );
  }

  void _showEditCooperativeDialog(Cooperative cooperative) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: cooperative.name);
    final regNumberController = TextEditingController(text: cooperative.registrationNumber);
    final districtController = TextEditingController(text: cooperative.district);
    final sectorController = TextEditingController(text: cooperative.sector);
    final cellController = TextEditingController(text: cooperative.cell);
    final villageController = TextEditingController(text: cooperative.village);
    final leaderNameController = TextEditingController(text: cooperative.leaderName);
    final leaderPhoneController = TextEditingController(text: cooperative.leaderPhone);
    final leaderEmailController = TextEditingController(text: cooperative.leaderEmail);
    final leaderIdController = TextEditingController(text: cooperative.leaderIdNumber);
    final descriptionController = TextEditingController(text: cooperative.description);
    DateTime registrationDate = cooperative.registrationDate;
    bool isActive = cooperative.isActive;
    bool isVerified = cooperative.isVerified;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Cooperative'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Basic Information
                const Text(
                  'Basic Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Cooperative Name *',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: regNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Registration Number',
                    prefixIcon: Icon(Icons.numbers),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Location
                const Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: districtController,
                        decoration: const InputDecoration(
                          labelText: 'District *',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: sectorController,
                        decoration: const InputDecoration(
                          labelText: 'Sector *',
                          prefixIcon: Icon(Icons.map),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: cellController,
                        decoration: const InputDecoration(
                          labelText: 'Cell',
                          prefixIcon: Icon(Icons.location_city),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: villageController,
                        decoration: const InputDecoration(
                          labelText: 'Village',
                          prefixIcon: Icon(Icons.home),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Leadership
                const Text(
                  'Leadership',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: leaderNameController,
                  decoration: const InputDecoration(
                    labelText: 'Leader Name *',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: leaderPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Leader Phone *',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        validator: Validators.phone,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: leaderEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Leader Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: Validators.email,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: leaderIdController,
                  decoration: const InputDecoration(
                    labelText: 'Leader ID Number',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Details
                const Text(
                  'Additional Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: DateFormat('yyyy-MM-dd').format(registrationDate),
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Registration Date',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: registrationDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            registrationDate = date;
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (value) {
                    isActive = value;
                  },
                  activeThumbColor: Colors.green,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Verified'),
                  value: isVerified,
                  onChanged: (value) {
                    isVerified = value;
                  },
                  activeThumbColor: Colors.blue,
                ),
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
                  'Cooperative updated successfully',
                  type: SnackBarType.success,
                );
                // TODO: Implement API call
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Cooperative cooperative) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cooperative'),
        content: Text('Are you sure you want to delete ${cooperative.name}? This action cannot be undone.'),
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
                'Cooperative deleted successfully',
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
              'Export Cooperatives',
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
              subtitle: const Text('Download all cooperatives as CSV file'),
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
              subtitle: const Text('Print cooperatives list'),
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
      body: Consumer<CooperativeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.cooperatives.isEmpty) {
            return const LoadingWidget(message: 'Loading cooperatives...');
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
                        ? Text('${_selectedCooperatives.length} selected')
                        : const Text('Cooperatives Management'),
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
                                      hintText: 'Search cooperatives...',
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
                          // Size Filter
                          FilterChips(
                            label: 'Size',
                            options: _sizeOptions.map((e) => e['value'] as String).toList(),
                            selectedOption: _selectedSize,
                            onSelected: (value) {
                              setState(() {
                                _selectedSize = value;
                                _applyFilters();
                              });
                            },
                            optionLabel: (value) {
                              final option = _sizeOptions.firstWhere((e) => e['value'] == value);
                              return option['label'];
                            },
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
              child: _filteredCooperatives.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.handshake_outlined,
                      title: 'No Cooperatives Found',
                      message: 'No cooperatives match your search criteria',
                      buttonText: 'Clear Filters',
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _selectedDistrict = 'all';
                          _selectedStatus = 'all';
                          _selectedSize = 'all';
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
        onPressed: _showAddCooperativeDialog,
        backgroundColor: AppColors.admin,
        icon: const Icon(Icons.add_business),
        label: const Text('Add Cooperative'),
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
      itemCount: _filteredCooperatives.length,
      itemBuilder: (context, index) {
        final cooperative = _filteredCooperatives[index];
        final isSelected = _selectedCooperatives.contains(cooperative);
        
        return _buildCooperativeGridCard(cooperative, isSelected);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredCooperatives.length,
      itemBuilder: (context, index) {
        final cooperative = _filteredCooperatives[index];
        final isSelected = _selectedCooperatives.contains(cooperative);
        
        return _buildCooperativeListCard(cooperative, isSelected);
      },
    );
  }

  Widget _buildCooperativeGridCard(Cooperative cooperative, bool isSelected) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: AppColors.admin, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showCooperativeDetails(cooperative),
        onLongPress: () => _toggleSelection(cooperative),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Status Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (cooperative.isVerified)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 12,
                          ),
                        ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cooperative.isActive 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          cooperative.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: cooperative.isActive ? Colors.green : Colors.red,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.handshake,
                      color: Colors.orange,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Name
                  Text(
                    cooperative.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Location
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, size: 10, color: Colors.orange),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          cooperative.district,
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
                      _buildGridStat(cooperative.totalMembers.toString(), 'Members'),
                      _buildGridStat(cooperative.totalGoats.toString(), 'Goats'),
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

  Widget _buildCooperativeListCard(Cooperative cooperative, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: AppColors.admin, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showCooperativeDetails(cooperative),
        onLongPress: () => _toggleSelection(cooperative),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox for selection mode
              if (_isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(cooperative),
                  activeColor: AppColors.admin,
                ),
              
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.handshake,
                  color: Colors.orange,
                  size: 30,
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
                            cooperative.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cooperative.isActive 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            cooperative.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: cooperative.isActive ? Colors.green : Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (cooperative.isVerified) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Verified',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reg: ${cooperative.registrationNumber ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.orange),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${cooperative.district}, ${cooperative.sector}',
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
                        Icon(Icons.person, size: 12, color: Colors.orange),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            cooperative.leaderName,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.people, size: 12, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          '${cooperative.totalMembers} members',
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
                  IconButton(
                    icon: const Icon(Icons.people, color: Colors.orange),
                    onPressed: () => _showManageMembersDialog(cooperative),
                    tooltip: 'Manage Members',
                    iconSize: 20,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () => _showEditCooperativeDialog(cooperative),
                    tooltip: 'Edit',
                    iconSize: 20,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(cooperative),
                    tooltip: 'Delete',
                    iconSize: 20,
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