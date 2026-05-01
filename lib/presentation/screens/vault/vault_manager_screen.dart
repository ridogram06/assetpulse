import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/vault_model.dart';

final _vaultsProvider = FutureProvider<List<VaultModel>>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];
  final data = await client
      .from('vaults')
      .select()
      .eq('user_id', userId)
      .order('created_at');
  return (data as List)
      .map((j) => VaultModel.fromJson(j as Map<String, dynamic>))
      .toList();
});

class VaultManagerScreen extends ConsumerWidget {
  const VaultManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultsAsync = ref.watch(_vaultsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('ভল্ট', style: AppTextStyles.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accent),
            onPressed: () => _showAddVault(context, ref),
          ),
        ],
      ),
      body: vaultsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('$e')),
        data: (vaults) {
          if (vaults.isEmpty) {
            return const Center(
              child: Text('কোনো ভল্ট নেই', style: AppTextStyles.bodyMedium));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vaults.length,
            itemBuilder: (_, i) {
              final v = vaults[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Text(v.icon, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.name, style: AppTextStyles.titleMedium),
                          if (v.budget != null)
                            Text('বাজেট: ৳${v.budget!.toStringAsFixed(0)}',
                                style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    if (v.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.accent.withOpacity(0.4)),
                        ),
                        child: const Text('ডিফল্ট',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.accent)),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddVault(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
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
            Container(width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('নতুন ভল্ট', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                labelText: 'ভল্টের নাম',
                labelStyle: AppTextStyles.bodyMedium,
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder)),
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
                if (nameCtrl.text.isEmpty) return;
                HapticFeedback.lightImpact();
                final client = Supabase.instance.client;
                await client.from('vaults').insert({
                  'id': const Uuid().v4(),
                  'user_id': client.auth.currentUser!.id,
                  'name': nameCtrl.text.trim(),
                  'icon': '📁',
                  'color': '#6366F1',
                  'is_default': false,
                  'created_at': DateTime.now().toIso8601String(),
                });
                ref.invalidate(_vaultsProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('সংরক্ষণ'),
            ),
          ],
        ),
      ),
    );
  }
}
