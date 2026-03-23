import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neo_bento_widgets.dart';

class BillDetailsPage extends StatefulWidget {
  final Map<String, dynamic> bill;
  const BillDetailsPage({super.key, required this.bill});

  @override
  State<BillDetailsPage> createState() => _BillDetailsPageState();
}

class _BillDetailsPageState extends State<BillDetailsPage> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _splits = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    try {
      final itemsResponse = await Supabase.instance.client.from('bill_items').select().eq('bill_id', widget.bill['id']);
      if (mounted) _items = List<Map<String, dynamic>>.from(itemsResponse);

      final splitsResponse = await Supabase.instance.client
          .from('bill_splits')
          .select('*, user:profiles(username, avatar_url)')
          .eq('bill_id', widget.bill['id']);
      if (mounted) _splits = List<Map<String, dynamic>>.from(splitsResponse);
      
      // If we don't have paid_by_user in the bill object, fetch it
      if (widget.bill['paid_by_user'] == null && widget.bill['paid_by'] != null) {
        final creatorResponse = await Supabase.instance.client
            .from('profiles')
            .select('username, avatar_url')
            .eq('id', widget.bill['paid_by'])
            .maybeSingle();
        if (mounted && creatorResponse != null) {
          setState(() {
            widget.bill['paid_by_user'] = creatorResponse;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching details: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _makePayment(double amount, String app) async {
    final upiId = "your-upi-id@oksbi"; // In a real app, this would be the bill creator's UPI ID
    final name = widget.bill['paid_by_user']?['username'] ?? "Roommate";
    
    String urlStr;
    if (app == 'gpay') {
      urlStr = 'gpay://upi/pay?pa=$upiId&pn=$name&am=$amount&cu=INR';
    } else if (app == 'phonepe') {
      urlStr = 'phonepe://pay?pa=$upiId&pn=$name&am=$amount&cu=INR';
    } else {
      urlStr = 'paytmmp://pay?pa=$upiId&pn=$name&am=$amount&cu=INR';
    }

    final url = Uri.parse(urlStr);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch $app. Make sure it is installed.')));
        }
      }
    } catch (e) {
      debugPrint("Payment launch error: $e");
    }
  }

  void _showPaymentOptions(double amount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassSheet(
        title: 'Pay Roomie',
        children: [
          Text('Amount: \$${amount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_rounded, color: Colors.blue),
            title: const Text('Google Pay'),
            onTap: () {
              Navigator.pop(context);
              _makePayment(amount, 'gpay');
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_rounded, color: Colors.purple),
            title: const Text('PhonePe'),
            onTap: () {
              Navigator.pop(context);
              _makePayment(amount, 'phonepe');
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_rounded, color: Colors.lightBlue),
            title: const Text('Paytm'),
            onTap: () {
              Navigator.pop(context);
              _makePayment(amount, 'paytm');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final mySplit = _splits.where((s) => s['user_id'] == user?.id).firstOrNull;
    final amountToPay = mySplit != null ? (mySplit['amount_owed'] - mySplit['amount_paid']) : 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(widget.bill['store_name'] ?? 'Bill Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Items', style: Theme.of(context).textTheme.headlineSmall),
                ..._items.map((item) => ListTile(title: Text(item['item_name']), trailing: Text('\$${item['price'].toStringAsFixed(2)}'))),
                const Divider(height: 30),
                Text('Splits', style: Theme.of(context).textTheme.headlineSmall),
                ..._splits.map((split) {
                  final roommate = split['user'];
                  return ListTile(
                    leading: CircleAvatar(backgroundImage: NetworkImage(roommate?['avatar_url'] ?? '')),
                    title: Text(roommate?['username'] ?? '...'),
                    subtitle: Text('Owes: \$${split['amount_owed'].toStringAsFixed(2)}'),
                    trailing: Text(split['status'], style: TextStyle(color: split['status'] == 'paid' ? AppColors.success : AppColors.accentRed)),
                  );
                }),
                const SizedBox(height: 30),
                if (amountToPay > 0)
                  SquishyButton(onPressed: () => _showPaymentOptions(amountToPay), label: 'Pay Your Share (\$${amountToPay.toStringAsFixed(2)})')
                else if (mySplit != null && mySplit['status'] == 'paid')
                  const Center(child: Text('✅ You have paid your share!', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)))
              ],
            ),
    );
  }
}
