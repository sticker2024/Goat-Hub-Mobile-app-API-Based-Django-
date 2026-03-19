import '../../models/special_case.dart';
import '../../utils/helpers.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/special_case_provider.dart';
import '../../core/constants/colors.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/filter_chips.dart';

class SpecialCasesScreen extends StatefulWidget {
  const SpecialCasesScreen({super.key});

  @override
  State<SpecialCasesScreen> createState() => _SpecialCasesScreenState();
}

class _SpecialCasesScreenState extends State<SpecialCasesScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedDistrict = 'all';
  String _selectedRabStatus = 'all';
  String _selectedSort = 'newest';
  String _selectedView = 'grid'; // 'grid' or 'list'
  bool _showFilters = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _pageSize = 20;
  
  List<String> _districts = [];
  List<SpecialCase> _filteredCases = [];
  List<SpecialCase> _selectedCases = [];
  bool _isSelectionMode = false;

  final List<Map<String, dynamic>> _statusOptions = [
    {'value': 'all', 'label': 'All', 'color': Colors.grey},
    {'value': 'reported', 'label': 'Reported', 'color': Colors.red},
    {'value': 'in_review', 'label': 'In Review', 'color': Colors.orange},
    {'value': 'resolved', 'label': 'Resolved', 'color': Colors.green},
  ];

  final List<Map<String, dynamic>> _rabStatusOptions = [
    {'value': 'all', 'label': 'All'},
    {'value': 'reported', 'label': 'Reported to RAB'},
    {'value': 'pending', 'label': 'Pending RAB'},
  ];

  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'newest', 'label': 'Newest First', 'icon': Icons.access_time},
    {'value': 'oldest', 'label': 'Oldest First', 'icon': Icons.history},
    {'value': 'urgent', 'label': 'Most Urgent', 'icon': Icons.warning},
    {'value': 'district', 'label': 'District', 'icon': Icons.location_on},
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
    final specialCaseProvider = context.read<SpecialCaseProvider>();
    await specialCaseProvider.loadSpecialCases();
    
    if (mounted) {
      setState(() {
        _districts = specialCaseProvider.specialCases
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
    final specialCaseProvider = context.read<SpecialCaseProvider>();
    var cases = List<SpecialCase>.from(specialCaseProvider.specialCases);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      cases = cases.where((c) {
        return c.district.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               c.sector.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               c.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Apply status filter
    if (_selectedStatus != 'all') {
      cases = cases.where((c) => c.status == _selectedStatus).toList();
    }
    
    // Apply district filter
    if (_selectedDistrict != 'all') {
      cases = cases.where((c) => c.district == _selectedDistrict).toList();
    }
    
    // Apply RAB status filter
    if (_selectedRabStatus != 'all') {
      if (_selectedRabStatus == 'reported') {
        cases = cases.where((c) => c.reportedToRab).toList();
      } else if (_selectedRabStatus == 'pending') {
        cases = cases.where((c) => !c.reportedToRab).toList();
      }
    }
    
    // Apply sorting
    switch (_selectedSort) {
      case 'newest':
        cases.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
        break;
      case 'oldest':
        cases.sort((a, b) => a.reportedAt.compareTo(b.reportedAt));
        break;
      case 'urgent':
        cases.sort((a, b) {
          // Prioritize unreported cases first, then by date
          if (a.reportedToRab != b.reportedToRab) {
            return a.reportedToRab ? 1 : -1;
          }
          return b.reportedAt.compareTo(a.reportedAt);
        });
        break;
      case 'district':
        cases.sort((a, b) => a.district.compareTo(b.district));
        break;
    }
    
    setState(() {
      _filteredCases = cases;
    });
  }

  void _toggleSelection(SpecialCase specialCase) {
    setState(() {
      if (_selectedCases.contains(specialCase)) {
        _selectedCases.remove(specialCase);
      } else {
        _selectedCases.add(specialCase);
      }
      _isSelectionMode = _selectedCases.isNotEmpty;
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedCases.length == _filteredCases.length) {
        _selectedCases.clear();
        _isSelectionMode = false;
      } else {
        _selectedCases = List.from(_filteredCases);
        _isSelectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedCases.clear();
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
              'Bulk Actions (${_selectedCases.length} selected)',
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
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.red),
              ),
              title: const Text('Report to RAB'),
              subtitle: Text('Report ${_selectedCases.length} cases to RAB'),
              onTap: () {
                Navigator.pop(context);
                _showBulkReportDialog();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.visibility, color: Colors.blue),
              ),
              title: const Text('Mark as In Review'),
              subtitle: Text('Mark ${_selectedCases.length} cases as in review'),
              onTap: () {
                Navigator.pop(context);
                _showBulkStatusDialog('in_review');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.green),
              ),
              title: const Text('Mark as Resolved'),
              subtitle: Text('Mark ${_selectedCases.length} cases as resolved'),
              onTap: () {
                Navigator.pop(context);
                _showBulkStatusDialog('resolved');
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
              subtitle: const Text('Permanently delete selected cases'),
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

  void _showBulkReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report to RAB'),
        content: Text('Are you sure you want to report ${_selectedCases.length} cases to Rwanda Agriculture Board?'),
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
                'Cases reported to RAB successfully',
                type: SnackBarType.success,
              );
              _clearSelection();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showBulkStatusDialog(String status) {
    String statusText = status == 'in_review' ? 'In Review' : 'Resolved';
    Color statusColor = status == 'in_review' ? Colors.blue : Colors.green;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark as $statusText'),
        content: Text('Are you sure you want to mark ${_selectedCases.length} cases as $statusText?'),
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
                'Cases updated successfully',
                type: SnackBarType.success,
              );
              _clearSelection();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: statusColor,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showBulkDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cases'),
        content: Text(
          'Are you sure you want to delete ${_selectedCases.length} cases? This action cannot be undone.',
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
                'Cases deleted successfully',
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

  void _showReportCaseDialog() {
    final formKey = GlobalKey<FormState>();
    final districtController = TextEditingController();
    final sectorController = TextEditingController();
    final descriptionController = TextEditingController();
    File? selectedImage;
    String selectedStatus = 'reported';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Special Case'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                const SizedBox(height: 16),
                
                // Description
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Case Description *',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                // Image Upload
                const Text(
                  'Attach Image',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1024,
                      maxHeight: 1024,
                      imageQuality: 80,
                    );
                    if (pickedFile != null) {
                      selectedImage = File(pickedFile.path);
                    }
                  },
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 40,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to add image',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Status
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Initial Status',
                    prefixIcon: Icon(Icons.flag),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'reported', child: Text('Reported')),
                    DropdownMenuItem(value: 'in_review', child: Text('In Review')),
                  ],
                  onChanged: (value) {
                    selectedStatus = value!;
                  },
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
                  'Special case reported successfully',
                  type: SnackBarType.success,
                );
                // TODO: Implement API call
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Report Case'),
          ),
        ],
      ),
    );
  }

  void _showCaseDetails(SpecialCase specialCase) {
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
          return _buildCaseDetailsSheet(specialCase, scrollController);
        },
      ),
    );
  }

  Widget _buildCaseDetailsSheet(SpecialCase specialCase, ScrollController controller) {
    final isUrgent = specialCase.status == 'reported' && !specialCase.reportedToRab;
    
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
                backgroundColor: (isUrgent ? Colors.red : specialCase.statusColor).withOpacity(0.1),
                child: Icon(
                  isUrgent ? Icons.warning : specialCase.statusIcon,
                  size: 40,
                  color: isUrgent ? Colors.red : specialCase.statusColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Case #${specialCase.caseId}',
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
                            color: specialCase.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            specialCase.statusDisplay,
                            style: TextStyle(
                              color: specialCase.statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (specialCase.reportedToRab)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'RAB Reported',
                              style: TextStyle(
                                color: Colors.green,
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
                // Location Information
                _buildInfoSection(
                  'Location',
                  Icons.location_on_outlined,
                  [
                    _buildInfoRow('District', specialCase.district),
                    _buildInfoRow('Sector', specialCase.sector),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Description
                _buildInfoSection(
                  'Description',
                  Icons.description_outlined,
                  [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        specialCase.description,
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Timeline
                _buildTimelineSection(specialCase),
                const SizedBox(height: 16),
                
                // Image if available
                if (specialCase.imageUrl != null)
                  _buildImageSection(specialCase.imageUrl!),
                const SizedBox(height: 16),
                
                // Actions (if urgent and not reported)
                if (isUrgent)
                  _buildUrgentActions(specialCase),
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
              if (!specialCase.reportedToRab && specialCase.status != 'resolved') ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showReportToRabDialog(specialCase);
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Report to RAB'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
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
              Icon(icon, color: Colors.red, size: 18),
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
            width: 80,
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

  Widget _buildTimelineSection(SpecialCase specialCase) {
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
              Icon(Icons.timeline, color: Colors.blue, size: 18),
              SizedBox(width: 8),
              Text(
                'Timeline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTimelineItem(
            'Reported',
            DateFormat('MMM dd, yyyy HH:mm').format(specialCase.reportedAt),
            Icons.report,
            Colors.red,
            true,
          ),
          if (specialCase.status == 'in_review')
            _buildTimelineItem(
              'In Review',
              'In progress',
              Icons.search,
              Colors.orange,
              true,
            ),
          if (specialCase.status == 'resolved')
            _buildTimelineItem(
              'Resolved',
              'Case closed',
              Icons.check_circle,
              Colors.green,
              true,
            ),
          if (specialCase.reportedToRab)
            _buildTimelineItem(
              'Reported to RAB',
              'Awaiting response',
              Icons.send,
              Colors.purple,
              true,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String subtitle, IconData icon, Color color, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(String imageUrl) {
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
              Icon(Icons.image, color: Colors.purple, size: 18),
              SizedBox(width: 8),
              Text(
                'Attached Image',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showFullScreenImage(imageUrl),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withOpacity(0.3),
                ),
                child: const Center(
                  child: Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentActions(SpecialCase specialCase) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text(
                'Urgent Action Required',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'This case needs to be reported to RAB immediately.',
            style: TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Dismiss'),
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
                    _showReportToRabDialog(specialCase);
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Report Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReportToRabDialog(SpecialCase specialCase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report to RAB'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to report this case to the Rwanda Agriculture Board?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Case #${specialCase.caseId} - ${specialCase.district}, ${specialCase.sector}',
              style: const TextStyle(fontWeight: FontWeight.bold),
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
                'Case reported to RAB successfully',
                type: SnackBarType.success,
              );
              // TODO: Implement API call
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showEditCaseDialog(SpecialCase specialCase) {
    final formKey = GlobalKey<FormState>();
    final districtController = TextEditingController(text: specialCase.district);
    final sectorController = TextEditingController(text: specialCase.sector);
    final descriptionController = TextEditingController(text: specialCase.description);
    String selectedStatus = specialCase.status;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Special Case'),
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
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.flag),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'reported', child: Text('Reported')),
                    DropdownMenuItem(value: 'in_review', child: Text('In Review')),
                    DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                  ],
                  onChanged: (value) {
                    selectedStatus = value!;
                  },
                ),
                if (specialCase.reportedToRab) ...[
                  const SizedBox(height: 12),
                  const ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text('Already Reported to RAB'),
                    subtitle: Text('This case has been reported to RAB'),
                  ),
                ],
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
                  'Case updated successfully',
                  type: SnackBarType.success,
                );
                // TODO: Implement API call
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(SpecialCase specialCase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Case'),
        content: Text('Are you sure you want to delete case #${specialCase.caseId}? This action cannot be undone.'),
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
                'Case deleted successfully',
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

  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(imageUrl),
            ),
          ),
        ),
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
              'Export Special Cases',
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
              subtitle: const Text('Download all cases as CSV file'),
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
              subtitle: const Text('Print cases list'),
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
      body: Consumer<SpecialCaseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.specialCases.isEmpty) {
            return const LoadingWidget(message: 'Loading special cases...');
          }

          if (provider.error != null) {
            return CustomErrorWidget(
              message: provider.error!,
              onRetry: _loadData,
            );
          }

          final urgentCount = provider.getUrgentCount();
          final reportedCount = provider.getReportedToRabCount();

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
                        ? Text('${_selectedCases.length} selected')
                        : const Text('Special Cases'),
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
                                      hintText: 'Search by location or description...',
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
                        // Quick Stats
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildQuickStat('Total', provider.specialCases.length.toString(), Colors.grey),
                              _buildQuickStat('Urgent', urgentCount.toString(), Colors.red),
                              _buildQuickStat('RAB Reported', reportedCount.toString(), Colors.green),
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
                          // RAB Status Filter
                          const Text(
                            'RAB Status',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _rabStatusOptions.map((option) {
                                final isSelected = _selectedRabStatus == option['value'];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    selected: isSelected,
                                    label: Text(option['label']),
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedRabStatus = option['value'];
                                        _applyFilters();
                                      });
                                    },
                                    selectedColor: AppColors.admin,
                                    checkmarkColor: Colors.white,
                                  ),
                                );
                              }).toList(),
                            ),
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
              child: _filteredCases.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.warning_amber_outlined,
                      title: 'No Special Cases Found',
                      message: 'No cases match your search criteria',
                      buttonText: 'Clear Filters',
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _selectedStatus = 'all';
                          _selectedDistrict = 'all';
                          _selectedRabStatus = 'all';
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
        onPressed: _showReportCaseDialog,
        backgroundColor: AppColors.admin,
        icon: const Icon(Icons.add_alert),
        label: const Text('Report Case'),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Column(
      children: [
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
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
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
      itemCount: _filteredCases.length,
      itemBuilder: (context, index) {
        final specialCase = _filteredCases[index];
        final isSelected = _selectedCases.contains(specialCase);
        
        return _buildCaseGridCard(specialCase, isSelected);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredCases.length,
      itemBuilder: (context, index) {
        final specialCase = _filteredCases[index];
        final isSelected = _selectedCases.contains(specialCase);
        
        return _buildCaseListCard(specialCase, isSelected);
      },
    );
  }

  Widget _buildCaseGridCard(SpecialCase specialCase, bool isSelected) {
    final isUrgent = specialCase.status == 'reported' && !specialCase.reportedToRab;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: AppColors.admin, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showCaseDetails(specialCase),
        onLongPress: () => _toggleSelection(specialCase),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Status Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: specialCase.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          specialCase.statusDisplay,
                          style: TextStyle(
                            color: specialCase.statusColor,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (specialCase.reportedToRab)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'RAB',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isUrgent ? Colors.red : specialCase.statusColor).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isUrgent ? Icons.warning : specialCase.statusIcon,
                      color: isUrgent ? Colors.red : specialCase.statusColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Location
                  Text(
                    specialCase.district,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    specialCase.sector,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Description snippet
                  Text(
                    specialCase.description.length > 40
                        ? '${specialCase.description.substring(0, 40)}...'
                        : specialCase.description,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, size: 10, color: Colors.grey.shade500),
                      const SizedBox(width: 2),
                      Text(
                        Helpers.timeAgo(specialCase.reportedAt),
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                        ),
                      ),
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
            if (isUrgent)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning,
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

  Widget _buildCaseListCard(SpecialCase specialCase, bool isSelected) {
    final isUrgent = specialCase.status == 'reported' && !specialCase.reportedToRab;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: AppColors.admin, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showCaseDetails(specialCase),
        onLongPress: () => _toggleSelection(specialCase),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox for selection mode
              if (_isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(specialCase),
                  activeColor: AppColors.admin,
                ),
              
              // Status Indicator
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: isUrgent ? Colors.red : specialCase.statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isUrgent ? Colors.red : specialCase.statusColor).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUrgent ? Icons.warning : specialCase.statusIcon,
                  color: isUrgent ? Colors.red : specialCase.statusColor,
                  size: 24,
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
                            '${specialCase.district}, ${specialCase.sector}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: specialCase.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            specialCase.statusDisplay,
                            style: TextStyle(
                              color: specialCase.statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (specialCase.reportedToRab) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'RAB',
                              style: TextStyle(
                                color: Colors.green,
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
                      specialCase.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          'Reported ${Helpers.timeAgo(specialCase.reportedAt)}',
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
                  if (!specialCase.reportedToRab)
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.red),
                      onPressed: () => _showReportToRabDialog(specialCase),
                      tooltip: 'Report to RAB',
                      iconSize: 20,
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () => _showEditCaseDialog(specialCase),
                    tooltip: 'Edit',
                    iconSize: 20,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(specialCase),
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