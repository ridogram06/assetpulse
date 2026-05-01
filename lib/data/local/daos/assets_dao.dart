import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/assets_table.dart';
import '../../models/asset_model.dart';

part 'assets_dao.g.dart';

@DriftAccessor(tables: [AssetsTable])
class AssetsDao extends DatabaseAccessor<AppDatabase> with _$AssetsDaoMixin {
  AssetsDao(super.db);

  Future<List<AssetsTableData>> getAllForUser(String userId) =>
      (select(assetsTable)..where((t) => t.userId.equals(userId))).get();

  Stream<List<AssetsTableData>> watchAllForUser(String userId) =>
      (select(assetsTable)..where((t) => t.userId.equals(userId))).watch();

  Future<AssetsTableData?> getById(String id) =>
      (select(assetsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsert(AssetModel asset) async {
    await into(assetsTable).insertOnConflictUpdate(_toCompanion(asset));
  }

  Future<void> batchInsert(List<AssetModel> assets) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(
        assetsTable,
        assets.map(_toCompanion).toList(),
      );
    });
  }

  Future<void> deleteById(String id) =>
      (delete(assetsTable)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAllForUser(String userId) =>
      (delete(assetsTable)..where((t) => t.userId.equals(userId))).go();

  AssetsTableCompanion _toCompanion(AssetModel a) => AssetsTableCompanion(
    id:                   Value(a.id),
    userId:               Value(a.userId),
    vaultId:              Value(a.vaultId),
    paymentMethodId:      Value(a.paymentMethodId),
    name:                 Value(a.name),
    category:             Value(a.category),
    icon:                 Value(a.icon),
    color:                Value(a.color),
    notes:                Value(a.notes),
    assetType:            Value(a.assetType),
    cost:                 Value(a.cost),
    currency:             Value(a.currency),
    startDate:            Value(a.startDate),
    endDate:              Value(a.endDate),
    billingCycle:         Value(a.billingCycle),
    autoRenew:            Value(a.autoRenew),
    notifyDaysBefore:     Value(a.notifyDaysBefore),
    suspendedAt:          Value(a.suspendedAt),
    suspendedUntil:       Value(a.suspendedUntil),
    finishedAt:           Value(a.finishedAt),
    predictedEndDate:     Value(a.predictedEndDate),
    predictionConfidence: Value(a.predictionConfidence),
    status:               Value(a.status),
    clientUpdatedAt:      Value(a.clientUpdatedAt),
    createdAt:            Value(a.createdAt),
    updatedAt:            Value(a.updatedAt),
  );
}
