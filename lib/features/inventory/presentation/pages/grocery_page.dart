import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neo_bento_widgets.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/repositories/inventory_repository.dart';
import '../widgets/smart_add_item_sheet.dart';
import 'receipt_scanner_view.dart';
import '../widgets/edit_item_sheet.dart';

class GroceryPage extends StatefulWidget {
  const GroceryPage({super.key});

  @override
  State<GroceryPage> createState() => _GroceryPageState();
}

class _GroceryPageState extends State<GroceryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final user = Supabase.instance.client.auth.currentUser;
  final InventoryRepository _repository = InventoryRepository();
  bool _isLoading = false;
  List<InventoryItem> _items = [];
  String? _apartmentId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
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
        final items = await _repository.getInventoryItems(_apartmentId!);
        if (mounted) {
          setState(() {
            _items = items;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching inventory: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addGrocery() async {
    if (_apartmentId == null) return;
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Let sheet define its own background
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SmartAddItemSheet(apartmentId: _apartmentId!),
      ),
    );

    if (result == true) {
      _fetchInventory();
    }
  }

  void _scanReceipt() async {
    if (_apartmentId == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptScannerView(apartmentId: _apartmentId!),
      ),
    );
    if (result == true) {
      _fetchInventory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter by personal vs shared
    final sharedItems = _items.where((i) => !i.isPrivate).toList();
    final personalItems = _items.where((i) => i.isPrivate).toList();

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
                    Text('Inventory', style: theme.textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      onPressed: _scanReceipt,
                      icon: const Icon(Icons.document_scanner, size: 28),
                      color: AppColors.primary,
                      tooltip: "Scan Receipt",
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addGrocery,
                      icon: const Icon(Icons.add_rounded, size: 32),
                      color: AppColors.primary,
                      tooltip: "Add Item manually",
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Room'),
                  Tab(text: 'Personal'),
                ],
                labelStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                indicatorColor: AppColors.primary,
                dividerColor: Colors.transparent,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _GroceryList(
                      items: sharedItems,
                      isLoading: _isLoading,
                      onRefresh: _fetchInventory,
                    ),
                    _GroceryList(
                      items: personalItems,
                      isLoading: _isLoading,
                      onRefresh: _fetchInventory,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroceryList extends StatelessWidget {
  const _GroceryList({required this.items, required this.isLoading, required this.onRefresh});
  final List<InventoryItem> items;
  final bool isLoading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text("Pantry is empty", style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _GroceryTile(item: item, onRefresh: onRefresh);
      },
    );
  }
}

class _GroceryTile extends StatelessWidget {
  const _GroceryTile({required this.item, required this.onRefresh});
  final InventoryItem item;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expiryDate = item.expiryDate;
    
    // Determine status logic (Zero Stock = Run out)
    String statusText = "In Stock";
    Color statusColor = AppColors.success;
    
    if (item.quantity <= 0) {
      statusText = "Run out";
      statusColor = AppColors.accentRed;
    } else if (expiryDate != null && expiryDate.difference(DateTime.now()).inDays < 3 && expiryDate.difference(DateTime.now()).inDays >= 0) {
      statusText = "Expiring Soon";
      statusColor = AppColors.accentPink;
    } else if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
      statusText = "Expired";
      statusColor = AppColors.accentRed;
    }

    // Attempt to color code categories
    bool isProduce = item.category.toLowerCase().contains("produce") || item.category.toLowerCase().contains("veg");

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: NeoBentoCard(
        padding: EdgeInsets.zero,
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: EditItemSheet(
                item: item,
                onUpdated: onRefresh,
              ),
            ),
          );
        },
        child: Padding(
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
                  isProduce ? Icons.eco_rounded : Icons.fastfood_rounded,
                  color: isProduce ? AppColors.accentMint : AppColors.accentPink,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.itemName, style: theme.textTheme.titleMedium),
                    Text("Qty: ${item.quantity}", style: theme.textTheme.bodySmall),
                    if (expiryDate != null)
                      Text(
                        "Expires in ${expiryDate.difference(DateTime.now()).inDays} days",
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: expiryDate.difference(DateTime.now()).inDays < 3 ? AppColors.accentRed : null,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}