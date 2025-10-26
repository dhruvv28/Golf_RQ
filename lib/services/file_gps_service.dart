import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Service that reads GPS data from a file on the rover
/// This is more reliable than TCP socket streaming
class FileGpsService extends ChangeNotifier {
  Timer? _pollTimer;
  String _roverIP = '172.20.10.4';
  int _roverPort = 8080; // HTTP server port for file access
  
  double? _ballLat;
  double? _ballLon;
  DateTime? _lastUpdate;
  bool _isPolling = false;
  
  // User's current position for distance calculation
  Position? _userPosition;
  
  double? get ballLat => _ballLat;
  double? get ballLon => _ballLon;
  DateTime? get lastUpdate => _lastUpdate;
  bool get isPolling => _isPolling;
  bool get hasValidGps => _ballLat != null && _ballLon != null && (_ballLat != 0.0 || _ballLon != 0.0);
  
  /// Update user's position (called from distance screen)
  void updateUserPosition(Position position) {
    _userPosition = position;
  }
  
  /// Start polling GPS data from file
  void startPolling({String roverIP = '172.20.10.4', int port = 8080}) {
    _roverIP = roverIP;
    _roverPort = port;
    
    if (_isPolling) {
      debugPrint('[FileGpsService] Already polling');
      return;
    }
    
    _isPolling = true;
    _pollTimer?.cancel();
    
    // Poll every 1 second
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => _fetchGpsData());
    
    debugPrint('[FileGpsService] 🚀 Started polling GPS from http://$_roverIP:$_roverPort/gps.txt');
    notifyListeners();
    
    // Fetch immediately
    _fetchGpsData();
  }
  
  /// Stop polling GPS data
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isPolling = false;
    
    debugPrint('[FileGpsService] 🛑 Stopped polling GPS');
    notifyListeners();
  }
  
  /// Fetch GPS data directly from file or TCP socket
  Future<void> _fetchGpsData() async {
    // Try direct file access first, then fall back to TCP socket
    final fileSuccess = await _fetchViaFile();
    if (!fileSuccess) {
      await _fetchViaTCP();
    }
  }
  
  /// Fetch GPS via direct file access (SMB/network share or local path)
  Future<bool> _fetchViaFile() async {
    try {
      // Try multiple possible file paths
      final possiblePaths = [
        '//$_roverIP/share/gps.txt',           // SMB share (Windows/Samba)
        '\\\\$_roverIP\\share\\gps.txt',      // Windows UNC path
        '/mnt/rover/gps.txt',                  // Linux mount point
        '/Volumes/rover/gps.txt',              // macOS mount point
        'gps.txt',                              // Local file (for testing)
      ];
      
      for (final path in possiblePaths) {
        try {
          final file = File(path);
          if (await file.exists()) {
            final content = await file.readAsString();
            
            if (content.isEmpty) {
              debugPrint('[FileGpsService] ⚠️ Empty GPS file at $path');
              continue;
            }
            
            // Parse JSON
            try {
              final gpsData = json.decode(content.trim());
              final lat = (gpsData['lat'] as num?)?.toDouble();
              final lon = (gpsData['lon'] as num?)?.toDouble();
              
              if (lat != null && lon != null) {
                if (lat != 0.0 || lon != 0.0) {
                  _ballLat = lat;
                  _ballLon = lon;
                  _lastUpdate = DateTime.now();
                  
                  debugPrint('[FileGpsService] ✅ File GPS updated from $path: lat=$lat, lon=$lon');
                  _calculateAndLogDistance();
                  notifyListeners();
                  return true;
                } else {
                  debugPrint('[FileGpsService] ⚠️ No ball detected (0,0)');
                }
              }
            } catch (e) {
              debugPrint('[FileGpsService] ❌ JSON parse error from $path: $e');
            }
          }
        } catch (e) {
          // File not accessible at this path, try next
          continue;
        }
      }
      
      debugPrint('[FileGpsService] ⚠️ GPS file not found at any path, trying TCP...');
    } catch (e) {
      debugPrint('[FileGpsService] ❌ File access error: $e');
    }
    return false;
  }
  
  /// Fetch GPS via TCP socket (reads directly from rover's TCP stream)
  Future<bool> _fetchViaTCP() async {
    Socket? socket;
    try {
      // Connect to rover's TCP server (port 5555)
      socket = await Socket.connect(
        _roverIP, 
        5555,
        timeout: const Duration(seconds: 2),
      );
      
      // Wait for data
      final completer = Completer<bool>();
      Timer(const Duration(seconds: 2), () {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });
      
      socket.listen(
        (data) {
          if (!completer.isCompleted) {
            try {
              final text = utf8.decode(data).trim();
              final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
              
              for (final line in lines) {
                try {
                  final gpsData = json.decode(line.trim());
                  final lat = (gpsData['lat'] as num?)?.toDouble();
                  final lon = (gpsData['lon'] as num?)?.toDouble();
                  
                  if (lat != null && lon != null) {
                    if (lat != 0.0 || lon != 0.0) {
                      _ballLat = lat;
                      _ballLon = lon;
                      _lastUpdate = DateTime.now();
                      
                      debugPrint('[FileGpsService] ✅ TCP GPS updated: lat=$lat, lon=$lon');
                      _calculateAndLogDistance();
                      notifyListeners();
                      completer.complete(true);
                      return;
                    }
                  }
                } catch (e) {
                  debugPrint('[FileGpsService] ⚠️ TCP line parse error: $e');
                }
              }
            } catch (e) {
              debugPrint('[FileGpsService] ❌ TCP decode error: $e');
            }
          }
        },
        onError: (e) {
          if (!completer.isCompleted) {
            debugPrint('[FileGpsService] ❌ TCP error: $e');
            completer.complete(false);
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );
      
      final success = await completer.future;
      await socket.close();
      return success;
      
    } catch (e) {
      debugPrint('[FileGpsService] ❌ TCP connection failed: $e');
      try {
        await socket?.close();
      } catch (_) {}
      return false;
    }
  }
  
  /// Clear GPS data
  void clearGps() {
    _ballLat = null;
    _ballLon = null;
    _lastUpdate = null;
    debugPrint('[FileGpsService] 🧹 Cleared GPS data');
    notifyListeners();
  }
  
  /// Set test GPS coordinates (for debugging)
  void setTestGps(double lat, double lon) {
    _ballLat = lat;
    _ballLon = lon;
    _lastUpdate = DateTime.now();
    debugPrint('[FileGpsService] 🧪 Test GPS set: $lat, $lon');
    _calculateAndLogDistance();
    notifyListeners();
  }
  
  /// Calculate and log distance to ball
  void _calculateAndLogDistance() {
    if (_ballLat == null || _ballLon == null) {
      debugPrint('[FileGpsService] ⚠️ Cannot calculate distance: No ball GPS');
      return;
    }
    
    if (_userPosition == null) {
      debugPrint('[FileGpsService] ⚠️ Cannot calculate distance: No user GPS (waiting for location...)');
      return;
    }
    
    // Calculate distance using Haversine formula
    final distanceMeters = Geolocator.distanceBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      _ballLat!,
      _ballLon!,
    );
    
    // Convert to yards (1 meter = 1.09361 yards)
    final distanceYards = distanceMeters * 1.09361;
    
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('📍 DISTANCE TO BALL CALCULATED');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('Your Position:  ${_userPosition!.latitude.toStringAsFixed(6)}, ${_userPosition!.longitude.toStringAsFixed(6)}');
    debugPrint('Ball Position:  ${_ballLat!.toStringAsFixed(6)}, ${_ballLon!.toStringAsFixed(6)}');
    debugPrint('Distance:       ${distanceYards.toStringAsFixed(1)} yards (${distanceMeters.toStringAsFixed(1)} meters)');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('');
  }
  
  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

