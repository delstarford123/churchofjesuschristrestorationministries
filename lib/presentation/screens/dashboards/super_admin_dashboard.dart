import 'package:flutter/material.dart';
import 'package:rlds_church_app/core/localization/church_translations.dart';
import 'package:rlds_church_app/core/theme/theme_provider.dart';
import 'package:rlds_church_app/data/services/church_auth_session.dart';
import 'package:rlds_church_app/presentation/screens/auth/welcome_landing_screen.dart';
import 'package:rlds_church_app/presentation/screens/ministry/church_ministry_hub_screen.dart';
import 'package:rlds_church_app/presentation/screens/scripture_reader_view.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  // Executive council roster
  final List<Map<String, String>> _executives = [
    {
      'id': 'RLDS-EXEC-001',
      'name': 'Pastor Samuel Makokha',
      'role': 'Senior Pastor',
      'branch': 'Kakamega Central Cathedral',
      'phone': '+254712000001',
      'status': 'Active'
    },
    {
      'id': 'RLDS-EXEC-002',
      'name': 'Elder Josephat Barasa',
      'role': 'Presiding Elder',
      'branch': 'Lurambi Assembly',
      'phone': '+254712000002',
      'status': 'Active'
    },
    {
      'id': 'RLDS-EXEC-003',
      'name': 'Pastor Timothy Wekesa',
      'role': 'Pastor & Evangelist',
      'branch': 'Malava Assembly',
      'phone': '+254712000003',
      'status': 'Active'
    },
    {
      'id': 'RLDS-EXEC-004',
      'name': 'Elder David Otieno',
      'role': 'District Elder',
      'branch': 'Nairobi Metropolitan Fellowship',
      'phone': '+254712000004',
      'status': 'Active'
    },
    {
      'id': 'RLDS-EXEC-005',
      'name': 'Deaconess Mary Namalwa',
      'role': 'Head Deaconess & Welfare',
      'branch': 'Kakamega Central Cathedral',
      'phone': '+254712000005',
      'status': 'Active'
    },
  ];

  // Branches - created dynamically by Executive Members & Super Admin
  final List<Map<String, dynamic>> _branches = [];

  void _showAddBranchDialog() {
    final branchNameCtrl = TextEditingController();
    final pastorCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register New Branch Assembly', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: branchNameCtrl,
              decoration: const InputDecoration(labelText: 'Assembly Name', hintText: 'e.g. Kakamega Central Assembly'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pastorCtrl,
              decoration: const InputDecoration(labelText: 'Pastor in Charge'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Contact Phone Number'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            onPressed: () {
              if (branchNameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _branches.add({
                    'name': branchNameCtrl.text.trim(),
                    'pastor': pastorCtrl.text.trim().isEmpty ? 'To be appointed' : pastorCtrl.text.trim(),
                    'members': 0,
                    'phone': phoneCtrl.text.trim(),
                  });
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create Assembly'),
          ),
        ],
      ),
    );
  }

  void _showAddExecutiveDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final branchController = TextEditingController(text: _branches.isNotEmpty ? _branches.first['name'] : 'Kakamega Central Cathedral');
    String selectedRole = 'Pastor';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Executive Council Member', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'Priesthood / Executive Role', prefixIcon: Icon(Icons.shield)),
                  items: const [
                    DropdownMenuItem(value: 'Pastor', child: Text('Pastor (Assembly Leader)')),
                    DropdownMenuItem(value: 'Presiding Elder', child: Text('Presiding Elder')),
                    DropdownMenuItem(value: 'Stewardship Kitty Director', child: Text('Stewardship Kitty Director')),
                    DropdownMenuItem(value: 'Church Secretary', child: Text('Church Secretary')),
                    DropdownMenuItem(value: 'Treasurer', child: Text('Church Treasurer')),
                    DropdownMenuItem(value: 'Head Deaconess', child: Text('Head Deaconess')),
                  ],
                  onChanged: (val) {
                    if (val != null) selectedRole = val;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: branchController,
                  decoration: const InputDecoration(labelText: 'Assigned Branch Assembly', prefixIcon: Icon(Icons.church_rounded)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  setState(() {
                    _executives.add({
                      'name': nameController.text.trim(),
                      'role': selectedRole,
                      'branch': branchController.text.trim(),
                      'phone': phoneController.text.trim().isEmpty ? '+254700000000' : phoneController.text.trim(),
                      'status': 'Active'
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Appoint Executive'),
            ),
          ],
        );
      },
    );
  }

  void _removeExecutive(int index) {
    final removed = _executives[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Executive Access?'),
        content: Text('Are you sure you want to remove ${removed['name']} from the Executive Council? They will return to standard member permissions.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() {
                _executives.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Revoked executive credentials for ${removed['name']}'), backgroundColor: Colors.redAccent),
              );
            },
            child: const Text('Revoke Access', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out / Logout'),
        content: const Text('Are you sure you want to sign out from the Super Admin Supreme Council portal?'),
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
  Widget build(BuildContext context) {
    final lang = AppStateNotifier.instance.currentLanguage;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ChurchTranslations.tr('super_admin_portal', lang: lang),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
            ),
            const Text(
              'RLDS Church Supreme Governance & Oversight',
              style: TextStyle(fontSize: 11, color: Colors.white70),
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
            icon: const Icon(Icons.history_edu_rounded, color: Colors.white),
            tooltip: 'Sacred Ministry & Records',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChurchMinistryHubScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: Color(0xFFD97706)),
            tooltip: 'Appoint Executive Member',
            onPressed: _showAddExecutiveDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Sign Out / Switch Account',
            onPressed: _showLogoutConfirmDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Executive Council Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/img/App icon.jpg',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.security_rounded, size: 48, color: Color(0xFFD97706)),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Supreme Presiding Council',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Authoritative role allocation, financial governance & audit trail control',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Quick Canonical & Sacred Ministry Gateways
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChurchMinistryHubScreen()));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E3A8A).withAlpha(40)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.history_edu_rounded, color: Color(0xFF1E3A8A), size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sacred Records', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
                              Text('20 Live Modules', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ScriptureReaderView()));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD97706).withAlpha(40)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_stories_rounded, color: Color(0xFFD97706), size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Scriptures', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD97706))),
                              Text('IV Bible & BoM', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Overview Statistics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Congregants',
                  value: '955 Members',
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Stewardship Kitty',
                  value: 'KES 2,450,000',
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFFD97706),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Active Branches',
                  value: '${_branches.length} Assemblies',
                  icon: Icons.church_rounded,
                  color: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Executive Council',
                  value: '${_executives.length} Ministers',
                  icon: Icons.badge_rounded,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Executive Council List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Executive Council Members',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: _showAddExecutiveDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Executive', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Executive Members Cards
          ...List.generate(_executives.length, (index) {
            final exec = _executives[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1E3A8A).withAlpha(30),
                  child: const Icon(Icons.shield_rounded, color: Color(0xFF1E3A8A)),
                ),
                title: Text(exec['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${exec['role']} • ${exec['branch']}\n${exec['phone']}'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  tooltip: 'Revoke Executive Credentials',
                  onPressed: () => _removeExecutive(index),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Branch Assemblies',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: _showAddBranchDialog,
                icon: const Icon(Icons.add_location_alt_rounded, size: 16),
                label: const Text('Add Branch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_branches.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  ChurchTranslations.tr('no_branches', lang: lang),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            )
          else
            ..._branches.map((b) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF16A34A),
                      child: Icon(Icons.church_rounded, color: Colors.white, size: 20),
                    ),
                    title: Text(b['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    subtitle: Text('Pastor: ${b['pastor']} | Contact: ${b['phone']}', overflow: TextOverflow.ellipsis),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildMetricCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
