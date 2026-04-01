import 'package:flutter/material.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/repositories/inventory_repository.dart';

class LooseItemForm extends StatefulWidget {
  final String itemName;
  final String category;
  final int defaultExpiryDays;
  final String apartmentId;
  final bool isShoppingList;

  const LooseItemForm({
    super.key,
    required this.itemName,
    required this.category,
    required this.defaultExpiryDays,
    required this.apartmentId,
    this.isShoppingList = false,
  });

  @override
  State<LooseItemForm> createState() => _LooseItemFormState();
}

class _LooseItemFormState extends State<LooseItemForm> {
  final InventoryRepository _repository = InventoryRepository();
  late final TextEditingController _quantityController;
  final TextEditingController _priceController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.isShoppingList ? "0" : "1");
  }
  
  String _selectedUnit = 'pcs'; 
  bool _isPrivate = false;
  bool _isSubmitting = false;

  final List<String> _units = ['kg', 'g', 'lbs', 'pcs', 'pk', 'dozen'];

  void _onPresetTapped(String value) {
    setState(() {
      _quantityController.text = value;
    });
  }

  Future<void> _submit() async {
    final qty = int.tryParse(_quantityController.text) ?? 1;
    
    setState(() => _isSubmitting = true);

    try {
      final nameWithUnit = _selectedUnit == 'pcs' ? widget.itemName : "${widget.itemName} ($_selectedUnit)";
      final bool isProduce = widget.category.toLowerCase().contains("produce") || widget.category.toLowerCase().contains("veg");

      final item = InventoryItem(
        itemName: nameWithUnit,
        category: _isPrivate ? 'personal' : 'room',
        quantity: qty,
        isVeg: isProduce,
        status: widget.isShoppingList ? 'run out' : 'refilled',
        expiryDate: DateTime.now().add(Duration(days: widget.defaultExpiryDays)),
        apartmentId: widget.apartmentId,
        isPrivate: _isPrivate,
        createdAt: DateTime.now(),
      );

      await _repository.addInventoryItem(item);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.itemName} added to Pantry!')),
        );
      }
    } catch (e) {
      debugPrint("Error adding item: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add item: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.itemName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${widget.category} • Expiry: ${widget.defaultExpiryDays} days",
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text("Quantity (Whole Numbers)", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedUnit,
                  items: _units.map((u) {
                    return DropdownMenuItem(value: u, child: Text(u));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedUnit = val);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['1', '2', '3', '4'].map((preset) {
            return ActionChip(
              label: Text(preset),
              onPressed: () => _onPresetTapped(preset),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        Text("Price (Optional)", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: "₹ ",
            hintText: "e.g., 50",
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(height: 16),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Mark as Personal"),
          subtitle: const Text("Hide from roommates"),
          value: _isPrivate,
          onChanged: (val) => setState(() => _isPrivate = val),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.add_shopping_cart),
            label: Text(_isSubmitting ? "Adding..." : (widget.isShoppingList ? "Add to Shopping List" : "Add to Pantry")),
          ),
        ),
      ],
    );
  }
}
