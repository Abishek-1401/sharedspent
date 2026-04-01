import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/master_catalog_model.dart';
import '../models/inventory_item_model.dart';

class InventoryRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Hardcoded master catalog search since table doesn't exist
  Future<List<MasterCatalogItem>> searchMasterCatalog(String query) async {
    final items = [
      MasterCatalogItem(id: '1', name: 'Onion', category: 'room', defaultExpiryDays: 14),
      MasterCatalogItem(id: '2', name: 'Tomato', category: 'room', defaultExpiryDays: 10),
      MasterCatalogItem(id: '3', name: 'Milk', category: 'room', defaultExpiryDays: 7),
      MasterCatalogItem(id: '4', name: 'Bread', category: 'room', defaultExpiryDays: 5),
      MasterCatalogItem(id: '5', name: 'Eggs', category: 'room', defaultExpiryDays: 14),
      MasterCatalogItem(id: '6', name: 'Potato', category: 'room', defaultExpiryDays: 30),
      MasterCatalogItem(id: '7', name: 'Rice', category: 'room', defaultExpiryDays: 180),
      MasterCatalogItem(id: '8', name: 'Dal', category: 'room', defaultExpiryDays: 180),
      MasterCatalogItem(id: '9', name: 'Apple', category: 'room', defaultExpiryDays: 14),
      MasterCatalogItem(id: '10', name: 'Banana', category: 'room', defaultExpiryDays: 5),
      MasterCatalogItem(id: '11', name: 'Chilli', category: 'room', defaultExpiryDays: 14),
    ];
    
    final normalizedQuery = normalizeItemName(query);
    if (normalizedQuery.isEmpty) return [];

    return items
        .where((e) => normalizeItemName(e.name).contains(normalizedQuery))
        .toList();
  }

  /// Data Normalization Script
  String normalizeItemName(String input) {
    String normalized = input.toLowerCase().trim();
    
    final weightRegex = RegExp(r'\b\d+(\.\d+)?[ ]*(kg|g|lb|oz|l|ml|pcs|pk|dozen)\b');
    normalized = normalized.replaceAll(weightRegex, '');

    final adjRegex = RegExp(r'\b(red|green|yellow|fresh|organic|loose|packed|large|small|medium)\b');
    normalized = normalized.replaceAll(adjRegex, '');

    normalized = normalized.replaceAll(RegExp(r'[^\w\s]'), '');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    return normalized;
  }

  /// Add new inventory item to existing 'inventory' table
  Future<InventoryItem> addInventoryItem(InventoryItem item) async {
    final response = await _client
        .from('inventory')
        .insert(item.toJson())
        .select()
        .single();
    return InventoryItem.fromJson(response);
  }

  /// Fetch all items for an apartment
  Future<List<InventoryItem>> getInventoryItems(String apartmentId) async {
    final response = await _client
        .from('inventory')
        .select()
        .eq('apartment_id', apartmentId)
        .order('expiry_date', ascending: true);

    return (response as List)
        .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Update an existing inventory item
  Future<InventoryItem> updateInventoryItem(InventoryItem item) async {
    if (item.id == null) throw Exception("Item ID cannot be null for update");
    final response = await _client
        .from('inventory')
        .update(item.toJson())
        .eq('id', item.id!)
        .select()
        .single();
    return InventoryItem.fromJson(response);
  }

  /// Delete an inventory item
  Future<void> deleteInventoryItem(String id) async {
    await _client.from('inventory').delete().eq('id', id);
  }
}
