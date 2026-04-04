// Customer Home screen — browse businesses and join queues

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/providers.dart';
import 'queue_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusinessProvider>().loadBusinesses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bizProvider = context.watch<BusinessProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('QueueLess'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: bizProvider.loadBusinesses,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: auth.logout,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(name: auth.user?.name ?? ''),
          Expanded(
            child: bizProvider.loading
                ? const Center(child: CircularProgressIndicator())
                : bizProvider.businesses.isEmpty
                    ? const Center(
                        child: Text('No businesses available yet.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: bizProvider.businesses.length,
                        itemBuilder: (ctx, i) =>
                            _BusinessCard(business: bizProvider.businesses[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  const _Header({required this.name});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: Colors.indigo.shade50,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, $name 👋',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Find a business and join the queue.',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
}

class _BusinessCard extends StatelessWidget {
  final Business business;
  const _BusinessCard({required this.business});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.indigo.shade100,
            child: const Icon(Icons.store, color: Colors.indigo),
          ),
          title: Text(business.name,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(business.category),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusChip(isOpen: business.isOpen),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => QueueScreen(business: business)),
          ),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  final bool isOpen;
  const _StatusChip({required this.isOpen});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isOpen ? Colors.green.shade100 : Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isOpen ? 'Open' : 'Closed',
          style: TextStyle(
            color: isOpen ? Colors.green.shade700 : Colors.red.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
