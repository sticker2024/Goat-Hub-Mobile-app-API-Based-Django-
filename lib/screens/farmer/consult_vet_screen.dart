import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/consultation_provider.dart';
import '../../models/user.dart';
import '../../core/constants/colors.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../shared/widgets/loading_widget.dart';

class ConsultVetScreen extends StatefulWidget {
  const ConsultVetScreen({super.key});

  @override
  State<ConsultVetScreen> createState() => _ConsultVetScreenState();
}

class _ConsultVetScreenState extends State<ConsultVetScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _locationController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  File? _selectedImage;
  bool _isLoading = false;
  bool _isUrgent = false;
  String? _selectedCategory;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'general', 'label': 'General Health', 'icon': Icons.health_and_safety, 'color': Colors.green},
    {'id': 'emergency', 'label': 'Emergency', 'icon': Icons.warning, 'color': Colors.red},
    {'id': 'vaccination', 'label': 'Vaccination', 'icon': Icons.vaccines, 'color': Colors.blue},
    {'id': 'nutrition', 'label': 'Nutrition', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'id': 'reproduction', 'label': 'Reproduction', 'icon': Icons.pets, 'color': Colors.purple},
    {'id': 'other', 'label': 'Other', 'icon': Icons.help, 'color': Colors.grey},
  ];

  final List<String> _quickSymptoms = [
    'Loss of appetite',
    'Limping',
    'Coughing',
    'Diarrhea',
    'Fever',
    'Skin issues',
    'Bloating',
    'Weakness',
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _prefillForm();
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

  void _prefillForm() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser as Farmer?;
    
    if (user != null) {
      _locationController.text = user.district;
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

  void _addSymptom(String symptom) {
    final currentText = _messageController.text;
    if (currentText.isEmpty) {
      _messageController.text = symptom;
    } else {
      _messageController.text = '$currentText\n- $symptom';
    }
  }

  Future<void> _submitConsultation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      Helpers.showSnackBar(
        context,
        'Please select a category',
        type: SnackBarType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final consultationProvider = Provider.of<ConsultationProvider>(context, listen: false);
    
    final user = authProvider.currentUser as Farmer?;
    
    if (user == null) {
      Helpers.showSnackBar(
        context,
        'You must be logged in',
        type: SnackBarType.error,
      );
      setState(() => _isLoading = false);
      return;
    }

    final consultationData = {
      'full_name': user.fullName,
      'phone_number': user.phone,
      'location': _locationController.text,
      'message': _messageController.text,
      'category': _selectedCategory,
      'is_urgent': _isUrgent,
    };

    final success = await consultationProvider.createConsultation(
      consultationData,
      imageFile: _selectedImage,
    );
    
    setState(() => _isLoading = false);

    if (success && mounted) {
      Helpers.showSnackBar(
        context,
        _isUrgent 
            ? 'Urgent consultation submitted! A vet will respond shortly.'
            : 'Consultation submitted successfully!',
        type: SnackBarType.success,
      );
      
      // Show success dialog
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Consultation Submitted!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isUrgent
                  ? 'A veterinarian will attend to your urgent case immediately.'
                  : 'You will receive a response within 24 hours.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/get-response');
            },
            child: const Text('View Responses'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consult a Veterinarian'),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Submitting consultation...')
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Urgent Toggle
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SwitchListTile(
                          title: const Text(
                            'Mark as Urgent',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: const Text(
                            'Check this for emergency cases requiring immediate attention',
                          ),
                          value: _isUrgent,
                          onChanged: (value) {
                            setState(() {
                              _isUrgent = value;
                            });
                          },
                          activeThumbColor: Colors.red,
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isUrgent ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.warning,
                              color: _isUrgent ? Colors.red : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category Selection
                      const Text(
                        'Select Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final isSelected = _selectedCategory == category['id'];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category['id'];
                                });
                              },
                              child: Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? (category['color'] as Color).withOpacity(0.1)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected 
                                        ? category['color'] 
                                        : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      category['icon'],
                                      color: isSelected ? category['color'] : Colors.grey,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      category['label'],
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isSelected ? category['color'] : Colors.grey,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Location
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Location',
                          hintText: 'Enter your location',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: Validators.required,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Quick Symptoms
                      const Text(
                        'Quick Symptoms',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _quickSymptoms.length,
                          itemBuilder: (context, index) {
                            final symptom = _quickSymptoms[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(symptom),
                                onPressed: () => _addSymptom(symptom),
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                labelStyle: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Message
                      TextFormField(
                        controller: _messageController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          labelText: 'Describe your issue',
                          hintText: 'Please describe your goat\'s symptoms in detail...',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please describe your issue';
                          }
                          if (value.length < 20) {
                            return 'Please provide more details (at least 20 characters)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Image Attachment
                      const Text(
                        'Add Image (Optional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _selectedImage != null 
                                  ? Colors.green 
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _selectedImage != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
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
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _selectedImage = null;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
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
                                      'Tap to add an image',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'JPG, PNG (Max 5MB)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _submitConsultation,
                          icon: Icon(_isUrgent ? Icons.warning : Icons.send),
                          label: Text(
                            _isUrgent ? 'Submit Urgent Request' : 'Submit Consultation',
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isUrgent ? Colors.red : AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tips Card
                      _buildTipsCard(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTipsCard() {
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
                Icon(Icons.lightbulb_outline, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Tips for a Good Consultation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTip('Be specific about symptoms and when they started'),
            _buildTip('Mention any medications you\'ve already tried'),
            _buildTip('Include your goat\'s age, breed, and recent activities'),
            _buildTip('Take clear photos of affected areas if possible'),
            _buildTip('Provide your accurate contact information'),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Consultations'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('• Responses are typically provided within 24 hours'),
            Text('• Urgent cases are prioritized and handled faster'),
            Text('• You can attach up to 1 image per consultation'),
            Text('• All consultations are reviewed by licensed veterinarians'),
            Text('• Follow-up questions can be asked in the same thread'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}