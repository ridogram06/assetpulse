import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/pending_sync_table.dart';

part 'pending_sync_dao.g.dart';

@DriftAccessor(tables: [PendingSyncTable])
class PendingSyncDao extends DatabaseAccessor<AppDatabase>
    with _$PendingSyncDaoMixin {
  PendingSyncDao(super.db);

  Future<List<PendingSyncTableData>> getAll() => select(pendingSyncTable).get();

  Future<void> enqueue(String assetId) async {
    await into(pendingSyncTable).insertOnConflictUpdate(PendingSyncTableCompanion(
      assetId:   Value(assetId),
      queuedAt:  Value(DateTime.now()),
      retryCount: const Value(0),
    ));
  }

  Future<void> remove(String assetId) =>
      (delete(pendingSyncTable)..where((t) => t.assetId.equals(assetId))).go();
}
