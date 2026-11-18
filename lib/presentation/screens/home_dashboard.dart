import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:rlds_church_app/core/constants/api_constants.dart';
import 'package:rlds_church_app/presentation/screens/tithes_payment_screen.dart';
import 'package:rlds_church_app/presentation/screens/kitty_analytics_screen.dart';
import 'package:rlds_church_app/presentation/screens/digital_card_screen.dart';
import 'package:rlds_church_app/presentation/screens/community_outreach_screen.dart';
import 'package:rlds_church_app/presentation/screens/church_life_screen.dart';
import 'package:rlds_church_app/presentation/screens/scripture_reader_view.dart';
import 'package:rlds_church_app/data/repositories/church_sync_repository.dart';
import 'package:rlds_church_app/presentation/blocs/sync/church_sync_bloc.dart';
import 'package:rlds_church_app/presentation/blocs/sync/church_sync_event.dart';
import 'package:rlds_church_app/presentation/blocs/sync/church_sync_state.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkInitialNetwork();
  }

  Future<void> _checkInitialNetwork() async {
    final repo = context.read<ChurchSyncRepository>();
    final online = await repo.hasInternetConnection();
    if (mounted) {
      setState(() {
        _isOnline = online;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChurchSyncBloc, ChurchSyncState>(
      listener: (context, state) {
        if (state is ChurchSyncSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    state.isOfflineQueued ? Icons.cloud_off_rounded : Icons.check_circle_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: state.isOfflineQueued ? const Color(0xFFD97706) : const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is ChurchSyncError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E3A8A),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.church_rounded, size: 36, color: Color(0xFFD97706)),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'RLDS Restoration Ministry',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Text(
                        'Digital Sanctuary • Delstarford Works',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.volunteer_activism_rounded, color: Color(0xFF1E3A8A)),
                  title: const Text('Tithes & Offerings (M-Pesa)', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _tabController.animateTo(0);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.menu_book_rounded, color: Color(0xFF1E3A8A)),
                  title: const Text('Inspired Scriptures & Book of Mormon', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Pillar 1: IV Bible, BoM & Offline RAG AI', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ScriptureReaderView()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.pie_chart_rounded, color: Color(0xFFD97706)),
                  title: const Text('Kitty Analytics & Credit Scoring'),
                  subtitle: const Text('AI Score, Pledges & Reserve Pool', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const KittyAnalyticsScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.badge_rounded, color: Color(0xFF1E3A8A)),
                  title: const Text('Digital Card & Smart Attendance'),
                  subtitle: const Text('QR Code Pass & NFC Check-in', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DigitalCardScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.handshake_rounded, color: Color(0xFF16A34A)),
                  title: const Text('Community Outreach & CBO'),
                  subtitle: const Text('FARD CBO Initiatives & Sunday School', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityOutreachScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event_note_rounded, color: Color(0xFF1E3A8A)),
                  title: const Text('Events & Branch Assemblies'),
                  subtitle: const Text('Kakamega Locator & Weekly Bulletin', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChurchLifeScreen()));
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.cloud_sync_rounded, color: Color(0xFFD97706)),
                  title: Text('Offline Queue (${state.queueCount})'),
                  onTap: () {
                    Navigator.pop(context);
                    _tabController.animateTo(2);
                  },
                ),
              ],
            ),
          ),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E3A8A),
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RLDS Restoration Ministry',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isOnline ? '🟢 Connected to Sanctuary Cloud' : '🟡 Offline Mode (Local Storage Active)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Check Connection & Refresh',
                icon: const Icon(Icons.sync_rounded, color: Colors.white),
                onPressed: () async {
                  await _checkInitialNetwork();
                  if (context.mounted) {
                    context.read<ChurchSyncBloc>().add(const TriggerBackgroundSyncEvent());
                  }
                },
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'Offline Queue',
                    icon: const Icon(Icons.inventory_2_outlined, color: Colors.white),
                    onPressed: () {
                      _tabController.animateTo(2);
                    },
                  ),
                  if (state.queueCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFD97706),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${state.queueCount}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFD97706),
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(icon: Icon(Icons.volunteer_activism_rounded), text: 'Tithe'),
                Tab(icon: Icon(Icons.account_balance_wallet_rounded), text: 'Kitty Loan'),
                Tab(icon: Icon(Icons.cloud_sync_rounded), text: 'Queue'),
                Tab(icon: Icon(Icons.chat_bubble_outline_rounded), text: 'Support'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              const TithesPaymentScreen(isEmbedded: true),
              _LoanFormView(isOnline: _isOnline),
              _QueueManagerView(queueCount: state.queueCount),
              const _ChurchChatbotView(),
            ],
          ),
        );
      },
    );
  }
}

// =========================================================================
// TAB 1: TITHE & OFFERING SUBMISSION VIEW
// =========================================================================
class _TitheFormView extends StatefulWidget {
  final bool isOnline;
  const _TitheFormView({required this.isOnline});

  @override
  State<_TitheFormView> createState() => _TitheFormViewState();
}

class _TitheFormViewState extends State<_TitheFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'John Doe');
  final _memberIdController = TextEditingController(text: 'RLDS-10023');
  final _amountController = TextEditingController();
  final _receiptController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedCategory = 'Tithe';

  final List<String> _categories = [
    'Tithe',
    'Thanksgiving',
    'Building Fund',
    'Missions & Outreach',
    'Sunday School',
    'Benevolence',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _memberIdController.dispose();
    _amountController.dispose();
    _receiptController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<ChurchSyncBloc>().add(
            SubmitTitheEvent(
              memberId: _memberIdController.text.trim(),
              memberName: _nameController.text.trim(),
              memberEmail: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
              amount: double.parse(_amountController.text.trim()),
              category: _selectedCategory,
              mpesaReceipt: _receiptController.text.trim().isEmpty ? 'PENDING-RECEIPT' : _receiptController.text.trim().toUpperCase(),
            ),
          );
      _amountController.clear();
      _receiptController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isOnline ? const Color(0xFFEFF6FF) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isOnline ? const Color(0xFFBFDBFE) : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                    color: widget.isOnline ? const Color(0xFF1E3A8A) : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isOnline
                          ? 'Online Mode: Contributions sync immediately with church records and trigger digital email receipts.'
                          : 'Offline Sanctuary Mode: Contributions are saved securely in your Hive queue and sync when you regain internet.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: widget.isOnline ? const Color(0xFF1E3A8A) : const Color(0xFF92400E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Member Full Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _memberIdController,
              decoration: const InputDecoration(
                labelText: 'RLDS Member ID',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Contribution Category',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (KES)',
                prefixIcon: Icon(Icons.attach_money_rounded),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter amount';
                if (double.tryParse(v) == null) return 'Enter valid number';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _receiptController,
              decoration: const InputDecoration(
                labelText: 'M-Pesa Receipt Code (e.g. QWE4827X12)',
                prefixIcon: Icon(Icons.receipt_long_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Receipt Email (Optional)',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _submit,
              icon: const Icon(Icons.volunteer_activism_rounded),
              label: const Text(
                'Submit Kingdom Contribution',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// TAB 2: STEWARDSHIP KITTY LOAN APPLICATION VIEW
// =========================================================================
class _LoanFormView extends StatefulWidget {
  final bool isOnline;
  const _LoanFormView({required this.isOnline});

  @override
  State<_LoanFormView> createState() => _LoanFormViewState();
}

class _LoanFormViewState extends State<_LoanFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'John Doe');
  final _memberIdController = TextEditingController(text: 'RLDS-10023');
  final _amountController = TextEditingController();
  final _periodController = TextEditingController(text: '6');
  final _guarantorController = TextEditingController();
  final _purposeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _memberIdController.dispose();
    _amountController.dispose();
    _periodController.dispose();
    _guarantorController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<ChurchSyncBloc>().add(
            SubmitLoanApplicationEvent(
              memberId: _memberIdController.text.trim(),
              memberName: _nameController.text.trim(),
              amountRequested: double.parse(_amountController.text.trim()),
              repaymentPeriodMonths: int.parse(_periodController.text.trim()),
              guarantorPhone: _guarantorController.text.trim(),
              purpose: _purposeController.text.trim().isEmpty ? 'General Development' : _purposeController.text.trim(),
            ),
          );
      _amountController.clear();
      _guarantorController.clear();
      _purposeController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF16A34A)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Stewardship Kitty Fund\nApplications are queued offline & reviewed exclusively by Executive Directors.',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Applicant Member Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _memberIdController,
              decoration: const InputDecoration(
                labelText: 'RLDS Member ID',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Loan Amount Requested (KES)',
                prefixIcon: Icon(Icons.monetization_on_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Enter requested amount' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _periodController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Repayment Period (Months)',
                prefixIcon: Icon(Icons.calendar_month_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Enter period' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _guarantorController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Church Member Guarantor Phone',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Guarantor phone is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _purposeController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Purpose of Loan (Business / Education / Agriculture)',
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _submit,
              icon: const Icon(Icons.send_rounded),
              label: const Text(
                'Submit Stewardship Kitty Application',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// TAB 3: OFFLINE QUEUE MANAGER VIEW
// =========================================================================
class _QueueManagerView extends StatelessWidget {
  final int queueCount;
  const _QueueManagerView({required this.queueCount});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ChurchSyncRepository>();
    final items = repo.getQueueItems();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: const Color(0xFFF9FAFB),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  Icon(
                    queueCount > 0 ? Icons.cloud_upload_outlined : Icons.cloud_done_rounded,
                    size: 48,
                    color: queueCount > 0 ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$queueCount Offline Item(s) Pending',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Stored safely in local Hive database on your device.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      context.read<ChurchSyncBloc>().add(const TriggerBackgroundSyncEvent());
                    },
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Flush & Synchronize Now'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Local Hive Queue Items',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'No offline records waiting.\nAll contributions and loans are synchronized.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, idx) {
                      final item = items[idx];
                      final type = item['type'] ?? 'item';
                      final payload = item['payload'] as Map? ?? {};
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: type == 'tithe' ? const Color(0xFF1E3A8A) : const Color(0xFFD97706),
                            child: Icon(
                              type == 'tithe' ? Icons.volunteer_activism : Icons.account_balance_wallet,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            type == 'tithe'
                                ? 'Tithe: KES ${payload['amount']} (${payload['category']})'
                                : 'Loan: KES ${payload['amount_requested']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text('Member: ${payload['member_name']} | Time: ${item['timestamp']}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// TAB 4: CHURCH ASSISTANT CHATBOT VIEW
// =========================================================================
class _ChurchChatbotView extends StatefulWidget {
  const _ChurchChatbotView();

  @override
  State<_ChurchChatbotView> createState() => _ChurchChatbotViewState();
}

class _ChurchChatbotViewState extends State<_ChurchChatbotView> {
  final _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'sender': 'bot',
      'text': 'Greetings in Christ! Welcome to the RLDS Church Assistant. Ask me about Stewardship Kitty loans, tithes, service schedules, or membership registration.',
    }
  ];
  bool _isSending = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _isSending = true;
    });
    _controller.clear();

    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl, connectTimeout: const Duration(seconds: 10)));
      final res = await dio.post(ApiConstants.chatMessage, data: {'message': text});
      if (mounted) {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': res.data['reply'] ?? 'Response received.',
          });
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': 'Offline Assistant: For loan applications and tithes, you can fill out the respective tabs even without internet; the app will queue and sync them automatically.',
          });
        });
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final msg = _messages[i];
              final isUser = msg['sender'] == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF1E3A8A) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: isUser ? null : Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    msg['text']!,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_isSending)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: LinearProgressIndicator(color: Color(0xFFD97706)),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 4, offset: const Offset(0, -1)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Ask about loans, tithes, service times...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: Color(0xFF1E3A8A)),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
