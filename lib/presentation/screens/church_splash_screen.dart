import 'package:flutter/material.dart';
import 'package:rlds_church_app/presentation/screens/home_dashboard.dart';

class ChurchSplashScreen extends StatefulWidget {
  final bool autoNavigate;
  const ChurchSplashScreen({super.key, this.autoNavigate = true});

  @override
  State<ChurchSplashScreen> createState() => _ChurchSplashScreenState();
}

class _ChurchSplashScreenState extends State<ChurchSplashScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.autoNavigate) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeDashboard()),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.church_rounded,
                  size: 80,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'The Church of Jesus Christ\nRestoration Ministry',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Digital Sanctuary & Stewardship Kitty',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
              ),
              const SizedBox(height: 32),
              const Text(
                'Powered by Delstarford Works',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
