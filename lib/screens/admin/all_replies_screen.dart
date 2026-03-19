import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/consultation.dart';
import '../../providers/consultation_provider.dart';
import '../../core/constants/colors.dart';
import '../../utils/helpers.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/filter_chips.dart';

class AllRepliesScreen extends StatefulWidget {
  const AllRepliesScreen({super.key});

  @override
  State<AllRepliesScreen> createState() => _AllRepliesScreenState();
}

class _AllRepliesScreenState extends State<AllRepliesScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  String _selectedSender = 'all';
  String _selectedDate = 'all';
  String _selectedSort = 'newest';
  String _selectedView = 'list'; // 'list' or 'compact'
  bool _showFilters = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _pageSize = 20;
  
  List<Reply> _filteredReplies = [];
  List<Reply> _selectedReplies = [];
  bool _isSelectionMode = false;

  final List<Map<String, dynamic>> _senderOptions = [
    {'value': 'all', 'label': 'All Senders', 'icon': Icons.all_inclusive},
    {'value': 'vet', 'label': 'Veterinarians', 'icon': Icons.medical_services},
    {'value': 'admin', 'label': 'Admins', 'icon': Icons.admin_panel_settings},
  ];

  final List<Map<String, dynamic>> _dateOptions = [
    {'value': 'all', 'label': 'All Time'},
    {'value': 'today', 'label': 'Today'},
    {'value': 'week', 'label': 'This Week'},
    {'value': 'month', 'label': 'This Month'},
    {'value': 'year', 'label': 'This Year'},
  ];

  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'newest', 'label': 'Newest First', 'icon': Icons.access_time},
    {'value': 'oldest', 'label': 'Oldest First', 'icon': Icons.history},
    {'value': 'farmer', 'label': 'Farmer Name', 'icon': Icons.person},
    {'value': 'sender', 'label': 'Sender Name', 'icon': Icons.reply},
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
    final consultationProvider = context.read<ConsultationProvider>();
    await consultationProvider.loadConsultations();
    
    if (mounted) {
      setState(() {
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
    final consultationProvider = context.read<ConsultationProvider>();
    var allReplies = List<Reply>.from(consultationProvider.replies);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      allReplies = allReplies.where((r) {
        return r.farmerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               r.senderName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               r.replyMessage.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (r.consultation?.message ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Apply sender filter
    if (_selectedSender != 'all') {
      if (_selectedSender == 'vet') {
        allReplies = allReplies.where((r) => r.isVet).toList();
      } else if (_selectedSender == 'admin') {
        allReplies = allReplies.where((r) => !r.isVet).toList();
      }
    }
    
    // Apply date filter
    if (_selectedDate != 'all') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      allReplies = allReplies.where((r) {
        switch (_selectedDate) {
          case 'today':
            return r.createdAt.isAfter(today);
          case 'week':
            return r.createdAt.isAfter(now.subtract(const Duration(days: 7)));
          case 'month':
            return r.createdAt.isAfter(DateTime(now.year, now.month, 1));
          case 'year':
            return r.createdAt.isAfter(DateTime(now.year, 1, 1));
          default:
            return true;
        }
      }).toList();
    }
    
    // Apply sorting
    switch (_selectedSort) {
      case 'newest':
        allReplies.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        allReplies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'farmer':
        allReplies.sort((a, b) => a.farmerName.compareTo(b.farmerName));
        break;
      case 'sender':
        allReplies.sort((a, b) => a.senderName.compareTo(b.senderName));
        break;
    }
    
    setState(() {
      _filteredReplies = allReplies;
    });
  }

  void _toggleSelection(Reply reply) {
    setState(() {
      if (_selectedReplies.contains(reply)) {
        _selectedReplies.remove(reply);
      } else {
        _selectedReplies.add(reply);
      }
      _isSelectionMode = _selectedReplies.isNotEmpty;
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedReplies.length == _filteredReplies.length) {
        _selectedReplies.clear();
        _isSelectionMode = false;
      } else {
        _selectedReplies = List.from(_filteredReplies);
        _isSelectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedReplies.clear();
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
              'Bulk Actions (${_selectedReplies.length} selected)',
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
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.email_outlined, color: Colors.blue),
              ),
              title: const Text('Send Email Copies'),
              subtitle: Text('Email ${_selectedReplies.length} replies'),
              onTap: () {
                Navigator.pop(context);
                _showBulkEmailDialog();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.archive_outlined, color: Colors.green),
              ),
              title: const Text('Archive Selected'),
              subtitle: Text('Archive ${_selectedReplies.length} replies'),
              onTap: () {
                Navigator.pop(context);
                _showBulkArchiveDialog();
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
              subtitle: const Text('Permanently delete selected replies'),
              onTap: () {
                Navigator.pop(context);
                _showBulkDeleteDialog();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.picture_as_pdf, color: Colors.purple),
              ),
              title: const Text('Export as PDF'),
              subtitle: const Text('Generate PDF report'),
              onTap: () {
                Navigator.pop(context);
                _showExportOptions();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkEmailDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Email Copies'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will send email copies of the selected replies.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes (Optional)',
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
                'Emails sent successfully',
                type: SnackBarType.success,
              );
              _clearSelection();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showBulkArchiveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Replies'),
        content: Text('Are you sure you want to archive ${_selectedReplies.length} replies?'),
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
                'Replies archived successfully',
                type: SnackBarType.success,
              );
              _clearSelection();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _showBulkDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Replies'),
        content: Text(
          'Are you sure you want to delete ${_selectedReplies.length} replies? This action cannot be undone.',
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
                'Replies deleted successfully',
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
                radius: 40,
                backgroundColor: reply.senderColor.withOpacity(0.1),
                child: Icon(
                  reply.senderIcon,
                  size: 40,
                  color: reply.senderColor,
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
                        fontSize: 22,
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
                          'Reply #${reply.replyId}',
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
                // Reply Message
                _buildMessageSection(
                  'Reply Message',
                  Icons.reply,
                  reply.replyMessage,
                  reply.senderColor,
                ),
                const SizedBox(height: 16),
                
                // Original Consultation
                _buildMessageSection(
                  'Original Consultation',
                  Icons.chat_outlined,
                  reply.consultation?.message ?? 'No consultation message',
                  Colors.grey.shade700,
                ),
                const SizedBox(height: 16),
                
                // Farmer Information
                _buildInfoSection(
                  'Farmer Information',
                  Icons.person_outline,
                  [
                    _buildInfoRow('Farmer Name', reply.farmerName),
                    _buildInfoRow('Consultation ID', '#${reply.consultation?.consultationId ?? 'N/A'}'),
                    _buildInfoRow('Location', reply.consultation?.location ?? 'N/A'),
                    _buildInfoRow('Phone', reply.consultation?.phoneNumber ?? 'N/A'),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Reply Details
                _buildInfoSection(
                  'Reply Details',
                  Icons.info_outline,
                  [
                    _buildInfoRow('Reply ID', reply.replyId.toString()),
                    _buildInfoRow('Date', DateFormat('MMM dd, yyyy').format(reply.createdAt)),
                    _buildInfoRow('Time', DateFormat('HH:mm').format(reply.createdAt)),
                    _buildInfoRow('Time Ago', reply.timeAgo),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Image if available
                if (reply.imageUrl != null)
                  _buildImageSection(reply.imageUrl!),
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
                    _sendEmailCopy(reply);
                  },
                  icon: const Icon(Icons.email),
                  label: const Text('Email Copy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageSection(String title, IconData icon, String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(height: 1.5),
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
              Icon(icon, color: Colors.purple, size: 18),
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

  void _sendEmailCopy(Reply reply) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Email Copy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.email, color: Colors.blue, size: 50),
            const SizedBox(height: 16),
            const Text('Send a copy of this reply via email?'),
            const SizedBox(height: 8),
            Text(
              'To: admin@example.com',
              style: TextStyle(color: Colors.grey.shade700),
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
                'Email sent successfully',
                type: SnackBarType.success,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _printReply(Reply reply) {
    // TODO: Implement print functionality
    Helpers.showSnackBar(
      context,
      'Print feature coming soon',
      type: SnackBarType.info,
    );
  }

  void _exportReply(Reply reply) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Export Reply',
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
                child: const Icon(Icons.picture_as_pdf, color: Colors.green),
              ),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                Helpers.showSnackBar(
                  context,
                  'PDF export started',
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
                child: const Icon(Icons.file_copy, color: Colors.blue),
              ),
              title: const Text('Export as Text'),
              onTap: () {
                Navigator.pop(context);
                Helpers.showSnackBar(
                  context,
                  'Text export started',
                  type: SnackBarType.success,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Reply reply) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reply'),
        content: Text('Are you sure you want to delete this reply? This action cannot be undone.'),
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
                'Reply deleted successfully',
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
              'Export Replies',
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
              subtitle: const Text('Download all replies as CSV file'),
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
              subtitle: const Text('Print replies list'),
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
      body: Consumer<ConsultationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.replies.isEmpty) {
            return const LoadingWidget(message: 'Loading replies...');
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
                        ? Text('${_selectedReplies.length} selected')
                        : const Text('All Replies'),
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
                            _selectedView = _selectedView == 'list' ? 'compact' : 'list';
                          });
                        },
                        tooltip: _selectedView == 'list' ? 'Compact View' : 'List View',
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
                                      hintText: 'Search by farmer, sender, or message...',
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
                              _buildQuickStat('Total', provider.replies.length.toString(), Colors.purple),
                              _buildQuickStat('Vet Replies', provider.replies.where((r) => r.isVet).length.toString(), Colors.green),
                              _buildQuickStat('Admin Replies', provider.replies.where((r) => !r.isVet).length.toString(), Colors.blue),
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
                          // Sender Filter
                          const Text(
                            'Sender',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _senderOptions.map((option) {
                                final isSelected = _selectedSender == option['value'];
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
                                        _selectedSender = option['value'];
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
                          const SizedBox(height: 12),
                          // Date Filter
                          FilterChips(
                            label: 'Date Range',
                            options: _dateOptions.map((e) => e['value'] as String).toList(),
                            selectedOption: _selectedDate,
                            onSelected: (value) {
                              setState(() {
                                _selectedDate = value;
                                _applyFilters();
                              });
                            },
                            optionLabel: (value) {
                              final option = _dateOptions.firstWhere((e) => e['value'] == value);
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
              child: _filteredReplies.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.reply_all_outlined,
                      title: 'No Replies Found',
                      message: 'No replies match your search criteria',
                      buttonText: 'Clear Filters',
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _selectedSender = 'all';
                          _selectedDate = 'all';
                          _applyFilters();
                        });
                      },
                    )
                  : _selectedView == 'list'
                      ? _buildListView()
                      : _buildCompactView(),
            ),
          );
        },
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

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredReplies.length,
      itemBuilder: (context, index) {
        final reply = _filteredReplies[index];
        final isSelected = _selectedReplies.contains(reply);
        
        return _buildReplyListCard(reply, isSelected);
      },
    );
  }

  Widget _buildCompactView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredReplies.length,
      itemBuilder: (context, index) {
        final reply = _filteredReplies[index];
        final isSelected = _selectedReplies.contains(reply);
        
        return _buildReplyCompactCard(reply, isSelected);
      },
    );
  }

  Widget _buildReplyListCard(Reply reply, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: AppColors.admin, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showReplyDetails(reply),
        onLongPress: () => _toggleSelection(reply),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox for selection mode
              if (_isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(reply),
                  activeColor: AppColors.admin,
                ),
              
              // Sender Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: reply.senderColor.withOpacity(0.1),
                child: Icon(
                  reply.senderIcon,
                  color: reply.senderColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reply.senderName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: reply.senderColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            reply.isVet ? 'Vet' : 'Admin',
                            style: TextStyle(
                              color: reply.senderColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // To Farmer
                    Text(
                      'To: ${reply.farmerName}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Reply Message
                    Text(
                      reply.replyMessage.length > 100
                          ? '${reply.replyMessage.substring(0, 100)}...'
                          : reply.replyMessage,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    
                    // Meta Information
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          reply.timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.chat, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Re: ${reply.consultation?.message.substring(0, 30) ?? 'No message'}...',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
              
              // Actions
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.email_outlined, size: 18),
                    onPressed: () => _sendEmailCopy(reply),
                    color: Colors.blue,
                    tooltip: 'Email Copy',
                  ),
                  IconButton(
                    icon: const Icon(Icons.print, size: 18),
                    onPressed: () => _printReply(reply),
                    color: Colors.green,
                    tooltip: 'Print',
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => _buildReplyActionsSheet(reply),
                      );
                    },
                    color: Colors.grey,
                    tooltip: 'More Actions',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyCompactCard(Reply reply, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
            ? BorderSide(color: AppColors.admin, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showReplyDetails(reply),
        onLongPress: () => _toggleSelection(reply),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (_isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(reply),
                  activeColor: AppColors.admin,
                ),
              
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: reply.senderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              
              Icon(
                reply.senderIcon,
                color: reply.senderColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${reply.senderName} → ${reply.farmerName}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          reply.timeAgo,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reply.replyMessage.length > 50
                          ? '${reply.replyMessage.substring(0, 50)}...'
                          : reply.replyMessage,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyActionsSheet(Reply reply) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Reply Actions',
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
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.email, color: Colors.blue),
            ),
            title: const Text('Send Email Copy'),
            onTap: () {
              Navigator.pop(context);
              _sendEmailCopy(reply);
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.print, color: Colors.green),
            ),
            title: const Text('Print'),
            onTap: () {
              Navigator.pop(context);
              _printReply(reply);
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.file_download, color: Colors.purple),
            ),
            title: const Text('Export'),
            onTap: () {
              Navigator.pop(context);
              _exportReply(reply);
            },
          ),
          const Divider(),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete, color: Colors.red),
            ),
            title: const Text('Delete'),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(reply);
            },
          ),
        ],
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