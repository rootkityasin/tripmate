import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';

class MapTileService {
  static const String _tileBaseUrl = 'https://tile.openstreetmap.org';
  static const int _maxZoomLevel = 18;
  static const int _minZoomLevel = 1;
  
  // Cache directory for offline tiles
  late Directory _cacheDir;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/map_tiles');
    
    if (!await _cacheDir.exists()) {
      await _cacheDir.create(recursive: true);
    }
    
    _isInitialized = true;
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
      totalTiles += (bounds['maxX']! - bounds['minX']! + 1) * 
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
    final tileFile = File('${_cacheDir.path}/${zoom}_${x}_$y.png');
    
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

  Map<String, int> _getBounds(double north, double south, double east, double west, int zoom) {
    final minX = _lonToTileX(west, zoom);
    final maxX = _lonToTileX(east, zoom);
    final minY = _latToTileY(north, zoom);
    final maxY = _latToTileY(south, zoom);
    
    return {
      'minX': minX,
      'maxX': maxX,
      'minY': minY,
      'maxY': maxY,
    };
  }

  int _lonToTileX(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  int _latToTileY(double lat, int zoom) {
    final latRad = lat * pi / 180.0;
    return ((1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / pi) / 2.0 * (1 << zoom)).floor();
  }

  // Custom tile provider that checks cache first
  TileProvider getCachedTileProvider() {
    return CachedTileProvider(cacheDir: _cacheDir);
  }

  // Get cache status
  Future<Map<String, dynamic>> getCacheStatus() async {
    await initialize();
    
    final files = await _cacheDir.list().toList();
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
      'cacheDirectory': _cacheDir.path,
    };
  }

  // Clear cache
  Future<void> clearCache() async {
    await initialize();
    
    final files = await _cacheDir.list().toList();
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
    final tileFile = File('${cacheDir.path}/${coordinates.z}_${coordinates.x}_${coordinates.y}.png');
    
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

// Remove these duplicate functions since we're using dart:math