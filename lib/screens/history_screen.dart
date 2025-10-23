import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../services/db_service.dart';
import '../services/voice_coach.dart';
import '../models/shot.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Announce screen entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoiceCoach>().announceScreen("Shot History");
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DbService>();

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: StreamBuilder<List<Shot>>(
        stream: db.shotsStream,
        initialData: const <Shot>[],
        builder: (context, snap) {
          debugPrint('[HistoryScreen] StreamBuilder snapshot: ${snap.connectionState}, data: ${snap.data?.length ?? 0} shots');
          final shots = snap.data ?? const <Shot>[];
          if (shots.isEmpty) {
            return const Center(
              child: Text('No shots yet. Save one on Distance screen.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: shots.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final s = shots[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.golf_course),
                  title: Text('${s.club} • ${s.distance.toStringAsFixed(0)} yd'),
                  subtitle: Text(
                    '${s.timestamp}\n(${s.lat.toStringAsFixed(5)}, ${s.lon.toStringAsFixed(5)})',
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.straighten), label: 'Distance'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Club'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.sports_golf), label: 'Sessions'),
          NavigationDestination(icon: Icon(Icons.flag), label: 'Goals'),
        ],
        onDestinationSelected: (i) {
          if (i == 0) Navigator.pushReplacementNamed(context, '/distance');
          if (i == 1) Navigator.pushReplacementNamed(context, '/recommend');
          if (i == 3) Navigator.pushReplacementNamed(context, '/analytics');
          if (i == 4) Navigator.pushReplacementNamed(context, '/sessions');
          if (i == 5) Navigator.pushReplacementNamed(context, '/goals');
        },
      ),
    );
  }
}
