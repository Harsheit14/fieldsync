import 'package:drift/native.dart';
import 'package:fieldsync/core/database/app_database.dart';

AppDatabase createInMemoryDatabase() => AppDatabase(NativeDatabase.memory());
