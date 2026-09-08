// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'survey_dao.dart';

// ignore_for_file: type=lint
mixin _$SurveyDaoMixin on DatabaseAccessor<AppDatabase> {
  $SurveysTable get surveys => attachedDatabase.surveys;
  SurveyDaoManager get managers => SurveyDaoManager(this);
}

class SurveyDaoManager {
  final _$SurveyDaoMixin _db;
  SurveyDaoManager(this._db);
  $$SurveysTableTableManager get surveys =>
      $$SurveysTableTableManager(_db.attachedDatabase, _db.surveys);
}
