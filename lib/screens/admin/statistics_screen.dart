
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/farmer_provider.dart';
import '../../providers/vet_provider.dart';
import '../../providers/consultation_provider.dart';
import '../../providers/cooperative_provider.dart';
import '../../providers/special_case_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../core/constants/colors.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isInitialized = false;
  String _selectedPeriod = 'month';
  String _selectedChartType = 'line';
  
  final List<String> _periods = ['week', 'month', 'quarter', 'year'];
  final List<String> _chartTypes = ['line', 'bar', 'pie'];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initAnimations();
    _loadData();
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
      body: Consumer5<FarmerProvider, VetProvider, ConsultationProvider, CooperativeProvider, StatisticsProvider>(
        builder: (context, farmerProvider, vetProvider, consultationProvider, cooperativeProvider, statisticsProvider, child) {
          if (!_isInitialized || 
              farmerProvider.isLoading || 
              vetProvider.isLoading || 
              consultationProvider.isLoading) {
            return const LoadingWidget(message: 'Loading statistics...');
          }

          if (farmerProvider.error != null) {
            return CustomErrorWidget(
              message: farmerProvider.error!,
              onRetry: _loadData,
            );
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // App Bar
                SliverAppBar(
                  expandedHeight: 150,
                  floating: true,
                  pinned: true,
                  backgroundColor: AppColors.admin,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text('Platform Statistics'),
                    titlePadding: const EdgeInsets.only(left: 70, bottom: 16),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.admin, AppColors.adminDark],
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
                    // Period Selector
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedPeriod,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        items: _periods.map((period) {
                          return DropdownMenuItem(
                            value: period,
                            child: Text(
                              period.toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPeriod = value!;
                          });
                        },
                      ),
                    ),
                    // Refresh Button
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadData,
                    ),
                  ],
                  bottom: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(icon: Icon(Icons.pie_chart), text: 'Overview'),
                      Tab(icon: Icon(Icons.people), text: 'Users'),
                      Tab(icon: Icon(Icons.chat), text: 'Consultations'),
                      Tab(icon: Icon(Icons.trending_up), text: 'Growth'),
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
                  _buildOverviewTab(farmerProvider, vetProvider, consultationProvider, cooperativeProvider, statisticsProvider),
                  _buildUsersTab(farmerProvider, vetProvider),
                  _buildConsultationsTab(consultationProvider),
                  _buildGrowthTab(statisticsProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============= OVERVIEW TAB =============

  Widget _buildOverviewTab(
    FarmerProvider farmerProvider,
    VetProvider vetProvider,
    ConsultationProvider consultationProvider,
    CooperativeProvider cooperativeProvider,
    StatisticsProvider statisticsProvider,
  ) {
    final stats = statisticsProvider.statistics;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard(
                'Total Farmers',
                farmerProvider.farmers.length.toString(),
                Icons.people,
                AppColors.primary,
                '+${(farmerProvider.farmers.length * 0.12).toInt()} this month',
              ),
              _buildMetricCard(
                'Veterinarians',
                vetProvider.vets.length.toString(),
                Icons.medical_services,
                AppColors.vet,
                '${vetProvider.getPendingCount()} pending',
              ),
              _buildMetricCard(
                'Consultations',
                consultationProvider.consultations.length.toString(),
                Icons.chat,
                Colors.orange,
                '${consultationProvider.getPendingCount()} pending',
              ),
              _buildMetricCard(
                'Cooperatives',
                cooperativeProvider.cooperatives.length.toString(),
                Icons.handshake,
                Colors.purple,
                '${cooperativeProvider.cooperatives.where((c) => c.isActive).length} active',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Charts Row
          Row(
            children: [
              // Chart Type Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildChartTypeButton('line', Icons.show_chart),
                    _buildChartTypeButton('bar', Icons.bar_chart),
                    _buildChartTypeButton('pie', Icons.pie_chart),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Chart
          Container(
            height: 300,
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
            child: _buildOverviewChart(_selectedChartType, stats),
          ),
          const SizedBox(height: 24),

          // Distribution Cards
          Row(
            children: [
              Expanded(
                child: _buildDistributionCard(
                  'User Distribution',
                  Icons.pie_chart,
                  [
                    {'label': 'Farmers', 'value': farmerProvider.farmers.length, 'color': AppColors.primary},
                    {'label': 'Vets', 'value': vetProvider.vets.length, 'color': AppColors.vet},
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDistributionCard(
                  'Consultation Status',
                  Icons.assignment,
                  [
                    {'label': 'Pending', 'value': consultationProvider.getPendingCount(), 'color': Colors.orange},
                    {'label': 'In Progress', 'value': consultationProvider.getInProgressCount(), 'color': Colors.blue},
                    {'label': 'Replied', 'value': consultationProvider.getRepliedCount(), 'color': Colors.green},
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Activity
          _buildRecentActivitySection(consultationProvider),
          const SizedBox(height: 24),

          // Quick Stats
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, String trend) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    fontSize: 24,
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
            Text(
              trend,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTypeButton(String type, IconData icon) {
    final isSelected = _selectedChartType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedChartType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.admin : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildOverviewChart(String type, stats) {
    switch (type) {
      case 'line':
        return LineChart(
          LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                    if (value.toInt() >= 0 && value.toInt() < months.length) {
                      return Text(months[value.toInt()]);
                    }
                    return const Text('');
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(12, (index) => FlSpot(index.toDouble(), 50 + index * 5 + (index % 3) * 10)),
                isCurved: true,
                color: AppColors.primary,
                barWidth: 3,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.1)),
              ),
              LineChartBarData(
                spots: List.generate(12, (index) => FlSpot(index.toDouble(), 30 + index * 4 + (index % 4) * 8)),
                isCurved: true,
                color: AppColors.vet,
                barWidth: 3,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: AppColors.vet.withOpacity(0.1)),
              ),
            ],
          ),
        );
      case 'bar':
        return BarChart(
          BarChartData(
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                    if (value.toInt() >= 0 && value.toInt() < months.length) {
                      return Text(months[value.toInt()]);
                    }
                    return const Text('');
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: true),
            barGroups: List.generate(6, (index) {
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: 40 + index * 5,
                    color: AppColors.primary,
                    width: 16,
                  ),
                  BarChartRodData(
                    toY: 30 + index * 4,
                    color: AppColors.vet,
                    width: 16,
                  ),
                ],
              );
            }),
          ),
        );
      case 'pie':
        return PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(
                value: 60,
                title: 'Farmers',
                color: AppColors.primary,
                radius: 80,
              ),
              PieChartSectionData(
                value: 25,
                title: 'Vets',
                color: AppColors.vet,
                radius: 80,
              ),
              PieChartSectionData(
                value: 15,
                title: 'Admins',
                color: Colors.orange,
                radius: 80,
              ),
            ],
            sectionsSpace: 2,
            centerSpaceRadius: 40,
          ),
        );
      default:
        return const Center(child: Text('Select a chart type'));
    }
  }

  Widget _buildDistributionCard(String title, IconData icon, List<Map<String, dynamic>> data) {
    final total = data.fold<int>(0, (sum, item) => sum + (item['value'] as int));
    
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
            Row(
              children: [
                Icon(icon, color: AppColors.admin, size: 18),
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
            const SizedBox(height: 16),
            ...data.map((item) {
              final percentage = total > 0 ? (item['value'] as int) / total * 100 : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['label'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          '${item['value']} (${percentage.toStringAsFixed(1)}%)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(item['color']),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(ConsultationProvider provider) {
    final recent = provider.consultations.take(5).toList();
    
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
            const Row(
              children: [
                Icon(Icons.history, color: AppColors.admin, size: 18),
                SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recent.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No recent activity'),
                ),
              )
            else
              ...recent.map((consultation) {
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: consultation.statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      consultation.statusIcon,
                      color: consultation.statusColor,
                      size: 20,
                    ),
                  ),
                  title: Text(consultation.fullName),
                  subtitle: Text(
                    consultation.message.length > 30
                        ? '${consultation.message.substring(0, 30)}...'
                        : consultation.message,
                  ),
                  trailing: Text(
                    consultation.timeAgo,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickStatBox(
            'Avg Response',
            '2.4 hours',
            Icons.timer,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatBox(
            'Success Rate',
            '94%',
            Icons.thumb_up,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatBox(
            'Active Today',
            '156',
            Icons.today,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
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
      ),
    );
  }

  // ============= USERS TAB =============

  Widget _buildUsersTab(FarmerProvider farmerProvider, VetProvider vetProvider) {
    final farmersByDistrict = farmerProvider.getFarmersByDistrict();
    final vetSpecializations = vetProvider.getSpecializations();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Farmers by District
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.map, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Farmers by District',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...farmersByDistrict.entries.map((entry) {
                    final percentage = entry.value / farmerProvider.farmers.length * 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              minHeight: 8,
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

          // Veterinarians by Specialization
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.medical_services, color: AppColors.vet, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Vets by Specialization',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...vetSpecializations.map((spec) {
                    final count = vetProvider.vets.where((v) => v.specialization == spec).length;
                    final percentage = count / vetProvider.vets.length * 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                spec,
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                '$count (${percentage.toStringAsFixed(1)}%)',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.vet),
                              minHeight: 8,
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

          // User Growth Chart
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'User Growth (Last 6 Months)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                                if (value.toInt() >= 0 && value.toInt() < months.length) {
                                  return Text(months[value.toInt()]);
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(6, (index) => FlSpot(index.toDouble(), 50 + index * 8)),
                            isCurved: true,
                            color: AppColors.primary,
                            barWidth: 3,
                            dotData: FlDotData(show: true),
                          ),
                          LineChartBarData(
                            spots: List.generate(6, (index) => FlSpot(index.toDouble(), 30 + index * 5)),
                            isCurved: true,
                            color: AppColors.vet,
                            barWidth: 3,
                            dotData: FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============= CONSULTATIONS TAB =============

  Widget _buildConsultationsTab(ConsultationProvider provider) {
    final pending = provider.getPendingCount();
    final inProgress = provider.getInProgressCount();
    final replied = provider.getRepliedCount();
    final total = provider.consultations.length;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Distribution
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.pie_chart, color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Consultation Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: total > 0 ? pending / total * 100 : 0,
                            title: 'Pending\n$pending',
                            color: Colors.orange,
                            radius: 80,
                          ),
                          PieChartSectionData(
                            value: total > 0 ? inProgress / total * 100 : 0,
                            title: 'In Progress\n$inProgress',
                            color: Colors.blue,
                            radius: 80,
                          ),
                          PieChartSectionData(
                            value: total > 0 ? replied / total * 100 : 0,
                            title: 'Replied\n$replied',
                            color: Colors.green,
                            radius: 80,
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Response Time Analysis
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.timer, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Average Response Time',
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
                      _buildResponseTimeMetric('Today', '2.4h', Colors.green),
                      _buildResponseTimeMetric('This Week', '3.1h', Colors.blue),
                      _buildResponseTimeMetric('This Month', '3.8h', Colors.orange),
                      _buildResponseTimeMetric('Average', '3.2h', Colors.purple),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Consultation Trends
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.purple, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Consultation Trends',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                if (value.toInt() >= 0 && value.toInt() < days.length) {
                                  return Text(days[value.toInt()]);
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        barGroups: List.generate(7, (index) {
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: 5 + index * 3,
                                color: Colors.blue,
                                width: 16,
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseTimeMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
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

  // ============= GROWTH TAB =============

  Widget _buildGrowthTab(StatisticsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Growth Metrics
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildGrowthMetricCard(
                'Farmers',
                '+12%',
                'from last month',
                Icons.people,
                Colors.green,
              ),
              _buildGrowthMetricCard(
                'Vets',
                '+8%',
                'from last month',
                Icons.medical_services,
                Colors.blue,
              ),
              _buildGrowthMetricCard(
                'Consultations',
                '+15%',
                'from last month',
                Icons.chat,
                Colors.orange,
              ),
              _buildGrowthMetricCard(
                'Cooperatives',
                '+5%',
                'from last month',
                Icons.handshake,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Year-over-Year Comparison
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.compare_arrows, color: Colors.teal, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Year-over-Year Growth',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const quarters = ['Q1', 'Q2', 'Q3', 'Q4'];
                                if (value.toInt() >= 0 && value.toInt() < quarters.length) {
                                  return Text(quarters[value.toInt()]);
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        barGroups: List.generate(4, (index) {
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: 100 + index * 20,
                                color: AppColors.primary.withOpacity(0.7),
                                width: 16,
                              ),
                              BarChartRodData(
                                toY: 80 + index * 25,
                                color: AppColors.vet.withOpacity(0.7),
                                width: 16,
                              ),
                            ],
                            barsSpace: 4,
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('This Year', AppColors.primary),
                      const SizedBox(width: 20),
                      _buildLegendItem('Last Year', AppColors.vet),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Projections
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Growth Projections',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildProjectionRow('Farmers', '1,200', '1,500', '+25%'),
                  const SizedBox(height: 12),
                  _buildProjectionRow('Vets', '85', '110', '+29%'),
                  const SizedBox(height: 12),
                  _buildProjectionRow('Consultations', '450', '600', '+33%'),
                  const SizedBox(height: 12),
                  _buildProjectionRow('Cooperatives', '25', '35', '+40%'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthMetricCard(String label, String growth, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    growth,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  Widget _buildProjectionRow(String label, String current, String projected, String growth) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Current: '),
                  Text(
                    current,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text('Projected: '),
                  Text(
                    projected,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      growth,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 10,
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
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}