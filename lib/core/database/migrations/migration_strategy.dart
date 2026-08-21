import 'package:drift/drift.dart';

MigrationStrategy createMigrationStrategy({
  required TableInfo surveys,
  required GeneratedColumn isDeleted,
  required TableInfo pendingOperations,
  required GeneratedColumn nextRetryAt,
}) {
  return MigrationStrategy(
    onCreate: (migrator) async => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(surveys, isDeleted);
      }
      if (from < 3) {
        await migrator.createTable(pendingOperations);
      }
      if (from < 4) {
        await migrator.addColumn(pendingOperations, nextRetryAt);
      }
    },
    beforeOpen: (details) async {},
  );
}
