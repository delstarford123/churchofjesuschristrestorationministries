import 'package:flutter/material.dart';
import 'package:rlds_church_app/core/localization/church_translations.dart';
import 'package:rlds_church_app/core/theme/theme_provider.dart';
import 'package:rlds_church_app/data/services/church_auth_session.dart';

class ExecutiveDashboard extends StatefulWidget {
  const ExecutiveDashboard({super.key});

  @override
  State<ExecutiveDashboard> createState() => _ExecutiveDashboardState();
}

class _ExecutiveDashboardState extends State<ExecutiveDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _pendingLoans = [
    {
      'id': 'LOAN-2026-081',
      'applicant': 'Grace Auma',
      'member_id': 'RLDS-2026-1044',
      'amount': 'KES 25,000',
      'purpose': 'Small Poultry Farming Enterprise',
      'ai_score': 88,
      'guarantor': 'Elder Josephat Barasa (Signed)',
      'status': 'Pending Approval'
    },
    {
      'id': 'LOAN-2026-082',
      'applicant': 'Peter Shikuku',
      'member_id': 'RLDS-2026-1092',
      'amount': 'KES 15,000',
      'purpose': 'Emergency Medical Support',
      'ai_score': 79,
      'guarantor': 'Deaconess Mary Namalwa (Signed)',
      'status': 'Pending Approval'
    },
  ];

  final List<Map<String, String>> _events = [
    {
      'title': 'Sabbath Worship & Holy Communion',
      'date': 'Sunday, Nov 22, 2026',
      'time': '9:30 AM',
      'branch': 'Kakamega Central Cathedral',
      'speaker': 'Pastor Samuel Makokha'
    },
    {
      'title': 'Restoration Youth Camp & Scripture Bee',
      'date': 'Saturday, Nov 28, 2026',
      'time': '8:00 AM',
      'branch': 'Malava Assembly',
      'speaker': 'Evangelist Timothy Wekesa'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final dateController = TextEditingController(text: 'Sunday, Dec 6, 2026');
    final timeController = TextEditingController(text: '10:00 AM');
    final speakerController = TextEditingController();
    final branchController = TextEditingController(text: 'Main Sanctuary');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Church Event', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Event Title')),
              const SizedBox(height: 10),
              TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date')),
              const SizedBox(height: 10),
              TextField(controller: timeController, decoration: const InputDecoration(labelText: 'Time')),
              const SizedBox(height: 10),
              TextField(controller: speakerController, decoration: const InputDecoration(labelText: 'Speaker / Minister in Charge')),
              const SizedBox(height: 10),
              TextField(controller: branchController, decoration: const InputDecoration(labelText: 'Host Branch / Sanctuary')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                setState(() {
                  _events.add({
                    'title': titleController.text.trim(),
                    'date': dateController.text.trim(),
                    'time': timeController.text.trim(),
                    'branch': branchController.text.trim(),
                    'speaker': speakerController.text.trim().isEmpty ? 'Ministerial Council' : speakerController.text.trim()
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event published successfully to Sanctuary feed!'), backgroundColor: Color(0xFF16A34A)),
                );
              }
            },
            child: const Text('Publish Event', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppStateNotifier.instance.currentLanguage;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ChurchTranslations.tr('executive_portal', lang: lang),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
            ),
            const Text(
              'Pastors, Elders & Deacons Administrative Council',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert_rounded, color: Color(0xFFD97706)),
            tooltip: 'Publish Event',
            onPressed: _showAddEventDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD97706),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.account_balance_wallet_rounded), text: 'Kitty Loans'),
            Tab(icon: Icon(Icons.event_available_rounded), text: 'Events & Liturgy'),
            Tab(icon: Icon(Icons.support_agent_rounded), text: 'Pastoral Care'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: STEWARDSHIP KITTY APPROVALS
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD97706).withAlpha(60)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: Color(0xFFD97706), size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Review loan applications, AI credit eligibility, and guarantor signatures prior to fund disbursement.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ..._pendingLoans.map((loan) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(loan['applicant'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'AI Score: ${loan['ai_score']}/100',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Member ID: ${loan['member_id']} • Requested: ${loan['amount']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text('Purpose: ${loan['purpose']}', style: const TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 16),
                            const SizedBox(width: 4),
                            Text('Guarantor: ${loan['guarantor']}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                              onPressed: () {
                                setState(() {
                                  _pendingLoans.remove(loan);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Declined loan for ${loan['applicant']}')),
                                );
                              },
                              child: const Text('Decline'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                              icon: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                              label: const Text('Approve & Disburse', style: TextStyle(color: Colors.white)),
                              onPressed: () {
                                setState(() {
                                  _pendingLoans.remove(loan);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Approved ${loan['amount']} for ${loan['applicant']} via M-Pesa B2C'),
                                    backgroundColor: const Color(0xFF16A34A),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),

          // TAB 2: EVENTS & BRANCH LITURGY
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Published Church Schedules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
                    onPressed: _showAddEventDialog,
                    icon: const Icon(Icons.add, color: Colors.white, size: 16),
                    label: const Text('New Event', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._events.map((event) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF1E3A8A),
                      child: Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
                    ),
                    title: Text(event['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${event['date']} • ${event['time']}\nLocation: ${event['branch']}\nMinister: ${event['speaker']}'),
                    isThreeLine: true,
                  ),
                );
              }),
            ],
          ),

          // TAB 3: PASTORAL COUNSELING
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const ListTile(
                  leading: Icon(Icons.mark_email_unread_rounded, color: Color(0xFFD97706)),
                  title: Text('Anonymous Pastoral Counseling Query #402', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Category: Spiritual Discernment & Family Prayer\n"Seeking guidance on church dedication and family prayer."'),
                  isThreeLine: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
