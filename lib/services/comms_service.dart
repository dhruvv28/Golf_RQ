import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

// iOS-specific network handling
bool get isIOS => Platform.isIOS;

// Default rover configuration
const int kDefaultRoverPort = 5555;

enum CommsStatus { idle, connecting, connected, error, disconnected }

class CommsService extends ChangeNotifier {
  Socket? _socket;

  // status & streams
  CommsStatus _status = CommsStatus.idle;
  final _statusCtrl = StreamController<CommsStatus>.broadcast();
  final _payloadCtrl = StreamController<String>.broadcast();
  final _pingCtrl = StreamController<int>.broadcast();

  CommsStatus get status => _status;
  Stream<CommsStatus> get statusStream => _statusCtrl.stream;
  Stream<String> get payloadStream => _payloadCtrl.stream;
  Stream<int> get pingStream => _pingCtrl.stream;

  // last info for UI
  String? _lastPayloadPretty;
  int? _lastPingMs;
  String? get lastPayloadPretty => _lastPayloadPretty;
  int? get lastPingMs => _lastPingMs;

  // rover (ball) GPS
  double? _ballLat;
  double? _ballLon;
  double? get ballLat => _ballLat;
  double? get ballLon => _ballLon;
  
  // Method to set test GPS coordinates
  void setTestGPS(double lat, double lon) {
    _ballLat = lat;
    _ballLon = lon;
    notifyListeners();
  }
  
  // Method to clear ball coordinates
  void clearBallGPS() {
    _ballLat = null;
    _ballLon = null;
    notifyListeners();
  }
  
  // Method to force refresh and debug current state
  void debugCurrentState() {
    debugPrint('[CommsService] 🔍 Debug State:');
    debugPrint('[CommsService] - Status: $_status');
    debugPrint('[CommsService] - Ball Lat: $_ballLat');
    debugPrint('[CommsService] - Ball Lon: $_ballLon');
    debugPrint('[CommsService] - Socket connected: ${_socket != null}');
    debugPrint('[CommsService] - Listeners count: ${_statusCtrl.hasListener ? "has listeners" : "no listeners"}');
  }

  void init() {
    // keep for future setup
  }

  /// Test connection to a specific rover IP
  Future<bool> testRoverConnection(String ip, {int port = kDefaultRoverPort}) async {
    try {
      debugPrint('[CommsService] Testing connection to $ip:$port...');
      final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
      await socket.close();
      debugPrint('[CommsService] ✅ Rover at $ip:$port is reachable');
      return true;
    } catch (e) {
      debugPrint('[CommsService] ❌ Rover at $ip:$port is not reachable: $e');
      debugPrint('[CommsService] Error type: ${e.runtimeType}');
      return false;
    }
  }

  /// Test common ports on a specific IP (useful for Raspberry Pi)
  Future<List<int>> testCommonPorts(String ip) async {
    final commonPorts = [5555, 8080, 3000, 5000, 8000, 22, 80, 443, 9999, 1234, 4567];
    final openPorts = <int>[];
    
    debugPrint('[CommsService] Testing common ports on $ip...');
    
    for (final port in commonPorts) {
      try {
        final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 2));
        await socket.close();
        openPorts.add(port);
        debugPrint('[CommsService] ✅ Port $port is open on $ip');
      } catch (e) {
        debugPrint('[CommsService] ❌ Port $port is closed on $ip');
      }
    }
    
    return openPorts;
  }

  /// Test if a specific port is sending JSON data
  Future<Map<String, dynamic>?> testPortForJSON(String ip, int port) async {
    Socket? testSocket;
    try {
      debugPrint('[CommsService] Testing port $port for JSON data...');
      testSocket = await Socket.connect(ip, port, timeout: const Duration(seconds: 3));
      
      // Wait for data
      final completer = Completer<Map<String, dynamic>?>();
      Timer(const Duration(seconds: 3), () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });
      
      late StreamSubscription subscription;
      subscription = testSocket.listen(
        (data) {
          if (!completer.isCompleted) {
            try {
              final text = utf8.decode(data).trim();
              debugPrint('[CommsService] 📡 Port $port received: "$text"');
              
              // Handle multiple JSON messages separated by newlines
              final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
              
              for (final line in lines) {
                try {
                  final jsonData = json.decode(line.trim());
                  debugPrint('[CommsService] ✅ Port $port sent valid JSON: $line');
                  completer.complete(jsonData);
                  subscription.cancel();
                  return;
                } catch (e) {
                  debugPrint('[CommsService] ⚠️ Port $port line not JSON: "$line"');
                }
              }
              
              // If no valid JSON found in any line
              if (!completer.isCompleted) {
                debugPrint('[CommsService] ❌ Port $port sent non-JSON data');
                completer.complete(null);
                subscription.cancel();
              }
            } catch (e) {
              debugPrint('[CommsService] ❌ Port $port decode error: $e');
              if (!completer.isCompleted) {
                completer.complete(null);
                subscription.cancel();
              }
            }
          }
        },
        onError: (e) {
          debugPrint('[CommsService] ❌ Port $port error: $e');
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
        onDone: () {
          debugPrint('[CommsService] ⚠️ Port $port connection closed');
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
      );
      
      final result = await completer.future;
      
      // Clean up
      await subscription.cancel();
      await testSocket.close();
      
      return result;
    } catch (e) {
      debugPrint('[CommsService] ❌ Port $port connection failed: $e');
      try {
        await testSocket?.close();
      } catch (_) {}
      return null;
    }
  }

  /// Scan network for rover devices
  Future<List<String>> discoverRoverIPs() async {
    final List<String> foundIPs = [];
    
    // Common network ranges to scan
    final networkRanges = [
      '172.20.10.',   // Rover's specific subnet
      '192.168.1.',   // Most common home/office networks
      '192.168.0.',   // Alternative home networks
      '192.168.4.',   // Mobile hotspots
      '10.0.2.',      // Android emulator
    ];

    for (final range in networkRanges) {
      debugPrint('[CommsService] Scanning range: $range');
      // Scan IPs 1-254 in each range
      for (int i = 1; i <= 254; i++) {
        final ip = '$range$i';
        try {
          final socket = await Socket.connect(ip, kDefaultRoverPort, timeout: const Duration(milliseconds: 500));
          await socket.close();
          foundIPs.add(ip);
          debugPrint('[CommsService] ✅ Found rover at $ip:$kDefaultRoverPort');
          // Stop scanning this range once we find one
          break;
        } catch (e) {
          // Continue scanning
        }
      }
      // If we found rovers, don't scan other ranges
      if (foundIPs.isNotEmpty) break;
    }
    
    return foundIPs;
  }

  Future<void> connect({required String ip, required int port}) async {
    await disconnect();
    _setStatus(CommsStatus.connecting);

    try {
      // Enhanced connection with better error handling for hotspot networks
      _socket = await Socket.connect(
        ip, 
        port, 
        timeout: Duration(seconds: isIOS ? 15 : 10), // Longer timeout on iOS
      );
      
      // Set socket options for better reliability on mobile networks
      _socket!.setOption(SocketOption.tcpNoDelay, true);
      
      // iOS-specific optimizations
      if (isIOS) {
        debugPrint('[CommsService] iOS connection established with extended timeout');
      }
      _socket!.listen(
        (data) {
          final text = utf8.decode(data);
          debugPrint('[CommsService] 📡 Raw data received: ${text.length} bytes');
          debugPrint('[CommsService] 📡 Raw text: "$text"');
          
          _lastPayloadPretty = _prettify(text);
          _payloadCtrl.add(_lastPayloadPretty!);

          // Handle multiple JSON messages in one packet
          final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
          
          for (final line in lines) {
            final cleanText = line.trim();
            if (cleanText.isEmpty) continue;
            
            debugPrint('[CommsService] 📡 Processing line: "$cleanText"');
            
            // parse rover JSON: {"lat": ..., "lon": ...}
            try {
              final j = json.decode(cleanText);
              final lat = (j['lat'] as num?)?.toDouble();
              final lon = (j['lon'] as num?)?.toDouble();
              debugPrint('[CommsService] 📍 Parsed GPS: lat=$lat, lon=$lon');
              
              if (lat != null && lon != null) {
                // Check if coordinates are valid (not 0,0 or invalid)
                if (lat != 0.0 || lon != 0.0) {
                  _ballLat = lat;
                  _ballLon = lon;
                  debugPrint('[CommsService] ✅ Ball detected! GPS coordinates set: $lat, $lon');
                  debugPrint('[CommsService] ✅ Notifying listeners...');
                  notifyListeners();
                } else {
                  debugPrint('[CommsService] ⚠️ No ball detected (0,0) - keeping previous coordinates');
                  // Don't clear previous coordinates when no ball is detected
                }
              } else {
                debugPrint('[CommsService] ❌ Missing lat/lon in JSON: $j');
              }
            } catch (e) {
              debugPrint('[CommsService] ❌ Failed to parse JSON: "$cleanText", error: $e');
            }
          }
        },
        onDone: () {
          debugPrint('[CommsService] Socket connection closed');
          _setStatus(CommsStatus.disconnected);
        },
        onError: (error) {
          debugPrint('[CommsService] Socket error: $error');
          _setStatus(CommsStatus.error);
        },
      );

      _setStatus(CommsStatus.connected);
      debugPrint('[CommsService] Connected to rover at $ip:$port');
    } catch (e) {
      debugPrint('[CommsService] Connection failed: $e');
      _setStatus(CommsStatus.error);
      rethrow; // Re-throw to show error in UI
    }
  }

  Future<void> ping() async {
    if (_socket == null) return;
    final sw = Stopwatch()..start();
    _socket!.write('ping\n');
    await _socket!.flush();
    // many devices won't echo, still surface a nominal latency
    await Future.delayed(const Duration(milliseconds: 150));
    sw.stop();
    _lastPingMs = sw.elapsedMilliseconds;
    _pingCtrl.add(_lastPingMs!);
    notifyListeners();
  }

  Future<void> disconnect() async {
    try {
      await _socket?.close();
    } finally {
      _socket = null;
      _setStatus(CommsStatus.disconnected);
    }
  }

  String _prettify(String raw) {
    try {
      final j = json.decode(raw);
      return const JsonEncoder.withIndent('  ').convert(j);
    } catch (_) {
      return raw.trim();
    }
  }

  void _setStatus(CommsStatus s) {
    _status = s;
    _statusCtrl.add(s);
    notifyListeners();
  }

  @override
  void dispose() {
    _socket?.destroy();
    _statusCtrl.close();
    _payloadCtrl.close();
    _pingCtrl.close();
    super.dispose();
  }
}
