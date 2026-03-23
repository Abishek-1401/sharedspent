import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neo_bento_widgets.dart';
import 'add_bill_page.dart';
import 'bill_details_page.dart';

class BillPage extends StatefulWidget {
  const BillPage({super.key});

  @override
  State<BillPage> createState() => _BillPageState();
}

class _BillPageState extends State<BillPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final user = Supabase.instance.client.auth.currentUser;
  bool _isLoading = false;
  List<Map<String, dynamic>> _mySplits = [];
  List<Map<String, dynamic>> _roomBills = [];
  double _youOwe = 0;
  double _youAreOwed = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchBillData();
  }

  Future<void> _fetchBillData() async {
    if (user == null) return;
    if (mounted) setState(() => _isLoading = true);

    try {
      // Fetch what I owe
      final mySplitsResponse = await Supabase.instance.client
          .from('bill_splits')
          .select('*, bill:expenses(*)')
          .eq('user_id', user!.id)
          .neq('status', 'paid');
      
      if (mounted) {
        _mySplits = List<Map<String, dynamic>>.from(mySplitsResponse);
        _youOwe = _mySplits.fold(0, (sum, split) => sum + (split['amount_owed'] - split['amount_paid']));
      }

      // Fetch what others owe me from bills I created
      final myBillsResponse = await Supabase.instance.client
          .from('expenses')
          .select('*, splits:bill_splits(*)')
          .eq('paid_by', user!.id);

      if (mounted) {
        _youAreOwed = 0;
        for (var bill in myBillsResponse) {
          for (var split in bill['splits']) {
            if (split['user_id'] != user!.id) {
              _youAreOwed += (split['amount_owed'] - split['amount_paid']);
            }
          }
        }
      }

      // Fetch all room bills
      final profileResponse = await Supabase.instance.client.from('profiles').select('apartment_id').eq('id', user!.id).maybeSingle();
      if (profileResponse != null && profileResponse['apartment_id'] != null) {
        final apartmentId = profileResponse['apartment_id'];
        final roomBillsResponse = await Supabase.instance.client
            .from('expenses')
            .select('*, paid_by_user:profiles!expenses_paid_by_fkey(username, avatar_url), splits:bill_splits(*, user:profiles(username, avatar_url))')
            .eq('apartment_id', apartmentId)
            .order('bill_date', ascending: false);
        
        if (mounted) {
          _roomBills = List<Map<String, dynamic>>.from(roomBillsResponse);
        }
      }

    } catch (e) {
      debugPrint("Error fetching bills: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddBillOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassSheet(
        title: 'Add a New Bill',
        children: [
          ListTile(
            leading: const Icon(Icons.document_scanner_outlined, size: 32),
            title: const Text('Scan Receipt (OCR)'),
            subtitle: const Text('Automatically detect items and prices'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement OCR flow
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.edit_note_rounded, size: 32),
            title: const Text('Enter Manually'),
            subtitle: const Text('Add items and split with roomies'),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddBillPage()));
              if (result == true) {
                _fetchBillData();
              }
            },
          ),
        ],
      ),
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
                    Text('Bills & Expenses', style: theme.textTheme.titleLarge),
                  ],
                ),
              ),
              _buildSummaryCard(),
              TabBar(
                controller: _tabController,
                tabs: const [Tab(text: 'Your Splits'), Tab(text: 'Room Bills')],
                labelStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                indicatorColor: AppColors.primary,
                dividerColor: Colors.transparent,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _BillList(bills: _mySplits, isLoading: _isLoading, isSplitView: true),
                    _BillList(bills: _roomBills, isLoading: _isLoading, isSplitView: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBillOptions,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SquishyCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryItem(title: 'You Owe', amount: _youOwe, color: AppColors.accentRed),
            const VerticalDivider(width: 20, thickness: 1),
            _SummaryItem(title: 'You are Owed', amount: _youAreOwed, color: AppColors.success),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.title, required this.amount, required this.color});
  final String title;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _BillList extends StatelessWidget {
  const _BillList({required this.bills, required this.isLoading, required this.isSplitView});
  final List<Map<String, dynamic>> bills;
  final bool isLoading;
  final bool isSplitView;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (bills.isEmpty) {
      return Center(
        child: Text(isSplitView ? 'No pending splits. You are all settled up!' : 'No bills found for this room yet.'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final data = bills[index];
        final bill = isSplitView ? data['bill'] : data;
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BillDetailsPage(bill: bill))),
          child: _BillTile(bill: bill, split: isSplitView ? data : null),
        );
      },
    );
  }
}

class _BillTile extends StatelessWidget {
  const _BillTile({required this.bill, this.split});
  final Map<String, dynamic> bill;
  final Map<String, dynamic>? split;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = split != null ? (split!['amount_owed'] - split!['amount_paid']) : (bill['amount']?.toDouble() ?? 0.0);
    final status = split?['status'] ?? 'paid';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: NeoBentoCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.receipt_long_rounded, size: 40, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bill['store_name'] ?? 'Unknown Store', style: theme.textTheme.titleMedium),
                  Text(
                    split != null
                        ? 'You owe: \$${amount.toStringAsFixed(2)}'
                        : 'Paid by ${bill['paid_by_user']?['username'] ?? '-'}',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (split != null)
                  Text(status.replaceAll('_', ' ').toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: _getStatusColor(status))),
              ],
            )
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'unpaid':
        return AppColors.accentRed;
      case 'partially_paid':
        return AppColors.accentYellow;
      default:
        return AppColors.success;
    }
  }
}