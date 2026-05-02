import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('সেটিংস', style: AppTextStyles.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.accent.withOpacity(0.2),
                  child: const Text('👤', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.userMetadata?['display_name'] as String? ?? 'ব্যবহারকারী',
                        style: AppTextStyles.titleMedium,
                      ),
                      Text(user?.email ?? '',
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('সাধারণ', style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          _SettingsGroup(items: [
            _SettingsTile(
              icon: Icons.currency_exchange,
              label: 'মুদ্রা',
              trailing: 'BDT ৳',
              onTap: () => _comingSoon(context),
            ),
            _SettingsTile(
              icon: Icons.palette_outlined,
              label: 'থিম',
              trailing: 'ডার্ক',
              onTap: () => _comingSoon(context),
            ),
            _SettingsTile(
              icon: Icons.language,
              label: 'ভাষা',
              trailing: 'বাংলা',
              onTap: () => _comingSoon(context),
            ),
            _SettingsTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'বাজেট',
              onTap: () => _editBudget(context),
            ),
          ]),
          const SizedBox(height: 20),
          const Text('অর্গানাইজেশন', style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          _SettingsGroup(items: [
            _SettingsTile(
              icon: Icons.folder_outlined,
              label: 'ভল্ট',
              onTap: () => context.push('/vaults'),
            ),
            _SettingsTile(
              icon: Icons.payment_outlined,
              label: 'পেমেন্ট পদ্ধতি',
              onTap: () => _comingSoon(context),
            ),
          ]),
          const SizedBox(height: 20),
          const Text('নিরাপত্তা', style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          _SettingsGroup(items: [
            _SettingsTile(
              icon: Icons.security_outlined,
              label: '2FA সেটআপ',
              onTap: () => _comingSoon(context),
            ),
            _SettingsTile(
              icon: Icons.fingerprint,
              label: 'বায়োমেট্রিক',
              onTap: () => _comingSoon(context),
            ),
          ]),
          const SizedBox(height: 20),
          const Text('ডেটা', style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          _SettingsGroup(items: [
            _SettingsTile(
              icon: Icons.download_outlined,
              label: 'CSV এক্সপোর্ট',
              onTap: () => _comingSoon(context),
            ),
            _SettingsTile(
              icon: Icons.picture_as_pdf_outlined,
              label: 'PDF রিপোর্ট',
              onTap: () => _comingSoon(context),
            ),
            _SettingsTile(
              icon: Icons.upload_outlined,
              label: 'CSV ইম্পোর্ট',
              onTap: () => _comingSoon(context),
            ),
          ]),
          const SizedBox(height: 20),
          _SettingsGroup(items: [
            _SettingsTile(
              icon: Icons.info_outline,
              label: 'সম্পর্কে',
              trailing: 'v1.0.0',
              onTap: () => _showAbout(context),
            ),
            _SettingsTile(
              icon: Icons.feedback_outlined,
              label: 'ফিডব্যাক পাঠান',
              onTap: () => _comingSoon(context),
            ),
          ]),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.critical,
              side: const BorderSide(color: AppColors.critical),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('লগআউট'),
            onPressed: () async {
              HapticFeedback.mediumImpact();
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.critical,
              side: BorderSide(color: AppColors.critical.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('অ্যাকাউন্ট মুছুন'),
            onPressed: () => _confirmDelete(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('শীঘ্রই আসছে 🚧'), duration: Duration(seconds: 1)),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'AssetPulse',
      applicationVersion: 'v1.0.0',
      applicationLegalese: '© 2026 AssetPulse',
      children: const [
        SizedBox(height: 12),
        Text('সম্পদ ও ব্যয় ট্র্যাকার'),
      ],
    );
  }

  void _editBudget(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('মাসিক বাজেট', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                labelText: 'বাজেট (৳)',
                labelStyle: AppTextStyles.bodyMedium,
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.cardBorder)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final v = double.tryParse(ctrl.text.trim());
                if (v == null) return;
                final client = Supabase.instance.client;
                final uid = client.auth.currentUser?.id;
                if (uid == null) return;
                await client
                    .from('profiles')
                    .update({'monthly_budget': v}).eq('id', uid);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('বাজেট সংরক্ষিত ✓')),
                  );
                }
              },
              child: const Text('সংরক্ষণ'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('অ্যাকাউন্ট মুছবেন?',
            style: AppTextStyles.titleMedium),
        content: const Text(
          'এই কাজটি অপরিবর্তনীয়। আপনার সব ডেটা স্থায়ীভাবে মুছে যাবে।',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('বাতিল')),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('মুছুন',
                style: TextStyle(color: AppColors.critical)),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                const Divider(
                    height: 1, color: AppColors.cardBorder, indent: 52),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(label, style: AppTextStyles.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing!, style: AppTextStyles.bodySmall),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right,
              color: AppColors.textMuted, size: 18),
        ],
      ),
      onTap: onTap,
    );
  }
}
