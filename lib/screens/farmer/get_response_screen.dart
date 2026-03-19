import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/consultation_provider.dart';
import '../../models/consultation.dart';
import '../../core/constants/colors.dart';
import '../../utils/helpers.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/status_badge.dart';

class GetResponseScreen extends StatefulWidget {
  const GetResponseScreen({super.key});

  @override
  State<GetResponseScreen> createState() => _GetResponseScreenState();
}

class _GetResponseScreenState extends State<GetResponseScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String _selectedFilter = 'all';
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initAnimations();
    _loadData();
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
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final consultationProvider = Provider.of<ConsultationProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      await consultationProvider.loadFarmerConsultations(
        authProvider.currentUser!.fullName,
      );
    }
    
    setState(() => _isLoading = false);
  }

  List<Consultation> _getFilteredConsultations(
    List<Consultation> consultations, 
    String filter
  ) {
    switch (filter) {
      case 'pending':
        return consultations.where((c) => c.status == 'pending').toList();
      case 'replied':
        return consultations.where((c) => c.status == 'replied').toList();
      case 'all':
      default:
        return consultations;
    }
  }

  void _showReplyDetails(Reply reply) {
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
          return _buildReplyDetailsSheet(reply, scrollController);
        },
      ),
    );
  }

  Widget _buildReplyDetailsSheet(Reply reply, ScrollController controller) {
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
                      reply.senderName,
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
          
          // Reply Message
          Expanded(
            child: ListView(
              controller: controller,
              children: [
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
                        'Response:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        reply.replyMessage,
                        style: const TextStyle(height: 1.5, fontSize: 15),
                      ),
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
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Original Consultation:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reply.consultation?.message ?? '', // Fixed: Added comma
                        style: const TextStyle(height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Image if available
                if (reply.imageUrl != null)
                  _buildImageSection(reply.imageUrl!),
                const SizedBox(height: 16),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showNewConsultationDialog(reply.consultation);
                        },
                        icon: const Icon(Icons.reply),
                        label: const Text('Follow Up'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _markAsRead(reply);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Mark as Read'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
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
    );
  }

  Widget _buildImageSection(String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attached Image:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
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

  void _showNewConsultationDialog(Consultation? consultation) {
    if (consultation == null) return;
    
    final messageController = TextEditingController(
      text: 'Regarding consultation #${consultation.consultationId}: I have a follow-up question...',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Follow-up Question'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ask a follow-up question about your previous consultation:'),
            const SizedBox(height: 12),
            TextFormField(
              controller: messageController,
              maxLines: 4,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Type your question here...',
              ),
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
                'Follow-up question sent',
                type: SnackBarType.success,
              );
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

  void _markAsRead(Reply reply) {
    Helpers.showSnackBar(
      context,
      'Marked as read',
      type: SnackBarType.success,
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
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submitted ${Helpers.timeAgo(consultation.createdAt)}',
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
                // Message
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
                        'Your Message:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        consultation.message,
                        style: const TextStyle(height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Replies
                if (consultation.replies.isNotEmpty) ...[
                  const Text(
                    'Replies:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...consultation.replies.map((reply) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: reply.senderColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: reply.senderColor.withOpacity(0.2)),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final authProvider = Provider.of<AuthProvider>(context);
    final consultationProvider = Provider.of<ConsultationProvider>(context);
    final farmer = authProvider.currentUser;

    if (_isLoading) {
      return const LoadingWidget(message: 'Loading responses...');
    }

    final consultations = consultationProvider.consultations;
    final pendingCount = consultations.where((c) => c.status == 'pending').length;
    final repliedCount = consultations.where((c) => c.status == 'replied').length;
    
    // Get all replies sorted by date
    final allReplies = <Reply>[]; // Initialize empty list since we need to fix this
    // This needs to be fixed based on your provider structure
    // final allReplies = consultationProvider.replies
    //     .where((r) => r.farmerName == farmer?.fullName)
    //     .toList()
    //     ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    final unreadCount = 0; // You can implement this with a read status field

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Responses'),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('All'),
                  if (consultations.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        consultations.length.toString(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Replies'),
                  if (repliedCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        repliedCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pendingCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          // Filter
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive, size: 18),
                    SizedBox(width: 8),
                    Text('All Consultations'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 18, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Pending'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'replied',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Replied'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'unread',
                child: Row(
                  children: [
                    Icon(Icons.markunread, size: 18, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Unread'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: TabBarView(
          controller: _tabController,
          children: [
            // All Consultations Tab
            _buildAllConsultationsTab(consultations),
            
            // Replies Tab
            _buildRepliesTab(allReplies),
            
            // Pending Tab
            _buildPendingTab(consultations.where((c) => c.status == 'pending').toList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/consult-vet'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('New Consultation'),
      ),
    );
  }

  Widget _buildAllConsultationsTab(List<Consultation> consultations) {
    final filtered = _getFilteredConsultations(consultations, _selectedFilter);
    
    if (filtered.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.inbox,
        title: 'No Consultations',
        message: _selectedFilter == 'all'
            ? 'You haven\'t submitted any consultations yet'
            : 'No $_selectedFilter consultations found',
        buttonText: 'Start Consultation',
        onPressed: () => context.go('/consult-vet'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final consultation = filtered[index];
        final hasReplies = consultation.replies.isNotEmpty;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showConsultationDetails(consultation),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Consultation #${consultation.consultationId}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Submitted ${Helpers.timeAgo(consultation.createdAt)}',
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
                  const SizedBox(height: 12),
                  
                  // Message Preview
                  Text(
                    consultation.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.5,
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
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            consultation.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      if (hasReplies)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.reply,
                                size: 12,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${consultation.replies.length} repl${consultation.replies.length > 1 ? 'ies' : 'y'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
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
          ),
        );
      },
    );
  }

  Widget _buildRepliesTab(List<Reply> replies) {
    if (replies.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.reply_all_outlined,
        title: 'No Replies Yet',
        message: 'When veterinarians reply to your consultations, they will appear here',
        buttonText: 'View Consultations',
        onPressed: () {
          _tabController.animateTo(0);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: replies.length,
      itemBuilder: (context, index) {
        final reply = replies[index];
        final isRecent = reply.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 1)));
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showReplyDetails(reply),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isRecent
                    ? Border.all(color: Colors.green, width: 2)
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
                                reply.senderName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                reply.timeAgo,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
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
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Reply Preview
                    Text(
                      reply.replyMessage,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    
                    // Footer with original consultation reference
                    Container(
                      padding: const EdgeInsets.all(12),
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
                              'Re: ${reply.consultation?.message ?? ''}',
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
                    
                    // Image indicator
                    if (reply.imageUrl != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.image, size: 14, color: Colors.purple),
                          const SizedBox(width: 4),
                          Text(
                            'Has attached image',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingTab(List<Consultation> pendingConsultations) {
    if (pendingConsultations.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.check_circle_outline,
        title: 'No Pending Consultations',
        message: 'All your consultations have been responded to',
        buttonText: 'Start New Consultation',
        onPressed: () => context.go('/consult-vet'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingConsultations.length,
      itemBuilder: (context, index) {
        final consultation = pendingConsultations[index];
        final hoursSince = DateTime.now().difference(consultation.createdAt).inHours;
        final isUrgent = hoursSince > 24;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: isUrgent ? Colors.red.shade50 : null,
          child: InkWell(
            onTap: () => _showConsultationDetails(consultation),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isUrgent ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isUrgent ? Icons.warning : Icons.access_time,
                          color: isUrgent ? Colors.red : Colors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Consultation #${consultation.consultationId}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Submitted ${Helpers.timeAgo(consultation.createdAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isUrgent ? Colors.red : Colors.grey.shade600,
                                fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                              ),
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
                              fontSize: 10,
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
                      color: isUrgent ? Colors.red.shade900 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Time indicator
                  LinearProgressIndicator(
                    value: hoursSince / 48, // Consider urgent after 48 hours
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isUrgent ? Colors.red : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isUrgent
                        ? 'This consultation is taking longer than expected'
                        : 'Expected response time: 24-48 hours',
                    style: TextStyle(
                      fontSize: 11,
                      color: isUrgent ? Colors.red : Colors.grey.shade600,
                    ),
                  ),
                ],
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
    super.dispose();
  }
}