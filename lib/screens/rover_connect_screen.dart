import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../services/comms_service.dart';
import '../services/file_gps_service.dart';
import '../services/club_service.dart';
import '../services/voice_coach.dart';

// Fallback defaults (edit as needed)
const String kDefaultRoverIp = '172.20.10.4'; // Rover's specific IP address
const int kDefaultRoverPort = 5555;

class RoverConnectScreen extends StatefulWidget {
  const RoverConnectScreen({super.key});

  @override
  State<RoverConnectScreen> createState() => _RoverConnectScreenState();
}

class _RoverConnectScreenState extends State<RoverConnectScreen> {
  final ipCtrl = TextEditingController(text: kDefaultRoverIp);
  final portCtrl = TextEditingController(text: kDefaultRoverPort.toString());

  StreamSubscription<CommsStatus>? _statusSub;
  StreamSubscription<String>? _payloadSub;
  StreamSubscription<int>? _pingSub;

  CommsStatus? _status;
  String? _lastMsg;
  int? _lastPingMs;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    final comms = context.read<CommsService>();
    _status = comms.status;
    _lastMsg = comms.lastPayloadPretty;
    _lastPingMs = comms.lastPingMs;

    _statusSub = comms.statusStream.listen((s) {
      if (!mounted) return;
      setState(() => _status = s);
      // Announce status changes
      switch (s) {
        case CommsStatus.connected:
          context.read<VoiceCoach>().announceSuccess("Connected to rover");
          break;
        case CommsStatus.error:
          context.read<VoiceCoach>().announceError("Connection failed");
          break;
        case CommsStatus.disconnected:
          context.read<VoiceCoach>().announceData("Disconnected from rover");
          break;
        default:
          break;
      }
    });
    _payloadSub = comms.payloadStream.listen((m) {
      if (!mounted) return;
      setState(() => _lastMsg = m);
    });
    _pingSub = comms.pingStream.listen((ms) {
      if (!mounted) return;
      setState(() => _lastPingMs = ms);
    });
    
    // Announce screen entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoiceCoach>().announceScreen("Rover Connection");
    });
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _payloadSub?.cancel();
    _pingSub?.cancel();
    ipCtrl.dispose();
    portCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_connecting) return;
    setState(() => _connecting = true);

    final ip = ipCtrl.text.trim().isEmpty ? kDefaultRoverIp : ipCtrl.text.trim();
    final port = int.tryParse(portCtrl.text.trim()) ?? kDefaultRoverPort;

    try {
      await context.read<CommsService>().connect(ip: ip, port: port);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected to rover!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connect failed: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Scan',
            textColor: Colors.white,
            onPressed: _scanForRover,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _scanForRover() async {
    setState(() => _connecting = true);
    
    try {
      final foundIPs = await context.read<CommsService>().discoverRoverIPs();
      if (foundIPs.isNotEmpty && mounted) {
        // Auto-fill the first found IP
        ipCtrl.text = foundIPs.first;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Found rover at: ${foundIPs.join(', ')}')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No rover found on network')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() => _connecting = true);
    
    final ip = ipCtrl.text.trim().isEmpty ? kDefaultRoverIp : ipCtrl.text.trim();
    final port = int.tryParse(portCtrl.text.trim()) ?? kDefaultRoverPort;
    
    try {
      final isReachable = await context.read<CommsService>().testRoverConnection(ip, port: port);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isReachable ? 'Rover is reachable at $ip:$port' : 'Rover not reachable at $ip:$port'),
            backgroundColor: isReachable ? Colors.green : Colors.red,
          ),
        );
        context.read<VoiceCoach>().announceData(
          isReachable ? "Rover is reachable" : "Rover not reachable"
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test failed: $e')),
        );
        context.read<VoiceCoach>().announceError("Connection test failed");
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _testPorts() async {
    setState(() => _connecting = true);
    
    final ip = ipCtrl.text.trim().isEmpty ? kDefaultRoverIp : ipCtrl.text.trim();
    
    try {
      final openPorts = await context.read<CommsService>().testCommonPorts(ip);
      if (mounted) {
        if (openPorts.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Open ports on $ip: ${openPorts.join(', ')}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
          context.read<VoiceCoach>().announceData("Found ${openPorts.length} open ports");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No open ports found on $ip'),
              backgroundColor: Colors.orange,
            ),
          );
          context.read<VoiceCoach>().announceError("No open ports found");
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Port test failed: $e')),
        );
        context.read<VoiceCoach>().announceError("Port test failed");
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _findRoverPort() async {
    setState(() => _connecting = true);
    
    final ip = ipCtrl.text.trim().isEmpty ? kDefaultRoverIp : ipCtrl.text.trim();
    
    try {
      // First find open ports
      final openPorts = await context.read<CommsService>().testCommonPorts(ip);
      
      if (openPorts.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No open ports found on rover'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Test each open port for JSON data
      for (final port in openPorts) {
        if (port == 22) continue; // Skip SSH port
        
        final jsonData = await context.read<CommsService>().testPortForJSON(ip, port);
        if (jsonData != null) {
          if (mounted) {
            // Auto-fill the port
            portCtrl.text = port.toString();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Found rover on port $port! Connecting...'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            context.read<VoiceCoach>().announceSuccess("Found rover on port $port");
            
            // Automatically connect to the found port
            try {
              await context.read<CommsService>().connect(ip: ip, port: port);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Connected to rover! GPS data streaming...'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
                context.read<VoiceCoach>().announceSuccess("Connected to rover");
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Found port but connection failed: $e'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          }
          return;
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ports ${openPorts.join(', ')} but none send JSON data'),
            backgroundColor: Colors.orange,
          ),
        );
        context.read<VoiceCoach>().announceError("No JSON data found on any port");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Port search failed: $e')),
        );
        context.read<VoiceCoach>().announceError("Port search failed");
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _ping() async {
    try {
      await context.read<CommsService>().ping();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ping failed: $e')),
      );
    }
  }

  Future<void> _continue() async {
    // Ask for location permission BEFORE navigating to the Distance screen.
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required to continue.')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/distance');
  }

  @override
  Widget build(BuildContext context) {
    final connected = _status == CommsStatus.connected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Rover'),
        actions: [
          IconButton(
            tooltip: 'Edit Clubs',
            icon: const Icon(Icons.sports_golf),
            onPressed: () => Navigator.pushReplacementNamed(context, '/setup'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              children: [
                const Icon(Icons.wifi, color: Colors.green),
                const SizedBox(width: 8),
                Text('Rover Connection', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            // Clubs preview
            Consumer<ClubService>(
              builder: (context, clubService, child) {
                return Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.sports_golf, size: 16),
                            const SizedBox(width: 8),
                            Text('Your Clubs', style: Theme.of(context).textTheme.titleSmall),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: clubService.yardsByClub.entries.take(4).map((entry) {
                            return Chip(
                              label: Text('${entry.key}: ${entry.value}yd'),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        ),
                        if (clubService.yardsByClub.length > 4)
                          Text('+${clubService.yardsByClub.length - 4} more clubs', 
                               style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ipCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Rover IP',
                      helperText: 'Default: 172.20.10.4 (Rover subnet)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: portCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _connecting ? null : _connect,
                    icon: _connecting
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.link),
                    label: const Text('Connect'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _connecting ? null : _testConnection,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Test'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _connecting ? null : _testPorts,
                    icon: const Icon(Icons.portable_wifi_off),
                    label: const Text('Test Ports'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _connecting ? null : _findRoverPort,
                    icon: const Icon(Icons.search),
                    label: const Text('Find Rover'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _connecting ? null : _scanForRover,
                    icon: const Icon(Icons.radar),
                    label: const Text('Scan Network'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _ping,
                    icon: const Icon(Icons.wifi_tethering),
                    label: const Text('Ping'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      // Show debug info
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Debug Info'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rover IP: ${ipCtrl.text}'),
                              Text('Port: ${portCtrl.text}'),
                              Text('Status: ${_status?.name ?? 'unknown'}'),
                              Text('Last Ping: ${_lastPingMs ?? '-'} ms'),
                              const SizedBox(height: 8),
                              Text('Ball GPS: ${context.read<CommsService>().ballLat ?? 'null'}, ${context.read<CommsService>().ballLon ?? 'null'}'),
                              Text('Last Message: ${_lastMsg ?? 'none'}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.info),
                    label: const Text('Debug'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      // Test with simulated GPS coordinates
                      final comms = context.read<CommsService>();
                      // Simulate a ball 50 yards away (roughly 45 meters)
                      final testLat = 40.7128; // NYC coordinates
                      final testLon = -74.0060;
                      
                      // Manually set test coordinates
                      comms.setTestGPS(testLat, testLon);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Test GPS set: 40.7128, -74.0060'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      context.read<VoiceCoach>().announceData("Test GPS coordinates set");
                    },
                    icon: const Icon(Icons.gps_fixed),
                    label: const Text('Test GPS'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      // Clear ball GPS coordinates
                      final comms = context.read<CommsService>();
                      comms.clearBallGPS();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ball GPS cleared'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      context.read<VoiceCoach>().announceData("Ball GPS cleared");
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Ball'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      // Debug current state
                      final comms = context.read<CommsService>();
                      comms.debugCurrentState();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Debug info printed to console. Ball GPS: ${comms.ballLat ?? 'null'}, ${comms.ballLon ?? 'null'}'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Debug State'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(connected ? Icons.check_circle : Icons.cancel, color: connected ? Colors.green : Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ${_status?.name ?? 'unknown'}', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('Ping: ${_lastPingMs ?? '-'} ms'),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: _ping,
                      child: const Text('Ping'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Real-time GPS coordinates display
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.gps_fixed, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text('Ball GPS Coordinates', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 8),
Consumer<FileGpsService>(
                      builder: (context, gpsService, child) {
                        final lat = gpsService.ballLat;
                        final lon = gpsService.ballLon;
                        final isPolling = gpsService.isPolling;
                        final lastUpdate = gpsService.lastUpdate;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Polling status
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isPolling ? Colors.green : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isPolling ? 'Polling GPS file...' : 'Not polling',
                                  style: TextStyle(
                                    color: isPolling ? Colors.green : Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text('Latitude: '),
                                Text(
                                  lat?.toStringAsFixed(6) ?? 'No data',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: lat != null ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text('Longitude: '),
                                Text(
                                  lon?.toStringAsFixed(6) ?? 'No data',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: lon != null ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            if (lastUpdate != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Last update: ${DateTime.now().difference(lastUpdate).inSeconds}s ago',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            if (lat != null && lon != null && lat != 0.0 && lon != 0.0) ...[
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Ball detected!',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange[200]!),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning, color: Colors.orange, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'No ball detected',
                                      style: TextStyle(
                                        color: Colors.orange[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            // Control buttons
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: isPolling ? null : () {
                                      final ip = ipCtrl.text.trim().isEmpty ? kDefaultRoverIp : ipCtrl.text.trim();
                                      gpsService.startPolling(roverIP: ip, port: 8080);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Started GPS polling from file'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Start Polling'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.tonalIcon(
                                    onPressed: !isPolling ? null : () {
                                      gpsService.stopPolling();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Stopped GPS polling'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.stop),
                                    label: const Text('Stop'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Last Rover Message', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Text(
                _lastMsg ?? '—',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: connected ? _continue : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
