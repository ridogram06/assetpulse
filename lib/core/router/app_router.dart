import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/signup_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/asset_detail/asset_detail_screen.dart';
import '../../presentation/screens/calendar/calendar_screen.dart';
import '../../presentation/screens/analytics/analytics_screen.dart';
import '../../presentation/screens/notifications/notification_center_screen.dart';
import '../../presentation/screens/vault/vault_manager_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final isOnAuthPage = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      final isOnSplash = state.matchedLocation == '/splash';
      final isOnOnboarding = state.matchedLocation == '/onboarding';

      if (isOnSplash || isOnOnboarding) return null;
      if (!isAuth && !isOnAuthPage) return '/login';
      if (isAuth && isOnAuthPage) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/splash',      builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding',  builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login',       builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup',      builder: (_, __) => const SignupScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const DashboardScreen(),
        routes: [
          GoRoute(
            path: 'asset/:id',
            builder: (_, state) => AssetDetailScreen(
              assetId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(path: '/calendar',      builder: (_, __) => const CalendarScreen()),
      GoRoute(path: '/analytics',     builder: (_, __) => const AnalyticsScreen()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationCenterScreen()),
      GoRoute(path: '/vaults',        builder: (_, __) => const VaultManagerScreen()),
      GoRoute(path: '/settings',      builder: (_, __) => const SettingsScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
