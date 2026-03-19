import 'package:flutter/material.dart';
import 'package:goathub/models/consultation.dart';
import 'package:goathub/models/user.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/consultation_provider.dart';
import '../../core/constants/colors.dart';
import '../../utils/helpers.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/status_badge.dart';

class VetDashboard extends StatefulWidget {
  const VetDashboard({super.key});

  @override
  State<VetDashboard> createState() => _VetDashboardState();
}

class _VetDashboardState extends State<VetDashboard> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isInitialized = false;
  String _selectedPeriod = 'week';
  final TextEditingController _searchController = TextEditingController();
  
  final List<Map<String, dynamic>> _quickActions = [
    {
      'title': 'Consultations',
      'icon': Icons.list_alt_outlined,
      'route': '/vet-consultations',
      'color': AppColors.vet,
      'description': 'View all consultations',
      'badge': null,
    },
    {
      'title': 'Messages',
      'icon': Icons.message_outlined,
      'route': '/vet-messages',
      'color': Colors.blue,
      'description': 'Check your replies',
      'badge': null,
    },
    {
      'title': 'Schedule',
      'icon': Icons.calendar_today_outlined,
      'route': '/vet-schedule',
      'color': Colors.purple,
      'description': 'Manage availability',
      'badge': null,
    },
    {
      'title': 'Profile',
      'icon': Icons.person_outline,
      'route': '/vet-profile',
      'color': Colors.teal,
      'description': 'Update information',
      'badge': null,
    },
  ];

  final List<Map<String, dynamic>> _performanceMetrics = [
    {
      'title': 'Response Time',
      'icon': Icons.timer_outlined,
      'value': '2.4',
      'unit': 'hours',
      'trend': '+12%',
      'isPositive': false,
    },
    {
      'title': 'Satisfaction',
      'icon': Icons.star_outline,
      'value': '4.8',
      'unit': '/5',
      'trend': '+5%',
      'isPositive': true,
    },
    {
      'title': 'Resolution Rate',
      'icon': Icons.check_circle_outline,
      'value': '94',
      'unit': '%',
      'trend': '+3%',
      'isPositive': true,
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
    await consultationProvider.loadConsultations();
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _filterConsultations(String query) {
    // Filter logic will be handled in the consultations screen
    if (query.isNotEmpty) {
      context.go('/vet-consultations?search=$query');
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

          final vet = authProvider.currentUser as Veterinarian?;
          
          // Check if vet is approved
          if (vet != null && !vet.isApproved) {
            return _buildPendingApprovalScreen();
          }

          final consultations = consultationProvider.consultations;
          
          // Calculate statistics
          final totalConsultations = consultations.length;
          final pendingCount = consultations.where((c) => c.status == 'pending').length;
          final inProgressCount = consultations.where((c) => c.status == 'in_progress').length;
          final completedCount = consultations.where((c) => c.status == 'replied').length;
          
          // Get urgent consultations (pending for more than 24 hours)
          final urgentCount = consultations.where((c) {
            if (c.status != 'pending') return false;
            final hoursSince = DateTime.now().difference(c.createdAt).inHours;
            return hoursSince > 24;
          }).length;

          // Get recent consultations
          final recentConsultations = consultations.take(5).toList();

          return RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.vet,
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppColors.vet,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeader(vet),
                  ),
                  actions: [
                    // Notification Bell
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: _showNotifications,
                        ),
                        if (urgentCount > 0)
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
                                urgentCount.toString(),
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
                      // Search Bar
                      _buildSearchBar(),
                      const SizedBox(height: 20),

                      // Statistics Cards
                      _buildStatisticsSection(
                        totalConsultations,
                        pendingCount,
                        inProgressCount,
                        completedCount,
                        urgentCount,
                      ),
                      const SizedBox(height: 24),

                      // Performance Metrics
                      _buildPerformanceMetrics(),
                      const SizedBox(height: 24),

                      // Quick Actions
                      _buildQuickActions(),
                      const SizedBox(height: 24),

                      // Activity Chart
                      _buildActivityChart(consultations),
                      const SizedBox(height: 24),

                      // Recent Consultations
                      _buildRecentConsultations(recentConsultations, urgentCount),
                      const SizedBox(height: 24),

                      // Pro Tips
                      _buildProTips(),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingApprovalScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.vet, AppColors.vetDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hourglass_empty,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Account Pending Approval',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your veterinarian account is being reviewed by our administrators. You will be notified once approved.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade300),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'License verification in progress',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.orange.shade300),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Estimated time: 24-48 hours',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => context.go('/role-select'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.vet,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Back to Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Veterinarian? vet) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.vet, AppColors.vetDark],
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
                  child: vet?.profilePicture != null
                      ? ClipOval(
                          child: Image.network(
                            vet!.profilePicture!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            Helpers.getInitials('Dr. ${vet?.fullName ?? 'Vet'}'),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.vet,
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
                        'Dr. ${vet?.fullName ?? 'Veterinarian'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          vet?.specializationDisplay ?? 'General Veterinary',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
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
      return 'Good Morning, Dr. 🌅';
    } else if (hour < 17) {
      return 'Good Afternoon, Dr. ☀️';
    } else {
      return 'Good Evening, Dr. 🌙';
    }
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search consultations...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterConsultations('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onSubmitted: _filterConsultations,
      ),
    );
  }

  Widget _buildStatisticsSection(
    int total,
    int pending,
    int inProgress,
    int completed,
    int urgent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
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
              Icons.assignment_outlined,
              AppColors.vet,
              'All consultations',
            ),
            _buildStatCard(
              'Pending',
              pending.toString(),
              Icons.access_time,
              Colors.orange,
              'Awaiting response',
              badge: urgent > 0 ? '$urgent urgent' : null,
            ),
            _buildStatCard(
              'In Progress',
              inProgress.toString(),
              Icons.autorenew,
              Colors.blue,
              'Being handled',
            ),
            _buildStatCard(
              'Completed',
              completed.toString(),
              Icons.check_circle_outlined,
              Colors.green,
              'Replied',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, String subtitle, {String? badge}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Padding(
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
          if (badge != null)
            Positioned(
              top: 8,
              right: 8,
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
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: _performanceMetrics.map((metric) {
            return Expanded(
              child: _buildMetricCard(
                metric['title'],
                metric['icon'],
                metric['value'],
                metric['unit'],
                metric['trend'],
                metric['isPositive'],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, IconData icon, String value, String unit, String trend, bool isPositive) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(right: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 10,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 9,
                          color: isPositive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildActivityChart(List<Consultation> consultations) {
    // Group consultations by day
    final Map<String, int> activityByDay = {};
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayKey = DateFormat('E').format(day);
      activityByDay[dayKey] = 0;
    }
    
    for (var consultation in consultations) {
      final dayKey = DateFormat('E').format(consultation.createdAt);
      if (activityByDay.containsKey(dayKey)) {
        activityByDay[dayKey] = (activityByDay[dayKey] ?? 0) + 1;
      }
    }

    final maxValue = activityByDay.values.reduce((a, b) => a > b ? a : b).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Weekly Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.vet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: _selectedPeriod,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, size: 16),
                items: const [
                  DropdownMenuItem(value: 'week', child: Text('Week')),
                  DropdownMenuItem(value: 'month', child: Text('Month')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 150,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: activityByDay.entries.map((entry) {
                    final height = maxValue > 0 ? (entry.value / maxValue) * 120 : 0;
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (entry.value > 0)
                            Text(
                              entry.value.toString(),
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.vet,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            height: 120,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.vet, AppColors.vetDark],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${consultations.length} consultations',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    'Avg: ${(consultations.length / 7).toStringAsFixed(1)} per day',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentConsultations(List<Consultation> consultations, int urgentCount) {
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
            Row(
              children: [
                if (urgentCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$urgentCount urgent',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => context.go('/vet-consultations'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.vet,
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
          ],
        ),
        const SizedBox(height: 16),
        consultations.isEmpty
            ? EmptyStateWidget(
                icon: Icons.inbox,
                title: 'No Consultations',
                message: 'There are no consultations to display',
                buttonText: 'Refresh',
                onPressed: _loadData,
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: consultations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final consultation = consultations[index];
                  final isUrgent = consultation.status == 'pending' && 
                      DateTime.now().difference(consultation.createdAt).inHours > 24;
                  
                  return _buildConsultationCard(consultation, isUrgent);
                },
              ),
      ],
    );
  }

  Widget _buildConsultationCard(Consultation consultation, bool isUrgent) {
    return Card(
      elevation: 2,
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
                ? Border.all(color: Colors.red, width: 1)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status Indicator
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isUrgent ? Colors.red : consultation.statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              consultation.fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isUrgent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'URGENT',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        consultation.message.length > 40
                            ? '${consultation.message.substring(0, 40)}...'
                            : consultation.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
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
                            color: isUrgent ? Colors.red : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            consultation.timeAgo,
                            style: TextStyle(
                              fontSize: 11,
                              color: isUrgent ? Colors.red : Colors.grey.shade600,
                              fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action Button
                if (consultation.status == 'pending')
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: ElevatedButton(
                      onPressed: () => context.go('/vet-reply/${consultation.consultationId}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.vet,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Reply'),
                    ),
                  )
                else
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
    final isUrgent = consultation.status == 'pending' && 
        DateTime.now().difference(consultation.createdAt).inHours > 24;

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
                  color: (isUrgent ? Colors.red : consultation.statusColor).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUrgent ? Icons.warning : consultation.statusIcon,
                  color: isUrgent ? Colors.red : consultation.statusColor,
                  size: 24,
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
                    Text(
                      'Consultation #${consultation.consultationId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'URGENT',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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
                // Farmer Message
                _buildDetailSection(
                  'Farmer\'s Message',
                  Icons.message_outlined,
                  consultation.message,
                ),
                const SizedBox(height: 16),
                
                // Location & Contact
                _buildInfoSection(
                  'Contact Information',
                  Icons.contact_mail_outlined,
                  [
                    'Location: ${consultation.location}',
                    'Phone: ${consultation.phoneNumber}',
                    'Submitted: ${DateFormat('MMM dd, yyyy HH:mm').format(consultation.createdAt)}',
                  ],
                ),
                const SizedBox(height: 16),
                
                // Image if available
                if (consultation.imageUrl != null) ...[
                  _buildImageSection(consultation.imageUrl!),
                  const SizedBox(height: 16),
                ],
                
                // Quick Response Templates
                _buildQuickTemplates(consultation),
                const SizedBox(height: 16),
                
                // Previous Replies
                if (consultation.replies.isNotEmpty) ...[
                  _buildPreviousReplies(consultation.replies),
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

  Widget _buildDetailSection(String title, IconData icon, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.vet, size: 20),
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
            Icon(icon, color: AppColors.vet, size: 20),
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
            Icon(Icons.image_outlined, color: AppColors.vet, size: 20),
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

  Widget _buildQuickTemplates(Consultation consultation) {
    final templates = [
      'Thank you for your consultation. Based on the symptoms described...',
      'I recommend the following treatment plan...',
      'Please monitor your goat for these signs and follow up in...',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Quick Templates',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
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
              label: Text('${template.substring(0, 20)}...'),
              onPressed: () {
                Navigator.pop(context);
                context.go(
                  '/vet-reply/${consultation.consultationId}',
                  extra: {'template': template},
                );
              },
              backgroundColor: AppColors.vet.withOpacity(0.1),
              labelStyle: TextStyle(color: AppColors.vet, fontSize: 11),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPreviousReplies(List<Reply> replies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history_outlined, color: AppColors.vet, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Previous Replies',
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
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
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
                        fontSize: 13,
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
    );
  }

  Widget _buildProTips() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.vet.withOpacity(0.1), AppColors.vet.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.vet.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, color: AppColors.vet),
              const SizedBox(width: 8),
              const Text(
                'Pro Tips for Better Responses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTip('Always ask for clarification if symptoms are unclear'),
          _buildTip('Provide specific dosage instructions when prescribing'),
          _buildTip('Include warning signs that require immediate attention'),
          _buildTip('Suggest follow-up timeline for monitoring progress'),
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: AppColors.vet, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(tip)),
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
            _buildNotificationItem(
              'New Consultation',
              'Farmer John Doe submitted a new consultation',
              Icons.message,
              Colors.blue,
              '5 min ago',
            ),
            _buildNotificationItem(
              'Urgent Case',
              'Consultation #1234 is pending for over 24 hours',
              Icons.warning,
              Colors.red,
              '2 hours ago',
            ),
            _buildNotificationItem(
              'Reply Received',
              'Farmer responded to your advice',
              Icons.reply,
              Colors.green,
              '1 day ago',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(String title, String message, IconData icon, Color color, String time) {
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
      subtitle: Text(message),
      trailing: Text(
        time,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}