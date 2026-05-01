import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
    Session? session;
    try {
      session = Supabase.instance.client.auth.currentSession;
    } catch (_) {
      session = null;
    }

    if (!seenOnboarding) {
      context.go('/onboarding');
    } else if (session != null) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: AppColors.accent.withOpacity(0.4), width: 1.5),
                ),
                child: const Icon(Icons.monitor_heart_outlined,
                    color: AppColors.accent, size: 44),
              ),
              const SizedBox(height: 20),
              const Text('AssetPulse', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 8),
              const Text('সম্পদ ও ব্যয় ট্র্যাকার',
                  style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
