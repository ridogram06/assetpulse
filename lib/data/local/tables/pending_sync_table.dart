import 'package:drift/drift.dart';

class PendingSyncTable extends Table {
  TextColumn get assetId    => text()();
  DateTimeColumn get queuedAt => dateTime()();
  IntColumn get retryCount  => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {assetId};
}
