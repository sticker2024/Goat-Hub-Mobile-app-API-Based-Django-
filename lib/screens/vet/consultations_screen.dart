import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/consultation_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/consultation.dart';
import '../../core/constants/colors.dart';
import '../../utils/helpers.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/status_badge.dart';

class ConsultationsScreen extends StatefulWidget {
  const ConsultationsScreen({super.key});

  @override
  State<ConsultationsScreen> createState() => _ConsultationsScreenState();
}

class _ConsultationsScreenState extends State<ConsultationsScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSort = 'newest';
  bool _showFilters = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'newest', 'label': 'Newest First', 'icon': Icons.access_time},
    {'value': 'oldest', 'label': 'Oldest First', 'icon': Icons.history},
    {'value': 'urgent', 'label': 'Most Urgent', 'icon': Icons.warning},
    {'value': 'name', 'label': 'Farmer Name', 'icon': Icons.person},
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initAnimations();
    _loadData();
    _searchController.addListener(_onSearchChanged);
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
    setState(() => _isLoading = true);
    
    final consultationProvider = context.read<ConsultationProvider>();
    await consultationProvider.loadConsultations();
    
    setState(() => _isLoading = false);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  List<Consultation> _getFilteredConsultations(List<Consultation> consultations) {
    var filtered = consultations.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             c.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             c.message.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             c.phoneNumber.contains(_searchQuery);
    }).toList();

    // Apply sorting
    switch (_selectedSort) {
      case 'newest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'urgent':
        filtered.sort((a, b) {
          final aUrgent = a.status == 'pending' && DateTime.now().difference(a.createdAt).inHours > 24;
          final bUrgent = b.status == 'pending' && DateTime.now().difference(b.createdAt).inHours > 24;
          if (aUrgent != bUrgent) return aUrgent ? -1 : 1;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
      case 'name':
        filtered.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
    }

    return filtered;
  }

  void _showConsultationDetails(Consultation consultation) {
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
          return _buildConsultationDetailsSheet(consultation, scrollController);
        },
      ),
    );
  }

  Widget _buildConsultationDetailsSheet(Consultation consultation, ScrollController controller) {
    final isUrgent = consultation.status == 'pending' && 
        DateTime.now().difference(consultation.createdAt).inHours > 24;
    final hoursSince = DateTime.now().difference(consultation.createdAt).inHours;

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
                radius: 30,
                backgroundColor: (isUrgent ? Colors.red : consultation.statusColor).withOpacity(0.1),
                child: Icon(
                  isUrgent ? Icons.warning : consultation.statusIcon,
                  color: isUrgent ? Colors.red : consultation.statusColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      consultation.fullName,
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
                            color: consultation.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            consultation.statusDisplay,
                            style: TextStyle(
                              color: consultation.statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ID: #${consultation.consultationId}',
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
            ],
          ),
          const SizedBox(height: 24),
          
          // Content
          Expanded(
            child: ListView(
              controller: controller,
              children: [
                // Farmer Information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Farmer Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.person, 'Name', consultation.fullName),
                      _buildInfoRow(Icons.phone, 'Phone', consultation.phoneNumber),
                      _buildInfoRow(Icons.location_on, 'Location', consultation.location),
                      _buildInfoRow(Icons.access_time, 'Submitted', 
                          '${DateFormat('MMM dd, yyyy HH:mm').format(consultation.createdAt)} (${hoursSince}h ago)'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Consultation Message
                Container(
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
                          Icon(Icons.message, color: Colors.blue, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Consultation Message',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        consultation.message,
                        style: const TextStyle(height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Image if available
                if (consultation.imageUrl != null)
                  _buildImageSection(consultation.imageUrl!),
                const SizedBox(height: 16),

                // Previous Replies
                if (consultation.replies.isNotEmpty)
                  _buildPreviousReplies(consultation.replies),
                const SizedBox(height: 16),

                // Quick Response Templates
                _buildQuickTemplates(consultation),
                const SizedBox(height: 16),

                // Urgent Notice
                if (isUrgent)
                  _buildUrgentNotice(hoursSince),
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
                    context.go('/vet-reply/${consultation.consultationId}');
                  },
                  icon: const Icon(Icons.reply),
                  label: const Text('Reply'),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
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
                  color: Colors.purple,
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

  Widget _buildPreviousReplies(List<Reply> replies) {
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
                'Previous Replies',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...replies.map((reply) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      reply.senderIcon,
                      size: 14,
                      color: reply.senderColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reply.senderName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: reply.senderColor,
                        ),
                      ),
                    ),
                    Text(
                      reply.timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(reply.replyMessage),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildQuickTemplates(Consultation consultation) {
    final templates = [
      'Thank you for your consultation. Based on the symptoms described, I recommend...',
      'I have reviewed your case and suggest the following treatment plan...',
      'Please monitor your goat for these signs and follow up in 3 days...',
      'This appears to be an urgent case. Please take your goat to the nearest clinic...',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Text(
                'Quick Templates',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: templates.map((template) {
              return ActionChip(
                label: Text(
                  template.length > 30 ? '${template.substring(0, 30)}...' : template,
                  style: const TextStyle(fontSize: 11),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  context.go(
                    '/vet-reply/${consultation.consultationId}',
                    extra: {'template': template},
                  );
                },
                backgroundColor: Colors.amber.withOpacity(0.1),
                labelStyle: TextStyle(color: Colors.amber.shade800),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentNotice(int hoursSince) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Urgent Case',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This consultation has been pending for $hoursSince hours. Please respond as soon as possible.',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ],
            ),
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

  void _updateStatus(Consultation consultation, String status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Text('Are you sure you want to mark this consultation as $status?'),
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
                'Status updated to $status',
                type: SnackBarType.success,
              );
              // TODO: Implement API call
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vet,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final consultationProvider = Provider.of<ConsultationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Remove the cast since we don't actually use 'vet' anywhere
    // final vet = authProvider.currentUser as Veterinarian?;

    if (_isLoading && consultationProvider.consultations.isEmpty) {
      return const LoadingWidget(message: 'Loading consultations...');
    }

    if (consultationProvider.error != null) {
      return CustomErrorWidget(
        message: consultationProvider.error!,
        onRetry: _loadData,
      );
    }

    final allConsultations = consultationProvider.consultations;
    final pendingConsultations = allConsultations.where((c) => c.status == 'pending').toList();
    final inProgressConsultations = allConsultations.where((c) => c.status == 'in_progress').toList();
    final repliedConsultations = allConsultations.where((c) => c.status == 'replied').toList();
    final urgentCount = pendingConsultations.where((c) => 
        DateTime.now().difference(c.createdAt).inHours > 24).length;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 150,
              floating: true,
              pinned: true,
              backgroundColor: AppColors.vet,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Consultations'),
                titlePadding: const EdgeInsets.only(left: 70, bottom: 16),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.vet, AppColors.vetDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              actions: [
                // Search
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                ),
                // Sort
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  onSelected: (value) {
                    setState(() {
                      _selectedSort = value;
                    });
                  },
                  itemBuilder: (context) {
                    return _sortOptions.map((option) {
                      return PopupMenuItem<String>(
                        value: option['value'] as String,
                        child: Row(
                          children: [
                            Icon(option['icon'] as IconData, size: 18),
                            const SizedBox(width: 8),
                            Text(option['label'] as String),
                          ],
                        ),
                      );
                    }).toList();
                  },
                ),
                // Refresh
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadData,
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(100),
                child: Column(
                  children: [
                    // Search Bar
                    if (_showFilters)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by farmer, location...',
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
                    
                    // Stats Summary
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatChip('Total', allConsultations.length, Colors.grey),
                          _buildStatChip('Pending', pendingConsultations.length, Colors.orange,
                              badge: urgentCount > 0 ? '$urgentCount urgent' : null),
                          _buildStatChip('In Progress', inProgressConsultations.length, Colors.blue),
                          _buildStatChip('Replied', repliedConsultations.length, Colors.green),
                        ],
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
          child: Column(
            children: [
              // Tabs
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: [
                    Tab(
                      child: Row(
                        children: [
                          const Text('All'),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              allConsultations.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        children: [
                          const Text('Pending'),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              pendingConsultations.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        children: [
                          const Text('In Progress'),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              inProgressConsultations.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        children: [
                          const Text('Replied'),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              repliedConsultations.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildConsultationList(_getFilteredConsultations(allConsultations)),
                    _buildConsultationList(_getFilteredConsultations(pendingConsultations)),
                    _buildConsultationList(_getFilteredConsultations(inProgressConsultations)),
                    _buildConsultationList(_getFilteredConsultations(repliedConsultations)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color, {String? badge}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (badge != null)
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConsultationList(List<Consultation> consultations) {
    if (consultations.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.inbox,
        title: 'No Consultations Found',
        message: 'There are no consultations matching your criteria',
        buttonText: 'Refresh',
        onPressed: _loadData,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: consultations.length,
      itemBuilder: (context, index) {
        final consultation = consultations[index];
        final isUrgent = consultation.status == 'pending' && 
            DateTime.now().difference(consultation.createdAt).inHours > 24;
        final hoursSince = DateTime.now().difference(consultation.createdAt).inHours;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showConsultationDetails(consultation),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isUrgent
                    ? Border.all(color: Colors.red, width: 2)
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: (isUrgent ? Colors.red : consultation.statusColor).withOpacity(0.1),
                          child: Text(
                            Helpers.getInitials(consultation.fullName),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isUrgent ? Colors.red : consultation.statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                consultation.fullName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      consultation.location,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isUrgent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'URGENT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Message Preview
                    Text(
                      consultation.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: isUrgent ? Colors.red : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$hoursSince hours ago',
                              style: TextStyle(
                                fontSize: 12,
                                color: isUrgent ? Colors.red : Colors.grey.shade600,
                                fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (consultation.imageUrl != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.image,
                                  size: 14,
                                  color: Colors.purple.shade300,
                                ),
                              ),
                            StatusBadge(
                              status: consultation.statusDisplay,
                              color: consultation.statusColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    // Action Buttons
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showConsultationDetails(consultation),
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('View Details'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.go('/vet-reply/${consultation.consultationId}'),
                            icon: const Icon(Icons.reply, size: 16),
                            label: const Text('Reply'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.vet,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Status Update for In Progress
                    if (consultation.status == 'in_progress')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _updateStatus(consultation, 'replied'),
                              child: const Text('Mark as Replied'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}