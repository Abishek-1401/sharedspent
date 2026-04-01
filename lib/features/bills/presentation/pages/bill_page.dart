import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neo_bento_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_bill_page.dart';
import 'bill_details_page.dart';
import 'spinner_page.dart';

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
  Map<String, Map<String, dynamic>> _settleUpOwed = {};
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
          .select('*, bill:bills(*, creator:profiles!bills_creator_id_fkey(id, username, avatar_url))')
          .eq('user_id', user!.id)
          .neq('status', 'paid');
      
      if (mounted) {
        _mySplits = List<Map<String, dynamic>>.from(mySplitsResponse);
        _youOwe = _mySplits.fold(0, (sum, split) => sum + (split['amount_owed'] - (split['amount_paid'] ?? 0)));
        
        // Group for Settle Up
        _settleUpOwed.clear();
        for (var split in _mySplits) {
          final bill = split['bill'];
          if (bill == null || bill['creator'] == null) continue;
          final creator = bill['creator'];
          final creatorId = creator['id'];
          final amount = split['amount_owed'] - (split['amount_paid'] ?? 0);
          
          if (!_settleUpOwed.containsKey(creatorId)) {
            _settleUpOwed[creatorId] = {
              'user': creator,
              'total_owed': 0.0,
              'splits': <Map<String, dynamic>>[]
            };
          }
          _settleUpOwed[creatorId]!['total_owed'] += amount;
          _settleUpOwed[creatorId]!['splits'].add(split);
        }
      }

      // Fetch what others owe me from bills I created
      final myBillsResponse = await Supabase.instance.client
          .from('bills')
          .select('*, splits:bill_splits(*)')
          .eq('creator_id', user!.id);

      if (mounted) {
        _youAreOwed = 0;
        for (var bill in myBillsResponse) {
          for (var split in bill['splits']) {
            if (split['user_id'] != user!.id) {
              _youAreOwed += (split['amount_owed'] - (split['amount_paid'] ?? 0));
            }
          }
        }
      }

      // Fetch all room bills
      final profileResponse = await Supabase.instance.client.from('profiles').select('apartment_id').eq('id', user!.id).maybeSingle();
      if (profileResponse != null && profileResponse['apartment_id'] != null) {
        final apartmentId = profileResponse['apartment_id'];
        
        // Cannot use foreign key join for creator_id, so we fetch splits' users and manually fetch creator profiles
        final roomBillsResponse = await Supabase.instance.client
            .from('bills')
            .select('*, splits:bill_splits(*, user:profiles(username, avatar_url))')
            .eq('apartment_id', apartmentId)
            .order('bill_date', ascending: false);
        
        final profilesResponse = await Supabase.instance.client.from('profiles').select('id, username, avatar_url').eq('apartment_id', apartmentId);
        final profileMap = {for (var p in profilesResponse) p['id']: p};

        if (mounted) {
          _roomBills = List<Map<String, dynamic>>.from(roomBillsResponse).map((bill) {
            bill['paid_by_user'] = profileMap[bill['creator_id']];
            return bill;
          }).toList();
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

  Future<void> _makePayment(double amount, String app, String roomieName, List<Map<String, dynamic>> splitsToSettle) async {
    final upiId = "your-upi-id@oksbi"; // In a real app, this would be their dynamic UPI
    
    String urlStr;
    if (app == 'gpay') {
      urlStr = 'gpay://upi/pay?pa=$upiId&pn=$roomieName&am=$amount&cu=INR';
    } else if (app == 'phonepe') {
      urlStr = 'phonepe://pay?pa=$upiId&pn=$roomieName&am=$amount&cu=INR';
    } else {
      urlStr = 'paytmmp://pay?pa=$upiId&pn=$roomieName&am=$amount&cu=INR';
    }

    final url = Uri.parse(urlStr);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch $app. Marking as paid internally.')));
      }

      // Automatically mark all these splits as paid
      setState(() => _isLoading = true);
      for (var split in splitsToSettle) {
        await Supabase.instance.client.from('bill_splits').update({'status': 'paid', 'amount_paid': split['amount_owed']}).eq('id', split['id']);
      }
      _fetchBillData(); // Refresh UI
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settled up successfully!')));
    } catch (e) {
      debugPrint("Payment launch error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showSettleUpOptions(Map<String, dynamic> group) {
    final amount = group['total_owed'] as double;
    final userName = group['user']['username'] ?? 'Roomie';
    final splits = group['splits'] as List<Map<String, dynamic>>;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassSheet(
        title: 'Settle Up with $userName',
        children: [
          Text('Batch Pay: \$${amount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Pays off ${splits.length} bills', style: Theme.of(context).textTheme.labelMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_rounded, color: Colors.blue),
            title: const Text('Google Pay'),
            onTap: () {
              Navigator.pop(context);
              _makePayment(amount, 'gpay', userName, splits);
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_rounded, color: Colors.purple),
            title: const Text('PhonePe'),
            onTap: () {
              Navigator.pop(context);
              _makePayment(amount, 'phonepe', userName, splits);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openSpinner() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    setState(() => _isLoading = true);
    try {
      final profile = await Supabase.instance.client.from('profiles').select('apartment_id').eq('id', user.id).maybeSingle();
      final apartmentId = profile?['apartment_id'];
      if (apartmentId != null) {
        final response = await Supabase.instance.client.from('profiles').select().eq('apartment_id', apartmentId);
        final list = List<Map<String,dynamic>>.from(response);
        if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => SpinnerPage(roommates: list)));
      }
    } catch(e) {
      debugPrint("Error opening spinner: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                    Text('Bills & Expenses', style: theme.textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      onPressed: _openSpinner,
                      icon: const Icon(Icons.casino_rounded, color: AppColors.primary, size: 28),
                    )
                  ],
                ),
              ),
              _buildSummaryCard(),
              TabBar(
                controller: _tabController,
                tabs: const [Tab(text: 'Bills'), Tab(text: 'Settle Up')],
                labelStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                indicatorColor: AppColors.primary,
                dividerColor: Colors.transparent,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _BillList(bills: _roomBills, isLoading: _isLoading, isSplitView: false),
                    _SettleUpView(groups: _settleUpOwed.values.toList(), isLoading: _isLoading, onSettle: _showSettleUpOptions),
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
    final amount = split != null ? (split!['amount_owed'] - (split!['amount_paid'] ?? 0)) : (bill['total_amount']?.toDouble() ?? 0.0);
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

class _SettleUpView extends StatelessWidget {
  const _SettleUpView({required this.groups, required this.isLoading, required this.onSettle});
  final List<Map<String, dynamic>> groups;
  final bool isLoading;
  final Function(Map<String, dynamic>) onSettle;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (groups.isEmpty) return const Center(child: Text("You don't owe anyone. Great job!"));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final user = group['user'];
        final totalOwed = group['total_owed'] as double;
        final splitsCount = (group['splits'] as List).length;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: NeoBentoCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(backgroundImage: NetworkImage(user['avatar_url'] ?? ''), radius: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['username'] ?? 'Roommate', style: Theme.of(context).textTheme.titleMedium),
                      Text('$splitsCount pending bill(s)', style: Theme.of(context).textTheme.labelMedium),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${totalOwed.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.accentRed)),
                    const SizedBox(height: 6),
                    SquishyButton(
                      onPressed: () => onSettle(group),
                      label: 'Settle Up',
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}