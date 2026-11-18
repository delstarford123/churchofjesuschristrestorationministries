import 'package:flutter/material.dart';
import 'package:rlds_church_app/core/localization/church_translations.dart';
import 'package:rlds_church_app/core/theme/theme_provider.dart';
import 'package:rlds_church_app/data/services/church_auth_session.dart';

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

  // Branches
  final List<Map<String, dynamic>> _branches = [
    {'name': 'Kakamega Central Cathedral', 'pastor': 'Pastor Samuel Makokha', 'members': 420, 'phone': '+254712000001'},
    {'name': 'Lurambi Assembly', 'pastor': 'Elder Josephat Barasa', 'members': 185, 'phone': '+254712000002'},
    {'name': 'Malava Assembly', 'pastor': 'Pastor Timothy Wekesa', 'members': 210, 'phone': '+254712000003'},
    {'name': 'Nairobi Metropolitan', 'pastor': 'Elder David Otieno', 'members': 140, 'phone': '+254712000004'},
  ];

  void _showAddExecutiveDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'Pastor';
    String selectedBranch = 'Kakamega Central Cathedral';

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
                  decoration: const InputDecoration(labelText: 'Ministerial Title / Role'),
                  items: ['Pastor', 'Elder', 'Bishop', 'Deacon', 'Deaconess']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) => selectedRole = val ?? selectedRole,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedBranch,
                  decoration: const InputDecoration(labelText: 'Branch Assembly Assignment'),
                  items: _branches
                      .map((b) => DropdownMenuItem(value: b['name'] as String, child: Text(b['name'] as String)))
                      .toList(),
                  onChanged: (val) => selectedBranch = val ?? selectedBranch,
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  setState(() {
                    _executives.add({
                      'id': 'RLDS-EXEC-00${_executives.length + 1}',
                      'name': nameController.text.trim(),
                      'role': selectedRole,
                      'branch': selectedBranch,
                      'phone': phoneController.text.trim().isEmpty ? '+254700000000' : phoneController.text.trim(),
                      'status': 'Active'
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Appointed ${nameController.text.trim()} to Executive Council'),
                      backgroundColor: const Color(0xFF16A34A),
                    ),
                  );
                }
              },
              child: const Text('Confirm Appointment', style: TextStyle(color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    final lang = AppStateNotifier.instance.currentLanguage;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            icon: const Icon(Icons.person_add_rounded, color: Color(0xFFD97706)),
            tooltip: 'Appoint Executive Member',
            onPressed: _showAddExecutiveDialog,
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
          const SizedBox(height: 16),

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
