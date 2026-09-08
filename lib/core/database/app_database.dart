import 'package:drift/drift.dart';
import 'package:fieldsync/core/database/converters/string_list_converter.dart';
import 'package:fieldsync/features/survey/data/local/dao/survey_dao.dart';
import 'package:fieldsync/features/survey/data/local/tables/surveys.dart';
import 'package:fieldsync/features/sync/data/local/dao/pending_operations_dao.dart';
import 'package:fieldsync/features/sync/data/local/tables/pending_operations.dart';

import 'connection/database_connection.dart';
import 'migrations/migration_strategy.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Surveys, PendingOperations],
  daos: [SurveyDao, PendingOperationsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? createDatabaseConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => createMigrationStrategy(
    surveys: surveys,
    isDeleted: surveys.isDeleted,
    pendingOperations: pendingOperations,
    nextRetryAt: pendingOperations.nextRetryAt,
  );
}
