import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rlds_church_app/data/repositories/church_sync_repository.dart';
import 'package:rlds_church_app/presentation/blocs/sync/church_sync_bloc.dart';
import 'package:rlds_church_app/presentation/blocs/sync/church_sync_event.dart';
import 'package:rlds_church_app/presentation/blocs/sync/church_sync_state.dart';

class TithesPaymentScreen extends StatefulWidget {
  final bool initialOffline;
  final bool isEmbedded;
  const TithesPaymentScreen({super.key, this.initialOffline = false, this.isEmbedded = false});

  @override
  State<TithesPaymentScreen> createState() => _TithesPaymentScreenState();
}

class _TithesPaymentScreenState extends State<TithesPaymentScreen> with SingleTickerProviderStateMixin {
  // Sacred Modernism Color Constants
  static const Color liturgicalBlue = Color(0xFF1E3A8A); // Deep Royal Blue
  static const Color stewardshipGold = Color(0xFFD97706); // Stewardship Gold Accent
  static const Color cleanNeutral = Color(0xFFF9FAFB); // Canvas background
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textCharcoal = Color(0xFF111827); // Primary typography
  static const Color textSlateGrey = Color(0xFF6B7280); // Sublines & timestamps
  static const Color mpesaGreen = Color(0xFF00A344); // Safaricom green accent

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Elder Grace Wanjiku');
  final _memberIdController = TextEditingController(text: 'RLDS-78241');
  final _emailController = TextEditingController(text: 'grace.wanjiku@rldschurch.org');
  final _phoneController = TextEditingController(text: '0712345678');
  final _amountController = TextEditingController(text: '2500');
  final _receiptController = TextEditingController();

  late TabController _paymentMethodTabController;
  bool _isOnline = true;
  bool _isAnonymous = false;
  bool _isProcessingStk = false;
  String _selectedCategory = 'Tithe (10%)';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Tithe (10%)', 'icon': Icons.volunteer_activism_rounded, 'subtitle': 'Malachi 3:10'},
    {'name': 'Thanksgiving', 'icon': Icons.spa_rounded, 'subtitle': 'Psalm 100:4'},
    {'name': 'Building Fund', 'icon': Icons.foundation_rounded, 'subtitle': 'Nehemiah 2:18'},
    {'name': 'Missions & Outreach', 'icon': Icons.public_rounded, 'subtitle': 'Mark 16:15'},
    {'name': 'Benevolence / Mercy', 'icon': Icons.favorite_rounded, 'subtitle': 'Proverbs 19:17'},
    {'name': 'Sunday School', 'icon': Icons.child_care_rounded, 'subtitle': 'Proverbs 22:6'},
  ];

  final List<int> _quickAmounts = [500, 1000, 2500, 5000, 10000];

  @override
  void initState() {
    super.initState();
    _paymentMethodTabController = TabController(length: 2, vsync: this);
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final repo = context.read<ChurchSyncRepository>();
    final online = await repo.hasInternetConnection();
    if (mounted) {
      setState(() => _isOnline = online);
    }
  }

  @override
  void dispose() {
    _paymentMethodTabController.dispose();
    _nameController.dispose();
    _memberIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _receiptController.dispose();
    super.dispose();
  }

  void _onQuickAmountSelected(int amount) {
    setState(() {
      _amountController.text = amount.toString();
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _submitContribution({required bool isStkPush}) {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid contribution amount greater than KES 0.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final memberName = _isAnonymous ? 'Anonymous Giver (In Secret)' : _nameController.text.trim();
    final memberId = _isAnonymous ? 'ANON-GIVER' : _memberIdController.text.trim();
    final memberEmail = _isAnonymous ? null : _emailController.text.trim();
    final mpesaCode = isStkPush
        ? 'STK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'
        : (_receiptController.text.trim().isEmpty ? 'PENDING-VERIFY' : _receiptController.text.trim().toUpperCase());

    if (isStkPush && _isOnline) {
      _showStkPromptSimulationDialog(
        phone: _phoneController.text.trim(),
        amount: amount,
        category: _selectedCategory,
        onConfirmed: () {
          context.read<ChurchSyncBloc>().add(
                SubmitTitheEvent(
                  memberId: memberId,
                  memberName: memberName,
                  memberEmail: memberEmail,
                  amount: amount,
                  category: _selectedCategory,
                  mpesaReceipt: mpesaCode,
                ),
              );
          _showOfficialReceiptDialog(
            amount: amount,
            category: _selectedCategory,
            mpesaCode: mpesaCode,
            memberName: memberName,
            memberId: memberId,
            isOffline: false,
          );
        },
      );
    } else {
      // Direct submission or Offline Queue
      context.read<ChurchSyncBloc>().add(
            SubmitTitheEvent(
              memberId: memberId,
              memberName: memberName,
              memberEmail: memberEmail,
              amount: amount,
              category: _selectedCategory,
              mpesaReceipt: mpesaCode,
            ),
          );

      _showOfficialReceiptDialog(
        amount: amount,
        category: _selectedCategory,
        mpesaCode: mpesaCode,
        memberName: memberName,
        memberId: memberId,
        isOffline: !_isOnline,
      );
    }
  }

  void _showStkPromptSimulationDialog({
    required String phone,
    required double amount,
    required String category,
    required VoidCallback onConfirmed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: mpesaGreen.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_android_rounded, color: mpesaGreen, size: 48),
            ),
            const SizedBox(height: 18),
            const Text(
              'Lipa Na M-Pesa Online',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: textCharcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A prompt has been dispatched to $phone for KES ${NumberFormat('#,##0.00').format(amount)}.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: textSlateGrey),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cleanNeutral,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Paybill No:', style: TextStyle(fontSize: 12, color: textSlateGrey)),
                      const Text('174379', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCharcoal)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Account:', style: TextStyle(fontSize: 12, color: textSlateGrey)),
                      Text(category.split(' ').first, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: liturgicalBlue)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(stewardshipGold)),
            const SizedBox(height: 16),
            const Text(
              'Please enter your M-Pesa PIN on your mobile phone to complete giving...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textSlateGrey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onConfirmed();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mpesaGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('PIN Entered'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOfficialReceiptDialog({
    required double amount,
    required String category,
    required String mpesaCode,
    required String memberName,
    required String memberId,
    required bool isOffline,
  }) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEE, d MMM yyyy • h:mm a').format(now);
    final txId = 'RLDS-TX-${now.millisecondsSinceEpoch.toString().substring(5)}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isOffline ? stewardshipGold.withAlpha(25) : liturgicalBlue.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOffline ? Icons.cloud_off_rounded : Icons.check_circle_rounded,
                size: 44,
                color: isOffline ? stewardshipGold : liturgicalBlue,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isOffline ? 'Contribution Queued Offline' : 'Kingdom Offering Received',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textCharcoal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isOffline
                  ? 'Encrypted in local device storage. Will sync to church ledger automatically once online.'
                  : 'Official sanctuary receipt generated and synchronized with church records.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: textSlateGrey),
            ),
            const SizedBox(height: 20),
            // Sacred Modernism Receipt Container
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cleanNeutral,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ministry:', style: TextStyle(fontSize: 12, color: textSlateGrey)),
                      const Text(
                        'RLDS Restoration Ministry',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: liturgicalBlue),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Giver:', style: TextStyle(fontSize: 12, color: textSlateGrey)),
                      Text('$memberName ($memberId)', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textCharcoal)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Category:', style: TextStyle(fontSize: 12, color: textSlateGrey)),
                      Text(category, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textCharcoal)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('M-Pesa Ref:', style: TextStyle(fontSize: 12, color: textSlateGrey)),
                      Text(mpesaCode, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: mpesaGreen)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Date & Time:', style: TextStyle(fontSize: 12, color: textSlateGrey)),
                      Text(formattedDate, style: const TextStyle(fontSize: 11.5, color: textSlateGrey)),
                    ],
                  ),
                  const Divider(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textCharcoal)),
                      Text(
                        'KES ${NumberFormat('#,##0.00').format(amount)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: liturgicalBlue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: liturgicalBlue.withAlpha(12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: liturgicalBlue.withAlpha(25)),
              ),
              child: const Text(
                '“Bring all the tithes into the storehouse... and prove Me now in this,” says the Lord. — Malachi 3:10',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: liturgicalBlue),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: liturgicalBlue),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _copyToClipboard(txId, 'Receipt Reference');
                    },
                    icon: const Icon(Icons.share_outlined, size: 18, color: liturgicalBlue),
                    label: const Text('Share Receipt', style: TextStyle(color: liturgicalBlue, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: liturgicalBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'The Church of Jesus Christ Restoration Ministry • Sacred Sanctuary',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: textSlateGrey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cleanNeutral,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              backgroundColor: liturgicalBlue,
              elevation: 0,
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tithes & Offerings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'M-Pesa Digital Sanctuary Portal',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isOnline ? Colors.green.withAlpha(40) : stewardshipGold.withAlpha(50),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _isOnline ? Colors.greenAccent : stewardshipGold, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isOnline ? 'Online' : 'Offline Mode',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. OFFLINE PERSISTENCE HERO BANNER
              if (!_isOnline)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.offline_bolt_rounded, color: stewardshipGold, size: 26),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Offline Mode Active: Your tithe pledge and receipt details will be safely preserved in your device\'s encrypted Hive storage and automatically synced to the church database once connectivity returns.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF92400E), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),

              // 2. ECCLESIASTICAL SCRIPTURE BANNER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF172554)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: liturgicalBlue.withAlpha(45), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surfaceWhite.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_stories_rounded, color: stewardshipGold, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '“Each of you should give what you have decided in your heart to give... for God loves a cheerful giver.”',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '2 Corinthians 9:7',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: stewardshipGold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. CONTRIBUTION CATEGORY SELECTION (Grid of Cards)
              const Text(
                'Select Contribution Purpose',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textCharcoal),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.2,
                ),
                itemCount: _categories.length,
                itemBuilder: (ctx, i) {
                  final cat = _categories[i];
                  final isSelected = _selectedCategory == cat['name'];
                  return InkWell(
                    onTap: () => setState(() => _selectedCategory = cat['name'] as String),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? liturgicalBlue : surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? stewardshipGold : Colors.grey.shade200,
                          width: isSelected ? 1.8 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected ? liturgicalBlue.withAlpha(30) : Colors.black.withAlpha(6),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            size: 24,
                            color: isSelected ? stewardshipGold : liturgicalBlue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  cat['name'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : textCharcoal,
                                  ),
                                ),
                                Text(
                                  cat['subtitle'] as String,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected ? Colors.white70 : textSlateGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // 4. AMOUNT SELECTION & QUICK CHIPS
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: surfaceWhite,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Giving Amount (KES)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textCharcoal),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: liturgicalBlue,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Text(
                              'KES',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textSlateGrey),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                          hintText: '0.00',
                          filled: true,
                          fillColor: cleanNeutral,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: liturgicalBlue, width: 2),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Please specify contribution amount';
                          if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: _quickAmounts.map((amt) {
                          final isCurrent = _amountController.text == amt.toString();
                          return ActionChip(
                            label: Text('KES ${NumberFormat('#,##0').format(amt)}'),
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? Colors.white : liturgicalBlue,
                            ),
                            backgroundColor: isCurrent ? liturgicalBlue : liturgicalBlue.withAlpha(15),
                            side: BorderSide(color: isCurrent ? stewardshipGold : Colors.transparent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            onPressed: () => _onQuickAmountSelected(amt),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 5. GIVER IDENTITY & ANONYMOUS TOGGLE
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: surfaceWhite,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Member Identification',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textCharcoal),
                          ),
                          Row(
                            children: [
                              const Text('Give In Secret', style: TextStyle(fontSize: 12, color: textSlateGrey)),
                              Switch(
                                value: _isAnonymous,
                                activeColor: stewardshipGold,
                                onChanged: (val) => setState(() => _isAnonymous = val),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (!_isAnonymous) ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: const Icon(Icons.person_outline, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          validator: (v) => !_isAnonymous && (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _memberIdController,
                                decoration: InputDecoration(
                                  labelText: 'RLDS Member ID',
                                  prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                                validator: (v) => !_isAnonymous && (v == null || v.isEmpty) ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Receipt Email',
                                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cleanNeutral,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.visibility_off_outlined, color: textSlateGrey, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '“Do not let your left hand know what your right hand is doing, so that your giving may be in secret.” — Matthew 6:3-4',
                                  style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: textSlateGrey),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 6. M-PESA DARAJA PAYMENT OPTIONS
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: surfaceWhite,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: mpesaGreen.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.payment_rounded, color: mpesaGreen, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Safaricom M-Pesa Integration',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: mpesaGreen),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TabBar(
                        controller: _paymentMethodTabController,
                        indicatorColor: mpesaGreen,
                        labelColor: mpesaGreen,
                        unselectedLabelColor: textSlateGrey,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        tabs: const [
                          Tab(text: '1. STK Push Prompt'),
                          Tab(text: '2. Paybill / Manual Code'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 220,
                        child: TabBarView(
                          controller: _paymentMethodTabController,
                          children: [
                            // TAB A: STK PUSH (Lipa Na M-Pesa Online)
                            SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: 'Safaricom Phone Number',
                                      hintText: '0712345678 or 254712345678',
                                      prefixIcon: const Icon(Icons.phone_iphone_rounded, color: mpesaGreen),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    validator: (v) => v == null || v.isEmpty ? 'Enter phone number' : null,
                                  ),
                                  const SizedBox(height: 14),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: mpesaGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 2,
                                    ),
                                    onPressed: () => _submitContribution(isStkPush: true),
                                    icon: const Icon(Icons.send_to_mobile_rounded),
                                    label: const Text(
                                      'Send M-Pesa STK PIN Prompt',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // TAB B: PAYBILL MANUAL ENTRY
                            SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: cleanNeutral,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Church Paybill:', style: TextStyle(fontSize: 11, color: textSlateGrey)),
                                            const Text('174379', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCharcoal)),
                                          ],
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy_rounded, size: 16, color: liturgicalBlue),
                                          onPressed: () => _copyToClipboard('174379', 'Paybill Number'),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Account Number:', style: TextStyle(fontSize: 11, color: textSlateGrey)),
                                            Text(_selectedCategory.split(' ').first, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: liturgicalBlue)),
                                          ],
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy_rounded, size: 16, color: liturgicalBlue),
                                          onPressed: () => _copyToClipboard(_selectedCategory.split(' ').first, 'Account Reference'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _receiptController,
                                    textCapitalization: TextCapitalization.characters,
                                    decoration: InputDecoration(
                                      labelText: 'M-Pesa Confirmation Code (e.g. QWE4827X12)',
                                      prefixIcon: const Icon(Icons.receipt_long_rounded, color: liturgicalBlue),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: liturgicalBlue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => _submitContribution(isStkPush: false),
                                    icon: const Icon(Icons.check_circle_outline_rounded),
                                    label: Text(
                                      _isOnline ? 'Verify & Generate Official Receipt' : 'Log Receipt Offline (Hive)',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 7. CHURCH FOOTER
              const Center(
                child: Text(
                  'The Church of Jesus Christ Restoration Ministry (RLDS Church)\nFaith, Consecration & Divine Stewardship',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: textSlateGrey,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
