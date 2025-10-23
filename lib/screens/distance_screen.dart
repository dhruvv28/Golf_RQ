import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../services/hole_service.dart';
import '../services/club_service.dart';
import '../services/voice_coach.dart';
import '../services/db_service.dart';
import '../services/comms_service.dart';
import '../services/practice_session_service.dart';

import '../models/shot.dart';
import '../utils/geo_utils.dart';
import '../widgets/quick_aim_overlay.dart';

class DistanceScreen extends StatefulWidget {
  const DistanceScreen({super.key});

  @override
  State<DistanceScreen> createState() => _DistanceScreenState();
}

class _DistanceScreenState extends State<DistanceScreen> {
  Position? _pos;
  CompassEvent? _compass;
  StreamSubscription<Position>? _gpsSub;
  StreamSubscription<CompassEvent>? _compSub;

  int? _lastAnnHole;
  int? _lastAnnBall;
  DateTime _lastAnnTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _startSensors();
    // Announce screen entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoiceCoach>().announceScreen("Distance Tracking");
    });
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _compSub?.cancel();
    super.dispose();
  }

  Future<void> _startSensors() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required.')),
        );
      }
      return;
    }

    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen((p) => setState(() => _pos = p));

    _compSub = FlutterCompass.events?.listen(
      (e) => setState(() => _compass = e),
    );
  }

  void _openSetHoleSheet() {
    final latCtrl = TextEditingController();
    final lonCtrl = TextEditingController();
    final distCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 12,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Set Hole', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () async {
                    final cur = await Geolocator.getCurrentPosition();
                    if (!ctx.mounted) return;
                    ctx.read<HoleService>().setHoleLatLon(cur.latitude, cur.longitude);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Use my current location'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(
                controller: latCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Latitude', border: OutlineInputBorder()),
              )),
              const SizedBox(width: 10),
              Expanded(child: TextField(
                controller: lonCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Longitude', border: OutlineInputBorder()),
              )),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final lat = double.tryParse(latCtrl.text);
                    final lon = double.tryParse(lonCtrl.text);
                    if (lat != null && lon != null) {
                      ctx.read<HoleService>().setHoleLatLon(lat, lon);
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Save lat/lon'),
                ),
              ),
            ]),
            const Divider(height: 26),
            TextField(
              controller: distCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Distance to hole (yd)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final yd = double.tryParse(distCtrl.text);
                    if (yd != null && yd > 0) {
                      ctx.read<HoleService>().setHoleDistanceYards(yd);
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Save distance only'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ctx.read<HoleService>().clear(),
              child: const Text('Clear hole'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hole   = context.watch<HoleService>().target;
    final comms  = context.watch<CommsService>();
    final club   = context.watch<ClubService>();
    final tts    = context.read<VoiceCoach>();
    final db     = context.read<DbService>();
    final sessionService = context.read<PracticeSessionService>();

    double? yardsToHole;
    double? targetBearing;
    if (hole.hasCoords && _pos != null) {
      final m = haversineMeters(_pos!.latitude, _pos!.longitude, hole.lat!, hole.lon!);
      yardsToHole = metersToYards(m);
      targetBearing = initialBearingDeg(_pos!.latitude, _pos!.longitude, hole.lat!, hole.lon!);
    } else if (hole.hasDistance) {
      yardsToHole = hole.distanceYards;
      targetBearing = null;
    }

    double? yardsToBall;
    if (_pos != null && comms.ballLat != null && comms.ballLon != null) {
      final mBall = haversineMeters(_pos!.latitude, _pos!.longitude, comms.ballLat!, comms.ballLon!);
      yardsToBall = metersToYards(mBall);
    }

    final heading = _compass?.heading;
    final String? recName =
        yardsToHole == null ? null : club.recommendForYards(yardsToHole.round());

    _maybeAnnounceBoth(tts, yardsToHole, yardsToBall, recName);

    Widget statCard(String label, String value, {Widget? trailing}) => Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ]),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Distance')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              statCard(
                'Distance to Hole',
                yardsToHole != null ? '${yardsToHole.toStringAsFixed(0)} yd' : '—',
                trailing: FilledButton.icon(
                  onPressed: _openSetHoleSheet,
                  icon: const Icon(Icons.flag),
                  label: const Text('Set Hole'),
                ),
              ),
              const SizedBox(height: 10),
              statCard(
                'Distance to Ball',
                yardsToBall != null ? '${yardsToBall.toStringAsFixed(0)} yd' : '—',
                trailing: const Icon(Icons.golf_course, size: 36),
              ),
              const SizedBox(height: 10),
              statCard(
                'Direction',
                (hole.hasCoords && heading != null && targetBearing != null)
                  ? _formatDirection(targetBearing, heading)
                  : (hole.hasCoords ? 'Calibrating…' : '—'),
                trailing: (hole.hasCoords && heading != null && targetBearing != null)
                  ? Transform.rotate(
                      angle: ((targetBearing - heading) * 3.1415926535 / 180.0),
                      child: const Icon(Icons.navigation, size: 36),
                    )
                  : const Icon(Icons.navigation_outlined, size: 36),
              ),
              const SizedBox(height: 10),
              statCard(
                'Recommended Club',
                recName ?? '—',
                trailing: const Icon(Icons.sports_golf, size: 36),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: (yardsToHole != null && recName != null)
                    ? () async {
                        final shot = Shot(
                          timestamp: DateTime.now(),
                          lat: _pos?.latitude ?? 0.0,
                          lon: _pos?.longitude ?? 0.0,
                          distance: yardsToHole!.toDouble(),
                          club: recName!,
                        );
                        final shotId = await db.saveShot(shot);
                        
                        // Add shot to current practice session if active
                        if (sessionService.hasActiveSession) {
                          await sessionService.addShotToCurrentSession(shotId);
                        }

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Shot saved')),
                          );
                          // Announce shot saved
                          context.read<VoiceCoach>().announceShot(shot.club, shot.distance);
                        }
                        tts.say('Saved shot: $recName ${yardsToHole!.round()} yards.');
                      }
                    : null,
                icon: const Icon(Icons.save_alt),
                label: const Text('Save Shot'),
              ),

              // --- DEV sanity button: remove later ---
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  await db.saveShot(
                    Shot(
                      timestamp: DateTime.now(),
                      lat: 12.0, lon: 77.0,
                      distance: 88.0,
                      club: 'SW',
                    ),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dummy shot saved')),
                    );
                  }
                },
                child: const Text('DEV: Add dummy shot'),
              ),
              // ---------------------------------------

              const SizedBox(height: 80),
            ],
          ),
          QuickAimOverlay(
            targetBearingDeg: targetBearing,
            headingDeg: heading,
          ),
        ],
      ),
      floatingActionButton: Consumer<PracticeSessionService>(
        builder: (context, sessionService, child) {
          if (sessionService.hasActiveSession) {
            return FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/sessions'),
              icon: const Icon(Icons.stop),
              label: const Text('End Session'),
              backgroundColor: Colors.red[600],
            );
          } else {
            return FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/sessions'),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Session'),
            );
          }
        },
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.straighten), label: 'Distance'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Club'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.sports_golf), label: 'Sessions'),
          NavigationDestination(icon: Icon(Icons.flag), label: 'Goals'),
        ],
        selectedIndex: 0,
        onDestinationSelected: (i) {
          final voiceCoach = context.read<VoiceCoach>();
          if (i == 1) {
            voiceCoach.announceNavigation("Club Recommendations");
            Navigator.pushReplacementNamed(context, '/recommend');
          }
          if (i == 2) {
            voiceCoach.announceNavigation("Shot History");
            Navigator.pushReplacementNamed(context, '/history');
          }
          if (i == 3) {
            voiceCoach.announceNavigation("Analytics Dashboard");
            Navigator.pushReplacementNamed(context, '/analytics');
          }
          if (i == 4) {
            voiceCoach.announceNavigation("Practice Sessions");
            Navigator.pushReplacementNamed(context, '/sessions');
          }
          if (i == 5) {
            voiceCoach.announceNavigation("Goals and Targets");
            Navigator.pushReplacementNamed(context, '/goals');
          }
        },
      ),
    );
  }

  void _maybeAnnounceBoth(VoiceCoach tts, double? holeYd, double? ballYd, String? recName) {
    final now = DateTime.now();
    if (now.difference(_lastAnnTime).inMilliseconds < 3000) return;

    final holeR = holeYd?.round();
    final ballR = ballYd?.round();

    final holeChanged = (holeR != null && (_lastAnnHole == null || (holeR - _lastAnnHole!).abs() >= 5));
    final ballChanged = (ballR != null && (_lastAnnBall == null || (ballR - _lastAnnBall!).abs() >= 5));

    if (!holeChanged && !ballChanged) return;

    final parts = <String>[];
    if (ballR != null) parts.add('Ball is $ballR yards');
    if (holeR != null) parts.add('Hole is $holeR yards');
    if (holeR != null && recName != null) parts.add('Recommended club: $recName');

    if (parts.isNotEmpty) {
      tts.say(parts.join('. ') + '.');
      _lastAnnTime = now;
      if (holeR != null) _lastAnnHole = holeR;
      if (ballR != null) _lastAnnBall = ballR;
    }
  }

  String _formatDirection(double brng, double heading) {
    final delta = (brng - heading + 360) % 360;
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final idx = ((delta + 22.5) ~/ 45) % 8;
    final side = delta <= 180 ? 'right' : 'left';
    final turn = delta <= 180 ? delta : (360 - delta);
    return '${dirs[idx]}  (${turn.toStringAsFixed(0)}° $side)';
  }
}
