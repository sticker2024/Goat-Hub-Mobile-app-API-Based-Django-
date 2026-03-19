import 'package:flutter/material.dart';
import 'package:goathub/models/consultation.dart';
import 'package:goathub/models/user.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/consultation_provider.dart';
import '../../core/constants/colors.dart';
import '../../utils/helpers.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart';

class ReplyConsultationScreen extends StatefulWidget {
  final int consultationId;
  final String? template;

  const ReplyConsultationScreen({
    super.key,
    required this.consultationId,
    this.template,
  });

  @override
  State<ReplyConsultationScreen> createState() => _ReplyConsultationScreenState();
}

class _ReplyConsultationScreenState extends State<ReplyConsultationScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _replyController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _prescriptionController = TextEditingController();
  final _followUpController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  File? _selectedImage;
  bool _isLoading = false;
  bool _isSending = false;
  Consultation? _consultation;
  String? _error;
  
  // Reply options
  bool _markAsResolved = false;
  bool _sendCopyToEmail = false;
  bool _requestFollowUp = false;
  String _selectedUrgency = 'normal';
  
  // Quick response templates
  final List<Map<String, String>> _quickTemplates = [
    {
      'title': 'General Advice',
      'content': 'Based on the symptoms described, I recommend monitoring your goat closely. Ensure it has access to clean water and is kept in a clean environment. If symptoms persist for more than 24 hours, please consult a local veterinarian.',
    },
    {
      'title': 'Medication',
      'content': 'I recommend administering [MEDICATION] at a dosage of [DOSAGE] twice daily for [DURATION] days. Please ensure you follow the dosage instructions carefully and monitor for any adverse reactions.',
    },
    {
      'title': 'Emergency',
      'content': 'The symptoms you described require immediate attention. Please take your goat to the nearest veterinary clinic immediately or contact emergency services.',
    },
    {
      'title': 'Follow-up',
      'content': 'Thank you for your consultation. Please follow these recommendations and update me on your goat\'s condition in [NUMBER] days. If you notice any worsening of symptoms, please consult immediately.',
    },
  ];

  final List<String> _urgencyLevels = ['low', 'normal', 'high', 'emergency'];
  final Map<String, Color> _urgencyColors = {
    'low': Colors.blue,
    'normal': Colors.green,
    'high': Colors.orange,
    'emergency': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadConsultation();
    
    // Pre-fill template if provided
    if (widget.template != null) {
      _replyController.text = widget.template!;
    }
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

  Future<void> _loadConsultation() async {
    setState(() => _isLoading = true);

    final consultationProvider = context.read<ConsultationProvider>();
    await consultationProvider.loadConsultations();
    
    final consultation = consultationProvider.consultations.firstWhere(
      (c) => c.consultationId == widget.consultationId,
      orElse: () => throw Exception('Consultation not found'),
    );

    // Load replies for this consultation
    await consultationProvider.loadConsultationReplies(widget.consultationId);

    if (mounted) {
      setState(() {
        _consultation = consultation;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      
      Helpers.showSnackBar(
        context,
        'Image selected successfully',
        type: SnackBarType.success,
      );
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      
      Helpers.showSnackBar(
        context,
        'Photo captured successfully',
        type: SnackBarType.success,
      );
    }
  }

  void _showImageSourceDialog() {
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
              'Add Image',
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
                child: const Icon(Icons.photo_library, color: Colors.blue),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.green),
              ),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _applyTemplate(String template) {
    setState(() {
      _replyController.text = template;
    });
  }

  void _showTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Templates'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _quickTemplates.length,
            itemBuilder: (context, index) {
              final template = _quickTemplates[index];
              return ListTile(
                title: Text(template['title']!),
                subtitle: Text(
                  '${template['content']!.substring(0, 50)}...',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _applyTemplate(template['content']!);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReply() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSending = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final consultationProvider = Provider.of<ConsultationProvider>(context, listen: false);
    
    final vet = authProvider.currentUser as Veterinarian?;
    
    if (vet == null) {
      Helpers.showSnackBar(
        context,
        'You must be logged in to reply',
        type: SnackBarType.error,
      );
      setState(() => _isSending = false);
      return;
    }

    // Build comprehensive reply message
    final replyParts = <String>[];
    
    if (_diagnosisController.text.isNotEmpty) {
      replyParts.add('**Diagnosis:** ${_diagnosisController.text}');
    }
    
    if (_treatmentController.text.isNotEmpty) {
      replyParts.add('**Treatment:** ${_treatmentController.text}');
    }
    
    if (_prescriptionController.text.isNotEmpty) {
      replyParts.add('**Prescription:** ${_prescriptionController.text}');
    }
    
    if (_replyController.text.isNotEmpty) {
      replyParts.add(_replyController.text);
    }
    
    if (_followUpController.text.isNotEmpty) {
      replyParts.add('**Follow-up:** ${_followUpController.text}');
    }
    
    final fullMessage = replyParts.join('\n\n');

    final replyData = {
      'consultation_id': widget.consultationId,
      'farmer_name': _consultation?.fullName ?? '',
      'reply_message': fullMessage,
      'sender_name': 'Dr. ${vet.fullName}',
      'urgency': _selectedUrgency,
      'request_follow_up': _requestFollowUp,
    };

    final success = await consultationProvider.createReply(
      replyData,
      imageFile: _selectedImage,
    );

    setState(() => _isSending = false);

    if (success && mounted) {
      // If mark as resolved, update consultation status
      if (_markAsResolved) {
        // TODO: Implement mark as resolved API call
      }

      // Send email copy if requested
      if (_sendCopyToEmail) {
        // TODO: Implement email sending
      }

      Helpers.showSnackBar(
        context,
        'Reply sent successfully!',
        type: SnackBarType.success,
      );
      
      // Navigate back to consultations
      context.pop();
    }
  }

  void _showPreview() {
    final replyParts = <String>[];
    
    if (_diagnosisController.text.isNotEmpty) {
      replyParts.add('**Diagnosis:** ${_diagnosisController.text}');
    }
    
    if (_treatmentController.text.isNotEmpty) {
      replyParts.add('**Treatment:** ${_treatmentController.text}');
    }
    
    if (_prescriptionController.text.isNotEmpty) {
      replyParts.add('**Prescription:** ${_prescriptionController.text}');
    }
    
    if (_replyController.text.isNotEmpty) {
      replyParts.add(_replyController.text);
    }
    
    if (_followUpController.text.isNotEmpty) {
      replyParts.add('**Follow-up:** ${_followUpController.text}');
    }
    
    final previewMessage = replyParts.join('\n\n');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply Preview'),
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                previewMessage.isEmpty ? 'No content to preview' : previewMessage,
                style: const TextStyle(height: 1.5),
              ),
              if (_selectedImage != null) ...[
                const SizedBox(height: 16),
                const Text('Attached Image:'),
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitReply();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vet,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading consultation...');
    }

    if (_error != null) {
      return CustomErrorWidget(
        message: _error!,
        onRetry: _loadConsultation,
      );
    }

    if (_consultation == null) {
      return const Center(
        child: Text('Consultation not found'),
      );
    }

    final isUrgent = _consultation!.status == 'pending' && 
        DateTime.now().difference(_consultation!.createdAt).inHours > 24;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reply to Consultation'),
        backgroundColor: AppColors.vet,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Preview button
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            onPressed: _showPreview,
            tooltip: 'Preview Reply',
          ),
          // Templates button
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: _showTemplateDialog,
            tooltip: 'Quick Templates',
          ),
        ],
      ),
      body: _isSending
          ? const LoadingWidget(message: 'Sending reply...')
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Consultation Summary Card
                      _buildConsultationSummary(isUrgent),
                      const SizedBox(height: 24),

                      // Professional Reply Form
                      _buildProfessionalForm(),
                      const SizedBox(height: 24),

                      // Image Attachment
                      _buildImageAttachment(),
                      const SizedBox(height: 24),

                      // Reply Options
                      _buildReplyOptions(),
                      const SizedBox(height: 24),

                      // Urgency Level
                      _buildUrgencySelector(),
                      const SizedBox(height: 24),

                      // Action Buttons
                      _buildActionButtons(),
                      const SizedBox(height: 16),

                      // Professional Guidelines
                      _buildGuidelines(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildConsultationSummary(bool isUrgent) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isUrgent
              ? Border.all(color: Colors.red, width: 2)
              : null,
        ),
        child: Column(
          children: [
            // Header with status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isUrgent ? Colors.red : AppColors.vet).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isUrgent ? Icons.warning : Icons.info_outline,
                    color: isUrgent ? Colors.red : AppColors.vet,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isUrgent ? 'Urgent Case - Respond ASAP' : 'Consultation Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isUrgent ? Colors.red : AppColors.vet,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _consultation!.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _consultation!.statusDisplay,
                      style: TextStyle(
                        color: _consultation!.statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Farmer info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.vet.withOpacity(0.1),
                        child: Text(
                          Helpers.getInitials(_consultation!.fullName),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.vet,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _consultation!.fullName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _consultation!.location,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _consultation!.phoneNumber,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
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

                  const SizedBox(height: 16),

                  // Original message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Farmer\'s Message:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _consultation!.message,
                          style: const TextStyle(height: 1.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Submitted: ${DateFormat('MMM dd, yyyy HH:mm').format(_consultation!.createdAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Image if available
                  if (_consultation!.imageUrl != null) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _showFullScreenImage(_consultation!.imageUrl!),
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(_consultation!.imageUrl!),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Professional Response',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Diagnosis
            TextFormField(
              controller: _diagnosisController,
              decoration: InputDecoration(
                labelText: 'Diagnosis',
                hintText: 'e.g., Respiratory infection, Parasitic infestation...',
                prefixIcon: const Icon(Icons.medical_information_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Treatment
            TextFormField(
              controller: _treatmentController,
              decoration: InputDecoration(
                labelText: 'Treatment Plan',
                hintText: 'Describe the recommended treatment...',
                prefixIcon: const Icon(Icons.healing_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            // Prescription
            TextFormField(
              controller: _prescriptionController,
              decoration: InputDecoration(
                labelText: 'Prescription (if any)',
                hintText: 'Medication name, dosage, frequency...',
                prefixIcon: const Icon(Icons.medical_services_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Additional Notes
            TextFormField(
              controller: _replyController,
              decoration: InputDecoration(
                labelText: 'Additional Notes / Advice',
                hintText: 'Add any additional instructions or recommendations...',
                prefixIcon: const Icon(Icons.note_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 4,
              validator: (value) {
                if ((value == null || value.isEmpty) && 
                    _diagnosisController.text.isEmpty && 
                    _treatmentController.text.isEmpty) {
                  return 'Please provide some response';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Follow-up Instructions
            TextFormField(
              controller: _followUpController,
              decoration: InputDecoration(
                labelText: 'Follow-up Instructions',
                hintText: 'When should the farmer follow up? What to monitor?',
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageAttachment() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Attachments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Optional',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Image preview
            if (_selectedImage != null)
              SizedBox(
                height: 150,
                width: double.infinity,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo_library, size: 30),
                      onPressed: _pickImage,
                      color: AppColors.vet,
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(Icons.camera_alt, size: 30),
                      onPressed: _takePhoto,
                      color: AppColors.vet,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),
            Text(
              'Supported formats: JPG, PNG. Max size: 5MB',
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

  Widget _buildReplyOptions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CheckboxListTile(
              title: const Text('Mark as resolved'),
              subtitle: const Text('Close this consultation after replying'),
              value: _markAsResolved,
              onChanged: (value) {
                setState(() {
                  _markAsResolved = value ?? false;
                });
              },
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, color: Colors.green),
              ),
            ),
            CheckboxListTile(
              title: const Text('Send copy to email'),
              subtitle: const Text('Email a copy of this reply to yourself'),
              value: _sendCopyToEmail,
              onChanged: (value) {
                setState(() {
                  _sendCopyToEmail = value ?? false;
                });
              },
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.email_outlined, color: Colors.blue),
              ),
            ),
            CheckboxListTile(
              title: const Text('Request follow-up'),
              subtitle: const Text('Ask farmer to follow up in specified time'),
              value: _requestFollowUp,
              onChanged: (value) {
                setState(() {
                  _requestFollowUp = value ?? false;
                });
              },
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_today_outlined, color: Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgencySelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Response Urgency',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _urgencyLevels.map((level) {
                final isSelected = _selectedUrgency == level;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedUrgency = level;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _urgencyColors[level]!.withOpacity(0.2)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? _urgencyColors[level]!
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _getUrgencyIcon(level),
                            color: isSelected ? _urgencyColors[level] : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            level.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? _urgencyColors[level] : Colors.grey,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getUrgencyIcon(String level) {
    switch (level) {
      case 'low':
        return Icons.arrow_downward;
      case 'normal':
        return Icons.remove;
      case 'high':
        return Icons.arrow_upward;
      case 'emergency':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _submitReply,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vet,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Send Reply'),
          ),
        ),
      ],
    );
  }

  Widget _buildGuidelines() {
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
          Row(
            children: [
              Icon(Icons.gavel_outlined, color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 8),
              Text(
                'Professional Guidelines',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGuideline('Provide clear, actionable advice'),
          _buildGuideline('Include dosage instructions when prescribing'),
          _buildGuideline('Mention warning signs requiring immediate attention'),
          _buildGuideline('Suggest follow-up timeline'),
          _buildGuideline('Be professional and empathetic'),
        ],
      ),
    );
  }

  Widget _buildGuideline(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.blue.shade700)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
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

  @override
  void dispose() {
    _animationController.dispose();
    _replyController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _prescriptionController.dispose();
    _followUpController.dispose();
    super.dispose();
  }
}