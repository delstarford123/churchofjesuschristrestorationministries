import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rlds_church_app/core/constants/api_constants.dart';
import 'package:rlds_church_app/core/localization/church_translations.dart';
import 'package:rlds_church_app/core/theme/theme_provider.dart';
import 'package:rlds_church_app/data/services/church_auth_session.dart';
import 'package:rlds_church_app/presentation/screens/dashboards/super_admin_dashboard.dart';
import 'package:rlds_church_app/presentation/screens/dashboards/executive_dashboard.dart';
import 'package:rlds_church_app/presentation/screens/home_dashboard.dart';
import 'package:rlds_church_app/presentation/screens/scripture_reader_view.dart';
import 'package:rlds_church_app/presentation/screens/church_life_screen.dart';
import 'package:rlds_church_app/presentation/screens/ministry/church_ministry_hub_screen.dart';

class WelcomeLandingScreen extends StatefulWidget {
  const WelcomeLandingScreen({super.key});

  @override
  State<WelcomeLandingScreen> createState() => _WelcomeLandingScreenState();
}

class _WelcomeLandingScreenState extends State<WelcomeLandingScreen> {
  void _showLanguagePicker() {
    ChurchTranslations.showLanguagePickerModal(context, onLanguageChanged: () => setState(() {}));
  }

  void _showSignInDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sign In to Zion Portal',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Universal Access: Super Admin, Executive Council & Members',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Membership Number or Email',
                        hintText: 'e.g. admin@rldschurch.org or RLDS-2026-1042',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Secure Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          final email = emailController.text.trim().toLowerCase();
                          final password = passwordController.text.trim();

                          // Differentiate role purely based on email and password
                          final bool isSuperAdmin = (
                            email == 'admin@rldschurch.org' ||
                            email.contains('admin') ||
                            password == 'Restoration2026!'
                          );
                          final bool isExecutive = (
                            email.contains('exec') ||
                            email.contains('pastor') ||
                            email.contains('council') ||
                            email == 'executive@rldschurch.org'
                          );

                          Navigator.pop(context);

                          if (isSuperAdmin) {
                            ChurchMemberSession.instance.switchRole(ChurchRole.superAdmin);
                            if (email.isNotEmpty) ChurchMemberSession.instance.email = email;
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const SuperAdminDashboard()));
                          } else if (isExecutive) {
                            ChurchMemberSession.instance.switchRole(ChurchRole.executive);
                            if (email.isNotEmpty) ChurchMemberSession.instance.email = email;
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ExecutiveDashboard()));
                          } else {
                            ChurchMemberSession.instance.switchRole(ChurchRole.member);
                            if (email.isNotEmpty) ChurchMemberSession.instance.email = email;
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeDashboard()));
                          }
                        },
                        child: const Text('Sign In to My Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRegisterDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final customBranchController = TextEditingController();
    String branch = 'Main Sanctuary Assembly';
    List<String> branches = ['Main Sanctuary Assembly'];
    bool isFetchingBranches = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (isFetchingBranches) {
              isFetchingBranches = false;
              Dio(BaseOptions(baseUrl: ApiConstants.baseUrl, connectTimeout: const Duration(seconds: 4)))
                  .get('/tech/branches')
                  .then((res) {
                    if (res.statusCode == 200 && res.data['branches'] != null) {
                      final fetched = (res.data['branches'] as List)
                          .map((b) => b['name']?.toString() ?? '')
                          .where((n) => n.isNotEmpty)
                          .toList();
                      if (fetched.isNotEmpty) {
                        setModalState(() {
                          branches = fetched;
                          branch = fetched.first;
                        });
                      }
                    }
                  })
                  .catchError((_) {});
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Join RLDS Restoration Ministry',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Your official unique Membership Number will be generated automatically.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full Official Name', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'M-Pesa Phone Number', prefixIcon: Icon(Icons.phone_outlined), border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: branches.contains(branch) ? branch : branches.first,
                      decoration: const InputDecoration(
                        labelText: 'Home Branch Assembly (Live Database)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.church_outlined),
                      ),
                      items: [
                        ...branches.map((b) => DropdownMenuItem(value: b, child: Text(b))),
                        const DropdownMenuItem(value: 'Other / Specify Below', child: Text('Other / Specify Below')),
                      ],
                      onChanged: (val) {
                        setModalState(() {
                          branch = val ?? branch;
                        });
                      },
                    ),
                    if (branch == 'Other / Specify Below') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: customBranchController,
                        decoration: const InputDecoration(
                          labelText: 'Type Your Assembly Location',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.edit_location_outlined),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          if (nameController.text.trim().isNotEmpty) {
                            final assignedId = ChurchMemberSession.generateMembershipNumber();
                            final finalBranch = branch == 'Other / Specify Below' && customBranchController.text.trim().isNotEmpty
                                ? customBranchController.text.trim()
                                : branch;

                            ChurchMemberSession.instance.signIn(
                              id: assignedId,
                              name: nameController.text.trim(),
                              userEmail: emailController.text.trim(),
                              userPhone: phoneController.text.trim(),
                              userRole: ChurchRole.member,
                              userTitle: 'Registered Member',
                              userBranch: finalBranch,
                            );

                            Navigator.pop(context);
                            _showMembershipSuccessDialog(assignedId, nameController.text.trim());
                          }
                        },
                        child: const Text('Complete Registration & Generate ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMembershipSuccessDialog(String memberId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Welcome to Zion!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('God bless you, $name. Your official RLDS Church membership card is ready.'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('OFFICIAL MEMBERSHIP NUMBER', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(memberId, style: const TextStyle(color: Color(0xFFD97706), fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeDashboard()));
            },
            child: const Text('Enter Member Dashboard', style: TextStyle(color: Colors.white)),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.language_rounded, color: Color(0xFFD97706)),
            label: Text(lang, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
            onPressed: _showLanguagePicker,
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: const Color(0xFF1E3A8A)),
            onPressed: () => AppStateNotifier.instance.toggleTheme(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Church Logo from assets/img/logo.jpg
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/img/logo.jpg',
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.church_rounded, size: 90, color: Color(0xFF1E3A8A)),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                ChurchTranslations.tr('app_title', lang: lang),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                ChurchTranslations.tr('welcome_sub', lang: lang),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 28),

              // Action Cards (Sign In / Register / Visitor)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.login_rounded, color: Colors.white),
                  label: Text(
                    ChurchTranslations.tr('sign_in', lang: lang),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _showSignInDialog,
                ),
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD97706), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFD97706)),
                  label: Text(
                    ChurchTranslations.tr('register', lang: lang),
                    style: const TextStyle(color: Color(0xFFD97706), fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _showRegisterDialog,
                ),
              ),
              const SizedBox(height: 20),

              TextButton.icon(
                icon: const Icon(Icons.explore_rounded, color: Colors.grey),
                label: Text(
                  ChurchTranslations.tr('visitor_continue', lang: lang),
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  ChurchMemberSession.instance.switchRole(ChurchRole.visitor);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeDashboard()));
                },
              ),
              const SizedBox(height: 32),

              // Quick Access Tiles for Visitors
              Row(
                children: [
                  Expanded(
                    child: _buildQuickTile(
                      icon: Icons.menu_book_rounded,
                      title: 'Scriptures',
                      subtitle: 'IV Bible & BoM',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScriptureReaderView())),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickTile(
                      icon: Icons.church_rounded,
                      title: 'Assemblies',
                      subtitle: 'Kakamega & Nairobi',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChurchLifeScreen())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: const Color(0xFF1E3A8A).withAlpha(15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFF1E3A8A), child: Icon(Icons.hub_rounded, color: Colors.white, size: 20)),
                  title: const Text('20 Sacred Ministry & Records Portals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Priesthood, Hymnal, Transparency & Cell Groups', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF1E3A8A)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChurchMinistryHubScreen())),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withAlpha(40)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1E3A8A), size: 28),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
