import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/consultation_provider.dart';
import '../../models/user.dart';
import '../../models/consultation.dart';
import '../../core/constants/colors.dart';
import '../../utils/helpers.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/status_badge.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isInitialized = false;
  String _selectedPeriod = 'week';
  
  final List<Map<String, dynamic>> _quickActions = [
    {
      'title': 'Consult Vet',
      'icon': Icons.medical_services_outlined,
      'route': '/consult-vet',
      'color': AppColors.primary,
      'description': 'Get expert advice',
    },
    {
      'title': 'Resources',
      'icon': Icons.school_outlined,
      'route': '/education',
      'color': Colors.orange,
      'description': 'Learn & grow',
    },
    {
      'title': 'Responses',
      'icon': Icons.reply_outlined,
      'route': '/get-response',
      'color': Colors.purple,
      'description': 'Check replies',
    },
    {
      'title': 'Profile',
      'icon': Icons.person_outline,
      'route': '/farmer-profile',
      'color': Colors.teal,
      'description': 'Manage account',
    },
  ];

  final List<Map<String, dynamic>> _healthTips = [
    {
      'title': 'Clean Water',
      'description': 'Provide fresh, clean water daily',
      'icon': Icons.water_drop_outlined,
      'color': Colors.blue,
    },
    {
      'title': 'Proper Nutrition',
      'description': 'Balanced feed with minerals',
      'icon': Icons.agriculture_outlined,
      'color': Colors.green,
    },
    {
      'title': 'Vaccinations',
      'description': 'Keep schedule updated',
      'icon': Icons.health_and_safety_outlined,
      'color': Colors.orange,
    },
    {
      'title': 'Clean Shelter',
      'description': 'Maintain dry, clean housing',
      'icon': Icons.home_outlined,
      'color': Colors.brown,
    },
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    final consultationProvider = context.read<ConsultationProvider>();
    final authProvider = context.read<AuthProvider>();
    
    if (authProvider.currentUser != null) {
      await consultationProvider.loadFarmerConsultations(
        authProvider.currentUser!.fullName,
      );
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      body: Consumer2<AuthProvider, ConsultationProvider>(
        builder: (context, authProvider, consultationProvider, child) {
          if (!_isInitialized || consultationProvider.isLoading) {
            return const LoadingWidget(message: 'Loading your dashboard...');
          }

          if (consultationProvider.error != null) {
            return CustomErrorWidget(
              message: consultationProvider.error!,
              onRetry: _loadData,
            );
          }

          final farmer = authProvider.currentUser as Farmer?;
          final consultations = consultationProvider.consultations;
          
          // Calculate statistics
          final totalConsultations = consultations.length;
          final pendingCount = consultations.where((c) => c.status == 'pending').length;
          final repliedCount = consultations.where((c) => c.status == 'replied').length;
          final inProgressCount = consultations.where((c) => c.status == 'in_progress').length;
          
          // Get recent consultations
          final recentConsultations = consultations.take(5).toList();

          return RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                // App Bar with Greeting
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeader(farmer),
                  ),
                  actions: [
                    // Notification Bell
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: _showNotifications,
                        ),
                        if (pendingCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                pendingCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Refresh Button
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadData,
                    ),
                  ],
                ),
                
                // Main Content
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Statistics Cards
                      _buildStatisticsSection(
                        totalConsultations,
                        pendingCount,
                        repliedCount,
                        inProgressCount,
                      ),
                      const SizedBox(height: 24),

                      // Quick Actions
                      _buildQuickActions(),
                      const SizedBox(height: 24),

                      // Period Filter
                      _buildPeriodFilter(),
                      const SizedBox(height: 16),

                      // Recent Consultations
                      _buildRecentConsultations(recentConsultations),
                      const SizedBox(height: 24),

                      // Health Tips
                      _buildHealthTips(),
                      const SizedBox(height: 24),

                      // Motivational Quote
                      _buildMotivationalQuote(),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/consult-vet'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('New Consultation'),
      ),
    );
  }

  Widget _buildHeader(Farmer? farmer) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                // Profile Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: farmer?.profilePicture != null
                      ? ClipOval(
                          child: Image.network(
                            farmer!.profilePicture!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            Helpers.getInitials(farmer?.fullName ?? 'Farmer'),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                // Greeting
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        farmer?.fullName ?? 'Farmer',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              farmer?.district ?? 'Location not set',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
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
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning 🌅';
    } else if (hour < 17) {
      return 'Good Afternoon ☀️';
    } else {
      return 'Good Evening 🌙';
    }
  }

  Widget _buildStatisticsSection(
    int total,
    int pending,
    int replied,
    int inProgress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _buildStatCard(
              'Total',
              total.toString(),
              Icons.chat_outlined,
              AppColors.primary,
              'All consultations',
            ),
            _buildStatCard(
              'Pending',
              pending.toString(),
              Icons.access_time,
              Colors.orange,
              'Awaiting reply',
            ),
            _buildStatCard(
              'In Progress',
              inProgress.toString(),
              Icons.autorenew,
              Colors.blue,
              'Being reviewed',
            ),
            _buildStatCard(
              'Replied',
              replied.toString(),
              Icons.check_circle_outlined,
              Colors.green,
              'Got responses',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Show detailed stats
          _showStatDetails(label, value, subtitle);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatDetails(String label, String value, String subtitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(subtitle),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: _quickActions.length,
          itemBuilder: (context, index) {
            final action = _quickActions[index];
            return _buildActionCard(
              action['title'],
              action['icon'],
              action['color'],
              action['description'],
              () => context.go(action['route']),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(String label, IconData icon, Color color, String description, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Row(
      children: [
        const Text(
          'Activity Overview:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButton<String>(
              value: _selectedPeriod,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down),
              items: const [
                DropdownMenuItem(value: 'week', child: Text('This Week')),
                DropdownMenuItem(value: 'month', child: Text('This Month')),
                DropdownMenuItem(value: 'year', child: Text('This Year')),
                DropdownMenuItem(value: 'all', child: Text('All Time')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
                });
                // TODO: Filter data based on period
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentConsultations(List<Consultation> consultations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Consultations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/get-response'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: Row(
                children: const [
                  Text('View All'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        consultations.isEmpty
            ? EmptyStateWidget(
                icon: Icons.inbox,
                title: 'No Consultations Yet',
                message: 'Start by consulting a veterinarian',
                buttonText: 'Consult Now',
                onPressed: () => context.go('/consult-vet'),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: consultations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final consultation = consultations[index];
                  return _buildConsultationCard(consultation);
                },
              ),
      ],
    );
  }

  Widget _buildConsultationCard(Consultation consultation) {
    return Dismissible(
      key: Key(consultation.consultationId.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (_) {
        // TODO: Implement delete
        Helpers.showSnackBar(
          context,
          'Consultation dismissed',
          type: SnackBarType.info,
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _showConsultationDetails(consultation),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status Indicator
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: consultation.statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        consultation.message.length > 40
                            ? '${consultation.message.substring(0, 40)}...'
                            : consultation.message,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
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
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            consultation.timeAgo,
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
                
                // Status Badge
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: StatusBadge(
                    status: consultation.statusDisplay,
                    color: consultation.statusColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Handle
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: consultation.statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  consultation.statusIcon,
                  color: consultation.statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consultation #${consultation.consultationId}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submitted ${Helpers.formatDateTime(consultation.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                status: consultation.statusDisplay,
                color: consultation.statusColor,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Content
          Expanded(
            child: ListView(
              controller: controller,
              children: [
                // Your Message
                _buildDetailSection(
                  'Your Message',
                  Icons.message_outlined,
                  consultation.message,
                ),
                const SizedBox(height: 16),
                
                // Location & Contact
                _buildInfoSection(
                  'Location & Contact',
                  Icons.location_on_outlined,
                  [
                    'Location: ${consultation.location}',
                    'Phone: ${consultation.phoneNumber}',
                  ],
                ),
                const SizedBox(height: 16),
                
                // Image if available
                if (consultation.imageUrl != null) ...[
                  _buildImageSection(consultation.imageUrl!),
                  const SizedBox(height: 16),
                ],
                
                // Replies
                if (consultation.replies.isNotEmpty) ...[
                  _buildRepliesSection(consultation.replies),
                  const SizedBox(height: 16),
                ],
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
              if (consultation.status == 'pending')
                const SizedBox(width: 12),
              if (consultation.status == 'pending')
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Edit consultation
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

  Widget _buildDetailSection(String title, IconData icon, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            content,
            style: const TextStyle(height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(item),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection(String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image_outlined, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
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
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
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
    );
  }

  Widget _buildRepliesSection(List<Reply> replies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.reply_outlined, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Replies',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...replies.map((reply) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: reply.isVet ? Colors.green.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: reply.isVet ? Colors.green.shade200 : Colors.blue.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    reply.senderIcon,
                    size: 16,
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
              if (reply.imageUrl != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showFullScreenImage(reply.imageUrl!),
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(reply.imageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        )),
      ],
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

  Widget _buildHealthTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            const Text(
              'Health Tips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _healthTips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final tip = _healthTips[index];
              return Container(
                width: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (tip['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (tip['color'] as Color).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (tip['color'] as Color).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        tip['icon'],
                        color: tip['color'],
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tip['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tip['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMotivationalQuote() {
    final quotes = [
      'The greatness of a nation and its moral progress can be judged by the way its animals are treated.',
      'Until one has loved an animal, a part of one\'s soul remains unawakened.',
      'Animals are such agreeable friends - they ask no questions, they pass no criticisms.',
      'The best way to ensure animal welfare is to educate farmers.',
    ];
    
    final randomQuote = quotes[DateTime.now().day % quotes.length];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.format_quote,
            color: AppColors.primary.withOpacity(0.5),
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '"$randomQuote"',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
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
              'Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Add notification items here
            const ListTile(
              leading: Icon(Icons.notifications, color: AppColors.primary),
              title: Text('New feature available'),
              subtitle: Text('Check out our new educational resources'),
            ),
            const ListTile(
              leading: Icon(Icons.reply, color: Colors.green),
              title: Text('Reply received'),
              subtitle: Text('A veterinarian replied to your consultation'),
            ),
          ],
        ),
      ),
    );
  }
}