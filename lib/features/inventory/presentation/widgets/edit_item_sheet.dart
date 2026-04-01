import 'package:flutter/material.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/repositories/inventory_repository.dart';

class EditItemSheet extends StatefulWidget {
  final InventoryItem item;
  final VoidCallback onUpdated;

  const EditItemSheet({super.key, required this.item, required this.onUpdated});

  @override
  State<EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<EditItemSheet> {
  final InventoryRepository _repository = InventoryRepository();
  late int _quantity;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.item.quantity;
  }

  Future<void> _updateItem() async {
    setState(() => _isSaving = true);
    try {
      final updatedItem = InventoryItem(
        id: widget.item.id,
        itemName: widget.item.itemName,
        category: widget.item.category,
        quantity: _quantity,
        isVeg: widget.item.isVeg,
        status: _quantity > 0 ? 'refilled' : 'run out',
        expiryDate: widget.item.expiryDate,
        apartmentId: widget.item.apartmentId,
        isPrivate: widget.item.isPrivate,
        createdAt: widget.item.createdAt,
      );
      await _repository.updateInventoryItem(updatedItem);
      if (mounted) {
        widget.onUpdated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.item.itemName} updated!')),
        );
      }
    } catch (e) {
      debugPrint("Error updating item: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Remove ${widget.item.itemName} from inventory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isSaving = true);
      try {
        await _repository.deleteInventoryItem(widget.item.id!);
        if (mounted) {
          widget.onUpdated();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.item.itemName} deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Edit ${widget.item.itemName}",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _isSaving ? null : _deleteItem,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Text("Quantity", style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _quantity > 0 ? () => setState(() => _quantity--) : null,
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 32,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('$_quantity', style: theme.textTheme.headlineMedium),
              ),
              IconButton(
                onPressed: () => setState(() => _quantity++),
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 32,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_quantity == 0)
            Center(
              child: Text(
                "This item will be marked as 'Run out' and appear in Shopping List",
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _isSaving ? null : _updateItem,
              child: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("Save Changes"),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
