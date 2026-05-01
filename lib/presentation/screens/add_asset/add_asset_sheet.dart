import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/asset_model.dart';
import '../../providers/asset_provider.dart';

class AddAssetSheet extends ConsumerStatefulWidget {
  const AddAssetSheet({super.key});

  @override
  ConsumerState<AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends ConsumerState<AddAssetSheet> {
  int _step = 0;
  String _assetType = 'deterministic';
  final _nameCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  String _icon = '📦';
  String _category = 'সাবস্ক্রিপশন';
  bool _autoRenew = false;
  bool _saving = false;

  final _categories = [
    '📱 সাবস্ক্রিপশন', '⚡ বিদ্যুৎ', '⛽ গ্যাস', '💧 পানি',
    '🏋️ জিম', '🌐 ইন্টারনেট', '📺 বিনোদন', '💊 ওষুধ', '🏠 ভাড়া',
  ];

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _costCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser!.id;
      final now = DateTime.now();

      await client.from('assets').insert({
        'id': const Uuid().v4(),
        'user_id': userId,
        'name': _nameCtrl.text.trim(),
        'asset_type': _assetType,
        'cost': double.tryParse(_costCtrl.text) ?? 0,
        'currency': 'BDT',
        'start_date': _startDate.toIso8601String().split('T').first,
        'end_date': _endDate?.toIso8601String().split('T').first,
        'icon': _icon,
        'category': _category,
        'auto_renew': _autoRenew,
        'status': 'active',
        'client_updated_at': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      ref.invalidate(assetsProvider);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          _StepIndicator(step: _step),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: [
              _buildStep0(),
              _buildStep1(),
              _buildStep2(),
              _buildStep3(),
            ][_step],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => setState(() => _step--),
                    child: const Text('পেছনে'),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saving
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          if (_step < 3) {
                            setState(() => _step++);
                          } else {
                            _save();
                          }
                        },
                  child: _saving
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(_step < 3 ? 'পরবর্তী' : 'সংরক্ষণ'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('সম্পদের ধরন', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            _TypeChip(
              label: 'নির্ধারিত',
              subtitle: 'সাবস্ক্রিপশন, বিল',
              icon: '📅',
              selected: _assetType == 'deterministic',
              onTap: () => setState(() => _assetType = 'deterministic'),
            ),
            const SizedBox(width: 12),
            _TypeChip(
              label: 'সম্ভাব্য',
              subtitle: 'গ্যাস, ওষুধ',
              icon: '⛽',
              selected: _assetType == 'probabilistic',
              onTap: () => setState(() => _assetType = 'probabilistic'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('মূল তথ্য', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        _Input(controller: _nameCtrl, label: 'সম্পদের নাম (যেমন: Netflix)'),
        const SizedBox(height: 12),
        _Input(
          controller: _costCtrl,
          label: 'খরচ (৳)',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((cat) {
            final selected = _category == cat.substring(2).trim() ||
                cat.contains(_category);
            return GestureDetector(
              onTap: () => setState(() {
                _category = cat.substring(2).trim();
                _icon = cat.substring(0, 2);
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.accent.withOpacity(0.15)
                      : AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.accent : AppColors.cardBorder,
                  ),
                ),
                child: Text(cat,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: selected
                            ? AppColors.accent
                            : AppColors.textSecondary)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('তারিখ', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        _DatePicker(
          label: 'শুরুর তারিখ',
          date: _startDate,
          onPick: (d) => setState(() => _startDate = d),
        ),
        if (_assetType == 'deterministic') ...[
          const SizedBox(height: 12),
          _DatePicker(
            label: 'শেষের তারিখ',
            date: _endDate,
            onPick: (d) => setState(() => _endDate = d),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.autoRenew, style: AppTextStyles.bodyLarge),
            value: _autoRenew,
            activeColor: AppColors.accent,
            onChanged: (v) => setState(() => _autoRenew = v),
          ),
        ],
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('সারসংক্ষেপ', style: AppTextStyles.titleMedium),
        const SizedBox(height: 16),
        _Summary(label: 'নাম', value: _nameCtrl.text),
        _Summary(label: 'ধরন',
            value: _assetType == 'deterministic' ? 'নির্ধারিত' : 'সম্ভাব্য'),
        _Summary(label: 'খরচ', value: '৳${_costCtrl.text}'),
        _Summary(label: 'বিভাগ', value: '$_icon $_category'),
        _Summary(label: 'শুরু',
            value: '${_startDate.day}/${_startDate.month}/${_startDate.year}'),
        if (_endDate != null)
          _Summary(label: 'শেষ',
              value: '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: i == step ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: i <= step ? AppColors.accent : AppColors.cardBorder,
          borderRadius: BorderRadius.circular(4),
        ),
      )),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label, subtitle, icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.subtitle,
      required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent.withOpacity(0.1) : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? AppColors.accent : AppColors.cardBorder,
                width: selected ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(label, style: AppTextStyles.titleMedium),
              Text(subtitle, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  const _Input({required this.controller, required this.label, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodyMedium,
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent)),
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onPick;
  const _DatePicker({required this.label, required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(primary: AppColors.accent),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Text(
              date != null
                  ? '${date!.day}/${date!.month}/${date!.year}'
                  : label,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: date != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final String label, value;
  const _Summary({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}
