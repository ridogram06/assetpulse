import 'package:flutter/material.dart';
import '../../../../data/models/asset_model.dart';
import 'deterministic_card.dart';
import 'probabilistic_card.dart';
import 'finished_card.dart';

class AssetList extends StatelessWidget {
  final List<AssetModel> assets;
  const AssetList({super.key, required this.assets});

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        if (asset.isFinished) return FinishedCard(asset: asset);
        if (asset.isDeterministic) return DeterministicCard(asset: asset);
        return ProbabilisticCard(asset: asset);
      },
    );
  }
}
