import 'package:fieldsync/features/survey/data/local/dao/survey_dao.dart';
import 'package:fieldsync/features/survey/data/mappers/survey_mapper.dart';
import 'package:fieldsync/features/survey/data/repositories/survey_repository_impl.dart';
import 'package:fieldsync/features/survey/domain/entities/survey_entity.dart';
import 'package:fieldsync/features/sync/data/local/dao/pending_operations_dao.dart';
import 'package:fieldsync/features/sync/data/logger/sync_logger_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake/in_memory_database.dart';
import '../../helpers/fixtures/sync_fixtures.dart';

void main() {
  test(
    'updates survey in place while preserving id and photo paths',
    () async {
      final database = createInMemoryDatabase();
      addTearDown(database.close);
      final repository = SurveyRepositoryImpl(
        SurveyDao(database),
        const SurveyMapper(),
        SyncLoggerImpl(),
      );
      final survey = SurveyEntity(
        id: 'survey-1',
        farmerName: 'Ada Farmer',
        cropType: 'Wheat',
        fieldArea: 12.5,
        latitude: 12.34,
        longitude: 56.78,
        photoPaths: const ['/tmp/fieldsync-photo.jpg'],
        status: 'active',
        createdAt: DateTime.utc(2025, 1, 1, 12),
        updatedAt: DateTime.utc(2025, 1, 1, 12),
      );
      final updated = SurveyEntity(
        id: survey.id,
        farmerName: 'Grace Farmer',
        cropType: 'Corn',
        fieldArea: 18.75,
        latitude: survey.latitude,
        longitude: survey.longitude,
        photoPaths: survey.photoPaths,
        status: survey.status,
        createdAt: survey.createdAt,
        updatedAt: survey.updatedAt.add(const Duration(minutes: 2)),
      );

      await repository.createSurvey(survey);
      await repository.updateSurvey(updated);

      final loaded = await repository.getSurveyById(survey.id);
      expect(loaded?.id, survey.id);
      expect(loaded?.farmerName, 'Grace Farmer');
      expect(loaded?.cropType, 'Corn');
      expect(loaded?.fieldArea, 18.75);
      expect(loaded?.photoPaths, survey.photoPaths);

      final operations = await PendingOperationsDao(
        database,
      ).watchAllOperations().first;
      expect(operations, hasLength(2));
      expect(operations.map((operation) => operation.operationType), [
        'create',
        'update',
      ]);
    },
  );

  test(
    'creates survey and outbox operation in one repository transaction',
    () async {
      final database = createInMemoryDatabase();
      addTearDown(database.close);
      final repository = SurveyRepositoryImpl(
        SurveyDao(database),
        const SurveyMapper(),
        SyncLoggerImpl(),
      );
      final survey = SyncFixtures.survey();

      await repository.createSurvey(survey);

      expect(
        (await repository.getSurveyById(survey.id))?.farmerName,
        'Ada Farmer',
      );
      final operations = await PendingOperationsDao(
        database,
      ).watchAllOperations().first;
      expect(operations, hasLength(1));
      expect(operations.single.entityId, survey.id);
      expect(operations.single.operationType, 'create');
    },
  );

  test('updates and soft-deletes surveys while queueing operations', () async {
    final database = createInMemoryDatabase();
    addTearDown(database.close);
    final repository = SurveyRepositoryImpl(
      SurveyDao(database),
      const SurveyMapper(),
      SyncLoggerImpl(),
    );
    final survey = SyncFixtures.survey();
    await repository.createSurvey(survey);
    final updated = SurveyEntity(
      id: survey.id,
      farmerName: 'Grace Farmer',
      cropType: survey.cropType,
      fieldArea: survey.fieldArea,
      latitude: survey.latitude,
      longitude: survey.longitude,
      photoPaths: const [],
      status: survey.status,
      createdAt: survey.createdAt,
      updatedAt: survey.updatedAt.add(const Duration(minutes: 1)),
    );

    await repository.updateSurvey(updated);
    await repository.deleteSurvey(updated.id);

    expect(await repository.watchAllSurveys().first, isEmpty);
    final operations = await PendingOperationsDao(
      database,
    ).watchAllOperations().first;
    expect(operations.map((operation) => operation.operationType), [
      'create',
      'update',
      'delete',
    ]);
  });
}
