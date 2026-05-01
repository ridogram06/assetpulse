import 'package:drift/drift.dart';

class AssetHistoryTable extends Table {
  TextColumn get id           => text()();
  TextColumn get userId       => text()();
  TextColumn get assetId      => text().nullable()();
  TextColumn get assetName    => text()();
  TextColumn get category     => text().nullable()();
  RealColumn get cost         => real().nullable()();
  TextColumn get currency     => text().withDefault(const Constant('BDT'))();
  DateTimeColumn get startDate  => dateTime()();
  DateTimeColumn get finishedAt => dateTime()();
  IntColumn get lifespanDays    => integer()();
  RealColumn get costPerDay     => real().nullable()();
  TextColumn get notes          => text().nullable()();
  DateTimeColumn get createdAt  => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
