import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neo_bento_widgets.dart';

class GroceryPage extends StatefulWidget {
  const GroceryPage({super.key});

  @override
  State<GroceryPage> createState() => _GroceryPageState();
}

class _GroceryPageState extends State<GroceryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final user = Supabase.instance.client.auth.currentUser;
  bool _isLoading = false;
  List<Map<String, dynamic>> _groceries = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchGroceries();
  }

  Future<void> _fetchGroceries() async {
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('inventory')
          .select()
          .or('user_id.eq.${user!.id},category.eq.room');
      
      if (mounted) {
        setState(() {
          _groceries = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint("Error fetching groceries: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addGrocery() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddGrocerySheet(onAdded: _fetchGroceries),
    );
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
                    Text('Groceries', style: theme.textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      onPressed: _addGrocery,
                      icon: const Icon(Icons.add_rounded, size: 32),
                      color: AppColors.primary,
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
                      items: _groceries.where((item) => item['category'] == 'room').toList(),
                      isLoading: _isLoading,
                    ),
                    _GroceryList(
                      items: _groceries.where((item) => item['category'] == 'personal' && item['user_id'] == user?.id).toList(),
                      isLoading: _isLoading,
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
  const _GroceryList({required this.items, required this.isLoading});
  final List<Map<String, dynamic>> items;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text("No groceries found", style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _GroceryTile(item: item);
      },
    );
  }
}

class _GroceryTile extends StatelessWidget {
  const _GroceryTile({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = item['status'] ?? 'refilled';
    final isVeg = item['is_veg'] ?? false;
    final expiryDate = item['expiry_date'] != null ? DateTime.parse(item['expiry_date']) : null;
    
    Color statusColor;
    String statusText = status;
    
    if (status == 'runout') {
      statusColor = AppColors.accentRed;
      statusText = "Run out";
    } else {
      statusColor = AppColors.success;
      statusText = "Refilled";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: NeoBentoCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isVeg ? AppColors.bentoMint : AppColors.bentoSalmon).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isVeg ? Icons.eco_rounded : Icons.fastfood_rounded,
                color: isVeg ? AppColors.accentMint : AppColors.accentPink,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['item_name'] ?? 'Unknown Item', style: theme.textTheme.titleMedium),
                  if (isVeg && expiryDate != null)
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
    );
  }
}

class _AddGrocerySheet extends StatefulWidget {
  const _AddGrocerySheet({required this.onAdded});
  final VoidCallback onAdded;

  @override
  State<_AddGrocerySheet> createState() => _AddGrocerySheetState();
}

class _AddGrocerySheetState extends State<_AddGrocerySheet> {
  final _nameController = TextEditingController();
  String _category = 'room';
  bool _isVeg = false;
  DateTime? _expiryDate;
  bool _isLoading = false;

  Future<void> _save() async {
    if (_nameController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final profile = await Supabase.instance.client.from('profiles').select('apartment_id').eq('id', user.id).single();
      
      await Supabase.instance.client.from('inventory').insert({
        'item_name': _nameController.text.trim(),
        'category': _category,
        'is_veg': _isVeg,
        'status': 'refilled',
        'expiry_date': _expiryDate?.toIso8601String(),
        'apartment_id': profile['apartment_id'],
      });

      widget.onAdded();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error saving grocery: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassSheet(
      title: 'Add Grocery',
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Item Name', hintText: 'e.g. Milk, Spinach'),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text('Category:', style: theme.textTheme.titleMedium),
            const SizedBox(width: 16),
            ChoiceChip(
              label: const Text('Room'),
              selected: _category == 'room',
              onSelected: (val) => setState(() => _category = 'room'),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Personal'),
              selected: _category == 'personal',
              onSelected: (val) => setState(() => _category = 'personal'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Is it a Vegetable?'),
          subtitle: const Text('Tracks freshness/expiry'),
          value: _isVeg,
          onChanged: (val) => setState(() => _isVeg = val),
          activeThumbColor: AppColors.primary,
        ),
        if (_isVeg) ...[
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Expiry Date'),
            subtitle: Text(_expiryDate == null ? 'Not set' : _expiryDate!.toString().split(' ')[0]),
            trailing: const Icon(Icons.calendar_today_rounded),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (picked != null) setState(() => _expiryDate = picked);
            },
          ),
        ],
        const SizedBox(height: 32),
        _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SquishyButton(label: 'Add to Pantry', onPressed: _save),
      ],
    );
  }
}