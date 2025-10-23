import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/club_service.dart';
import '../services/voice_coach.dart';

class RecommendScreen extends StatefulWidget {
  const RecommendScreen({super.key});

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    final svc = context.read<ClubService>();
    _ctrls = {
      for (final e in svc.currentYardages.entries)
        e.key: TextEditingController(text: e.value.toString()),
    };
    // Announce screen entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoiceCoach>().announceScreen("Club Recommendations");
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final svc = context.read<ClubService>();
    final map = {
      for (final e in _ctrls.entries)
        e.key: int.tryParse(e.value.text.trim()) ?? 0,
    };
    await svc.saveYardages(map);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yardages saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keys = _ctrls.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Recommend')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Edit your carry distances. Club recommendations on Distance use these values.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              for (final k in keys) ...[
                TextFormField(
                  controller: _ctrls[k],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: k,
                    suffixText: 'yd',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (s) {
                    final v = int.tryParse((s ?? '').trim());
                    if (v == null || v <= 0) return 'Enter a positive number';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
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
          if (i == 2) Navigator.pushReplacementNamed(context, '/history');
          if (i == 3) Navigator.pushReplacementNamed(context, '/analytics');
          if (i == 4) Navigator.pushReplacementNamed(context, '/sessions');
          if (i == 5) Navigator.pushReplacementNamed(context, '/goals');
        },
      ),
    );
  }
}
