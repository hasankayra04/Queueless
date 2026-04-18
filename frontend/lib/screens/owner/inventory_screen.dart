// Inventory screen — owner manages stock levels

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/providers.dart';

class InventoryScreen extends StatefulWidget {
  final Business business;
  const InventoryScreen({super.key, required this.business});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadInventory(widget.business.id);
    });
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddItemSheet(businessId: widget.business.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.business.name} — Inventory'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => inv.loadInventory(widget.business.id),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: inv.loading
          ? const Center(child: CircularProgressIndicator())
          : inv.items.isEmpty
              ? const Center(
                  child: Text('No inventory items.\nTap + to add one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: inv.items.length,
                  itemBuilder: (ctx, i) => _InventoryTile(
                    item: inv.items[i],
                    businessId: widget.business.id,
                  ),
                ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  final InventoryItem item;
  final String businessId;
  const _InventoryTile({required this.item, required this.businessId});

  Future<void> _updateQty(BuildContext context) async {
    final ctrl = TextEditingController(text: '${item.quantity}');
    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Update Quantity: ${item.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'New Quantity', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, int.tryParse(ctrl.text)),
              child: const Text('Update')),
        ],
      ),
    );
    if (result == null || !context.mounted) return;
    await context
        .read<InventoryProvider>()
        .updateQuantity(businessId, item.id, result);
  }

  Future<void> _markOutOfStock(BuildContext context) async {
    await context
        .read<InventoryProvider>()
        .markOutOfStock(businessId, item.id);
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete "${item.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context
        .read<InventoryProvider>()
        .deleteItem(businessId, item.id);
  }

  Color get _statusColor => switch (item.status) {
        InventoryStatus.available => Colors.green,
        InventoryStatus.limited => Colors.orange,
        InventoryStatus.outOfStock => Colors.red,
      };

  String get _statusLabel => switch (item.status) {
        InventoryStatus.available => 'In Stock',
        InventoryStatus.limited => 'Limited',
        InventoryStatus.outOfStock => 'Out of Stock',
      };

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _statusColor.withOpacity(0.15),
            child: Icon(Icons.inventory_2, color: _statusColor),
          ),
          title: Text(item.name,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Qty: ${item.quantity}'),
              if (item.price != null)
                Text('\$${item.price!.toStringAsFixed(2)}'),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusChip(label: _statusLabel, color: _statusColor),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'update') _updateQty(context);
                  if (v == 'oos') _markOutOfStock(context);
                  if (v == 'delete') _delete(context);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'update', child: Text('Update Quantity')),
                  const PopupMenuItem(
                      value: 'oos', child: Text('Mark Out of Stock')),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _AddItemSheet extends StatefulWidget {
  final String businessId;
  const _AddItemSheet({required this.businessId});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '0');
  final _priceCtrl = TextEditingController();
  final _threshCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _threshCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final inv = context.read<InventoryProvider>();
    final ok = await inv.addItem(
      widget.businessId,
      name: _nameCtrl.text.trim(),
      quantity: int.tryParse(_qtyCtrl.text) ?? 0,
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      lowStockThreshold: int.tryParse(_threshCtrl.text),
      price: double.tryParse(_priceCtrl.text),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(inv.error ?? 'Failed to add item')));
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
              Text('Add Inventory Item',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Item Name', border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Quantity', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Price (\$)', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _threshCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Low Stock Threshold (optional)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white),
                child: const Text('Add Item'),
              ),
            ],
          ),
        ),
      );
}
