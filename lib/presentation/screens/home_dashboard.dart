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
import 'package:rlds_church_app/presentation/screens/ministry/church_ministry_hub_screen.dart';
import 'package:rlds_church_app/presentation/screens/auth/welcome_landing_screen.dart';
import 'package:rlds_church_app/core/localization/church_translations.dart';
import 'package:rlds_church_app/core/theme/theme_provider.dart';
import 'package:rlds_church_app/data/services/church_auth_session.dart';
import 'package:rlds_church_app/data/repositories/church_sync_repository.dart';
import 'package:rlds_church_app/presentation/blocs/sync/church_sync_bloc.dart';
import 'package:rlds_church_app/presentation/blocs/sync/church_sync_event.dart';
import 'package:rlds_church_app/presentation/blocs/sync/church_sync_state.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out / Logout'),
        content: const Text('Are you sure you want to sign out from your church dashboard?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ChurchMemberSession.instance.clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeLandingScreen()),
                (route) => false,
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/img/App icon.jpg',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.church_rounded, size: 36, color: Color(0xFFD97706)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'RLDS Restoration Ministry',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Text(
                        'Digital Zion • Restoration Ministry',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.hub_rounded, color: Color(0xFF16A34A)),
                  title: const Text('20 Sacred Ministry Portals', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Priesthood, Hymnal, Transparency & Records', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChurchMinistryHubScreen()));
                  },
                ),
                const Divider(),
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
                  title: const Text('Community Outreach & Welfare'),
                  subtitle: const Text('Church Welfare & Sunday School', style: TextStyle(fontSize: 11)),
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
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  title: const Text('Sign Out / Switch Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeLandingScreen()));
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
                  _isOnline ? '🟢 Zion Online Network' : '🟡 Offline Mode (Local Storage Active)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Language / Lugha',
                icon: const Icon(Icons.language_rounded, color: Colors.white),
                onPressed: () {
                  ChurchTranslations.showLanguagePickerModal(context, onLanguageChanged: () => setState(() {}));
                },
              ),
              IconButton(
                tooltip: 'Toggle Theme',
                icon: Icon(
                  AppStateNotifier.instance.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: Colors.white,
                ),
                onPressed: () {
                  AppStateNotifier.instance.toggleTheme();
                  setState(() {});
                },
              ),
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
              IconButton(
                tooltip: 'Sign Out / Switch Account',
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: _showLogoutConfirmDialog,
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
                Tab(icon: Icon(Icons.account_balance_wallet_rounded), text: 'Stewardship Kitty'),
                Tab(icon: Icon(Icons.cloud_sync_rounded), text: 'Queue'),
                Tab(icon: Icon(Icons.chat_bubble_outline_rounded), text: 'Support'),
              ],
            ),
          ),
          body: Column(
            children: [
              if (ChurchMemberSession.instance.role == ChurchRole.visitor)
                Container(
                  color: const Color(0xFFFEF3C7),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ChurchTranslations.tr('visitor_notice', lang: AppStateNotifier.instance.currentLanguage),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeLandingScreen()));
                        },
                        child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    const TithesPaymentScreen(isEmbedded: true),
                    _LoanFormView(isOnline: _isOnline),
                    _QueueManagerView(queueCount: state.queueCount),
                    const _ChurchChatbotView(),
                  ],
                ),
              ),
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
  final _nameController = TextEditingController(text: ChurchMemberSession.instance.fullName);
  final _memberIdController = TextEditingController(text: ChurchMemberSession.instance.memberId);
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

  void _showVisitorBlockedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Member Registration Required'),
        content: const Text('You are currently browsing as a Visitor. To apply for a Stewardship Kitty development loan, please register as an RLDS member or sign in with your membership credentials.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Dismiss')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeLandingScreen()));
            },
            child: const Text('Sign In / Register'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (ChurchMemberSession.instance.role == ChurchRole.visitor) {
      _showVisitorBlockedDialog();
      return;
    }
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
                          : 'Offline Zion Mode: Contributions are saved securely in your Hive queue and sync when you regain internet.',
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
  final _nameController = TextEditingController(text: ChurchMemberSession.instance.fullName);
  final _memberIdController = TextEditingController(text: ChurchMemberSession.instance.memberId);
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

  void _showVisitorBlockedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Member Registration Required'),
        content: const Text('You are currently browsing as a Visitor. To apply for a Stewardship Kitty development loan, please register as an RLDS member or sign in with your membership credentials.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Dismiss')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeLandingScreen()));
            },
            child: const Text('Sign In / Register'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (ChurchMemberSession.instance.role == ChurchRole.visitor) {
      _showVisitorBlockedDialog();
      return;
    }
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
// TAB 4: CHURCH ASSISTANT CHATBOT VIEW WITH OFFLINE AI & TTS
// =========================================================================
class _ChurchChatbotView extends StatefulWidget {
  const _ChurchChatbotView();

  @override
  State<_ChurchChatbotView> createState() => _ChurchChatbotViewState();
}

class _ChurchChatbotViewState extends State<_ChurchChatbotView> {
  final _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;
  int? _speakingIndex;
  bool _autoSpeak = false;

  final List<Map<String, String>> _messages = [
    {
      'sender': 'bot',
      'text': 'Greetings in Christ! Welcome to the RLDS Church Assistant. Ask me about Stewardship Kitty loans, personal tithe records, service schedules, or scriptures.',
    }
  ];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _speakingIndex = null;
        });
      }
    });
    _flutterTts.setErrorHandler((_) {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _speakingIndex = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak(String text, int index) async {
    if (_isSpeaking && _speakingIndex == index) {
      await _stopSpeech();
      return;
    }
    await _stopSpeech();
    final cleanText = text
        .replaceAll(RegExp(r'[*#_`>•]'), '')
        .replaceAll(RegExp(r'[🏛️🙏⛪📝🤝📖💰👤📊✅⚠️🤖📍]'), '')
        .trim();
    if (cleanText.isEmpty) return;

    setState(() {
      _isSpeaking = true;
      _speakingIndex = index;
    });
    await _flutterTts.setSpeechRate(0.48);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(cleanText);
  }

  Future<void> _stopSpeech() async {
    await _flutterTts.stop();
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _speakingIndex = null;
      });
    }
  }

  String _generateOfflineAiReply(String query) {
    final q = query.toLowerCase();
    final session = ChurchMemberSession.instance;

    // 1. Identity & Profile
    if (q.contains('who am i') || q.contains('my profile') || q.contains('my id') || q.contains('my details') || q.contains('my name')) {
      if (session.isLoggedIn) {
        return '👤 **Member Identity (Local Storage Cache):**\n\n'
            '• **Full Name:** ${session.fullName}\n'
            '• **Member ID:** ${session.memberId}\n'
            '• **Role:** ${session.title}\n'
            '• **Assigned Assembly:** ${session.assignedBranch}\n'
            '• **Phone:** ${session.phone}\n'
            '• **Status:** Active Member in Zion';
      } else {
        return '👋 You are currently in Visitor Mode. Please Sign In on the welcome screen to view your member profile.';
      }
    }

    // 2. Personal Tithes & Giving
    if (q.contains('my tithe') || q.contains('my contribution') || q.contains('how much') || q.contains('my giving') || q.contains('sadaka')) {
      if (session.isLoggedIn) {
        return '🙏 **Personal Tithes & Giving Record:**\n\n'
            '• **Member:** ${session.fullName} (${session.memberId})\n'
            '• **Branch Assembly:** ${session.assignedBranch}\n'
            '• **Giving Status:** Up to date in church records.\n'
            '• **Offline Giving:** You can enter contributions on the "Tithe" tab anytime; records queue in offline storage and sync automatically when internet is available.';
      } else {
        return '🙏 Tithes can be submitted on the Tithe tab. Sign in to link contributions to your official membership record.';
      }
    }

    // 3. Stewardship Kitty Loans & Eligibility
    if (q.contains('loan') || q.contains('kitty') || q.contains('borrow') || q.contains('eligible') || q.contains('credit score')) {
      if (session.isLoggedIn) {
        return '🏛️ **Stewardship Kitty Loan Guidelines:**\n\n'
            '• **Member:** ${session.fullName}\n'
            '• **Assembly:** ${session.assignedBranch}\n'
            '• **Eligibility:** 3 consecutive months of recorded tithes & active guarantor required.\n'
            '• **Apply Offline:** You can fill out the Stewardship Kitty loan form right now; applications queue safely in offline storage and submit when you reconnect.';
      } else {
        return '🏛️ The Stewardship Kitty provides interest-free development loans to consecrated members. Please register or sign in to verify eligibility.';
      }
    }

    // 4. Restoration Scriptures
    if (q.contains('scripture') || q.contains('bible') || q.contains('inspired version') || q.contains('book of mormon') || q.contains('nephi') || q.contains('enoch') || q.contains('zion')) {
      return '📖 **Restoration Sacred Scriptures:**\n\n'
          '• **Inspired Version (JST):** Corrected by Joseph Smith with restored Genesis passages (Enoch\'s Zion) and Matthew 24.\n'
          '• **Book of Mormon:** Another witness of Jesus Christ from 1 Nephi through Moroni.\n'
          '• **100% Offline:** All books, chapters, and verses are stored directly in this app for offline reading anytime.';
    }

    // 5. Worship Service Schedule
    if (q.contains('service') || q.contains('time') || q.contains('schedule') || q.contains('sunday') || q.contains('prayer')) {
      return '⛪ **Worship Service Schedule:**\n\n'
          '• **Sunday Zion Worship:** 10:00 AM – 1:00 PM\n'
          '• **Sunday School & Youth:** 9:00 AM – 10:00 AM\n'
          '• **Wednesday Midweek Word & Prayer:** 6:00 PM – 7:30 PM\n'
          '• **Saturday Youth Ministry Fellowship:** 3:00 PM – 5:00 PM';
    }

    // 6. Branch Locator & Pastor
    if (q.contains('branch') || q.contains('pastor') || q.contains('location') || q.contains('kakamega') || q.contains('contact')) {
      return '📍 **Branch Assemblies in Kenya:**\n\n'
          '• **Kakamega Central Cathedral (Headquarters):** Pastor Samuel Makokha\n'
          '• **Lurambi Assembly:** Elder Josephat Barasa\n'
          '• **Malava Outreach Assembly:** Pastor Timothy Wekesa\n'
          '• **Nairobi Metropolitan Fellowship:** Elder David Otieno\n'
          'Check the "Events & Branch Assemblies" menu for GPS coordinates and contact phone numbers.';
    }

    return '🤖 **RLDS Church Assistant (Local AI):**\n\n'
        'I am running on your device. I can answer questions about:\n'
        '1. Your Member Profile & Branch (${session.assignedBranch})\n'
        '2. Stewardship Kitty loans and eligibility\n'
        '3. Tithes, offerings and offline sync\n'
        '4. Inspired Version & Book of Mormon scriptures\n'
        '5. Sunday service times and branch contacts\n\n'
        'How may I serve you today?';
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _isSending = true;
    });
    _controller.clear();
    _scrollToBottom();

    final session = ChurchMemberSession.instance;
    String botReply = '';

    try {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 7),
        receiveTimeout: const Duration(seconds: 7),
      ));
      final res = await dio.post(
        ApiConstants.chatMessage,
        data: {
          'message': text,
          'member_id': session.memberId,
          'email': session.email,
          'phone': session.phone,
          'full_name': session.fullName,
          'branch': session.assignedBranch,
          'role': session.role.name,
        },
      );
      botReply = res.data['reply'] ?? _generateOfflineAiReply(text);
    } catch (_) {
      botReply = _generateOfflineAiReply(text);
    } finally {
      if (mounted) {
        setState(() {
          _messages.add({'sender': 'bot', 'text': botReply});
          _isSending = false;
        });
        _scrollToBottom();
        if (_autoSpeak) {
          _speak(botReply, _messages.length - 1);
        }
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppStateNotifier.instance.currentLanguage;

    return Column(
      children: [
        // AI Chatbot Header with Status and Voice Auto-Speak Toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(bottom: BorderSide(color: Colors.grey.withAlpha(50))),
          ),
          child: Row(
            children: [
              const Icon(Icons.support_agent_rounded, color: Color(0xFF1E3A8A), size: 22),
              const SizedBox(width: 8),
              Text(
                ChurchTranslations.tr('ai_support', lang: lang),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _autoSpeak ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    size: 16,
                    color: _autoSpeak ? const Color(0xFF16A34A) : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  const Text('Speak', style: TextStyle(fontSize: 11)),
                  Switch(
                    value: _autoSpeak,
                    onChanged: (val) {
                      setState(() => _autoSpeak = val);
                      if (!val && _isSpeaking) _stopSpeech();
                    },
                    activeThumbColor: const Color(0xFF16A34A),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final msg = _messages[i];
              final isUser = msg['sender'] == 'user';
              final isSpeakingThis = _isSpeaking && _speakingIndex == i;

              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF1E3A8A) : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: isUser ? null : Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg['text']!,
                        style: TextStyle(
                          color: isUser ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                          fontSize: 13.5,
                        ),
                      ),
                      if (!isUser) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => _speak(msg['text']!, i),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSpeakingThis
                                      ? Colors.redAccent.withAlpha(20)
                                      : const Color(0xFF1E3A8A).withAlpha(15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSpeakingThis ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                                      size: 16,
                                      color: isSpeakingThis ? Colors.redAccent : const Color(0xFF1E3A8A),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isSpeakingThis
                                          ? ChurchTranslations.tr('stop_speech', lang: lang)
                                          : ChurchTranslations.tr('speak_response', lang: lang),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isSpeakingThis ? Colors.redAccent : const Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 4, offset: const Offset(0, -1)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: ChurchTranslations.tr('ai_prompt', lang: lang),
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
