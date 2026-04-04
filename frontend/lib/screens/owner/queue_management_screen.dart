// Queue Management screen — owner manages the queue (serve, prioritize)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/providers.dart';

class QueueManagementScreen extends StatefulWidget {
  final Business business;
  const QueueManagementScreen({super.key, required this.business});

  @override
  State<QueueManagementScreen> createState() => _QueueManagementScreenState();
}

class _QueueManagementScreenState extends State<QueueManagementScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refresh() =>
      context.read<QueueProvider>().loadQueue(widget.business.id);

  Future<void> _serveNext() async {
    final qp = context.read<QueueProvider>();
    final ok = await qp.serveNext(widget.business.id);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(qp.error ?? 'Error')));
    }
  }

  Future<void> _serveSpecific(String entryId) async {
    final qp = context.read<QueueProvider>();
    await qp.serveNext(widget.business.id, entryId: entryId);
  }

  Future<void> _setPriority(String entryId, QueuePriority current) async {
    final priority = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Set Priority'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'normal'),
            child: const Text('Normal'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'vip'),
            child:
                const Text('VIP', style: TextStyle(color: Colors.amber)),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'urgent'),
            child:
                const Text('Urgent', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (priority == null || !mounted) return;
    final qp = context.read<QueueProvider>();
    await qp.setPriority(widget.business.id, entryId, priority);
  }

  @override
  Widget build(BuildContext context) {
    final qp = context.watch<QueueProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.business.name} — Queue'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            color: Colors.indigo.shade50,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(label: 'Waiting', value: '${qp.totalWaiting}'),
                _Stat(
                    label: 'Avg. Time',
                    value: '${widget.business.avgServiceTimeMinutes} min'),
              ],
            ),
          ),

          // Serve next button
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: qp.entries.isEmpty ? null : _serveNext,
              icon: const Icon(Icons.skip_next),
              label: const Text('Serve Next Customer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),

          // Queue list
          Expanded(
            child: qp.loading
                ? const Center(child: CircularProgressIndicator())
                : qp.entries.isEmpty
                    ? const Center(child: Text('Queue is empty'))
                    : ListView.builder(
                        itemCount: qp.entries.length,
                        itemBuilder: (ctx, i) {
                          final entry = qp.entries[i];
                          return _EntryManageTile(
                            entry: entry,
                            avgServiceTime:
                                widget.business.avgServiceTimeMinutes,
                            onServe: () => _serveSpecific(entry.id),
                            onPriority: () =>
                                _setPriority(entry.id, entry.priority),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      );
}

class _EntryManageTile extends StatelessWidget {
  final QueueEntry entry;
  final int avgServiceTime;
  final VoidCallback onServe;
  final VoidCallback onPriority;

  const _EntryManageTile({
    required this.entry,
    required this.avgServiceTime,
    required this.onServe,
    required this.onPriority,
  });

  Color get _priorityColor => switch (entry.priority) {
        QueuePriority.urgent => Colors.red,
        QueuePriority.vip => Colors.amber.shade700,
        QueuePriority.normal => Colors.indigo,
      };

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _priorityColor.withOpacity(0.15),
            child: Text('${entry.position}',
                style: TextStyle(
                    color: _priorityColor, fontWeight: FontWeight.bold)),
          ),
          title: Text(entry.customerName),
          subtitle: Text('~${entry.estimatedWaitMinutes} min'
              '${entry.note != null ? " • ${entry.note}" : ""}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (entry.priority != QueuePriority.normal)
                _PriorityChip(priority: entry.priority),
              IconButton(
                tooltip: 'Set Priority',
                icon: const Icon(Icons.star_border),
                onPressed: onPriority,
              ),
              IconButton(
                tooltip: 'Serve Now',
                icon: const Icon(Icons.check_circle_outline,
                    color: Colors.green),
                onPressed: onServe,
              ),
            ],
          ),
        ),
      );
}

class _PriorityChip extends StatelessWidget {
  final QueuePriority priority;
  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (priority) {
      QueuePriority.urgent => ('URGENT', Colors.red),
      QueuePriority.vip => ('VIP', Colors.amber.shade700),
      QueuePriority.normal => ('', Colors.transparent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
