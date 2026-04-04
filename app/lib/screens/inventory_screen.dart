import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/inventory_service.dart';
import '../widgets/inventory_item_card.dart';

/// Screen for managing business inventory.
///
/// Allows owners to add, update, and remove inventory items,
/// as well as manage stock levels and out-of-stock status.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryService>().fetchItems();
    });
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '0');
    final unitController = TextEditingController(text: 'pieces');
    final thresholdController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Inventory Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit (e.g., pieces, kg, boxes)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: thresholdController,
                decoration: const InputDecoration(
                  labelText: 'Low Stock Threshold',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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
              if (nameController.text.trim().isEmpty) return;

              final inventoryService = context.read<InventoryService>();
              await inventoryService.addItem(
                name: nameController.text.trim(),
                quantity: int.tryParse(quantityController.text) ?? 0,
                unit: unitController.text.trim(),
                lowStockThreshold:
                    int.tryParse(thresholdController.text) ?? 0,
              );

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryService = context.watch<InventoryService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: inventoryService.fetchItems,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: RefreshIndicator(
        onRefresh: inventoryService.fetchItems,
        child: inventoryService.isLoading
            ? const Center(child: CircularProgressIndicator())
            : inventoryService.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(
                          'No inventory items yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add your first item',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: inventoryService.items.length,
                    itemBuilder: (context, index) {
                      final item = inventoryService.items[index];
                      return InventoryItemCard(
                        item: item,
                        onUpdateStock: (quantity) {
                          inventoryService.updateStock(item.id, quantity);
                        },
                        onToggleOutOfStock: () {
                          inventoryService.setOutOfStock(
                              item.id, !item.isOutOfStock);
                        },
                        onDelete: () {
                          inventoryService.removeItem(item.id);
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
