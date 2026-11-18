import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rlds_church_app/core/constants/api_constants.dart';

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

  bool _isSwahili = false;
  List<dynamic> _branches = [];
  bool _isLoadingBranches = true;

  final List<Map<String, dynamic>> _events = [
    {
      'title': 'Grand Restoration Revival Crusade',
      'date': 'Friday - Sunday • 4:00 PM',
      'location': 'Muliro Gardens, Kakamega CBD',
      'category': 'Crusade & Healing',
      'rsvpd': false
    },
    {
      'title': 'Stewardship Kitty Quarterly Review',
      'date': 'Saturday • 2:00 PM',
      'location': 'Cathedral Boardroom & Zoom',
      'category': 'Governance',
      'rsvpd': true
    },
    {
      'title': 'Youth Fellowship & Worship Night',
      'date': 'Next Friday • 6:30 PM',
      'location': 'Lurambi Assembly Sanctuary',
      'category': 'Youth Ministry',
      'rsvpd': false
    }
  ];

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl, connectTimeout: const Duration(seconds: 8)));
      final res = await dio.get('/tech/branches');
      if (res.statusCode == 200 && mounted) {
        setState(() => _branches = res.data['branches'] ?? []);
      }
    } catch (_) {
      // Fallback local list
      setState(() {
        _branches = [
          {
            'name': 'Kakamega Central Cathedral',
            'pastor_in_charge': 'Pastor Samuel Makokha',
            'contact_phone': '+254712000001',
            'address': 'Cathedral Way, Kakamega CBD'
          },
          {
            'name': 'Lurambi Assembly',
            'pastor_in_charge': 'Elder Josephat Barasa',
            'contact_phone': '+254712000002',
            'address': 'Lurambi Junction, Webuye Highway'
          },
          {
            'name': 'Malava Assembly & Outreach Centre',
            'pastor_in_charge': 'Pastor Timothy Wekesa',
            'contact_phone': '+254712000003',
            'address': 'Malava Market Plaza, Kakamega North'
          }
        ];
      });
    } finally {
      if (mounted) setState(() => _isLoadingBranches = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cleanNeutral,
      appBar: AppBar(
        backgroundColor: liturgicalBlue,
        elevation: 0,
        title: Text(
          _isSwahili ? 'Matawi na Matukio' : 'Events & Branch Assemblies',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () => setState(() => _isSwahili = !_isSwahili),
            icon: const Icon(Icons.language_rounded, size: 18),
            label: Text(_isSwahili ? 'SWA (🇰🇪)' : 'ENG (🇬🇧)', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    const Row(
                      children: [
                        Icon(Icons.event_available_rounded, color: stewardshipGold, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Upcoming Events & Crusades',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._events.map((e) {
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
                                  Text(e['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827))),
                                  Text('${e['date']} • ${e['location']}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: e['rsvpd'] ? const Color(0xFF16A34A) : liturgicalBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                setState(() => e['rsvpd'] = !e['rsvpd']);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e['rsvpd'] ? 'RSVP Confirmed for ${e['title']}' : 'RSVP Cancelled'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Text(e['rsvpd'] ? 'RSVP\'d ✓' : 'RSVP', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                    const SizedBox(height: 4),
                    const Text(
                      'RLDS assemblies across Kakamega County and Kenya',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingBranches)
                      const Center(child: CircularProgressIndicator())
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
