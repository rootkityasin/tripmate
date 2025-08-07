import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:exif/exif.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../models/journal_entry.dart';
import '../../services/journal_service.dart';
import '../../services/location_service.dart';

class NewJournalEntryPage extends StatefulWidget {
  const NewJournalEntryPage({super.key});

  @override
  State<NewJournalEntryPage> createState() => _NewJournalEntryPageState();
}

class _NewJournalEntryPageState extends State<NewJournalEntryPage>
    with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final JournalService _journalService = JournalService();
  final LocationService _locationService = LocationService();
  final ImagePicker _picker = ImagePicker();

  List<XFile> _selectedImages = [];
  List<Map<String, dynamic>> _imageLocations = [];
  String _selectedMood = '😊';
  LatLng? _selectedLocation;
  String? _selectedLocationName;
  bool _isLoading = false;
  bool _showMap = false;
  late TabController _tabController;

  final List<String> _moods = [
    '😊',
    '😍',
    '🥳',
    '😎',
    '🤔',
    '😴',
    '😋',
    '🤗',
    '😌',
    '🥰',
    '😂',
    '🤩',
    '😇',
    '🤪',
    '😊',
    '🙃',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });

        // Extract location from each image
        for (XFile image in images) {
          await _extractLocationFromImage(image);
        }

        // If we found locations in images, show the map
        if (_imageLocations.isNotEmpty && !_showMap) {
          setState(() {
            _showMap = true;
            _tabController.animateTo(1);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _extractLocationFromImage(XFile image) async {
    try {
      final file = File(image.path);
      final bytes = await file.readAsBytes();
      final data = await readExifFromBytes(bytes);

      if (data.isNotEmpty) {
        final gpsLat = data['GPS GPSLatitude'];
        final gpsLatRef = data['GPS GPSLatitudeRef'];
        final gpsLon = data['GPS GPSLongitude'];
        final gpsLonRef = data['GPS GPSLongitudeRef'];

        if (gpsLat != null && gpsLon != null) {
          final lat = _convertDMSToDD(gpsLat, gpsLatRef?.toString() ?? 'N');
          final lon = _convertDMSToDD(gpsLon, gpsLonRef?.toString() ?? 'E');

          if (lat != null && lon != null) {
            final location = LatLng(lat, lon);
            final locationName = await _getLocationName(lat, lon);

            setState(() {
              _imageLocations.add({
                'imagePath': image.path,
                'location': location,
                'locationName': locationName,
              });

              // Set as selected location if it's the first one
              if (_selectedLocation == null) {
                _selectedLocation = location;
                _selectedLocationName = locationName;
              }
            });
          }
        }
      }
    } catch (e) {
      print('Error extracting location from image: $e');
    }
  }

  double? _convertDMSToDD(dynamic dms, String ref) {
    try {
      if (dms is List && dms.length >= 3) {
        final degrees = dms[0].toDouble();
        final minutes = dms[1].toDouble();
        final seconds = dms[2].toDouble();

        double dd = degrees + (minutes / 60) + (seconds / 3600);

        if (ref == 'S' || ref == 'W') {
          dd = -dd;
        }

        return dd;
      }
    } catch (e) {
      print('Error converting DMS to DD: $e');
    }
    return null;
  }

  Future<String> _getLocationName(double lat, double lon) async {
    try {
      final placemarks = await _locationService.getPlacemarkFromCoordinates(
        lat,
        lon,
      );
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.locality}, ${placemark.country}';
      }
    } catch (e) {
      print('Error getting location name: $e');
    }
    return 'Unknown Location';
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Permission.location.request();
      if (permission.isGranted) {
        final position = await Geolocator.getCurrentPosition();
        final locationName = await _getLocationName(
          position.latitude,
          position.longitude,
        );

        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _selectedLocationName = locationName;
          _showMap = true;
        });

        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      final imagePath = _selectedImages[index].path;
      _selectedImages.removeAt(index);
      _imageLocations.removeWhere((loc) => loc['imagePath'] == imagePath);

      if (_selectedImages.isEmpty) {
        _showMap = false;
        _tabController.animateTo(0);
      }
    });
  }

  Future<void> _saveEntry() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _journalService.initialize();

      final entry = JournalEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tripId: 'general', // For now, all entries go to general trip
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        photoPaths: _selectedImages.map((img) => img.path).toList(),
        mood: _selectedMood,
        timestamp: DateTime.now(),
        latitude: _selectedLocation?.latitude,
        longitude: _selectedLocation?.longitude,
        locationName: _selectedLocationName,
      );

      await _journalService.addEntry(entry);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.all(16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.orange, fontSize: 17),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'New Entry',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _saveEntry,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.orange,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            if (_showMap) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'Entry'),
                    Tab(text: 'Location'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Content
            Expanded(
              child: _showMap
                  ? TabBarView(
                      controller: _tabController,
                      children: [_buildEntryTab(), _buildLocationTab()],
                    )
                  : _buildEntryTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mood Selector
          const Text(
            'How are you feeling?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _moods.length,
              itemBuilder: (context, index) {
                final mood = _moods[index];
                final isSelected = mood == _selectedMood;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = mood),
                  child: Container(
                    width: 50,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(mood, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Title Input
          const Text(
            'Title',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Enter a title for your entry...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: const Color(0xFF2C2C2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),

          // Content Input
          const Text(
            'What happened?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            maxLines: 8,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Write about your experience...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: const Color(0xFF2C2C2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),

          // Photos Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Photos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: _pickImages,
                icon: const Icon(
                  Icons.add_photo_alternate,
                  color: Colors.orange,
                ),
                label: const Text(
                  'Add Photos',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_selectedImages.isNotEmpty) ...[
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF2C2C2E),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_selectedImages[index].path),
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Colors.white.withOpacity(0.5),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to add photos',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Location Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location, color: Colors.orange),
                label: const Text(
                  'Current Location',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),

          if (_selectedLocationName != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedLocationName!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationTab() {
    return Column(
      children: [
        // Location from images
        if (_imageLocations.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Locations from Photos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...(_imageLocations.map(
                  (imgLoc) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(imgLoc['imagePath']),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      imgLoc['locationName'],
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    trailing: Radio<LatLng>(
                      value: imgLoc['location'],
                      groupValue: _selectedLocation,
                      onChanged: (LatLng? value) {
                        setState(() {
                          _selectedLocation = value;
                          _selectedLocationName = imgLoc['locationName'];
                        });
                      },
                      activeColor: Colors.orange,
                    ),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Map
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF2C2C2E),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _selectedLocation != null
                  ? FlutterMap(
                      options: MapOptions(
                        initialCenter: _selectedLocation!,
                        initialZoom: 15.0,
                        onTap: (tapPosition, point) async {
                          final locationName = await _getLocationName(
                            point.latitude,
                            point.longitude,
                          );
                          setState(() {
                            _selectedLocation = point;
                            _selectedLocationName = locationName;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.tripmate',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLocation!,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                            // Add markers for image locations
                            ...(_imageLocations.map(
                              (imgLoc) => Marker(
                                point: imgLoc['location'],
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            )),
                          ],
                        ),
                      ],
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            color: Colors.white54,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Add photos with location data\nor get current location to see map',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
