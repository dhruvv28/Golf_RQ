import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../services/comms_service.dart';
import '../services/club_service.dart';
import '../services/voice_coach.dart';

// Fallback defaults (edit as needed)
const String kDefaultRoverIp = '192.168.4.1'; // on Android emulator use 10.0.2.2 to reach host
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
                      helperText: 'Emulator → host: use 10.0.2.2',
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
                    onPressed: _connecting ? null : _scanForRover,
                    icon: const Icon(Icons.radar),
                    label: const Text('Scan'),
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
