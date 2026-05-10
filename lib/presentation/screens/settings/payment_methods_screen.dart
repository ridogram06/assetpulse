import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// V4 Group 2 — Payment Method CRUD.
/// Required upstream by V5 FIX-2 (payment verification flow).
final paymentMethodsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final c = Supabase.instance.client;
  final uid = c.auth.currentUser?.id;
  if (uid == null) return [];
  final data = await c
      .from('payment_methods')
      .select()
      .eq('user_id', uid)
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(data as List);
});

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methods = ref.watch(paymentMethodsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('পেমেন্ট পদ্ধতি', style: AppTextStyles.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('নতুন'),
        onPressed: () => _showEditor(context, ref, null),
      ),
      body: methods.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('ত্রুটি: $e',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💳', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 12),
                    const Text('কোনো পেমেন্ট পদ্ধতি যোগ করা হয়নি',
                        style: AppTextStyles.titleMedium,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    Text(
                      'bKash, Nagad, Visa, Cash — যা ব্যবহার করেন তা যোগ করুন।',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final m = list[i];
              final color = _parseHex(m['color'] as String?);
              return Dismissible(
                key: ValueKey(m['id']),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.critical,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          title: const Text('মুছে ফেলবেন?',
                              style: AppTextStyles.titleMedium),
                          content: Text(
                              '"${m['name']}" পেমেন্ট পদ্ধতিটি স্থায়ীভাবে মুছে যাবে।',
                              style: AppTextStyles.bodyMedium),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('বাতিল')),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('মুছুন',
                                  style: TextStyle(
                                      color: AppColors.critical)),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                },
                onDismissed: (_) async {
                  await Supabase.instance.client
                      .from('payment_methods')
                      .delete()
                      .eq('id', m['id']);
                  ref.invalidate(paymentMethodsProvider);
                },
                child: GestureDetector(
                  onTap: () => _showEditor(context, ref, m),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            (m['icon'] as String?) ?? '💳',
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(m['name'] as String,
                              style: AppTextStyles.bodyLarge),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.textMuted, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static Color _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.accent;
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.tryParse(h, radix: 16) ?? 0xFF6366F1);
  }

  void _showEditor(
      BuildContext context, WidgetRef ref, Map<String, dynamic>? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PaymentMethodEditor(
        existing: existing,
        onSaved: () => ref.invalidate(paymentMethodsProvider),
      ),
    );
  }
}

class _PaymentMethodEditor extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;
  const _PaymentMethodEditor({this.existing, required this.onSaved});

  @override
  State<_PaymentMethodEditor> createState() => _PaymentMethodEditorState();
}

class _PaymentMethodEditorState extends State<_PaymentMethodEditor> {
  late final TextEditingController _name;
  String _icon = '💳';
  String _color = '#E91E8C';
  bool _busy = false;

  static const _icons = [
    '💳', '🏦', '💵', '📱', '🟢', '🟠', '🔵',
    '💴', '💶', '💷', '💰', '🪙',
  ];
  static const _colors = [
    '#E91E8C', '#6366F1', '#22C55E', '#F5C542',
    '#EF4444', '#3B82F6', '#A855F7', '#14B8A6',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: (e?['name'] as String?) ?? '');
    _icon = (e?['icon'] as String?) ?? '💳';
    _color = (e?['color'] as String?) ?? '#E91E8C';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    try {
      final c = Supabase.instance.client;
      final uid = c.auth.currentUser!.id;
      final payload = {
        'user_id': uid,
        'name': name,
        'icon': _icon,
        'color': _color,
      };
      if (widget.existing == null) {
        await c.from('payment_methods').insert({
          'id': const Uuid().v4(),
          ...payload,
        });
      } else {
        await c
            .from('payment_methods')
            .update(payload)
            .eq('id', widget.existing!['id']);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ত্রুটি: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text(widget.existing == null ? 'নতুন পেমেন্ট পদ্ধতি' : 'এডিট',
              style: AppTextStyles.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            style: AppTextStyles.bodyLarge,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'নাম (যেমন: bKash, Visa Card)',
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
          const Text('আইকন', style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _icons.map((i) {
              final sel = i == _icon;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _icon = i);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.accent.withOpacity(0.2)
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel
                          ? AppColors.accent
                          : AppColors.cardBorder,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(i, style: const TextStyle(fontSize: 22)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('রঙ', style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _colors.map((c) {
              final sel = c == _color;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _color = c);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: PaymentMethodsScreen._parseHex(c),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: sel ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('সংরক্ষণ'),
          ),
        ],
      ),
    );
  }
}
