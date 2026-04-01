import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neo_bento_widgets.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/repositories/inventory_repository.dart';
import '../widgets/smart_add_item_sheet.dart';

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  final user = Supabase.instance.client.auth.currentUser;
  final InventoryRepository _repository = InventoryRepository();
  bool _isLoading = false;
  List<InventoryItem> _items = [];
  String? _apartmentId;

  @override
  void initState() {
    super.initState();
    _fetchShoppingList();
  }

  Future<void> _fetchShoppingList() async {
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      if (_apartmentId == null) {
        final profileRes = await Supabase.instance.client
            .from('profiles')
            .select('apartment_id')
            .eq('id', user!.id)
            .maybeSingle();
        if (profileRes != null) {
          _apartmentId = profileRes['apartment_id'] as String?;
        }
      }

      if (_apartmentId != null) {
        final allItems = await _repository.getInventoryItems(_apartmentId!);
        // Items with quantity <= 0 are our shopping list
        if (mounted) {
          setState(() {
            _items = allItems.where((i) => i.quantity <= 0).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching shopping list: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addToList() async {
    if (_apartmentId == null) return;
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SmartAddItemSheet(
          apartmentId: _apartmentId!,
          isShoppingList: true, // Will default to 0 quantity
        ),
      ),
    );

    if (result == true) {
      _fetchShoppingList();
    }
  }

  Future<void> _markAsPurchased(InventoryItem item) async {
    try {
      // Bring quantity back to 1 (or whatever default)
      final updatedItem = InventoryItem(
        id: item.id,
        itemName: item.itemName,
        category: item.category,
        quantity: 1, 
        isVeg: item.isVeg,
        status: 'refilled',
        expiryDate: item.expiryDate,
        apartmentId: item.apartmentId,
        isPrivate: item.isPrivate,
        createdAt: item.createdAt,
      );
      await _repository.updateInventoryItem(updatedItem);
      _fetchShoppingList(); // Refresh list to remove it
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.itemName} marked as purchased!')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _removeItem(InventoryItem item) async {
    try {
      await _repository.deleteInventoryItem(item.id!);
      _fetchShoppingList();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: NeoBentoBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    Text('Shopping List', style: theme.textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      onPressed: _addToList,
                      icon: const Icon(Icons.add_shopping_cart, size: 28),
                      color: AppColors.primary,
                      tooltip: "Add Item manually",
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text("Shopping list is empty", style: theme.textTheme.bodyLarge),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return _ShoppingListTile(
                                item: item,
                                onPurchased: () => _markAsPurchased(item),
                                onRemove: () => _removeItem(item),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShoppingListTile extends StatelessWidget {
  const _ShoppingListTile({required this.item, required this.onPurchased, required this.onRemove});
  final InventoryItem item;
  final VoidCallback onPurchased;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isProduce = item.category.toLowerCase().contains("produce") || item.category.toLowerCase().contains("veg");

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: NeoBentoCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isProduce ? AppColors.bentoMint : AppColors.bentoSalmon).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.shopping_cart_checkout_outlined,
                color: isProduce ? AppColors.accentMint : AppColors.accentPink,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.itemName, style: theme.textTheme.titleMedium?.copyWith(
                    decoration: item.quantity > 0 ? TextDecoration.lineThrough : null, // If we kept it here
                  )),
                  Text(item.isPrivate ? "Personal" : "Shared", style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(
              onPressed: onPurchased,
              icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
              tooltip: "Mark as Purchased",
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, color: AppColors.accentRed),
              tooltip: "Remove from list",
            )
          ],
        ),
      ),
    );
  }
}
