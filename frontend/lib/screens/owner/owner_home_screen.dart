// Owner Home screen — manage businesses

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/providers.dart';
import '../../models/models.dart';
import 'queue_management_screen.dart';
import 'inventory_screen.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusinessProvider>().loadMyBusinesses();
    });
  }

  void _showCreateBusinessDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateBusinessSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final biz = context.watch<BusinessProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Businesses'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: biz.loadMyBusinesses),
          IconButton(icon: const Icon(Icons.logout), onPressed: auth.logout),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateBusinessDialog,
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Business', style: TextStyle(color: Colors.white)),
      ),
      body: biz.loading
          ? const Center(child: CircularProgressIndicator())
          : biz.myBusinesses.isEmpty
              ? const Center(
                  child: Text(
                    'No businesses yet.\nTap + to create one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: biz.myBusinesses.length,
                  itemBuilder: (ctx, i) =>
                      _BusinessManageCard(business: biz.myBusinesses[i]),
                ),
    );
  }
}

class _BusinessManageCard extends StatelessWidget {
  final Business business;
  const _BusinessManageCard({required this.business});

  @override
  Widget build(BuildContext context) {
    final biz = context.read<BusinessProvider>();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(business.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Switch(
                  value: business.isOpen,
                  onChanged: (v) => biz.toggleOpen(business.id, v),
                  activeColor: Colors.indigo,
                ),
              ],
            ),
            Text(business.category,
                style: TextStyle(color: Colors.grey.shade600)),
            if (business.address != null)
              Text(business.address!,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                QueueManagementScreen(business: business))),
                    icon: const Icon(Icons.queue, size: 18),
                    label: const Text('Queue'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                InventoryScreen(business: business))),
                    icon: const Icon(Icons.inventory, size: 18),
                    label: const Text('Inventory'),
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

class _CreateBusinessSheet extends StatefulWidget {
  const _CreateBusinessSheet();

  @override
  State<_CreateBusinessSheet> createState() => _CreateBusinessSheetState();
}

class _CreateBusinessSheetState extends State<_CreateBusinessSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  int _avgTime = 5;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _catCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final biz = context.read<BusinessProvider>();
    final b = await biz.createBusiness(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _catCtrl.text.trim(),
      address: _addrCtrl.text.trim().isEmpty ? null : _addrCtrl.text.trim(),
      avgServiceTimeMinutes: _avgTime,
    );
    if (!mounted) return;
    if (b != null) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(biz.error ?? 'Failed to create')));
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('New Business',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Business Name', border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _catCtrl,
                decoration: const InputDecoration(
                    labelText: 'Category (e.g. Bakery)', border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Description', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addrCtrl,
                decoration: const InputDecoration(
                    labelText: 'Address (optional)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Avg. service time (min):'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: _avgTime.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: '$_avgTime',
                      onChanged: (v) => setState(() => _avgTime = v.round()),
                    ),
                  ),
                  Text('$_avgTime min'),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white),
                child: const Text('Create Business'),
              ),
            ],
          ),
        ),
      );
}
