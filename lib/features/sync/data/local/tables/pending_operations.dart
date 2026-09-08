import 'package:drift/drift.dart';

class PendingOperations extends Table {
  TextColumn get id => text()();

  TextColumn get entityType => text()();

  TextColumn get entityId => text()();

  TextColumn get operationType => text()();

  TextColumn get payload => text()();

  DateTimeColumn get createdAt => dateTime()();

  IntColumn get retryCount => integer()();

  TextColumn get status => text()();

  DateTimeColumn get nextRetryAt => dateTime().nullable()();

  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
