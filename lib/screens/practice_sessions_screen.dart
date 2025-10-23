import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/practice_session_service.dart';
import '../services/voice_coach.dart';
import '../models/practice_session.dart';

class PracticeSessionsScreen extends StatefulWidget {
  const PracticeSessionsScreen({super.key});

  @override
  State<PracticeSessionsScreen> createState() => _PracticeSessionsScreenState();
}

class _PracticeSessionsScreenState extends State<PracticeSessionsScreen> {
  @override
  void initState() {
    super.initState();
    // Announce screen entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoiceCoach>().announceScreen("Practice Sessions");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Sessions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer<PracticeSessionService>(
            builder: (context, service, child) {
              if (service.hasActiveSession) {
                return IconButton(
                  onPressed: () => _showEndSessionDialog(context, service),
                  icon: const Icon(Icons.stop),
                  tooltip: 'End Session',
                );
              }
              return IconButton(
                onPressed: () => _showStartSessionDialog(context, service),
                icon: const Icon(Icons.play_arrow),
                tooltip: 'Start Session',
              );
            },
          ),
        ],
      ),
      body: Consumer<PracticeSessionService>(
        builder: (context, service, child) {
          if (service.sessions.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (service.hasActiveSession) ...[
                _buildActiveSessionCard(context, service.currentSession!),
                const SizedBox(height: 16),
              ],
              _buildSessionsList(context, service),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 4,
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
          if (i == 2) Navigator.pushReplacementNamed(context, '/history');
          if (i == 3) Navigator.pushReplacementNamed(context, '/analytics');
          if (i == 5) Navigator.pushReplacementNamed(context, '/goals');
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_golf,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Practice Sessions Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start tracking your practice sessions to see detailed analytics and progress over time.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showStartSessionDialog(context, context.read<PracticeSessionService>()),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start First Session'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSessionCard(BuildContext context, PracticeSession session) {
    final duration = DateTime.now().difference(session.startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return Card(
      elevation: 3,
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_circle_filled, color: Colors.green[600]),
                const SizedBox(width: 8),
                Text(
                  'Active Session',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              session.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Duration: ${hours}h ${minutes}m',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.golf_course, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Shots: ${session.shotIds.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (session.courseName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    session.courseName!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEndSessionDialog(context, context.read<PracticeSessionService>()),
                    icon: const Icon(Icons.stop),
                    label: const Text('End Session'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/distance'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Shot'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsList(BuildContext context, PracticeSessionService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Previous Sessions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...service.sessions.where((s) => !s.isActive).map((session) => 
          _buildSessionCard(context, session)),
      ],
    );
  }

  Widget _buildSessionCard(BuildContext context, PracticeSession session) {
    final duration = session.duration;
    final hours = duration?.inHours ?? 0;
    final minutes = duration?.inMinutes.remainder(60) ?? 0;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.sports_golf,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          session.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${session.startTime.day}/${session.startTime.month}/${session.startTime.year}'),
            if (duration != null)
              Text('${hours}h ${minutes}m • ${session.shotIds.length} shots'),
            if (session.courseName != null)
              Text('📍 ${session.courseName}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view',
              child: const Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: const Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'view') {
              _showSessionDetails(context, session);
            } else if (value == 'delete') {
              _showDeleteConfirmation(context, session);
            }
          },
        ),
      ),
    );
  }

  void _showStartSessionDialog(BuildContext context, PracticeSessionService service) {
    final nameController = TextEditingController();
    final courseController = TextEditingController();
    final weatherController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Practice Session'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Session Name',
                  hintText: 'e.g., Short Game Practice',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: courseController,
                decoration: const InputDecoration(
                  labelText: 'Course/Location (Optional)',
                  hintText: 'e.g., Local Driving Range',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weatherController,
                decoration: const InputDecoration(
                  labelText: 'Weather Conditions (Optional)',
                  hintText: 'e.g., Sunny, 75°F',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Focus areas, goals, etc.',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await service.startSession(
                  name: nameController.text,
                  courseName: courseController.text.isNotEmpty ? courseController.text : null,
                  weatherConditions: weatherController.text.isNotEmpty ? weatherController.text : null,
                  notes: notesController.text.isNotEmpty ? notesController.text : null,
                );
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/distance');
              }
            },
            child: const Text('Start Session'),
          ),
        ],
      ),
    );
  }

  void _showEndSessionDialog(BuildContext context, PracticeSessionService service) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Practice Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('End "${service.currentSession?.name}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Session Notes (Optional)',
                hintText: 'How did it go? What did you work on?',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await service.endSession(notes: notesController.text.isNotEmpty ? notesController.text : null);
              Navigator.pop(context);
            },
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }

  void _showSessionDetails(BuildContext context, PracticeSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(session.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Date', '${session.startTime.day}/${session.startTime.month}/${session.startTime.year}'),
              if (session.duration != null)
                _buildDetailRow('Duration', '${session.duration!.inHours}h ${session.duration!.inMinutes.remainder(60)}m'),
              _buildDetailRow('Shots', '${session.shotIds.length}'),
              if (session.courseName != null)
                _buildDetailRow('Location', session.courseName!),
              if (session.weatherConditions != null)
                _buildDetailRow('Weather', session.weatherConditions!),
              if (session.notes != null) ...[
                const SizedBox(height: 8),
                const Text('Notes:', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(session.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PracticeSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text('Are you sure you want to delete "${session.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<PracticeSessionService>().deleteSession(session.id!);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
