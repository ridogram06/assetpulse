import 'package:drift/drift.dart';

class AssetsTable extends Table {
  TextColumn get id              => text()();
  TextColumn get userId          => text()();
  TextColumn get vaultId         => text().nullable()();
  TextColumn get paymentMethodId => text().nullable()();
  TextColumn get name            => text()();
  TextColumn get category        => text().nullable()();
  TextColumn get icon            => text().withDefault(const Constant('📦'))();
  TextColumn get color           => text().withDefault(const Constant('#6366F1'))();
  TextColumn get notes           => text().nullable()();
  TextColumn get assetType       => text()();
  RealColumn get cost            => real()();
  TextColumn get currency        => text().withDefault(const Constant('BDT'))();
  DateTimeColumn get startDate   => dateTime()();

  // Deterministic
  DateTimeColumn get endDate           => dateTime().nullable()();
  TextColumn get billingCycle          => text().nullable()();
  BoolColumn get autoRenew             => boolean().withDefault(const Constant(false))();
  IntColumn get notifyDaysBefore       => integer().withDefault(const Constant(3))();
  DateTimeColumn get suspendedAt       => dateTime().nullable()();
  DateTimeColumn get suspendedUntil    => dateTime().nullable()();

  // Probabilistic
  DateTimeColumn get finishedAt           => dateTime().nullable()();
  DateTimeColumn get predictedEndDate     => dateTime().nullable()();
  RealColumn get predictionConfidence     => real().nullable()();

  TextColumn get status             => text().withDefault(const Constant('active'))();
  DateTimeColumn get clientUpdatedAt => dateTime()();
  DateTimeColumn get createdAt       => dateTime()();
  DateTimeColumn get updatedAt       => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
