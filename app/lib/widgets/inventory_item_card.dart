import 'package:flutter/material.dart';

import '../models/inventory_item.dart';

/// Card displaying an inventory item with stock management controls.
class InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final ValueChanged<int> onUpdateStock;
  final VoidCallback onToggleOutOfStock;
  final VoidCallback onDelete;

  const InventoryItemCard({
    super.key,
    required this.item,
    required this.onUpdateStock,
    required this.onToggleOutOfStock,
    required this.onDelete,
  });

  void _showUpdateStockDialog(BuildContext context) {
    final controller = TextEditingController(text: '${item.quantity}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock: ${item.name}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New Quantity',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final quantity = int.tryParse(controller.text);
              if (quantity != null) {
                onUpdateStock(quantity);
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (item.isOutOfStock)
                  Chip(
                    label: const Text('OUT OF STOCK'),
                    backgroundColor: theme.colorScheme.errorContainer,
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                      fontSize: 11,
                    ),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'stock':
                        _showUpdateStockDialog(context);
                      case 'toggle':
                        onToggleOutOfStock();
                      case 'delete':
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'stock',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Update Stock'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: ListTile(
                        leading: Icon(
                          item.isOutOfStock
                              ? Icons.check_circle
                              : Icons.block,
                        ),
                        title: Text(
                          item.isOutOfStock
                              ? 'Mark In Stock'
                              : 'Mark Out of Stock',
                        ),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.inventory, size: 16,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${item.quantity} ${item.unit}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                if (item.autoOutOfStock) ...[
                  Icon(Icons.auto_mode, size: 16,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'Auto out-of-stock at ≤${item.lowStockThreshold}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Quick stock adjustment buttons
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: item.quantity > 0
                      ? () => onUpdateStock(item.quantity - 1)
                      : null,
                  icon: const Icon(Icons.remove),
                  iconSize: 18,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '${item.quantity}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => onUpdateStock(item.quantity + 1),
                  icon: const Icon(Icons.add),
                  iconSize: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
