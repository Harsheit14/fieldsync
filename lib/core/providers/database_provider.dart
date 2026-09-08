import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldsync/core/database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
