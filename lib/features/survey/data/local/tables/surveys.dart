import 'package:drift/drift.dart';
import 'package:fieldsync/core/database/converters/string_list_converter.dart';

class Surveys extends Table {
  TextColumn get id => text()();

  TextColumn get farmerName => text()();

  TextColumn get cropType => text()();

  RealColumn get fieldArea => real()();

  RealColumn get latitude => real()();

  RealColumn get longitude => real()();

  TextColumn get photoPaths =>
      text().map(const StringListConverter())();

  TextColumn get status => text()();

  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}