import 'dart:convert';

import 'package:fieldsync/features/survey/data/local/dao/survey_dao.dart';
import 'package:fieldsync/features/survey/data/mappers/survey_mapper.dart';
import 'package:fieldsync/features/survey/domain/entities/survey_entity.dart';
import 'package:fieldsync/features/survey/domain/repositories/survey_repository.dart';
import 'package:fieldsync/features/sync/data/local/dao/pending_operations_dao.dart';
import 'package:fieldsync/features/sync/data/mappers/pending_operation_mapper.dart';
import 'package:fieldsync/features/sync/domain/entities/pending_operation_entity.dart';
import 'package:fieldsync/features/sync/domain/entities/sync_log_entry.dart';
import 'package:fieldsync/features/sync/domain/logger/sync_logger.dart';
import 'package:uuid/uuid.dart';

class SurveyRepositoryImpl implements SurveyRepository {
  SurveyRepositoryImpl(this._surveyDao, this._surveyMapper, this._syncLogger);

  final SurveyDao _surveyDao;
  final SurveyMapper _surveyMapper;
  final SyncLogger _syncLogger;

  late final PendingOperationsDao _pendingOperationsDao = PendingOperationsDao(
    _surveyDao.attachedDatabase,
  );

  static const _pendingOperationMapper = PendingOperationMapper();
  static const _surveyEntityType = 'Survey';

  @override
  Future<void> createSurvey(SurveyEntity survey) async {
    await _surveyDao.attachedDatabase.transaction(() async {
      await _surveyDao.insertSurvey(_surveyMapper.toCompanion(survey));

      await _enqueueOperation(survey, PendingOperationType.create);
    });
  }

  @override
  Future<void> updateSurvey(SurveyEntity survey) async {
    await _surveyDao.attachedDatabase.transaction(() async {
      await _surveyDao.updateSurvey(_surveyMapper.toCompanion(survey));

      await _enqueueOperation(survey, PendingOperationType.update);
    });
  }

  @override
  Future<void> deleteSurvey(String id) async {
    await _surveyDao.attachedDatabase.transaction(() async {
      final survey = await _surveyDao.getSurveyById(id);

      if (survey == null) {
        return;
      }

      final entity = _surveyMapper.toEntity(survey);

      await _surveyDao.markSurveyDeleted(id);

      await _enqueueOperation(entity, PendingOperationType.delete);
    });
  }

  @override
  Future<SurveyEntity?> getSurveyById(String id) async {
    final survey = await _surveyDao.getSurveyById(id);

    return survey == null ? null : _surveyMapper.toEntity(survey);
  }

  @override
  Stream<List<SurveyEntity>> watchAllSurveys() {
    return _surveyDao.watchAllSurveys().map(
      (surveys) => surveys.map(_surveyMapper.toEntity).toList(),
    );
  }

  Future<void> _enqueueOperation(
    SurveyEntity survey,
    PendingOperationType operationType,
  ) async {
    final operation = PendingOperationEntity(
      id: const Uuid().v4(),
      entityType: _surveyEntityType,
      entityId: survey.id,
      operationType: operationType,
      payload: _serializeSurvey(survey),
      createdAt: DateTime.now(),
      retryCount: 0,
      status: PendingOperationStatus.pending,
    );

    await _pendingOperationsDao.enqueue(
      _pendingOperationMapper.toCompanion(operation),
    );

    await _syncLogger.log(
      SyncLogEntry(
        timestamp: DateTime.now(),
        operationId: operation.id,
        entityType: operation.entityType,
        entityId: operation.entityId,
        eventType: SyncLogEventType.operationQueued,
        message: 'Operation queued for synchronization.',
        metadata: {'operationType': operation.operationType.name},
      ),
    );
  }

  String _serializeSurvey(SurveyEntity survey) {
    return jsonEncode({
      'id': survey.id,
      'farmerName': survey.farmerName,
      'cropType': survey.cropType,
      'fieldArea': survey.fieldArea,
      'latitude': survey.latitude,
      'longitude': survey.longitude,
      'photoPaths': survey.photoPaths,
      'status': survey.status,
      'createdAt': survey.createdAt.toIso8601String(),
      'updatedAt': survey.updatedAt.toIso8601String(),
    });
  }
}
