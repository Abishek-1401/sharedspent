import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/models/inventory_item_model.dart';

class ReceiptScannerView extends StatefulWidget {
  final String apartmentId;

  const ReceiptScannerView({super.key, required this.apartmentId});

  @override
  State<ReceiptScannerView> createState() => _ReceiptScannerViewState();
}

class _ReceiptScannerViewState extends State<ReceiptScannerView> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();
  final InventoryRepository _repository = InventoryRepository();

  File? _imageFile;
  bool _isProcessing = false;
  bool _isSaving = false;
  List<String> _extractedLines = [];
  List<String> _detectedItems = [];
  List<String> _selectedItems = [];

  Future<void> _scanReceipt() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() {
      _imageFile = File(image.path);
      _isProcessing = true;
      _detectedItems.clear();
      _selectedItems.clear();
    });

    try {
      final inputImage = InputImage.fromFile(_imageFile!);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      _extractedLines = recognizedText.blocks.expand((block) => block.lines).map((e) => e.text).toList();
      _identifyGroceryItems(_extractedLines);
    } catch (e) {
      debugPrint("Error processing OCR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read receipt: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _identifyGroceryItems(List<String> rawText) {
    final potentialKeywords = ['onion', 'milk', 'bread', 'eggs', 'chilli', 'tomato', 'potato', 'apple', 'banana', 'rice', 'dal'];
    Set<String> foundItems = {};

    for (String line in rawText) {
      final normalizedLine = _repository.normalizeItemName(line);
      for (String keyword in potentialKeywords) {
        if (normalizedLine.contains(keyword)) {
          foundItems.add(keyword[0].toUpperCase() + keyword.substring(1));
        }
      }
    }

    setState(() {
      _detectedItems = foundItems.toList();
      _selectedItems = List.from(_detectedItems);
    });
  }

  Future<void> _addSelectedToPantry() async {
    if (_selectedItems.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      for (String name in _selectedItems) {
        final isProduce = ['Onion', 'Chilli', 'Tomato', 'Potato', 'Apple', 'Banana'].contains(name);
        final item = InventoryItem(
          itemName: name,
          category: "room",
          quantity: 1,
          isVeg: isProduce,
          status: 'refilled',
          apartmentId: widget.apartmentId,
          createdAt: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 7)),
        );
        await _repository.addInventoryItem(item);
      }
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${_selectedItems.length} items to Pantry!')),
        );
      }
    } catch (e) {
      debugPrint("Error saving bulk items: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding items: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Snap & Suggest")),
      body: _isProcessing 
        ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Analyzing Receipt..."),
              ],
            ),
          )
        : _detectedItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: theme.colorScheme.primary.withOpacity(0.5)).animate().scale(),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _scanReceipt,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Scan Receipt"),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  "Detected Items",
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text("Uncheck items you don't want to add."),
                const SizedBox(height: 16),
                
                ..._detectedItems.map((item) {
                  final isSelected = _selectedItems.contains(item);
                  return CheckboxListTile(
                    title: Text(item, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Category: Room • Qty: 1"),
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedItems.add(item);
                        } else {
                          _selectedItems.remove(item);
                        }
                      });
                    },
                  );
                }),
                
                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: (_selectedItems.isEmpty || _isSaving) ? null : _addSelectedToPantry,
                    icon: _isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.add_task),
                    label: Text(_isSaving ? "Adding..." : "Add ${_selectedItems.length} to Pantry"),
                  ),
                ),
              ],
            ).animate().slideY(begin: 0.1).fadeIn(),
    );
  }
}
