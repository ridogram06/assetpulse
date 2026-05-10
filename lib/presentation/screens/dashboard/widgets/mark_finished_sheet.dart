import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/asset_model.dart';
import '../../../../domain/usecases/asset_actions.dart';
import '../../../providers/asset_provider.dart';
import '../../add_asset/add_asset_sheet.dart';

/// Full 6-step Mark-Finished flow for probabilistic assets:
///   1. Confirmation (total duration display)
///   2-3. Insert history + update asset (via AssetActions.markFinished)
///   4. Show prediction result + comparison vs previous entry
///   5. Prompt re-add (same name)
///   6. Celebration (✅ haptic + snackbar — Lottie can be added later)
class MarkFinishedSheet extends ConsumerStatefulWidget {
  final AssetModel asset;
  const MarkFinishedSheet({super.key, required this.asset});

  @override
  ConsumerState<MarkFinishedSheet> createState() => _MarkFinishedSheetState();
}

class _MarkFinishedSheetState extends ConsumerState<MarkFinishedSheet> {
  int _step = 0; // 0 = confirm, 1 = success/comparison, 2 = re-add prompt
  bool _busy = false;
  Map<String, dynamic>? _prediction;
  List<Map<String, dynamic>> _history = const [];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          if (_step == 0) ..._buildConfirm(),
          if (_step == 1) ..._buildSuccess(),
          if (_step == 2) ..._buildReAdd(),
        ],
      ),
    );
  }

  // ---------------------- Step 1: Confirmation ----------------------
  List<Widget> _buildConfirm() {
    final elapsed = DateTime.now().difference(widget.asset.createdAt);
    return [
      const Text('শেষ হয়েছে নিশ্চিত করুন', style: AppTextStyles.titleLarge),
      const SizedBox(height: 8),
      Text(widget.asset.name, style: AppTextStyles.bodyMedium),
      const SizedBox(height: 20),
      _Box(
        bg: AppColors.activeDim,
        children: [
          const Text('মোট আয়ু', style: AppTextStyles.bodySmall),
          const SizedBox(height: 4),
          Text(
            '${elapsed.inDays} দিন ${elapsed.inHours % 24} ঘণ্টা',
            style: AppTextStyles.titleLarge
                .copyWith(color: AppColors.active, fontSize: 22),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.cardBorder),
                  foregroundColor: AppColors.textSecondary),
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: const Text('বাতিল'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.active,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _busy ? null : _onConfirm,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('নিশ্চিত'),
            ),
          ),
        ],
      ),
    ];
  }

  Future<void> _onConfirm() async {
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      _prediction = await AssetActions.markFinished(widget.asset);
      _history = await AssetActions.recentHistory(
          widget.asset.userId, widget.asset.name,
          canonicalId: widget.asset.id);
      ref.invalidate(assetsProvider);
      if (mounted) setState(() => _step = 1);
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

  // ---------------------- Step 2: Success + Comparison ----------------------
  List<Widget> _buildSuccess() {
    final current = _history.isNotEmpty ? _history.first : null;
    final previous = _history.length > 1 ? _history[1] : null;
    final currentDays = (current?['lifespan_days'] as int?) ?? 0;
    final previousDays = previous?['lifespan_days'] as int?;
    final diff = previousDays != null ? currentDays - previousDays : null;
    final cpd = (current?['cost_per_day'] as num?)?.toDouble();

    String insight = '';
    Color insightColor = AppColors.textSecondary;
    if (diff != null) {
      if (diff > 0) {
        insight = 'আগেরটির চেয়ে $diff দিন বেশি চলেছে ✅';
        insightColor = AppColors.active;
      } else if (diff < 0) {
        insight = 'আগেরটির চেয়ে ${diff.abs()} দিন কম চলেছে ⚠';
        insightColor = AppColors.warning;
      } else {
        insight = 'আগেরটির মতোই চলেছে';
      }
    }

    return [
      const Text('✅', style: TextStyle(fontSize: 56), textAlign: TextAlign.center),
      const SizedBox(height: 8),
      const Text('শেষ হয়েছে!',
          style: AppTextStyles.titleLarge, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      _Box(bg: AppColors.activeDim, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(label: 'এইবার', value: '${currentDays}d'),
            _Stat(
                label: 'আগেরটি',
                value: previousDays != null ? '${previousDays}d' : '—'),
            _Stat(
              label: 'পার্থক্য',
              value: diff != null
                  ? '${diff > 0 ? '+' : ''}${diff}d'
                  : '—',
              color: insightColor,
            ),
          ],
        ),
        if (cpd != null) ...[
          const SizedBox(height: 8),
          Text('৳${cpd.toStringAsFixed(2)} / দিন',
              style: AppTextStyles.bodySmall),
        ],
        if (insight.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(insight,
              style: AppTextStyles.bodyMedium.copyWith(color: insightColor)),
        ],
      ]),
      if (_prediction != null && _prediction!['predicted_date'] != null) ...[
        const SizedBox(height: 12),
        _Box(bg: AppColors.blueDim, children: [
          Text('🤖 AI পূর্বাভাস',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.blue)),
          const SizedBox(height: 4),
          Text(
            'পরেরটি ~${_prediction!['mean_days']} দিন চলবে '
            '(${(_prediction!['confidence'] as num?)?.toStringAsFixed(0) ?? '—'}% নিশ্চিততা)',
            style: AppTextStyles.bodyMedium,
          ),
        ]),
      ],
      const SizedBox(height: 20),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14)),
        onPressed: () => setState(() => _step = 2),
        child: const Text('পরবর্তী'),
      ),
    ];
  }

  // ---------------------- Step 3: Re-add prompt ----------------------
  List<Widget> _buildReAdd() {
    return [
      Text('নতুন ${widget.asset.name} যোগ করবেন?',
          style: AppTextStyles.titleLarge, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      const Text('একই নাম ও ক্যাটাগরিতে আরেকটি এন্ট্রি তৈরি হবে।',
          style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.cardBorder),
                  foregroundColor: AppColors.textSecondary),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: const Text('না, পরে'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AddAssetSheet(),
                );
              },
              child: const Text('হ্যাঁ, যোগ করুন'),
            ),
          ),
        ],
      ),
    ];
  }
}

class _Box extends StatelessWidget {
  final Color bg;
  final List<Widget> children;
  const _Box({required this.bg, required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Stat({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: AppTextStyles.titleMedium
              .copyWith(color: color ?? AppColors.textPrimary)),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.bodySmall),
    ]);
  }
}
