import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/queue_entry.dart';
import '../services/auth_service.dart';
import '../services/queue_service.dart';
import 'inventory_screen.dart';

/// Dashboard for business owners.
///
/// Shows queue management, serve next customer, priority controls,
/// and navigation to inventory management.
class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QueueService>().fetchQueue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final queueService = context.watch<QueueService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Inventory',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InventoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => queueService.fetchQueue(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: auth.logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: queueService.fetchQueue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stats row
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              '${queueService.waitingCount}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'In Queue',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              '~${queueService.waitingCount * 5}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Min Wait',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Serve next button
              FilledButton.icon(
                onPressed: queueService.waitingCount > 0
                    ? () async {
                        final entry = await queueService.serveNext();
                        if (entry != null && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Now serving: ${entry.customerName}'),
                            ),
                          );
                        }
                      }
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Serve Next Customer'),
              ),
              const SizedBox(height: 24),

              // Queue list
              Text('Queue', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),

              if (queueService.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (queueService.queue.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 48,
                            color: theme.colorScheme.primary),
                        const SizedBox(height: 8),
                        Text(
                          'No one in queue',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...queueService.queue.map(
                  (entry) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            _priorityColor(entry.priority, theme),
                        child: Text(
                          '${entry.position}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(entry.customerName),
                      subtitle: Text(
                        '${entry.priority.name.toUpperCase()} • ~${entry.estimatedWaitMinutes} min',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          switch (value) {
                            case 'vip':
                              await queueService.setPriority(
                                  entry.id, QueuePriority.vip);
                            case 'urgent':
                              await queueService.setPriority(
                                  entry.id, QueuePriority.urgent);
                            case 'normal':
                              await queueService.setPriority(
                                  entry.id, QueuePriority.normal);
                            case 'remove':
                              await queueService.leaveQueue(entry.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'vip',
                            child: ListTile(
                              leading: Icon(Icons.star, color: Colors.amber),
                              title: Text('Set VIP'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'urgent',
                            child: ListTile(
                              leading: Icon(Icons.priority_high,
                                  color: Colors.red),
                              title: Text('Set Urgent'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'normal',
                            child: ListTile(
                              leading: Icon(Icons.person),
                              title: Text('Set Normal'),
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'remove',
                            child: ListTile(
                              leading: Icon(Icons.remove_circle,
                                  color: Colors.red),
                              title: Text('Remove'),
                            ),
                          ),
                        ],
                      ),
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
