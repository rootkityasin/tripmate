import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapTileService {
  static const String _tileBaseUrl = 'https://tile.openstreetmap.org';
  static const int _maxZoomLevel = 18;
  static const int _minZoomLevel = 1;

  // Cache directory for offline tiles
  Directory? _cacheDir;
  bool _isInitialized = false;
  bool _useFileSystem = true;

  Future<void> initialize() async {
    if (_isInitialized) return;

    print('Initializing MapTileService...');

    // Try multiple fallback approaches
    final attempts = [
      () async {
        print('Attempt 1: Using getApplicationDocumentsDirectory()');
        final appDir = await getApplicationDocumentsDirectory();
        return Directory('${appDir.path}/map_tiles');
      },
      () async {
        print('Attempt 2: Using getTemporaryDirectory()');
        final tempDir = await getTemporaryDirectory();
        return Directory('${tempDir.path}/map_tiles');
      },
      () async {
        print('Attempt 3: Using current working directory');
        return Directory('map_tiles');
      },
      () async {
        print('Attempt 4: Using system temp directory');
        return Directory.systemTemp.createTemp('tripmate_maps');
      },
    ];

    bool success = false;
    Exception? lastError;

    for (int i = 0; i < attempts.length; i++) {
      try {
        print('Trying initialization attempt ${i + 1}...');
        _cacheDir = await attempts[i]();

        if (_cacheDir != null && !await _cacheDir!.exists()) {
          await _cacheDir!.create(recursive: true);
        }

        // Test write access
        if (_cacheDir != null) {
          final testFile = File(
            '${_cacheDir!.path}/test_${DateTime.now().millisecondsSinceEpoch}.tmp',
          );
          await testFile.writeAsString('test');
          if (await testFile.exists()) {
            await testFile.delete();
            print('Write test successful');
          }
        }

        _isInitialized = true;
        _useFileSystem = true;
        success = true;
        print('MapTileService initialized successfully with attempt ${i + 1}');
        print('Cache directory: ${_cacheDir?.path}');
        break;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        print('MapTileService initialization attempt ${i + 1} failed: $e');
        continue;
      }
    }

    if (!success) {
      print(
        'All file system attempts failed. Falling back to memory-only mode.',
      );
      print('Last error: $lastError');
      _cacheDir = null;
      _useFileSystem = false;
      _isInitialized = true;
      print(
        'MapTileService initialized in memory-only mode (downloads disabled)',
      );
    }
  }

  // Download tiles for a specific area (bounding box)
  Future<void> downloadAreaTiles({
    required double northLat,
    required double southLat,
    required double eastLng,
    required double westLng,
    required int minZoom,
    required int maxZoom,
    Function(int current, int total)? onProgress,
  }) async {
    await initialize();

    int totalTiles = 0;
    int currentTile = 0;

    // Calculate total tiles to download
    for (int zoom = minZoom; zoom <= maxZoom; zoom++) {
      final bounds = _getBounds(northLat, southLat, eastLng, westLng, zoom);
      totalTiles +=
          (bounds['maxX']! - bounds['minX']! + 1) *
          (bounds['maxY']! - bounds['minY']! + 1);
    }

    // Download tiles
    for (int zoom = minZoom; zoom <= maxZoom; zoom++) {
      final bounds = _getBounds(northLat, southLat, eastLng, westLng, zoom);

      for (int x = bounds['minX']!; x <= bounds['maxX']!; x++) {
        for (int y = bounds['minY']!; y <= bounds['maxY']!; y++) {
          await _downloadTile(zoom, x, y);
          currentTile++;
          onProgress?.call(currentTile, totalTiles);
        }
      }
    }
  }

  // Download tiles for Bandarban area (default tourist location)
  Future<void> downloadBandarbanTiles({
    Function(int current, int total)? onProgress,
  }) async {
    // Bandarban bounding box coordinates
    const double northLat = 22.3;
    const double southLat = 22.0;
    const double eastLng = 92.4;
    const double westLng = 92.0;

    await downloadAreaTiles(
      northLat: northLat,
      southLat: southLat,
      eastLng: eastLng,
      westLng: westLng,
      minZoom: 10,
      maxZoom: 16,
      onProgress: onProgress,
    );
  }

  Future<void> _downloadTile(int zoom, int x, int y) async {
    // Skip downloading if file system is not available
    if (!_useFileSystem || _cacheDir == null) {
      return;
    }

    final tileFile = File('${_cacheDir!.path}/${zoom}_${x}_$y.png');

    // Skip if tile already exists
    if (await tileFile.exists()) return;

    try {
      final url = '$_tileBaseUrl/$zoom/$x/$y.png';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        await tileFile.writeAsBytes(response.bodyBytes);
      }
    } catch (e) {
      print('Error downloading tile $zoom/$x/$y: $e');
    }
  }

  Map<String, int> _getBounds(
    double north,
    double south,
    double east,
    double west,
    int zoom,
  ) {
    final minX = _lonToTileX(west, zoom);
    final maxX = _lonToTileX(east, zoom);
    final minY = _latToTileY(north, zoom);
    final maxY = _latToTileY(south, zoom);

    return {'minX': minX, 'maxX': maxX, 'minY': minY, 'maxY': maxY};
  }

  int _lonToTileX(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  int _latToTileY(double lat, int zoom) {
    final latRad = lat * pi / 180.0;
    return ((1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / pi) /
            2.0 *
            (1 << zoom))
        .floor();
  }

  // Custom tile provider that checks cache first
  TileProvider getCachedTileProvider() {
    if (_cacheDir != null) {
      return CachedTileProvider(cacheDir: _cacheDir!);
    } else {
      // Return a network-only tile provider if no cache directory
      return NetworkTileProvider();
    }
  }

  // Download tiles for a specific destination with a reasonable radius
  Future<void> downloadDestinationTiles(
    LatLng center,
    String destinationName, {
    Function(int current, int total)? onProgress,
    double radiusKm = 25.0, // 25km radius around the destination
  }) async {
    await initialize();

    // Calculate bounding box around the center point
    const double earthRadius = 6371.0; // Earth's radius in km
    final double latDelta = (radiusKm / earthRadius) * (180 / pi);
    final double lngDelta =
        (radiusKm / earthRadius) * (180 / pi) / cos(center.latitude * pi / 180);

    final double north = center.latitude + latDelta;
    final double south = center.latitude - latDelta;
    final double east = center.longitude + lngDelta;
    final double west = center.longitude - lngDelta;

    // Download tiles for zoom levels 8-16 (good balance of detail and download size)
    await downloadAreaTiles(
      northLat: north,
      southLat: south,
      eastLng: east,
      westLng: west,
      minZoom: 8,
      maxZoom: 16,
      onProgress: onProgress,
    );

    print('Downloaded offline maps for $destinationName');
  }

  // Get cache status
  Future<Map<String, dynamic>> getCacheStatus() async {
    await initialize();

    if (_cacheDir == null || !_useFileSystem) {
      return {
        'tileCount': 0,
        'cacheSizeMB': '0.00',
        'cacheDirectory': 'Memory only (no file system access)',
      };
    }

    final files = await _cacheDir!.list().toList();
    final tileCount = files.where((f) => f.path.endsWith('.png')).length;

    double cacheSize = 0;
    for (final file in files) {
      if (file is File) {
        final stat = await file.stat();
        cacheSize += stat.size;
      }
    }

    return {
      'tileCount': tileCount,
      'cacheSizeMB': (cacheSize / (1024 * 1024)).toStringAsFixed(2),
      'cacheDirectory': _cacheDir!.path,
    };
  }

  // Clear cache
  Future<void> clearCache() async {
    await initialize();

    if (_cacheDir == null || !_useFileSystem) {
      print('No cache directory to clear');
      return;
    }

    final files = await _cacheDir!.list().toList();
    for (final file in files) {
      if (file is File) {
        await file.delete();
      }
    }
  }
}

// Custom tile provider that uses cached tiles when available
class CachedTileProvider extends TileProvider {
  final Directory cacheDir;

  CachedTileProvider({required this.cacheDir});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final tileFile = File(
      '${cacheDir.path}/${coordinates.z}_${coordinates.x}_${coordinates.y}.png',
    );

    if (tileFile.existsSync()) {
      // Return cached tile
      return FileImage(tileFile);
    } else {
      // Fallback to network
      final url = options.urlTemplate!
          .replaceAll('{z}', coordinates.z.toString())
          .replaceAll('{x}', coordinates.x.toString())
          .replaceAll('{y}', coordinates.y.toString());
      return NetworkImage(url);
    }
  }
}

// Network-only tile provider for when file system is not available
class NetworkTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = options.urlTemplate!
        .replaceAll('{z}', coordinates.z.toString())
        .replaceAll('{x}', coordinates.x.toString())
        .replaceAll('{y}', coordinates.y.toString());
    return NetworkImage(url);
  }
}

// Remove these duplicate functions since we're using dart:math
