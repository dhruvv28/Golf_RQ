import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/club_service.dart';
import '../services/voice_coach.dart';

class SetupClubsScreen extends StatefulWidget {
  const SetupClubsScreen({super.key});

  @override
  State<SetupClubsScreen> createState() => _SetupClubsScreenState();
}

class _SetupClubsScreenState extends State<SetupClubsScreen> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    final svc = context.read<ClubService>();
    for (final club in ClubService.clubs) {
      _controllers[club] =
          TextEditingController(text: svc.yardsByClub[club]?.toString() ?? '');
    }
    // Announce screen entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoiceCoach>().announceScreen("Club Setup");
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    final svc = context.read<ClubService>();
    for (final entry in _controllers.entries) {
      final v = int.tryParse(entry.value.text);
      if (v != null) await svc.setYardage(entry.key, v);
    }
    // keep calling setSetupDone if you like, but routing doesn’t depend on it now
    await svc.setSetupDone(true);
    if (mounted) Navigator.pushReplacementNamed(context, '/connect');
  }

  void _continueWithoutChanges() {
    Navigator.pushReplacementNamed(context, '/connect');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalize your clubs'),
        actions: [
          IconButton(
            tooltip: 'Connect Rover',
            icon: const Icon(Icons.wifi_tethering),
            onPressed: () => Navigator.pushReplacementNamed(context, '/connect'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dear Golfer, let’s set your yardages 🎯',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'These values power your club recommendations. You can tweak them anytime.',
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                elevation: 2,
                child: ListView(
                children: ClubService.clubs.map((club) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: TextField(
                      controller: _controllers[club],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '$club (yards)',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        suffixText: 'yd',
                      ),
                    ),
                  );
                }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saveAndContinue,
                    icon: const Icon(Icons.check),
                    label: const Text('Save & continue'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _continueWithoutChanges,
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Continue (no changes)'),
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
