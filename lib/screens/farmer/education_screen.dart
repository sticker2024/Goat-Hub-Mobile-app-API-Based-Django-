import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/colors.dart';
import '../../utils/helpers.dart';
class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';
  
  final List<Category> _categories = [
    Category(id: 'all', name: 'All', icon: Icons.grid_view, color: AppColors.primary),
    Category(id: 'health', name: 'Health', icon: Icons.health_and_safety, color: Colors.green),
    Category(id: 'nutrition', name: 'Nutrition', icon: Icons.restaurant, color: Colors.orange),
    Category(id: 'breeding', name: 'Breeding', icon: Icons.pets, color: Colors.purple),
    Category(id: 'diseases', name: 'Diseases', icon: Icons.sick, color: Colors.red),
    Category(id: 'management', name: 'Management', icon: Icons.agriculture, color: Colors.brown),
    Category(id: 'vaccination', name: 'Vaccination', icon: Icons.vaccines, color: Colors.blue),
  ];

  final List<Resource> _featuredResources = [
    Resource(
      id: 1,
      title: 'Complete Guide to Goat Health',
      description: 'A comprehensive guide covering all aspects of goat health management.',
      imageUrl: 'assets/images/health_guide.jpg',
      readTime: 15,
      category: 'health',
      views: 15234,
      likes: 1234,
    ),
    Resource(
      id: 2,
      title: 'Understanding Goat Nutrition',
      description: 'Learn about balanced diets, supplements, and feeding schedules.',
      imageUrl: 'assets/images/nutrition.jpg',
      readTime: 12,
      category: 'nutrition',
      views: 10234,
      likes: 987,
    ),
  ];

  final List<Resource> _allResources = [
    Resource(
      id: 3,
      title: 'Common Goat Diseases',
      description: 'Identify and treat common diseases in goats.',
      imageUrl: 'assets/images/diseases.jpg',
      readTime: 10,
      category: 'diseases',
      views: 8234,
      likes: 756,
    ),
    Resource(
      id: 4,
      title: 'Breeding Best Practices',
      description: 'Tips for successful breeding and kidding management.',
      imageUrl: 'assets/images/breeding.jpg',
      readTime: 14,
      category: 'breeding',
      views: 7234,
      likes: 645,
    ),
    Resource(
      id: 5,
      title: 'Vaccination Schedule',
      description: 'Complete vaccination guide for goats of all ages.',
      imageUrl: 'assets/images/vaccination.jpg',
      readTime: 8,
      category: 'vaccination',
      views: 11234,
      likes: 1023,
    ),
    Resource(
      id: 6,
      title: 'Farm Management Calendar',
      description: 'Year-round management tasks and planning.',
      imageUrl: 'assets/images/calendar.jpg',
      readTime: 20,
      category: 'management',
      views: 6234,
      likes: 534,
    ),
  ];

  final List<Video> _videos = [
    Video(
      id: 1,
      title: 'How to Check Vital Signs',
      thumbnail: 'assets/images/video1.jpg',
      duration: '5:30',
      views: 12345,
      youtubeId: 'abc123',
    ),
    Video(
      id: 2,
      title: 'Hoof Trimming Guide',
      thumbnail: 'assets/images/video2.jpg',
      duration: '8:45',
      views: 9876,
      youtubeId: 'def456',
    ),
    Video(
      id: 3,
      title: 'Signs of Illness',
      thumbnail: 'assets/images/video3.jpg',
      duration: '6:15',
      views: 8765,
      youtubeId: 'ghi789',
    ),
    Video(
      id: 4,
      title: 'Proper Feeding Techniques',
      thumbnail: 'assets/images/video4.jpg',
      duration: '7:20',
      views: 7654,
      youtubeId: 'jkl012',
    ),
  ];

  final List<FAQ> _faqs = [
    FAQ(
      question: 'How often should I vaccinate my goats?',
      answer: 'Vaccination schedules vary by region and disease risk. Generally, core vaccines are given annually, with boosters as recommended by your veterinarian.',
    ),
    FAQ(
      question: 'What are signs of a sick goat?',
      answer: 'Common signs include loss of appetite, lethargy, fever, diarrhea, coughing, and isolation from the herd.',
    ),
    FAQ(
      question: 'How much water do goats need?',
      answer: 'Adult goats typically need 2-4 gallons of water per day, more in hot weather or when lactating.',
    ),
    FAQ(
      question: 'When should I deworm my goats?',
      answer: 'Deworming schedules depend on your location and parasite pressure. Consult your vet for a targeted deworming program.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  List<Resource> get _filteredResources {
    return _allResources.where((r) {
      final matchesSearch = _searchQuery.isEmpty ||
          r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'all' || r.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> _launchYouTube(String videoId) async {
    final url = 'https://www.youtube.com/watch?v=$videoId';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      Helpers.showSnackBar(
        context,
        'Could not launch video',
        type: SnackBarType.error,
      );
    }
  }

  void _showResourceDetails(Resource resource) {
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
          return _buildResourceDetailsSheet(resource, scrollController);
        },
      ),
    );
  }

  Widget _buildResourceDetailsSheet(Resource resource, ScrollController controller) {
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
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(resource.category),
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${resource.readTime} min read',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.remove_red_eye, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${resource.views} views',
                          style: TextStyle(color: Colors.grey.shade600),
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
                // Description
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
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        resource.description * 3, // Simulated full content
                        style: const TextStyle(height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Key Points
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Key Points',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildKeyPoint('Regular health checks are essential'),
                      _buildKeyPoint('Keep vaccination records updated'),
                      _buildKeyPoint('Monitor for early signs of illness'),
                      _buildKeyPoint('Maintain clean living conditions'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Related Resources
                const Text(
                  'Related Resources',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Related Article ${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Short description here...',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
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
                    Helpers.showSnackBar(
                      context,
                      'Resource saved to your library',
                      type: SnackBarType.success,
                    );
                  },
                  icon: const Icon(Icons.bookmark),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyPoint(String point) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(point)),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final cat = _categories.firstWhere(
      (c) => c.id == category,
      orElse: () => _categories.first,
    );
    return cat.icon;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Educational Resources'),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Resources'),
            Tab(text: 'Videos'),
            Tab(text: 'FAQs'),
            Tab(text: 'Saved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResourcesTab(),
          _buildVideosTab(),
          _buildFaqsTab(),
          _buildSavedTab(),
        ],
      ),
    );
  }

  Widget _buildResourcesTab() {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search resources...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 12),
              
              // Categories
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(category.name),
                        avatar: Icon(
                          category.icon,
                          size: 16,
                          color: isSelected ? Colors.white : category.color,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category.id;
                          });
                        },
                        selectedColor: category.color,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Featured Section
        if (_searchQuery.isEmpty && _selectedCategory == 'all')
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _featuredResources.length,
              itemBuilder: (context, index) {
                final resource = _featuredResources[index];
                return Container(
                  width: 300,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showResourceDetails(resource),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'FEATURED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              resource.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              resource.description,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  '${resource.readTime} min',
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.remove_red_eye, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  '${resource.views}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // Resources Grid
        Expanded(
          child: _filteredResources.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No resources found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _filteredResources.length,
                  itemBuilder: (context, index) {
                    final resource = _filteredResources[index];
                    return _buildResourceCard(resource);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildResourceCard(Resource resource) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showResourceDetails(resource),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(resource.category),
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                resource.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                resource.description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 10, color: Colors.grey.shade500),
                      const SizedBox(width: 2),
                      Text(
                        '${resource.readTime} min',
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.favorite, size: 10, color: Colors.red.shade300),
                      const SizedBox(width: 2),
                      Text(
                        '${resource.likes}',
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideosTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return _buildVideoCard(video);
      },
    );
  }

  Widget _buildVideoCard(Video video) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _launchYouTube(video.youtubeId),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.play_circle_fill, size: 40, color: Colors.white),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      video.duration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.remove_red_eye, size: 10, color: Colors.grey.shade500),
                      const SizedBox(width: 2),
                      Text(
                        '${video.views} views',
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _faqs.length,
      itemBuilder: (context, index) {
        final faq = _faqs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.help_outline,
                color: AppColors.primary,
                size: 16,
              ),
            ),
            title: Text(
              faq.question,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  faq.answer,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSavedTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Saved Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Resources you save will appear here',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _tabController.animateTo(0);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Browse Resources'),
          ),
        ],
      ),
    );
  }
}

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class Resource {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final int readTime;
  final String category;
  final int views;
  final int likes;

  Resource({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.readTime,
    required this.category,
    required this.views,
    required this.likes,
  });
}

class Video {
  final int id;
  final String title;
  final String thumbnail;
  final String duration;
  final int views;
  final String youtubeId;

  Video({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.duration,
    required this.views,
    required this.youtubeId,
  });
}

class FAQ {
  final String question;
  final String answer;

  FAQ({
    required this.question,
    required this.answer,
  });
}