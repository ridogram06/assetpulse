import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/assets_table.dart';
import 'tables/history_table.dart';
import 'tables/pending_sync_table.dart';
import 'daos/assets_dao.dart';
import 'daos/history_dao.dart';
import 'daos/pending_sync_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [AssetsTable, AssetHistoryTable, PendingSyncTable],
  daos: [AssetsDao, HistoryDao, PendingSyncDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'assetpulse.db'));
    return NativeDatabase.createInBackground(file);
  });
}
