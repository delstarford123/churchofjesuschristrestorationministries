import 'package:flutter/material.dart';
import 'package:rlds_church_app/core/theme/theme_provider.dart';
import 'package:rlds_church_app/core/localization/church_translations.dart';
import 'package:rlds_church_app/data/services/church_auth_session.dart';

class ChurchMinistryHubScreen extends StatefulWidget {
  final int initialTabIndex;
  const ChurchMinistryHubScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ChurchMinistryHubScreen> createState() => _ChurchMinistryHubScreenState();
}

class _ChurchMinistryHubScreenState extends State<ChurchMinistryHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppStateNotifier.instance.currentLanguage;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sacred Ministry & Records', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
            Text('20 High-Impact Connection & Governance Portals', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD97706),
          indicatorWeight: 3,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.shield_outlined), text: 'Priesthood & Ordinances'),
            Tab(icon: Icon(Icons.menu_book_outlined), text: 'Worship & Devotionals'),
            Tab(icon: Icon(Icons.pie_chart_outline), text: 'Transparency & Benevolence'),
            Tab(icon: Icon(Icons.people_outline), text: 'Community & Governance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PriesthoodOrdinancesView(),
          _WorshipDevotionalsView(),
          _TransparencyBenevolenceView(),
          _CommunityGovernanceView(),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 1: PRIESTHOOD, ORDINANCES & SACRED RECORDS (Features 1, 2, 6, 12, 13)
// =============================================================================
class _PriesthoodOrdinancesView extends StatefulWidget {
  @override
  State<_PriesthoodOrdinancesView> createState() => _PriesthoodOrdinancesViewState();
}

class _PriesthoodOrdinancesViewState extends State<_PriesthoodOrdinancesView> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Digital Priesthood Lineage Tracker
        _buildModuleCard(
          icon: Icons.history_edu_rounded,
          badge: 'FEATURE 1',
          title: 'Digital Ordination & Priesthood Lineage',
          subtitle: 'Verify priesthood office (Deacon, Teacher, Priest, Elder, High Priest, Bishop, Apostle) and canonical line of authority.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Minister: Pastor Samuel Makokha', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Office: Presiding Elder • Quorum: High Priests Quorum', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    Text('Ordained by: Presiding Bishopric (May 12, 2018)', style: TextStyle(fontSize: 12)),
                    SizedBox(height: 4),
                    Text('Certificate: RLDS-ORD-2018-042 • Canonical Lineage Verified', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Sacrament & Sick Visitation Roster
        _buildModuleCard(
          icon: Icons.local_hospital_outlined,
          badge: 'FEATURE 2',
          title: 'Sacrament Service & Sick Visitation Roster',
          subtitle: 'Deacons log home visits to elderly and housebound members to administer the Lord\'s Supper and assess welfare needs.',
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: Color(0xFFD97706), child: Icon(Icons.home, color: Colors.white, size: 20)),
                title: const Text('Sister Martha Nakhumicha (Lurambi)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Administered: Holy Communion • Welfare: Food basket delivered\nVisited by: Deaconess Mary Namalwa', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), minimumSize: const Size(double.infinity, 38)),
                onPressed: () => _showDialog('Log New Visitation', 'Record member name, address, sacrament status, and welfare notes for Deacon board review.'),
                icon: const Icon(Icons.add_task, color: Colors.white, size: 16),
                label: const Text('Log Home Visitation Record', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 6. Sacred Vows & Marriage Registry
        _buildModuleCard(
          icon: Icons.favorite_rounded,
          badge: 'FEATURE 6',
          title: 'Sacred Vows & Marriage Registry',
          subtitle: 'Digital repository for church matrimony certificates, pre-marital counseling logs, and officiant signatures.',
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withAlpha(50)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Matrimony of: Bro. David & Sis. Grace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Officiant: Pastor Samuel Makokha • Kakamega Cathedral', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text('Pre-marital Counseling: 8 Sessions Completed • Registry: #RLDS-MAR-2026-08', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 12. Church Assets & Sacred Communion Inventory QR Tagging
        _buildModuleCard(
          icon: Icons.qr_code_scanner_rounded,
          badge: 'FEATURE 12',
          title: 'Church Assets & Communion Inventory QR Tagging',
          subtitle: 'Physical QR stickers placed on church sound systems, communion trays, and tents for deacon audits.',
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Silver Communion Trays (Set of 6)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  Text('Status: Excellent', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 4),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cathedral Audio PA Mixer & Mics', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  Text('Status: Tagged #TAG-AUD-04', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 38)),
                onPressed: () => _showDialog('Scan Asset QR Tag', 'Camera scanner active. Scan asset label to log location and condition.'),
                icon: const Icon(Icons.qr_code_scanner, size: 16),
                label: const Text('Scan Asset QR Code', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 13. Digital Covenant & Baptismal Certificate Generator
        _buildModuleCard(
          icon: Icons.workspace_premium_rounded,
          badge: 'FEATURE 13',
          title: 'Digital Covenant & Baptismal Certificate',
          subtitle: 'Instant generation of official church baptism and blessing certificates signed digitally by the Bishopric with QR verification.',
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, color: Color(0xFFD97706), size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Candidate: ${ChurchMemberSession.instance.fullName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const Text('Baptized: January 15, 2026 • Waters of Kakamega', style: TextStyle(fontSize: 11)),
                      const Text('Seal: VERIFIED-RLDS-SACRED-SEAL-2026', style: TextStyle(fontSize: 10, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Dismiss'))],
      ),
    );
  }
}

// =============================================================================
// TAB 2: LITURGY, DEVOTIONALS & WORSHIP LIFE (Features 3, 4, 8, 11, 15)
// =============================================================================
class _WorshipDevotionalsView extends StatefulWidget {
  @override
  State<_WorshipDevotionalsView> createState() => _WorshipDevotionalsViewState();
}

class _WorshipDevotionalsViewState extends State<_WorshipDevotionalsView> {
  int _prayerCount = 148;
  bool _isPlayingHymn = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 4. Restoration Hymnal with Audio
        _buildModuleCard(
          icon: Icons.music_note_rounded,
          badge: 'FEATURE 4',
          title: 'Restoration Hymnal with Audio Accompaniment',
          subtitle: 'Sacred hymns with lyrics in English and Kiswahili, sheet music meter, and offline audio playback for branch singing.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withAlpha(15), borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hymn #1: The Spirit of God Like a Fire Is Burning', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Text('Swahili: Roho wa Mungu Kama Moto Unawaka', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11, color: Colors.blueGrey)),
                    const SizedBox(height: 6),
                    const Text('"The Spirit of God like a fire is burning! The latter-day glory begins to come forth; The visions and blessings of old are returning, and angels are coming to visit the earth."', style: TextStyle(fontSize: 11)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(_isPlayingHymn ? Icons.pause_circle_filled : Icons.play_circle_fill, color: const Color(0xFFD97706), size: 32),
                          onPressed: () => setState(() => _isPlayingHymn = !_isPlayingHymn),
                        ),
                        Text(_isPlayingHymn ? 'Playing Offline Accompaniment (G Major)...' : 'Play Hymn Audio Accompaniment', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 8. Direct-to-Pastor Prayer Request Wall
        _buildModuleCard(
          icon: Icons.volunteer_activism_rounded,
          badge: 'FEATURE 8',
          title: 'Direct-to-Pastor Prayer Wall',
          subtitle: 'Submit public requests for church intercession or confidential requests visible only to the Pastoral Quorum.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.withAlpha(40)), borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Healing Prayer for Sick Congregants', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Congregational', style: TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('"Praying for divine health and strength upon all mothers and children in Malava and Lurambi assemblies."', style: TextStyle(fontSize: 11)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$_prayerCount Saints Praying', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                        TextButton.icon(
                          onPressed: () => setState(() => _prayerCount++),
                          icon: const Icon(Icons.favorite, color: Colors.redAccent, size: 16),
                          label: const Text('I am Praying', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 11. Push-Notification Devotional & Daily Fasting
        _buildModuleCard(
          icon: Icons.notifications_active_outlined,
          badge: 'FEATURE 11',
          title: 'Daily Devotionals & Fasting Reminders',
          subtitle: 'Scheduled devotionals from the Inspired Version & Book of Mormon, plus Wednesday fasting guidelines.',
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFD97706).withAlpha(15), borderRadius: BorderRadius.circular(10)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today\'s Sacred Focus: Building Zion in Righteousness', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Reading: Genesis 7:23 (IV) & Mosiah 4:16', style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Fasting Notice: Wednesday Restoration Fast until 3:00 PM for community widows and youth employment.', style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 15. Offline Voice Sermon Recorder & Podcast Archive
        _buildModuleCard(
          icon: Icons.mic_external_on_rounded,
          badge: 'FEATURE 15',
          title: 'Offline Voice Sermons & Audio Archive',
          subtitle: 'Pastoral preaching recorded during service, compressed and cached on your device for offline listening during the week.',
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: Color(0xFF1E3A8A), child: Icon(Icons.headphones, color: Colors.white, size: 18)),
                title: const Text('The Law of Consecration & Stewardship', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Preacher: Pastor Samuel Makokha • 42 mins\nDownloaded for offline study', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.download_done, color: Color(0xFF16A34A)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Automated Birthday & Baptism Anniversary Blessings
        _buildModuleCard(
          icon: Icons.cake_outlined,
          badge: 'FEATURE 3',
          title: 'Birthday & Baptism Anniversary Blessings',
          subtitle: 'Personalized SMS and pastoral blessings sent automatically on members\' birthdays and spiritual baptism milestones.',
          child: const Text('Automated ministerial blessings active for all registered congregants via Africa\'s Talking SMS.', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
        ),
      ],
    );
  }
}

// =============================================================================
// TAB 3: FINANCIAL TRANSPARENCY & BENEVOLENCE (Features 9, 10, 18)
// =============================================================================
class _TransparencyBenevolenceView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 9. Financial Transparency Reports
        _buildModuleCard(
          icon: Icons.account_balance_rounded,
          badge: 'FEATURE 9',
          title: 'Quarterly Financial Transparency Reports',
          subtitle: 'Public visual infographics showing how tithes and offerings are distributed across benevolence, evangelism, and building.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Q3 2026 Tithe Stewardship Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              _buildProgressBar('Benevolence & Needy Assistance', 0.25, 'KES 680,000 (25%)', const Color(0xFF16A34A)),
              _buildProgressBar('Sanctuary Building & Development', 0.45, 'KES 1,250,000 (45%)', const Color(0xFF1E3A8A)),
              _buildProgressBar('Missions, Outreach & Education', 0.20, 'KES 520,000 (20%)', const Color(0xFFD97706)),
              _buildProgressBar('Stewardship Kitty Reserve Pool', 0.10, 'KES 1,000,000 (10%)', Colors.purple),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 10. Emergency Medical & Bereavement Assistance Fund
        _buildModuleCard(
          icon: Icons.emergency_outlined,
          badge: 'FEATURE 10',
          title: 'Emergency Medical & Bereavement Assistance',
          subtitle: 'Rapid-action benevolence triggers where members can opt into emergency drives verified by the Deacon board.',
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.redAccent.withAlpha(50)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Emergency Medical Fund: Lurambi Sister', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent)),
                    Text('Urgent', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Verified by: Deaconess Mary Namalwa • Raised: KES 45,000 / KES 60,000', style: TextStyle(fontSize: 11)),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), minimumSize: const Size(double.infinity, 36)),
                  onPressed: () {},
                  child: const Text('Contribute KES 500 via M-Pesa', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 18. Multi-Pledge Project Tracker
        _buildModuleCard(
          icon: Icons.apartment_rounded,
          badge: 'FEATURE 18',
          title: 'Multi-Pledge Project Tracker',
          subtitle: 'Visual progress bars toward church physical development projects, showing pledged vs. redeemed contributions.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kakamega Central Cathedral Expansion (1,200 Seats)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              _buildProgressBar('Target: KES 5,000,000', 0.64, 'Raised: KES 3,200,000 (64%)', const Color(0xFF1E3A8A)),
              const SizedBox(height: 10),
              const Text('Malava Outreach Center 2-Acre Land Acquisition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              _buildProgressBar('Target: KES 1,500,000', 0.56, 'Raised: KES 850,000 (56%)', const Color(0xFFD97706)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(String label, double value, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ]),
          const SizedBox(height: 3),
          LinearProgressIndicator(value: value, color: color, backgroundColor: color.withAlpha(30), minHeight: 6),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 4: COMMUNITY, FAMILIES, MENTORSHIP & GOVERNANCE (Features 5, 7, 14, 16, 17, 19, 20)
// =============================================================================
class _CommunityGovernanceView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 5. Interactive Branch Fellowship Geo-Locator
        _buildModuleCard(
          icon: Icons.map_outlined,
          badge: 'FEATURE 5',
          title: 'Branch Fellowship Geo-Locator',
          subtitle: 'Live directory for Kakamega, Nairobi, and Western assemblies with turn-by-turn navigation.',
          child: const Text('4 Assemblies Active: Kakamega Central Cathedral (0.2827° N, 34.7519° E), Lurambi, Malava, Nairobi Upper Hill.', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(height: 16),

        // 7. Sunday School Scripture Memorization Badge System
        _buildModuleCard(
          icon: Icons.star_rate_rounded,
          badge: 'FEATURE 7',
          title: 'Sunday School Scripture Badge System',
          subtitle: 'Gamified memory verse milestone badges for children with digital certificates sent to parents.',
          child: Row(
            children: [
              const Icon(Icons.military_tech_rounded, color: Color(0xFFD97706), size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Badge: "Enoch\'s Zion Pioneer"', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Text('Memory Verse: Genesis 7:23 (IV)', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
                    Row(children: List.generate(5, (index) => const Icon(Icons.star, color: Color(0xFFD97706), size: 14))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 14. Small-Group / Fellowship Cell Group Portal
        _buildModuleCard(
          icon: Icons.diversity_3_rounded,
          badge: 'FEATURE 14',
          title: 'Fellowship Cell Group Portal',
          subtitle: 'Map members to neighborhood fellowship groups with localized prayer meetings and weekly hosts.',
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Cell: Kakamega Central Shalom Cell', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('Host Family: Bro. & Sis. Makokha • Tuesdays 5:30 PM\nArea: Amalemba / Town • 24 Active Saints', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 16. Youth Mentorship & Career Empowerment Directory
        _buildModuleCard(
          icon: Icons.school_rounded,
          badge: 'FEATURE 16',
          title: 'Youth Mentorship & Career Empowerment',
          subtitle: 'Professional networking connecting young graduates with established church professionals for career guidance.',
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available Mentors in Congregation:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              SizedBox(height: 4),
              Text('• Eng. Derrick Ochieng (Civil Engineering) - 2 Slots\n• Dr. Grace Wanjiku (Public Health & Medicine) - 3 Slots', style: TextStyle(fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 17. Parent-Child Secure Pickup Verification System
        _buildModuleCard(
          icon: Icons.security_rounded,
          badge: 'FEATURE 17',
          title: 'Parent-Child Secure Pickup Verification',
          subtitle: 'Dynamic 4-digit PIN + QR security check ensuring child safety during Sunday school release.',
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF16A34A).withAlpha(15), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Active Today\'s Pickup PIN:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text('7821', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 19. Digital Pastoral Counseling Appointment Scheduler
        _buildModuleCard(
          icon: Icons.calendar_month_rounded,
          badge: 'FEATURE 19',
          title: 'Pastoral Counseling Appointment Scheduler',
          subtitle: 'Book 30-minute private spiritual counseling sessions directly with a Pastor or Elder.',
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), minimumSize: const Size(double.infinity, 38)),
            onPressed: () {},
            icon: const Icon(Icons.event_available, color: Colors.white, size: 16),
            label: const Text('Schedule Pastoral Counseling Session', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 16),

        // 20. Church Council Voting & Deliberative Governance System
        _buildModuleCard(
          icon: Icons.how_to_vote_rounded,
          badge: 'FEATURE 20',
          title: 'Church Council Voting & Governance',
          subtitle: 'Tamper-proof voting for branch executive committee appointments and annual general resolutions.',
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.withAlpha(40)), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Active Ballot: 2026 Deacons Board Confirmation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                const Text('Status: 148 Yes • 8 No • Voting Closes in 12 Days', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Vote No'))),
                    const SizedBox(width: 8),
                    Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)), onPressed: () {}, child: const Text('Vote Yes', style: TextStyle(color: Colors.white)))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Reusable Module Card Builder
Widget _buildModuleCard({
  required IconData icon,
  required String badge,
  required String title,
  required String subtitle,
  required Widget child,
}) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF1E3A8A), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(badge, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                    ),
                    const SizedBox(height: 2),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}
