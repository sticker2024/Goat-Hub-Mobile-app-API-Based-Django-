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
// Add this import for FilterChip

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _filterOptions = [
    {'value': 'all', 'label': 'All Messages', 'icon': Icons.all_inclusive},
    {'value': 'recent', 'label': 'Recent', 'icon': Icons.access_time},
    {'value': 'followup', 'label': 'Needs Follow-up', 'icon': Icons.reply},
    {'value': 'urgent', 'label': 'Urgent', 'icon': Icons.warning},
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

  List<Reply> _getFilteredReplies(List<Reply> replies) {
    var filtered = replies.where((r) {
      if (_searchQuery.isEmpty) return true;
      return r.farmerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             r.replyMessage.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (r.consultation?.message ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Apply additional filters
    switch (_selectedFilter) {
      case 'recent':
        filtered = filtered.where((r) => 
            r.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)))
        ).toList();
        break;
      case 'followup':
        // Messages that might need follow-up (older than 3 days)
        filtered = filtered.where((r) => 
            r.createdAt.isBefore(DateTime.now().subtract(const Duration(days: 3))) &&
            (r.consultation?.status ?? '') != 'replied'
        ).toList();
        break;
      case 'urgent':
        filtered = filtered.where((r) => 
            (r.consultation?.status ?? '') == 'pending' &&
            DateTime.now().difference(r.consultation?.createdAt ?? DateTime.now()).inHours > 24
        ).toList();
        break;
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return filtered;
  }

  void _showMessageDetails(Reply reply) {
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
          return _buildMessageDetailsSheet(reply, scrollController);
        },
      ),
    );
  }

  Widget _buildMessageDetailsSheet(Reply reply, ScrollController controller) {
    final hoursSince = DateTime.now().difference(reply.consultation?.createdAt ?? DateTime.now()).inHours;
    final needsFollowUp = hoursSince > 72 && (reply.consultation?.status ?? '') != 'replied';

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
                backgroundColor: reply.senderColor.withOpacity(0.1),
                child: Icon(
                  reply.senderIcon,
                  color: reply.senderColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To: ${reply.farmerName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: reply.senderColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            reply.isVet ? 'Veterinarian' : 'Administrator',
                            style: TextStyle(
                              color: reply.senderColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM dd, yyyy').format(reply.createdAt),
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
                // Your Reply
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: reply.senderColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: reply.senderColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Reply:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        reply.replyMessage,
                        style: const TextStyle(height: 1.5, fontSize: 15),
                      ),
                      if (reply.imageUrl != null) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _showFullScreenImage(reply.imageUrl!),
                          child: Container(
                            height: 150,
                            width: 150,
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
                ),
                const SizedBox(height: 16),

                // Original Consultation
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
                        'Original Consultation:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reply.consultation?.message ?? 'No message available',
                        style: const TextStyle(height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Submitted ${Helpers.timeAgo(reply.consultation?.createdAt ?? DateTime.now())}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Farmer Contact Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Farmer Contact:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildContactRow(Icons.person, 'Name', reply.farmerName),
                      _buildContactRow(Icons.phone, 'Phone', reply.consultation?.phoneNumber ?? 'N/A'),
                      _buildContactRow(Icons.location_on, 'Location', reply.consultation?.location ?? 'N/A'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Follow-up reminder if needed
                if (needsFollowUp)
                  _buildFollowUpReminder(reply),
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
                    context.go('/vet-reply/${reply.consultation?.consultationId ?? 0}');
                  },
                  icon: const Icon(Icons.reply),
                  label: const Text('Reply Again'),
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

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpReminder(Reply reply) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Follow-up Needed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This consultation hasn\'t been marked as resolved. Consider following up with the farmer.',
                  style: TextStyle(color: Colors.orange.shade700),
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

  void _copyMessage(String message) {
    // TODO: Implement copy to clipboard
    Helpers.showSnackBar(
      context,
      'Message copied to clipboard',
      type: SnackBarType.success,
    );
  }

  void _shareMessage(Reply reply) {
    // TODO: Implement share
    Helpers.showSnackBar(
      context,
      'Share feature coming soon',
      type: SnackBarType.info,
    );
  }

  void _deleteMessage(Reply reply) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
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
                'Message deleted',
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final consultationProvider = Provider.of<ConsultationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    // Remove the cast since we're not using vet

    if (_isLoading && consultationProvider.replies.isEmpty) {
      return const LoadingWidget(message: 'Loading messages...');
    }

    if (consultationProvider.error != null) {
      return CustomErrorWidget(
        message: consultationProvider.error!,
        onRetry: _loadData,
      );
    }

    // Get all replies
    final allReplies = consultationProvider.replies;
    
    // Group replies by date
    final Map<String, List<Reply>> groupedReplies = {};
    for (var reply in allReplies) {
      final dateKey = DateFormat('yyyy-MM-dd').format(reply.createdAt);
      if (!groupedReplies.containsKey(dateKey)) {
        groupedReplies[dateKey] = [];
      }
      groupedReplies[dateKey]!.add(reply);
    }

    // Sort dates
    final sortedDates = groupedReplies.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.vet,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search Bar
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
                      hintText: 'Search messages...',
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
              
              // Filter Chips
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filterOptions.length,
                  itemBuilder: (context, index) {
                    final option = _filterOptions[index];
                    final isSelected = _selectedFilter == option['value'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              option['icon'] as IconData,
                              size: 16,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(option['label'] as String),
                          ],
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = option['value'] as String;
                          });
                        },
                        selectedColor: AppColors.vet,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        actions: [
          // Stats
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.message, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  allReplies.length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: allReplies.isEmpty
            ? EmptyStateWidget(
                icon: Icons.mark_as_unread,
                title: 'No Messages Yet',
                message: 'When you reply to consultations, your messages will appear here',
                buttonText: 'View Consultations',
                onPressed: () => context.go('/vet-consultations'),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final date = sortedDates[index];
                  final dateReplies = groupedReplies[date]!;
                  final filteredReplies = _getFilteredReplies(dateReplies);
                  
                  if (filteredReplies.isEmpty) return const SizedBox();
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Header
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _formatDateHeader(DateTime.parse(date)),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      // Messages for this date
                      ...filteredReplies.map((reply) => _buildMessageCard(reply)),
                    ],
                  );
                },
              ),
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return 'Today';
    } else if (dateDay == yesterday) {
      return 'Yesterday';
    } else if (dateDay.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE').format(date); // Day name
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }

  Widget _buildMessageCard(Reply reply) {
    final isRecent = reply.createdAt.isAfter(DateTime.now().subtract(const Duration(hours: 24)));
    final needsFollowUp = (reply.consultation?.status ?? '') != 'replied' && 
        reply.createdAt.isBefore(DateTime.now().subtract(const Duration(days: 3)));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showMessageDetails(reply),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isRecent
                ? Border.all(color: Colors.green, width: 2)
                : needsFollowUp
                    ? Border.all(color: Colors.orange, width: 2)
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
                      radius: 20,
                      backgroundColor: reply.senderColor.withOpacity(0.1),
                      child: Icon(
                        reply.senderIcon,
                        color: reply.senderColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'To: ${reply.farmerName}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                reply.timeAgo,
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
                    if (isRecent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (needsFollowUp)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'FOLLOW UP',
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
                  reply.replyMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(height: 1.4),
                ),
                const SizedBox(height: 12),
                
                // Footer with original consultation reference
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Re: ${reply.consultation?.message ?? 'No message'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action Buttons
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () => _copyMessage(reply.replyMessage),
                      color: Colors.blue,
                      tooltip: 'Copy',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, size: 18),
                      onPressed: () => _shareMessage(reply),
                      color: Colors.green,
                      tooltip: 'Share',
                    ),
                    IconButton(
                      icon: const Icon(Icons.reply, size: 18),
                      onPressed: () => context.go('/vet-reply/${reply.consultation?.consultationId ?? 0}'),
                      color: AppColors.vet,
                      tooltip: 'Reply Again',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => _deleteMessage(reply),
                      color: Colors.red,
                      tooltip: 'Delete',
                    ),
                  ],
                ),
                
                // Status indicators
                if (reply.imageUrl != null || (reply.consultation?.status ?? '') == 'pending')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        if (reply.imageUrl != null) ...[
                          Icon(Icons.image, size: 14, color: Colors.purple),
                          const SizedBox(width: 4),
                          Text(
                            'Has image',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ],
                        if (reply.imageUrl != null && (reply.consultation?.status ?? '') == 'pending')
                          const SizedBox(width: 12),
                        if ((reply.consultation?.status ?? '') == 'pending') ...[
                          Icon(Icons.warning, size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'Awaiting response',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
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