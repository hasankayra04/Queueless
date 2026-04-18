// Queue screen — customer views queue and joins/leaves

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/providers.dart';

class QueueScreen extends StatefulWidget {
  final Business business;
  const QueueScreen({super.key, required this.business});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refresh() {
    final qp = context.read<QueueProvider>();
    qp.loadQueue(widget.business.id);
    qp.loadMyEntry(widget.business.id);
  }

  Future<void> _join() async {
    final qp = context.read<QueueProvider>();
    final ok = await qp.joinQueue(widget.business.id);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(qp.error ?? 'Failed to join')));
    }
  }

  Future<void> _leave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave Queue?'),
        content: const Text('You will lose your position in the queue.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Leave', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final qp = context.read<QueueProvider>();
    await qp.leaveQueue(widget.business.id);
  }

  @override
  Widget build(BuildContext context) {
    final qp = context.watch<QueueProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.business.name),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // My position card
            if (qp.myEntry != null) ...[
              _MyPositionCard(entry: qp.myEntry!, business: widget.business),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _leave,
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Leave Queue'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white),
              ),
              const SizedBox(height: 24),
            ],

            // Join button
            if (qp.myEntry == null && widget.business.isOpen) ...[
              ElevatedButton.icon(
                onPressed: qp.loading ? null : _join,
                icon: const Icon(Icons.queue),
                label: qp.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Join Queue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (!widget.business.isOpen) ...[
              const Card(
                color: Colors.orange,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white),
                      SizedBox(width: 8),
                      Text('This business is currently closed.',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Queue stats
            _QueueStats(
              totalWaiting: qp.totalWaiting,
              avgServiceTime: widget.business.avgServiceTimeMinutes,
            ),
            const SizedBox(height: 16),

            // Queue list
            Text('Current Queue (${qp.entries.length} waiting)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...qp.entries.map((e) => _QueueEntryTile(entry: e)),
          ],
        ),
      ),
    );
  }
}

class _MyPositionCard extends StatelessWidget {
  final QueueEntry entry;
  final Business business;
  const _MyPositionCard({required this.entry, required this.business});

  @override
  Widget build(BuildContext context) => Card(
        color: Colors.indigo.shade600,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text('Your Position',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Text('${entry.position}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('~${entry.estimatedWaitMinutes} min wait',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 16)),
              if (entry.priority != QueuePriority.normal) ...[
                const SizedBox(height: 8),
                _PriorityBadge(priority: entry.priority),
              ],
            ],
          ),
        ),
      );
}

class _QueueStats extends StatelessWidget {
  final int totalWaiting;
  final int avgServiceTime;
  const _QueueStats(
      {required this.totalWaiting, required this.avgServiceTime});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
              child: _StatCard(
            icon: Icons.people,
            label: 'Waiting',
            value: '$totalWaiting',
          )),
          const SizedBox(width: 12),
          Expanded(
              child: _StatCard(
            icon: Icons.timer,
            label: 'Avg. Service',
            value: '$avgServiceTime min',
          )),
        ],
      );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: Colors.indigo),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              Text(label, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
}

class _QueueEntryTile extends StatelessWidget {
  final QueueEntry entry;
  const _QueueEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: CircleAvatar(
          backgroundColor: _priorityColor(entry.priority).withOpacity(0.2),
          child: Text('${entry.position}',
              style: TextStyle(
                  color: _priorityColor(entry.priority),
                  fontWeight: FontWeight.bold)),
        ),
        title: Text(entry.customerName),
        subtitle: Text('~${entry.estimatedWaitMinutes} min'),
        trailing: entry.priority != QueuePriority.normal
            ? _PriorityBadge(priority: entry.priority)
            : null,
      );

  Color _priorityColor(QueuePriority p) => switch (p) {
        QueuePriority.urgent => Colors.red,
        QueuePriority.vip => Colors.amber.shade700,
        QueuePriority.normal => Colors.indigo,
      };
}

class _PriorityBadge extends StatelessWidget {
  final QueuePriority priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (priority) {
      QueuePriority.urgent => ('URGENT', Colors.red),
      QueuePriority.vip => ('VIP', Colors.amber.shade700),
      QueuePriority.normal => ('', Colors.transparent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
