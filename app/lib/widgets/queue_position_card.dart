import 'package:flutter/material.dart';

/// Card showing the customer's current position in the queue.
///
/// Displays position number, estimated wait time, priority level,
/// and a button to leave the queue.
class QueuePositionCard extends StatelessWidget {
  final int position;
  final int estimatedWait;
  final String priority;
  final VoidCallback onLeave;

  const QueuePositionCard({
    super.key,
    required this.position,
    required this.estimatedWait,
    required this.priority,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Your Position',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer,
              ),
              child: Center(
                child: Text(
                  '$position',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, size: 18),
                const SizedBox(width: 4),
                Text(
                  'Estimated wait: ~$estimatedWait min',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(priority.toUpperCase()),
              backgroundColor: _priorityColor(priority, theme),
              labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onLeave,
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Leave Queue'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(String priority, ThemeData theme) {
    switch (priority) {
      case 'urgent':
        return theme.colorScheme.error;
      case 'vip':
        return Colors.amber;
      default:
        return theme.colorScheme.primary;
    }
  }
}
