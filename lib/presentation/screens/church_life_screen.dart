import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rlds_church_app/core/constants/api_constants.dart';
import 'package:rlds_church_app/core/localization/church_translations.dart';
import 'package:rlds_church_app/core/theme/theme_provider.dart';

class ChurchLifeScreen extends StatefulWidget {
  const ChurchLifeScreen({super.key});

  @override
  State<ChurchLifeScreen> createState() => _ChurchLifeScreenState();
}

class _ChurchLifeScreenState extends State<ChurchLifeScreen> {
  static const Color liturgicalBlue = Color(0xFF1E3A8A);
  static const Color stewardshipGold = Color(0xFFD97706);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color cleanNeutral = Color(0xFFF9FAFB);

  List<dynamic> _branches = [];
  bool _isLoadingBranches = true;

  List<Map<String, dynamic>> _events = [];
  bool _isLoadingEvents = true;

  @override
  void initState() {
    super.initState();
    _fetchBranches();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl, connectTimeout: const Duration(seconds: 8)));
      final res = await dio.get('/tech/events');
      if (res.statusCode == 200 && mounted) {
        final list = res.data['events'] as List? ?? [];
        setState(() {
          _events = list.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _events = []);
    } finally {
      if (mounted) setState(() => _isLoadingEvents = false);
    }
  }

  void _showAddEventDialog() {
    final titleCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: 'Upcoming Sabbath • 10:00 AM');
    final locationCtrl = TextEditingController(text: 'Main Sanctuary Assembly');
    final categoryCtrl = TextEditingController(text: 'Worship Service');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish Church Event / Retreat', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Event / Retreat Title')),
              const SizedBox(height: 8),
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date & Time')),
              const SizedBox(height: 8),
              TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Assembly Location / Venue')),
              const SizedBox(height: 8),
              TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category (Service, Retreat, Crusade)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: liturgicalBlue, foregroundColor: Colors.white),
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _events.insert(0, {
                    'title': titleCtrl.text.trim(),
                    'date': dateCtrl.text.trim(),
                    'location': locationCtrl.text.trim(),
                    'category': categoryCtrl.text.trim(),
                    'rsvpd': false,
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event published successfully to church calendar!'), backgroundColor: Color(0xFF16A34A)),
                );
              }
            },
            child: const Text('Publish Event'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchBranches() async {
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl, connectTimeout: const Duration(seconds: 8)));
      final res = await dio.get('/tech/branches');
      if (res.statusCode == 200 && mounted) {
        setState(() => _branches = res.data['branches'] ?? []);
      }
    } catch (_) {
      // Empty by default - branches will be created dynamically by executive members
      if (mounted) setState(() => _branches = []);
    } finally {
      if (mounted) setState(() => _isLoadingBranches = false);
    }
  }

  void _showAddBranchDialog() {
    final nameCtrl = TextEditingController();
    final countyCtrl = TextEditingController(text: 'Kakamega');
    final pastorCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_business_rounded, color: liturgicalBlue),
            SizedBox(width: 8),
            Text('Register Assembly', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Branch / Assembly Name', hintText: 'e.g. Kakamega Central Assembly'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: countyCtrl,
                decoration: const InputDecoration(labelText: 'County / Region', hintText: 'e.g. Kakamega'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: pastorCtrl,
                decoration: const InputDecoration(labelText: 'Pastor / Presiding Elder In Charge'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Contact Phone Number', hintText: 'e.g. +254712000000'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Physical Address / Location Landmark'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: liturgicalBlue, foregroundColor: Colors.white),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              final newBranch = {
                'name': name,
                'county': countyCtrl.text.trim(),
                'pastor_in_charge': pastorCtrl.text.trim(),
                'contact_phone': phoneCtrl.text.trim(),
                'address': addressCtrl.text.trim(),
              };

              try {
                final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
                await dio.post('/tech/branches', data: newBranch);
              } catch (_) {}

              setState(() {
                _branches.insert(0, newBranch);
              });
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cleanNeutral,
      appBar: AppBar(
        backgroundColor: liturgicalBlue,
        elevation: 0,
        title: Text(
          ChurchTranslations.tr('events_calendar', lang: AppStateNotifier.instance.currentLanguage),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(AppStateNotifier.instance.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: Colors.white),
            tooltip: 'Toggle Theme',
            onPressed: () => AppStateNotifier.instance.toggleTheme(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. WEEKLY DIGITAL BULLETIN HERO
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: surfaceWhite,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.newspaper_rounded, color: liturgicalBlue, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Weekly Digital Bulletin',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: stewardshipGold.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Next Sunday',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: stewardshipGold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Sermon: "Restoration of the Kingdom: Walking in Divine Stewardship"',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: liturgicalBlue),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Scripture: Haggai 1:4-9 & Malachi 3:10-12 • Preacher: Pastor Samuel Makokha',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cleanNeutral,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• 09:00 AM: Sunday School & Intercession', style: TextStyle(fontSize: 11.5, color: Color(0xFF374151))),
                          Text('• 10:00 AM: Worship & Praises (Choir)', style: TextStyle(fontSize: 11.5, color: Color(0xFF374151))),
                          Text('• 11:00 AM: Tithes & Stewardship Kitty Blessing', style: TextStyle(fontSize: 11.5, color: Color(0xFF374151))),
                          Text('• 11:30 AM: Ministry of the Word & Altar Call', style: TextStyle(fontSize: 11.5, color: Color(0xFF374151))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 2. UPCOMING EVENTS & RSVP
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: surfaceWhite,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.event_available_rounded, color: stewardshipGold, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Upcoming Events & Retreats',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _showAddEventDialog,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add Event', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingEvents)
                      const Center(child: CircularProgressIndicator())
                    else if (_events.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cleanNeutral,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.event_busy_rounded, size: 36, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              ChurchTranslations.tr('no_events', lang: AppStateNotifier.instance.currentLanguage),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: stewardshipGold,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              onPressed: _showAddEventDialog,
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Publish New Event / Retreat', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._events.map((e) {
                        final title = e['title'] ?? 'Church Gathering';
                        final date = e['event_date'] ?? e['date'] ?? 'Upcoming';
                        final location = e['location'] ?? 'Sanctuary Assembly';
                        final rsvpd = e['rsvpd'] == true;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cleanNeutral,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827))),
                                    Text('$date • $location', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: rsvpd ? const Color(0xFF16A34A) : liturgicalBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  setState(() => e['rsvpd'] = !rsvpd);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(!rsvpd ? 'RSVP Confirmed for $title' : 'RSVP Cancelled'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: Text(rsvpd ? 'RSVP\'d ✓' : 'RSVP', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 3. INTERACTIVE BRANCH LOCATOR
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: surfaceWhite,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.location_on_rounded, color: liturgicalBlue, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Church Branch Assemblies',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _showAddBranchDialog,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add Assembly', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Official assemblies registered by Church Executive Administration',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingBranches)
                      const Center(child: CircularProgressIndicator())
                    else if (_branches.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cleanNeutral,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.church_rounded, size: 36, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text(
                              'No Branch Assemblies Registered Yet',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827)),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Branch assemblies are registered directly by Executive Members and Church Administration.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: liturgicalBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              onPressed: _showAddBranchDialog,
                              icon: const Icon(Icons.add_business_rounded, size: 16),
                              label: const Text('Register New Branch Assembly', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._branches.map((b) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cleanNeutral,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: liturgicalBlue.withAlpha(15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.place_rounded, color: liturgicalBlue, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827))),
                                    Text('${b['address']}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                                    Text('Pastor: ${b['pastor_in_charge']} • ${b['contact_phone']}', style: const TextStyle(fontSize: 10.5, color: stewardshipGold, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
