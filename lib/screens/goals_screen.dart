import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/goal_service.dart';
import '../services/voice_coach.dart';
import '../models/goal.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    // Announce screen entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoiceCoach>().announceScreen("Goals and Targets");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showCreateGoalDialog(context),
            icon: const Icon(Icons.add),
            tooltip: 'Create Goal',
          ),
        ],
      ),
      body: Consumer<GoalService>(
        builder: (context, service, child) {
          if (service.goals.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (service.overdueGoals.isNotEmpty) ...[
                _buildOverdueGoals(context, service.overdueGoals),
                const SizedBox(height: 16),
              ],
              if (service.activeGoals.isNotEmpty) ...[
                _buildActiveGoals(context, service.activeGoals),
                const SizedBox(height: 16),
              ],
              if (service.completedGoals.isNotEmpty) ...[
                _buildCompletedGoals(context, service.completedGoals),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 5,
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
          if (i == 4) Navigator.pushReplacementNamed(context, '/sessions');
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
              Icons.flag,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Goals Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Set goals to track your improvement and stay motivated in your golf practice.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showCreateGoalDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Goal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueGoals(BuildContext context, List<Goal> goals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning, color: Colors.red[600]),
            const SizedBox(width: 8),
            Text(
              'Overdue Goals',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...goals.map((goal) => _buildGoalCard(context, goal, isOverdue: true)),
      ],
    );
  }

  Widget _buildActiveGoals(BuildContext context, List<Goal> goals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.track_changes, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              'Active Goals',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...goals.map((goal) => _buildGoalCard(context, goal)),
      ],
    );
  }

  Widget _buildCompletedGoals(BuildContext context, List<Goal> goals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            Text(
              'Completed Goals',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...goals.map((goal) => _buildGoalCard(context, goal, isCompleted: true)),
      ],
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal, {bool isOverdue = false, bool isCompleted = false}) {
    Color cardColor;
    Color progressColor;
    
    if (isCompleted) {
      cardColor = Colors.green[50]!;
      progressColor = Colors.green;
    } else if (isOverdue) {
      cardColor = Colors.red[50]!;
      progressColor = Colors.red;
    } else {
      cardColor = Colors.blue[50]!;
      progressColor = Theme.of(context).primaryColor;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isCompleted)
                  Icon(Icons.check_circle, color: Colors.green[600])
                else if (isOverdue)
                  Icon(Icons.warning, color: Colors.red[600])
                else
                  Icon(_getGoalIcon(goal.type), color: progressColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              goal.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress: ${goal.progressPercentage.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: goal.progressPercentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${goal.currentValue.toStringAsFixed(1)} / ${goal.targetValue.toStringAsFixed(1)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _getGoalUnit(goal.type),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Target: ${goal.targetDate.day}/${goal.targetDate.month}/${goal.targetDate.year}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (goal.club != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      goal.club!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (!isCompleted && !isOverdue) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showEditGoalDialog(context, goal),
                      child: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _showCompleteGoalDialog(context, goal),
                      child: const Text('Complete'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getGoalIcon(GoalType type) {
    switch (type) {
      case GoalType.consistency:
        return Icons.timeline;
      case GoalType.distance:
        return Icons.straighten;
      case GoalType.accuracy:
        return Icons.gps_fixed;
      case GoalType.practice:
        return Icons.sports_golf;
      case GoalType.improvement:
        return Icons.trending_up;
    }
  }

  String _getGoalUnit(GoalType type) {
    switch (type) {
      case GoalType.consistency:
        return 'yd std dev';
      case GoalType.distance:
        return 'yards';
      case GoalType.accuracy:
        return '%';
      case GoalType.practice:
        return 'shots';
      case GoalType.improvement:
        return 'points';
    }
  }

  void _showCreateGoalDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final targetController = TextEditingController();
    final clubController = TextEditingController();
    GoalType selectedType = GoalType.improvement;
    DateTime targetDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Goal Title',
                    hintText: 'e.g., Improve 5-iron consistency',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'What do you want to achieve?',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<GoalType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Goal Type'),
                  items: GoalType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getGoalTypeName(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetController,
                  decoration: InputDecoration(
                    labelText: 'Target Value',
                    hintText: _getGoalHint(selectedType),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: clubController,
                  decoration: const InputDecoration(
                    labelText: 'Club (Optional)',
                    hintText: 'e.g., 5-iron, SW',
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text('Target Date: ${targetDate.day}/${targetDate.month}/${targetDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: targetDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        targetDate = date;
                      });
                    }
                  },
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
                if (titleController.text.isNotEmpty && 
                    descriptionController.text.isNotEmpty &&
                    targetController.text.isNotEmpty) {
                  await context.read<GoalService>().createGoal(
                    title: titleController.text,
                    description: descriptionController.text,
                    type: selectedType,
                    targetValue: double.tryParse(targetController.text) ?? 0,
                    targetDate: targetDate,
                    club: clubController.text.isNotEmpty ? clubController.text : null,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Create Goal'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGoalDialog(BuildContext context, Goal goal) {
    // Similar to create goal dialog but pre-filled
    _showCreateGoalDialog(context);
  }

  void _showCompleteGoalDialog(BuildContext context, Goal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Goal'),
        content: Text('Mark "${goal.title}" as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<GoalService>().completeGoal(goal.id!);
              Navigator.pop(context);
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  String _getGoalTypeName(GoalType type) {
    switch (type) {
      case GoalType.consistency:
        return 'Consistency (Lower std dev)';
      case GoalType.distance:
        return 'Distance (Increase avg)';
      case GoalType.accuracy:
        return 'Accuracy (Hit target %)';
      case GoalType.practice:
        return 'Practice (Shot count)';
      case GoalType.improvement:
        return 'General Improvement';
    }
  }

  String _getGoalHint(GoalType type) {
    switch (type) {
      case GoalType.consistency:
        return 'e.g., 15 (yards standard deviation)';
      case GoalType.distance:
        return 'e.g., 200 (yards average)';
      case GoalType.accuracy:
        return 'e.g., 80 (percentage)';
      case GoalType.practice:
        return 'e.g., 100 (total shots)';
      case GoalType.improvement:
        return 'e.g., 10 (improvement points)';
    }
  }
}
