import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/widgets/neo_bento_widgets.dart';
import 'spinner_page.dart';

class SplitBillPage extends StatefulWidget {
  final Map<String, dynamic> bill;
  const SplitBillPage({super.key, required this.bill});

  @override
  State<SplitBillPage> createState() => _SplitBillPageState();
}

class _SplitBillPageState extends State<SplitBillPage> {
  List<Map<String, dynamic>> _roommates = [];
  final Set<String> _selectedRoommates = {};
  final String _splitMethod = 'equally';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRoommates();
  }

  Future<void> _fetchRoommates() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final apartmentId = (await Supabase.instance.client.from('profiles').select('apartment_id').eq('id', user.id).single())['apartment_id'];
      final response = await Supabase.instance.client.from('profiles').select().eq('apartment_id', apartmentId);
      setState(() {
        _roommates = List<Map<String, dynamic>>.from(response);
        _selectedRoommates.addAll(_roommates.map((r) => r['id'] as String));
      });
    } catch (e) {
      debugPrint("Error fetching roommates: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSplits() async {
    if (_selectedRoommates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one roommate to split with.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final totalAmount = widget.bill['amount'] as double;
      final splitAmount = totalAmount / _selectedRoommates.length;

      for (var roommateId in _selectedRoommates) {
        await Supabase.instance.client.from('bill_splits').insert({
          'bill_id': widget.bill['id'],
          'user_id': roommateId,
          'amount_owed': splitAmount,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill split successfully!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error saving splits: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Split The Bill')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Total: \$${widget.bill['amount'].toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8.0,
                    children: _roommates.map((roommate) {
                      return ChoiceChip(
                        label: Text(roommate['username'] ?? '...'),
                        selected: _selectedRoommates.contains(roommate['id']),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedRoommates.add(roommate['id']);
                            } else {
                              _selectedRoommates.remove(roommate['id']);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  if (_splitMethod == 'equally')
                    Text('Each pays: \$${(_selectedRoommates.isNotEmpty ? widget.bill['amount'] / _selectedRoommates.length : 0).toStringAsFixed(2)}'),
                  const Spacer(),
                  SquishyButton(label: 'Confirm Split', onPressed: _saveSplits),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () async {
                      final winner = await Navigator.push(context, MaterialPageRoute(builder: (_) => SpinnerPage(roommates: _roommates)));
                      if (winner != null) {
                        setState(() {
                          _selectedRoommates.clear();
                          _selectedRoommates.add(winner['id']);
                        });
                      }
                    },
                    icon: const Icon(Icons.casino_rounded),
                    label: const Text('Spin to see who pays!'),
                  )
                ],
              ),
            ),
    );
  }
}
