import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neo_bento_widgets.dart';
import '../../../inventory/data/models/inventory_item_model.dart';
import '../../../inventory/data/repositories/inventory_repository.dart';
import 'split_bill_page.dart';

class AddBillPage extends StatefulWidget {
  const AddBillPage({super.key});

  @override
  State<AddBillPage> createState() => _AddBillPageState();
}

class _AddBillPageState extends State<AddBillPage> {
  final _storeNameController = TextEditingController();
  final List<BillItem> _items = [BillItem(name: '', price: 0)];
  bool _isLoading = false;
  List<InventoryItem> _shoppingListItems = [];
  final InventoryRepository _inventoryRepo = InventoryRepository();

  @override
  void initState() {
    super.initState();
    _fetchShoppingList();
  }

  Future<void> _fetchShoppingList() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await Supabase.instance.client.from('profiles').select('apartment_id').eq('id', user.id).maybeSingle();
      if (profile != null && profile['apartment_id'] != null) {
        final items = await _inventoryRepo.getInventoryItems(profile['apartment_id']);
        if (mounted) {
          setState(() {
            _shoppingListItems = items.where((i) => i.quantity <= 0).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching shopping list recommendations: $e");
    }
  }

  Future<void> _scanReceipt() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      // Simple heuristic for receipt parsing:
      // 1. Look for lines that look like "ItemName Price"
      // 2. Look for store name (usually the first few lines)
      
      List<BillItem> scannedItems = [];
      String? storeName;

      final List<String> lines = recognizedText.text.split('\n');
      if (lines.isNotEmpty) {
        storeName = lines.first.trim();
      }

      final priceRegex = RegExp(r'(\d+[\.,]\d{2})');

      for (String line in lines) {
        final match = priceRegex.firstMatch(line);
        if (match != null) {
          final priceStr = match.group(0)!.replaceAll(',', '.');
          final price = double.tryParse(priceStr) ?? 0;
          final name = line.replaceAll(priceStr, '').trim();
          
          if (name.isNotEmpty && price > 0) {
            scannedItems.add(BillItem(name: name, price: price));
          }
        }
      }

      setState(() {
        if (storeName != null && _storeNameController.text.isEmpty) {
          _storeNameController.text = storeName;
        }
        if (scannedItems.isNotEmpty) {
          _items.clear();
          _items.addAll(scannedItems);
        }
      });

      await textRecognizer.close();
    } catch (e) {
      debugPrint("OCR Error: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to parse receipt. Try manual entry.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addItem() {
    setState(() {
      _items.add(BillItem(name: '', price: 0));
    });
  }

  void _addRecommendedItem(InventoryItem item) {
    setState(() {
      // If there is an empty row, fill it. Else add new.
      final emptyIndex = _items.indexWhere((i) => i.name.isEmpty && i.price == 0);
      if (emptyIndex != -1) {
        _items[emptyIndex].name = item.itemName;
      } else {
        _items.add(BillItem(name: item.itemName, price: 0));
      }
      _shoppingListItems.removeWhere((i) => i.id == item.id);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _saveBill() async {
    if (_items.any((item) => item.name.isEmpty || item.price <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all item fields correctly.')));
      return;
    }

    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final apartmentId = (await Supabase.instance.client.from('profiles').select('apartment_id').eq('id', user.id).single())['apartment_id'];
      final totalAmount = _items.fold<double>(0, (sum, item) => sum + item.price);

      if (apartmentId == null) {
        throw Exception("You must be part of an apartment to add a bill.");
      }

      final billResponse = await Supabase.instance.client.from('bills').insert({
        'total_amount': totalAmount,
        'store_name': _storeNameController.text.isEmpty ? 'Miscellaneous' : _storeNameController.text,
        'creator_id': user.id,
        'apartment_id': apartmentId,
        'bill_date': DateTime.now().toIso8601String(),
      }).select().single();

      final billId = billResponse['id'];

      for (var item in _items) {
        await Supabase.instance.client.from('bill_items').insert({
          'bill_id': billId,
          'item_name': item.name,
          'price': item.price,
        });

        // --- GROCERY AUTO-REFILL LOGIC ---
        try {
          final groceryMatch = await Supabase.instance.client
              .from('inventory')
              .select()
              .eq('apartment_id', apartmentId)
              .ilike('item_name', '%${item.name}%')
              .maybeSingle();

          if (groceryMatch != null) {
            await Supabase.instance.client
                .from('inventory')
                .update({
                  'status': 'refilled',
                  'quantity': groceryMatch['quantity'] <= 0 ? 1 : groceryMatch['quantity']
                })
                .eq('id', groceryMatch['id']);
          }
        } catch (e) {
          debugPrint("Inventory auto-refill error for ${item.name}: $e");
        }
      }

      if (mounted) {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => SplitBillPage(bill: billResponse)));
      }

    } catch (e) {
      debugPrint("Error saving bill: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Bill'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _scanReceipt,
            icon: const Icon(Icons.document_scanner_outlined, color: AppColors.primary),
            tooltip: 'Scan Receipt',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _storeNameController,
              decoration: const InputDecoration(labelText: 'Store Name (Optional)'),
            ),
            const SizedBox(height: 16),
            if (_shoppingListItems.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Shopping List Recommendations', style: Theme.of(context).textTheme.labelLarge),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _shoppingListItems.length,
                  itemBuilder: (context, index) {
                    final item = _shoppingListItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        avatar: const Icon(Icons.add_shopping_cart, size: 16),
                        label: Text(item.itemName),
                        onPressed: () => _addRecommendedItem(item),
                        backgroundColor: AppColors.accentPink.withOpacity(0.1),
                        side: const BorderSide(color: AppColors.accentPink),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return _BillItemTile(
                    item: _items[index],
                    onRemove: () => _removeItem(index),
                  );
                },
              ),
            ),
            TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              SquishyButton(label: 'Save Bill', onPressed: _saveBill),
          ],
        ),
      ),
    );
  }
}

class BillItem {
  String name;
  double price;
  BillItem({required this.name, required this.price});
}

class _BillItemTile extends StatelessWidget {
  final BillItem item;
  final VoidCallback onRemove;

  const _BillItemTile({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: item.name,
              onChanged: (value) => item.name = value,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: TextFormField(
              initialValue: item.price.toString(),
              onChanged: (value) => item.price = double.tryParse(value) ?? 0,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: AppColors.accentRed),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
