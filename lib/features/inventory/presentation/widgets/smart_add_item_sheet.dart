import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/master_catalog_model.dart';
import '../../data/repositories/inventory_repository.dart';
import 'loose_item_form.dart'; 

class SmartAddItemSheet extends StatefulWidget {
  final String apartmentId;
  final bool isShoppingList;

  const SmartAddItemSheet({
    super.key, 
    required this.apartmentId,
    this.isShoppingList = false,
  });

  @override
  State<SmartAddItemSheet> createState() => _SmartAddItemSheetState();
}

class _SmartAddItemSheetState extends State<SmartAddItemSheet> {
  final TextEditingController _searchController = TextEditingController();
  final InventoryRepository _repository = InventoryRepository();
  
  List<MasterCatalogItem> _suggestions = [];
  bool _isLoading = false;
  MasterCatalogItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() async {
    final query = _searchController.text;
    if (query.length < 2) {
      if (mounted) setState(() => _suggestions = []);
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    try {
      final results = await _repository.searchMasterCatalog(query);
      if (mounted) setState(() => _suggestions = results);
    } catch (e) {
      debugPrint("Error fetching suggestions: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSuggestionSelected(MasterCatalogItem item) {
    setState(() {
      _selectedItem = item;
      _searchController.text = item.name;
      _suggestions = [];
    });
    FocusScope.of(context).unfocus();
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
          Text(
            "Add to Pantry",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Start typing (e.g., 'Onio...')",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isLoading 
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 16, height: 16, 
                      child: CircularProgressIndicator(strokeWidth: 2)
                    ),
                  ) 
                : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            ),
          ),
          
          if (_suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _suggestions[index];
                  return ListTile(
                    leading: const Icon(Icons.fastfood_outlined),
                    title: Text(item.name),
                    subtitle: Text(item.category),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => _onSuggestionSelected(item),
                  ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX();
                },
              ),
            ),

          const SizedBox(height: 24),
          
          if (_selectedItem != null || _searchController.text.isNotEmpty)
            LooseItemForm(
              itemName: _selectedItem?.name ?? _searchController.text,
              category: _selectedItem?.category ?? "room",
              defaultExpiryDays: _selectedItem?.defaultExpiryDays ?? 7,
              apartmentId: widget.apartmentId,
              isShoppingList: widget.isShoppingList,
            ).animate().fadeIn().slideY(begin: 0.1),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
