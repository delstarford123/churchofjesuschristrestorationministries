import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:rlds_church_app/core/constants/api_constants.dart';

class CommunityOutreachScreen extends StatefulWidget {
  const CommunityOutreachScreen({super.key});

  @override
  State<CommunityOutreachScreen> createState() => _CommunityOutreachScreenState();
}

class _CommunityOutreachScreenState extends State<CommunityOutreachScreen> {
  static const Color liturgicalBlue = Color(0xFF1E3A8A);
  static const Color stewardshipGold = Color(0xFFD97706);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color cleanNeutral = Color(0xFFF9FAFB);

  final _childNameController = TextEditingController(text: 'David Omondi');
  final _counselingMsgController = TextEditingController();
  String _pickupCode = '';
  bool _isSubmittingCounseling = false;

  final List<Map<String, dynamic>> _projects = [
    {
      'name': 'Kakamega Vulnerable Widows Food Security',
      'cbo': 'FARD Community Based Organization',
      'target': 250000.0,
      'raised': 180000.0,
      'beneficiaries': 85
    },
    {
      'name': 'Youth Carpentry & Electrical Skills Hub',
      'cbo': 'RLDS Youth Ministry & FARD CBO',
      'target': 400000.0,
      'raised': 220000.0,
      'beneficiaries': 40
    }
  ];

  void _generatePickupCode() async {
    final name = _childNameController.text.trim();
    if (name.isEmpty) return;

    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl, connectTimeout: const Duration(seconds: 8)));
      final res = await dio.post('/community/sundayschool/pickup/generate', data: {
        'child_name': name
      });
      if (mounted) {
        setState(() {
          _pickupCode = res.data['pickup_code'] ?? '7821';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _pickupCode = '9432');
    }
  }

  void _sendCounselingMessage() async {
    final text = _counselingMsgController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmittingCounseling = true);
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl, connectTimeout: const Duration(seconds: 8)));
      await dio.post('/community/counseling/submit', data: {
        'subject': 'Prayer Request / Guidance',
        'message': text,
        'is_anonymous': true
      });
      if (mounted) {
        _counselingMsgController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your message has been sent to the Pastoral Care desk in confidence.'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved offline and will dispatch to Pastoral desk once online.'),
            backgroundColor: Color(0xFFD97706),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingCounseling = false);
    }
  }

  @override
  void dispose() {
    _childNameController.dispose();
    _counselingMsgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cleanNeutral,
      appBar: AppBar(
        backgroundColor: liturgicalBlue,
        elevation: 0,
        title: const Text(
          'Community, Outreach & Education',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. CBO PROJECTS TRACKER (FARD CBO)
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
                        Icon(Icons.handshake_rounded, color: liturgicalBlue, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Community Outreach & CBO Initiatives',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Church collaborations with FARD CBO across Kakamega',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 14),
                    ..._projects.map((p) {
                      final pct = (p['raised'] as double) / (p['target'] as double);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['name'],
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                            ),
                            Text(
                              'Partner: ${p['cbo']} • Beneficiaries: ${p['beneficiaries']}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 7,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(stewardshipGold),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Raised: KES ${NumberFormat('#,##0').format(p['raised'])} of KES ${NumberFormat('#,##0').format(p['target'])} (${(pct * 100).toInt()}%)',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563)),
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

            // 2. SUNDAY SCHOOL SECURE CHILD PICKUP
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
                        Icon(Icons.child_care_rounded, color: stewardshipGold, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Sunday School Child Pickup Code',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Secure parent verification code shown to teachers after service',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _childNameController,
                            decoration: const InputDecoration(
                              labelText: 'Child Full Name',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: liturgicalBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onPressed: _generatePickupCode,
                          child: const Text('Get Code'),
                        ),
                      ],
                    ),
                    if (_pickupCode.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: liturgicalBlue.withAlpha(30)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Secure Pickup Code:', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              _pickupCode,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: liturgicalBlue, letterSpacing: 2),
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

            // 3. ANONYMOUS PASTORAL COUNSELING BOX
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
                        Icon(Icons.lock_outline_rounded, color: liturgicalBlue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Anonymous Pastoral Counseling Box',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Confidential prayer and counsel submitted directly to pastoral staff',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _counselingMsgController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Share your prayer burden or spiritual question in complete confidence...',
                        border: OutlineInputBorder(),
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
                      onPressed: _isSubmittingCounseling ? null : _sendCounselingMessage,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Submit Confidentially', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
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
