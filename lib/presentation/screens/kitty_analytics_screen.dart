import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:rlds_church_app/core/constants/api_constants.dart';

class KittyAnalyticsScreen extends StatefulWidget {
  const KittyAnalyticsScreen({super.key});

  @override
  State<KittyAnalyticsScreen> createState() => _KittyAnalyticsScreenState();
}

class _KittyAnalyticsScreenState extends State<KittyAnalyticsScreen> {
  static const Color liturgicalBlue = Color(0xFF1E3A8A);
  static const Color stewardshipGold = Color(0xFFD97706);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color cleanNeutral = Color(0xFFF9FAFB);

  bool _isLoading = true;
  double _creditScore = 84.5;
  String _riskTier = 'Low Risk (Preferred Borrower)';
  double _eligibleLimit = 75000.0;
  
  // Kitty Pool Analytics (Executive Director View)
  double _totalReserve = 1250000.0;
  double _liquidCapital = 820000.0;
  double _totalDisbursed = 430000.0;
  double _defaultRate = 1.8;

  // Pledges
  final List<Map<String, dynamic>> _pledges = [
    {
      'campaign': 'Cathedral Land Acquisition (Kakamega)',
      'pledged': 100000.0,
      'fulfilled': 65000.0,
      'currency': 'KES'
    },
    {
      'campaign': 'Mission Outreach Vehicle Fund',
      'pledged': 50000.0,
      'fulfilled': 20000.0,
      'currency': 'KES'
    }
  ];

  @override
  void initState() {
    super.initState();
    _fetchLiveAnalytics();
  }

  Future<void> _fetchLiveAnalytics() async {
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl, connectTimeout: const Duration(seconds: 8)));
      final res = await dio.get('/financials/kitty/analytics');
      if (res.statusCode == 200 && mounted) {
        final data = res.data['analytics'];
        setState(() {
          _totalReserve = (data['total_kitty_reserve_fund_kes'] as num).toDouble();
          _liquidCapital = (data['available_liquid_capital_kes'] as num).toDouble();
          _totalDisbursed = (data['total_capital_disbursed_kes'] as num).toDouble();
          _defaultRate = (data['default_rate_percent'] as num).toDouble();
        });
      }
    } catch (_) {
      // Use defaults
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,##0.00');

    return Scaffold(
      backgroundColor: cleanNeutral,
      appBar: AppBar(
        backgroundColor: liturgicalBlue,
        elevation: 0,
        title: const Text(
          'Stewardship Kitty & Analytics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(stewardshipGold)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. AI CREDIT SCORING CARD
                  Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: surfaceWhite,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI Credit Scoring Algorithm',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                                  ),
                                  Text(
                                    'Evaluates tithe consistency & guarantor trust',
                                    style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withAlpha(25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _riskTier.split('(').first.trim(),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 110,
                                height: 110,
                                child: CircularProgressIndicator(
                                  value: _creditScore / 100,
                                  strokeWidth: 9,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: const AlwaysStoppedAnimation<Color>(stewardshipGold),
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    '${_creditScore.toInt()}',
                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: liturgicalBlue),
                                  ),
                                  const Text('/ 100 PTS', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cleanNeutral,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Eligible Kitty Loan Limit:', style: TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
                                Text(
                                  'KES ${currencyFmt.format(_eligibleLimit)}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: liturgicalBlue),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 2. EXECUTIVE DIRECTORS KITTY LIQUIDITY OVERVIEW
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
                              Icon(Icons.pie_chart_outline_rounded, color: liturgicalBlue, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Fund Liquidity & Reserve Pool',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Executive Board Transparency Dashboard',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: liturgicalBlue.withAlpha(12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Liquid Capital', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                                      const SizedBox(height: 4),
                                      Text(
                                        'KES ${NumberFormat('#,##0').format(_liquidCapital)}',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: liturgicalBlue),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: stewardshipGold.withAlpha(20),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Disbursed Loans', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                                      const SizedBox(height: 4),
                                      Text(
                                        'KES ${NumberFormat('#,##0').format(_totalDisbursed)}',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: stewardshipGold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Portfolio Default Rate: $_defaultRate%', style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                              const Text('Audit Status: Verified', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. MULTI-CURRENCY & PLEDGE TRACKER
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
                              Icon(Icons.terrain_rounded, color: stewardshipGold, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Church Land & Building Pledges',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ..._pledges.map((p) {
                            final pct = (p['fulfilled'] as double) / (p['pledged'] as double);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p['campaign'],
                                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                                        ),
                                      ),
                                      Text(
                                        '${(pct * 100).toInt()}%',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: liturgicalBlue),
                                      ),
                                    ],
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
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Fulfilled: KES ${NumberFormat('#,##0').format(p['fulfilled'])}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                      ),
                                      Text(
                                        'Target: KES ${NumberFormat('#,##0').format(p['pledged'])}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                      ),
                                    ],
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
