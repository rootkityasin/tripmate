import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../services/map_tile_service.dart';
import '../../constants/app_styles.dart';

class NewTripPage extends StatefulWidget {
  const NewTripPage({super.key});

  @override
  State<NewTripPage> createState() => _NewTripPageState();
}

class _NewTripPageState extends State<NewTripPage> {
  final TextEditingController _searchController = TextEditingController();
  MapTileService? _mapTileService;
  List<TripDestination> _filteredDestinations = [];
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _downloadingDestination;
  String _selectedCategory = 'all'; // Track selected category filter

  // Famous trip destinations in Bangladesh
  static final List<TripDestination> _bangladeshDestinations = [
    TripDestination(
      name: 'Bandarban',
      description: 'Hill tracts with beautiful mountains and waterfalls',
      image: '🏔️',
      region: 'Chittagong Hill Tracts',
      coordinates: const LatLng(22.1953, 92.2184),
      category: 'Camping',
      attractions: [
        'Nilgiri Hills',
        'Golden Temple',
        'Boga Lake',
        'Chimbuk Hill',
      ],
    ),
    TripDestination(
      name: 'Cox\'s Bazar',
      description: 'World\'s longest natural sandy beach',
      image: '🏖️',
      region: 'Chittagong',
      coordinates: const LatLng(21.4272, 92.0058),
      category: 'Beach',
      attractions: [
        'Cox\'s Bazar Beach',
        'Himchari',
        'Inani Beach',
        'Saint Martin\'s Island',
      ],
    ),
    TripDestination(
      name: 'Rangamati',
      description: 'Lake district with tribal culture and hanging bridge',
      image: '🛶',
      region: 'Chittagong Hill Tracts',
      coordinates: const LatLng(22.6504, 92.1751),
      category: 'Camping',
      attractions: [
        'Kaptai Lake',
        'Hanging Bridge',
        'Tribal Cultural Institute',
        'Shuvolong Waterfall',
      ],
    ),
    TripDestination(
      name: 'Khagrachari',
      description: 'Pristine hills and tribal heritage',
      image: '🌲',
      region: 'Chittagong Hill Tracts',
      coordinates: const LatLng(23.1193, 91.9847),
      category: 'Camping',
      attractions: [
        'Alutila Cave',
        'Richhang Waterfall',
        'Toichangya Village',
        'Panchari',
      ],
    ),
    TripDestination(
      name: 'Sylhet',
      description: 'Tea gardens and spiritual sites',
      image: '🍃',
      region: 'Sylhet',
      coordinates: const LatLng(24.8949, 91.8687),
      category: 'City',
      attractions: [
        'Ratargul Swamp Forest',
        'Jaflong',
        'Tea Gardens',
        'Hazrat Shah Jalal Mazar',
      ],
    ),
    TripDestination(
      name: 'Sundarban',
      description: 'World\'s largest mangrove forest and Royal Bengal Tigers',
      image: '🐅',
      region: 'Khulna',
      coordinates: const LatLng(22.4419, 89.1847),
      category: 'Camping',
      attractions: [
        'Tiger spotting',
        'Mangrove forests',
        'Kotka Beach',
        'Hiron Point',
      ],
    ),
    TripDestination(
      name: 'Sreemangal',
      description: 'Tea capital of Bangladesh with lush green landscapes',
      image: '☕',
      region: 'Sylhet',
      coordinates: const LatLng(24.3065, 91.7296),
      category: 'Camping',
      attractions: [
        'Lawachara National Park',
        'Tea Gardens',
        'Madhabpur Lake',
        'Ham Ham Waterfall',
      ],
    ),
    TripDestination(
      name: 'Kuakata',
      description: 'Panoramic sea beach with sunrise and sunset views',
      image: '🌅',
      region: 'Barisal',
      coordinates: const LatLng(21.8174, 90.1198),
      category: 'Beach',
      attractions: [
        'Kuakata Beach',
        'Fatrar Char',
        'Rakhine Village',
        'Keramat Ali Jame Mosque',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredDestinations = _bangladeshDestinations;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterDestinations([String? query]) {
    setState(() {
      final searchQuery = query ?? _searchController.text;
      
      _filteredDestinations = _bangladeshDestinations
          .where((destination) {
            // Apply search filter
            final matchesSearch = searchQuery.isEmpty ||
                destination.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                destination.region.toLowerCase().contains(searchQuery.toLowerCase()) ||
                destination.description.toLowerCase().contains(searchQuery.toLowerCase());
            
            // Apply category filter
            final matchesCategory = _selectedCategory == 'all' || 
                destination.category.toLowerCase() == _selectedCategory.toLowerCase();
            
            return matchesSearch && matchesCategory;
          })
          .toList();
    });
  }

  void _selectCategory(String category) {
    setState(() {
      if (category.toLowerCase() == 'all') {
        _selectedCategory = 'all';
      } else {
        _selectedCategory = category.toLowerCase();
      }
    });
    _filterDestinations();
  }

  Future<MapTileService?> _getMapTileService() async {
    if (_mapTileService == null) {
      try {
        _mapTileService = MapTileService();
        await _mapTileService!.initialize();

        // Check if service is in memory-only mode
        final cacheStatus = await _mapTileService!.getCacheStatus();
        if (cacheStatus['cacheDirectory'] ==
            'Memory only (no file system access)') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Running in memory-only mode. Maps will be downloaded from internet each time.',
                ),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (e) {
        print('Error initializing MapTileService: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Map service initialization failed. Download feature disabled.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return null;
      }
    }
    return _mapTileService!;
  }

  Future<void> _downloadDestinationMaps(TripDestination destination) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadingDestination = destination.name;
    });

    try {
      final mapService = await _getMapTileService();

      if (mapService == null) {
        // Service initialization failed, skip download but still create trip
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${destination.name} trip created (maps not downloaded)',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          _startTrip(destination);
        }
        return;
      }

      await mapService.downloadDestinationTiles(
        destination.coordinates,
        destination.name,
        onProgress: (current, total) {
          setState(() {
            _downloadProgress = current / total;
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${destination.name} maps downloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to the trip page with this destination
        _startTrip(destination);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
        _downloadingDestination = null;
      });
    }
  }

  void _startTrip(TripDestination destination) {
    // TODO: Navigate to trip planning page with selected destination
    Navigator.pop(context, destination);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Destination'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: AppStyles.primaryColor.withOpacity(0.1),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterDestinations,
                          decoration: InputDecoration(
                            hintText: 'Search destination and explore',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: Colors.grey[700],
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isDownloading) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Downloading $_downloadingDestination maps...',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _downloadProgress,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppStyles.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(_downloadProgress * 100).toStringAsFixed(1)}% complete',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Explore by category section
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore by category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildCategoryCard(
                        'All',
                        Icons.apps_rounded,
                        const Color(0xFF8E8E93),
                        _selectedCategory == 'all',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCategoryCard(
                        'Beach',
                        Icons.beach_access_rounded,
                        const Color(0xFF007AFF),
                        _selectedCategory == 'beach',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCategoryCard(
                        'Camping',
                        Icons.nature_people_rounded,
                        const Color(0xFF34C759),
                        _selectedCategory == 'camping',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCategoryCard(
                        'City',
                        Icons.location_city_rounded,
                        const Color(0xFFFF9500),
                        _selectedCategory == 'city',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _filteredDestinations.length,
              itemBuilder: (context, index) {
                final destination = _filteredDestinations[index];
                final isDownloading =
                    _downloadingDestination == destination.name;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isDownloading ? null : () => _startTrip(destination),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                destination.image,
                                style: const TextStyle(fontSize: 32),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      destination.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      destination.region,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppStyles.primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: isDownloading
                                    ? null
                                    : () =>
                                          _downloadDestinationMaps(destination),
                                icon: Icon(
                                  isDownloading
                                      ? Icons.hourglass_empty
                                      : Icons.download,
                                  color: isDownloading
                                      ? Colors.grey
                                      : AppStyles.primaryColor,
                                ),
                                tooltip: 'Download offline maps',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            destination.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Popular Attractions:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: destination.attractions.map((attraction) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppStyles.primaryColor.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  attraction,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppStyles.primaryColor,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color, bool isActive) {
    return GestureDetector(
      onTap: () => _selectCategory(title),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TripDestination {
  final String name;
  final String description;
  final String image;
  final String region;
  final LatLng coordinates;
  final List<String> attractions;
  final String category; // Beach, Camping, City, etc.

  const TripDestination({
    required this.name,
    required this.description,
    required this.image,
    required this.region,
    required this.coordinates,
    required this.attractions,
    required this.category,
  });
}
