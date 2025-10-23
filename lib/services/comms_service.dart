import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

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

  void init() {
    // keep for future setup
  }

  /// Scan network for rover devices
  Future<List<String>> discoverRoverIPs() async {
    final List<String> foundIPs = [];
    
    // Common network ranges to scan
    final networkRanges = [
      '192.168.1.',   // Most common home/office networks
      '192.168.0.',   // Alternative home networks
      '192.168.4.',   // Mobile hotspots
      '10.0.2.',      // Android emulator
    ];

    for (final range in networkRanges) {
      // Scan IPs 1-254 in each range
      for (int i = 1; i <= 254; i++) {
        final ip = '$range$i';
        try {
          final socket = await Socket.connect(ip, kDefaultRoverPort, timeout: const Duration(milliseconds: 500));
          await socket.close();
          foundIPs.add(ip);
          debugPrint('[CommsService] Found rover at $ip');
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
        timeout: const Duration(seconds: 10), // Increased timeout for hotspot discovery
      );
      
      // Set socket options for better reliability on mobile networks
      _socket!.setOption(SocketOption.tcpNoDelay, true);
      _socket!.listen(
        (data) {
          final text = utf8.decode(data);
          _lastPayloadPretty = _prettify(text);
          _payloadCtrl.add(_lastPayloadPretty!);

          // parse rover JSON: {"lat": ..., "lon": ...}
          try {
            final j = json.decode(text);
            final lat = (j['lat'] as num?)?.toDouble();
            final lon = (j['lon'] as num?)?.toDouble();
            if (lat != null && lon != null) {
              _ballLat = lat;
              _ballLon = lon;
              notifyListeners();
            }
          } catch (_) {
            // ignore non-JSON payloads
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
