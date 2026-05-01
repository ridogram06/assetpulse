import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

final _notificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];
  final data = await client
      .from('notification_log')
      .select()
      .eq('user_id', userId)
      .order('sent_at', ascending: false)
      .limit(50);
  return List<Map<String, dynamic>>.from(data as List);
});

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(_notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('নোটিফিকেশন', style: AppTextStyles.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => ref.refresh(_notificationsProvider),
            child: const Text('রিফ্রেশ',
                style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
      body: notifsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('$e')),
        data: (notifs) {
          if (notifs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔔', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('কোনো নোটিফিকেশন নেই',
                      style: AppTextStyles.bodyMedium),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            separatorBuilder: (_, __) =>
                const Divider(color: AppColors.cardBorder, height: 1),
            itemBuilder: (_, i) {
              final n = notifs[i];
              final isUnread = n['read_at'] == null;
              final type = n['notif_type'] as String? ?? '';
              final icon = type.contains('warning')
                  ? '⚠️'
                  : type.contains('expired')
                      ? '🔴'
                      : type.contains('budget')
                          ? '💰'
                          : type.contains('prediction')
                              ? '🤖'
                              : '🔔';

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                leading: Stack(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 28)),
                    if (isUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accent, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  n['title'] as String? ?? type,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight:
                        isUnread ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                subtitle: Text(
                  _formatTime(n['sent_at'] as String? ?? ''),
                  style: AppTextStyles.bodySmall,
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} মিনিট আগে';
      if (diff.inHours < 24) return '${diff.inHours} ঘণ্টা আগে';
      return '${diff.inDays} দিন আগে';
    } catch (_) {
      return '';
    }
  }
}
