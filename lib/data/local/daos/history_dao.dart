import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/history_table.dart';
import '../../models/asset_history_model.dart';

part 'history_dao.g.dart';

@DriftAccessor(tables: [AssetHistoryTable])
class HistoryDao extends DatabaseAccessor<AppDatabase> with _$HistoryDaoMixin {
  HistoryDao(super.db);

  Future<List<AssetHistoryTableData>> getForAssetName(
    String userId, String assetName) =>
      (select(assetHistoryTable)
        ..where((t) => t.userId.equals(userId) & t.assetName.equals(assetName))
        ..orderBy([(t) => OrderingTerm.desc(t.finishedAt)])
      ).get();

  Future<void> insert(AssetHistoryModel h) async {
    await into(assetHistoryTable).insert(AssetHistoryTableCompanion(
      id:           Value(h.id),
      userId:       Value(h.userId),
      assetId:      Value(h.assetId),
      assetName:    Value(h.assetName),
      category:     Value(h.category),
      cost:         Value(h.cost),
      currency:     Value(h.currency),
      startDate:    Value(h.startDate),
      finishedAt:   Value(h.finishedAt),
      lifespanDays: Value(h.lifespanDays),
      costPerDay:   Value(h.costPerDay),
      notes:        Value(h.notes),
      createdAt:    Value(h.createdAt),
    ));
  }
}
