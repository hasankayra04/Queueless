import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/queue_entry.dart';
import '../services/auth_service.dart';
import '../services/queue_service.dart';
import '../widgets/queue_position_card.dart';

/// Home screen for customers.
///
/// Shows the customer's queue position, estimated wait time,
/// and allows joining or leaving the queue.
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch queue data on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      final queueService = context.read<QueueService>();
      queueService.fetchQueue();
      if (auth.currentUser != null) {
        queueService.fetchMyPosition(auth.currentUser!.id);
      }
    });
  }

  Future<void> _joinQueue() async {
    final auth = context.read<AuthService>();
    final queueService = context.read<QueueService>();
    final user = auth.currentUser!;

    await queueService.joinQueue(
      customerId: user.id,
      customerName: user.name,
    );

    if (mounted) {
      queueService.fetchMyPosition(user.id);
    }
  }

  Future<void> _leaveQueue(String entryId) async {
    final auth = context.read<AuthService>();
    final queueService = context.read<QueueService>();

    await queueService.leaveQueue(entryId);

    if (mounted) {
      queueService.fetchMyPosition(auth.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final queueService = context.watch<QueueService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QueueLess'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              queueService.fetchQueue();
              if (auth.currentUser != null) {
                queueService.fetchMyPosition(auth.currentUser!.id);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: auth.logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await queueService.fetchQueue();
          if (auth.currentUser != null) {
            await queueService.fetchMyPosition(auth.currentUser!.id);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Greeting
              Text(
                'Welcome, ${auth.currentUser?.name ?? "Customer"}!',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),

              // Queue position card
              if (queueService.myPosition != null)
                QueuePositionCard(
                  position: queueService.myPosition!['position'] as int,
                  estimatedWait:
                      queueService.myPosition!['estimatedWaitMinutes'] as int,
                  priority: queueService.myPosition!['priority'] as String,
                  onLeave: () => _leaveQueue(
                    queueService.myPosition!['entryId'] as String,
                  ),
                )
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.queue,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'You are not in the queue',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${queueService.waitingCount} people currently waiting',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed:
                              queueService.isLoading ? null : _joinQueue,
                          icon: const Icon(Icons.add),
                          label: const Text('Join Queue'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Live queue view
              Text(
                'Current Queue',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              if (queueService.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (queueService.queue.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Queue is empty',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ...queueService.queue.map(
                  (entry) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _priorityColor(entry.priority, theme),
                        child: Text('${entry.position}'),
                      ),
                      title: Text(entry.customerName),
                      subtitle: Text(
                        '${entry.priority.name.toUpperCase()} • ~${entry.estimatedWaitMinutes} min wait',
                      ),
                      trailing: entry.customerId == auth.currentUser?.id
                          ? const Chip(label: Text('You'))
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _priorityColor(QueuePriority priority, ThemeData theme) {
    switch (priority) {
      case QueuePriority.urgent:
        return theme.colorScheme.error;
      case QueuePriority.vip:
        return Colors.amber;
      case QueuePriority.normal:
        return theme.colorScheme.primary;
    }
  }
}
