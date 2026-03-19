import '../../models/user.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farmer_provider.dart';
import '../../providers/consultation_provider.dart';
import '../../providers/vet_provider.dart';
import '../../providers/cooperative_provider.dart';
import '../../providers/special_case_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../core/constants/colors.dart';
import '../../utils/helpers.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/status_badge.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isInitialized = false;
  String _selectedPeriod = 'week';
  int _selectedChartIndex = 0;
  
  final List<Map<String, dynamic>> _quickActions = [
    {
      'title': 'Farmers',
      'icon': Icons.people_outline,
      'route': '/admin-farmers',
      'color': AppColors.primary,
      'description': 'Manage farmers',
      'badge': null,
    },
    {
      'title': 'Veterinarians',
      'icon': Icons.medical_services_outlined,
      'route': '/admin-vets',
      'color': AppColors.vet,
      'description': 'Approve & manage',
      'badge': 'pending',
    },
    {
      'title': 'Cooperatives',
      'icon': Icons.handshake_outlined,
      'route': '/admin-cooperatives',
      'color': Colors.orange,
      'description': 'Manage groups',
      'badge': null,
    },
    {
      'title': 'Special Cases',
      'icon': Icons.warning_amber_outlined,
      'route': '/admin-special-cases',
      'color': Colors.red,
      'description': 'Urgent cases',
      'badge': 'urgent',
    },
    {
      'title': 'All Replies',
      'icon': Icons.reply_all_outlined,
      'route': '/admin-all-replies',
      'color': Colors.purple,
      'description': 'View responses',
      'badge': null,
    },
    {
      'title': 'Statistics',
      'icon': Icons.bar_chart_outlined,
      'route': '/admin-statistics',
      'color': Colors.teal,
      'description': 'Analytics',
      'badge': null,
    },
  ];

  final List<Color> _gradientColors = [
    AppColors.primary,
    AppColors.vet,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.teal,
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
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

  Future<void> _loadAllData() async {
    if (!mounted) return;
    
    await Future.wait([
      context.read<FarmerProvider>().loadFarmers(),
      context.read<VetProvider>().loadVets(),
      context.read<ConsultationProvider>().loadConsultations(),
      context.read<CooperativeProvider>().loadCooperatives(),
      context.read<SpecialCaseProvider>().loadSpecialCases(),
      context.read<StatisticsProvider>().loadStatistics(),
    ]);
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      body: Consumer5<FarmerProvider, VetProvider, ConsultationProvider, SpecialCaseProvider, StatisticsProvider>(
        builder: (context, farmerProvider, vetProvider, consultationProvider, specialCaseProvider, statisticsProvider, child) {
          if (!_isInitialized || 
              farmerProvider.isLoading || 
              vetProvider.isLoading || 
              consultationProvider.isLoading) {
            return const LoadingWidget(message: 'Loading admin dashboard...');
          }

          if (farmerProvider.error != null) {
            return CustomErrorWidget(
              message: farmerProvider.error!,
              onRetry: _loadAllData,
            );
          }

          // Calculate statistics
          final totalFarmers = farmerProvider.farmers.length;
          final totalVets = vetProvider.vets.length;
          final pendingVets = vetProvider.getPendingCount();
          final totalConsultations = consultationProvider.consultations.length;
          final pendingConsultations = consultationProvider.getPendingCount();
          final totalSpecialCases = specialCaseProvider.specialCases.length;
          final urgentCases = specialCaseProvider.getUrgentCount();
          final totalCooperatives = context.read<CooperativeProvider>().cooperatives.length;

          // Get recent activities
          final recentConsultations = consultationProvider.consultations.take(5).toList();
          final recentSpecialCases = specialCaseProvider.specialCases.take(5).toList();
          final pendingVetList = vetProvider.vets.where((v) => !v.isApproved).take(5).toList();

          return RefreshIndicator(
            onRefresh: _loadAllData,
            color: AppColors.admin,
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppColors.admin,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeader(),
                  ),
                  actions: [
                    // Notification Bell
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: _showNotifications,
                        ),
                        if (urgentCases + pendingVets > 0)
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
                                (urgentCases + pendingVets).toString(),
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
                    IconButton(
                      icon: const Icon(Icons.person_outline),
                      onPressed: () => context.go('/admin-profile'),
                      tooltip: 'Profile',
                      ),
                    // Refresh Button
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadAllData,
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
                        totalFarmers,
                        totalVets,
                        totalConsultations,
                        totalSpecialCases,
                        pendingVets,
                        pendingConsultations,
                        urgentCases,
                        totalCooperatives,
                      ),
                      const SizedBox(height: 24),

                      // Quick Actions
                      _buildQuickActions(pendingVets, urgentCases),
                      const SizedBox(height: 24),

                      // Charts Section
                      _buildChartsSection(consultationProvider, vetProvider),
                      const SizedBox(height: 24),

                      // Pending Approvals
                      if (pendingVetList.isNotEmpty) ...[
                        _buildPendingApprovals(pendingVetList),
                        const SizedBox(height: 24),
                      ],

                      // Recent Activity Grid
                      _buildRecentActivityGrid(
                        recentConsultations,
                        recentSpecialCases,
                      ),
                      const SizedBox(height: 24),

                      // System Health
                      _buildSystemHealth(),
                      const SizedBox(height: 24),

                      // Quick Stats
                      _buildQuickStats(),
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

  Widget _buildHeader() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.admin, AppColors.adminDark],
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
                // Admin Avatar
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
                  child: Center(
                    child: Text(
                      Helpers.getInitials(user?.fullName ?? 'Admin'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.admin,
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
                        user?.fullName ?? 'Administrator',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Platform Administrator',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
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
      return 'Good Morning, Admin 🌅';
    } else if (hour < 17) {
      return 'Good Afternoon, Admin ☀️';
    } else {
      return 'Good Evening, Admin 🌙';
    }
  }

  Widget _buildStatisticsSection(
    int totalFarmers,
    int totalVets,
    int totalConsultations,
    int totalSpecialCases,
    int pendingVets,
    int pendingConsultations,
    int urgentCases,
    int totalCooperatives,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard(
          'Farmers',
          totalFarmers.toString(),
          Icons.people_outline,
          AppColors.primary,
          '+${(totalFarmers * 0.12).toInt()} this month',
          true,
        ),
        _buildStatCard(
          'Veterinarians',
          totalVets.toString(),
          Icons.medical_services_outlined,
          AppColors.vet,
          '$pendingVets pending',
          pendingVets == 0,
          badge: pendingVets > 0 ? '$pendingVets' : null,
        ),
        _buildStatCard(
          'Consultations',
          totalConsultations.toString(),
          Icons.chat_outlined,
          Colors.orange,
          '$pendingConsultations pending',
          false,
          badge: pendingConsultations > 0 ? '$pendingConsultations' : null,
        ),
        _buildStatCard(
          'Special Cases',
          totalSpecialCases.toString(),
          Icons.warning_amber_outlined,
          Colors.red,
          '$urgentCases urgent',
          urgentCases == 0,
          badge: urgentCases > 0 ? '$urgentCases' : null,
        ),
        _buildStatCard(
          'Cooperatives',
          totalCooperatives.toString(),
          Icons.handshake_outlined,
          Colors.purple,
          'Active: ${(totalCooperatives * 0.8).toInt()}',
          true,
        ),
        _buildStatCard(
          'Replies',
          context.read<ConsultationProvider>().replies.length.toString(),
          Icons.reply_outlined,
          Colors.teal,
          'Response rate: 94%',
          true,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, String trend, bool isPositive, {String? badge}) {
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 10,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
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

  Widget _buildQuickActions(int pendingVets, int urgentCases) {
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
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: _quickActions.length,
          itemBuilder: (context, index) {
            final action = _quickActions[index];
            bool showBadge = false;
            String badgeText = '';
            
            if (action['badge'] == 'pending' && pendingVets > 0) {
              showBadge = true;
              badgeText = pendingVets.toString();
            } else if (action['badge'] == 'urgent' && urgentCases > 0) {
              showBadge = true;
              badgeText = urgentCases.toString();
            }
            
            return _buildActionCard(
              action['title'],
              action['icon'],
              action['color'],
              action['description'],
              () => context.go(action['route']),
              badge: showBadge ? badgeText : null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(String label, IconData icon, Color color, String description, VoidCallback onTap, {String? badge}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
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
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(ConsultationProvider consultationProvider, VetProvider vetProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.admin.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButton<String>(
                value: _selectedPeriod,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down),
                items: const [
                  DropdownMenuItem(value: 'week', child: Text('This Week')),
                  DropdownMenuItem(value: 'month', child: Text('This Month')),
                  DropdownMenuItem(value: 'year', child: Text('This Year')),
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
        
        // Chart Tabs
        Row(
          children: [
            _buildChartTab('Platform Growth', 0),
            const SizedBox(width: 8),
            _buildChartTab('User Activity', 1),
            const SizedBox(width: 8),
            _buildChartTab('Consultations', 2),
          ],
        ),
        const SizedBox(height: 16),
        
        // Chart
        Container(
          height: 200,
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
          child: _buildChart(_selectedChartIndex, consultationProvider, vetProvider),
        ),
      ],
    );
  }

  Widget _buildChartTab(String label, int index) {
    final isSelected = _selectedChartIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedChartIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.admin : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildChart(int index, ConsultationProvider consultationProvider, VetProvider vetProvider) {
    switch (index) {
      case 0:
        return _buildGrowthChart();
      case 1:
        return _buildActivityChart();
      case 2:
        return _buildConsultationStatusChart(consultationProvider);
      default:
        return _buildGrowthChart();
    }
  }

  Widget _buildGrowthChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Text(
                    days[value.toInt()],
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(7, (index) => FlSpot(index.toDouble(), 10 + index * 2.5)),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.1),
            ),
          ),
          LineChartBarData(
            spots: List.generate(7, (index) => FlSpot(index.toDouble(), 5 + index * 3)),
            isCurved: true,
            color: AppColors.vet,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.vet.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    return BarChart(
      BarChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Text(
                    days[value.toInt()],
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: 5 + index * 2,
                color: _gradientColors[index % _gradientColors.length],
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildConsultationStatusChart(ConsultationProvider provider) {
    final pending = provider.getPendingCount();
    final inProgress = provider.getInProgressCount();
    final replied = provider.getRepliedCount();
    final total = pending + inProgress + replied;
    
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: total > 0 ? pending / total * 100 : 0,
            title: 'Pending',
            color: Colors.orange,
            radius: 80,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: total > 0 ? inProgress / total * 100 : 0,
            title: 'In Progress',
            color: Colors.blue,
            radius: 80,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: total > 0 ? replied / total * 100 : 0,
            title: 'Replied',
            color: Colors.green,
            radius: 80,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildPendingApprovals(List pendingVetList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pending Approvals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/admin-vets?status=pending'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.admin,
              ),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pendingVetList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final vet = pendingVetList[index] as Veterinarian;
            return _buildPendingVetCard(vet);
          },
        ),
      ],
    );
  }

  Widget _buildPendingVetCard(Veterinarian vet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.vet.withOpacity(0.1),
              child: const Icon(
                Icons.medical_services,
                color: AppColors.vet,
                size: 30,
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vet.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${vet.specializationDisplay} • ${vet.yearsExperience} years exp.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _approveVet(vet),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.green, size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _rejectVet(vet),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.red, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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
              // TODO: Implement approve API call
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
        content: Text('Are you sure you want to reject Dr. ${vet.fullName}?'),
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
              // TODO: Implement reject API call
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

  Widget _buildRecentActivityGrid(List recentConsultations, List recentSpecialCases) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recent Consultations
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chat, color: Colors.orange, size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Recent Consultations',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (recentConsultations.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text('No recent consultations'),
                          ),
                        )
                      else
                        ...recentConsultations.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              StatusBadge(
                                status: c.statusDisplay,
                                color: c.statusColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.fullName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      c.timeAgo,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Recent Special Cases
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.warning, color: Colors.red, size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Special Cases',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (recentSpecialCases.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text('No special cases'),
                          ),
                        )
                      else
                        ...recentSpecialCases.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: c.statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${c.district}, ${c.sector}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      Helpers.timeAgo(c.reportedAt),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!c.reportedToRab)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'RAB',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSystemHealth() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Health',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildHealthMetric(
                    'Database',
                    'Operational',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildHealthMetric(
                    'Storage',
                    '45% used',
                    Icons.storage,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildHealthMetric(
                    'API',
                    '99.9% uptime',
                    Icons.api,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildHealthMetric(
                    'Active Users',
                    '1,234',
                    Icons.people,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildHealthMetric(
                    'Response Time',
                    '2.4s',
                    Icons.timer,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildHealthMetric(
                    'Errors',
                    '0',
                    Icons.error_outline,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
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

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatBox(
            'Avg. Response',
            '2.4 hours',
            Icons.timer_outlined,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            'Success Rate',
            '94%',
            Icons.thumb_up_outlined,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            'Active Today',
            '156',
            Icons.today_outlined,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade600,
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
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildNotificationItem(
                    'New Veterinarian Registration',
                    'Dr. Jane Smith has registered and requires approval',
                    Icons.medical_services,
                    AppColors.vet,
                    '5 min ago',
                  ),
                  _buildNotificationItem(
                    'Urgent Special Case',
                    'Disease outbreak reported in Gicumbi district',
                    Icons.warning,
                    Colors.red,
                    '1 hour ago',
                  ),
                  _buildNotificationItem(
                    'System Update',
                    'Daily backup completed successfully',
                    Icons.system_update,
                    Colors.blue,
                    '2 hours ago',
                  ),
                  _buildNotificationItem(
                    'New Cooperative',
                    'Gicumbi Farmers Cooperative registered',
                    Icons.handshake,
                    Colors.orange,
                    '5 hours ago',
                  ),
                ],
              ),
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