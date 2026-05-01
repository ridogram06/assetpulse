import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app.dart';
import 'core/services/notification_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase - don't crash if not configured
  const supabaseUrl = 'https://coguoqqkcwdqbhwlvvao.supabase.co';
  const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvZ3VvcXFrY3dkcWJod2x2dmFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2NTQ2MTcsImV4cCI6MjA5MzIzMDYxN30.ybw73ih7cGhHNOeVj6M0YPT9OomN9ccNwHI55v8mxII';

  try {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  } catch (e) {
    debugPrint('Supabase init failed (running without backend): $e');
  }

  // Firebase - optional, skip if google-services.json missing
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }

  // Notifications - optional
  try {
    await NotificationService.initialize(flutterLocalNotificationsPlugin);
  } catch (e) {
    debugPrint('Notifications init skipped: $e');
  }

  runApp(const ProviderScope(child: AssetPulseApp()));
}
