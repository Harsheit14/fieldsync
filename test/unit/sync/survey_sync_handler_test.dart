import 'dart:convert';

import 'package:fieldsync/features/sync/data/handlers/survey_sync_handler.dart';
import 'package:fieldsync/features/sync/data/logger/sync_logger_impl.dart';
import 'package:fieldsync/features/sync/domain/entities/pending_operation_entity.dart';
import 'package:fieldsync/features/sync/domain/entities/sync_log_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures/sync_fixtures.dart';
import '../../helpers/mocks/sync_mocks.dart';

void main() {
  late MockRemoteSyncService remoteSyncService;
  late SyncLoggerImpl logger;
  late SurveySyncHandler handler;

  setUp(() {
    remoteSyncService = MockRemoteSyncService();
    logger = SyncLoggerImpl();

    handler = SurveySyncHandler(
      remoteSyncService,
      logger,
    );
  });

  PendingOperationEntity operationWith({
    PendingOperationType operationType = PendingOperationType.create,
    String payload = '{}',
  }) {
    return PendingOperationEntity(
      id: 'operation-1',
      entityType: 'Survey',
      entityId: 'survey-1',
      operationType: operationType,
      payload: payload,
      createdAt: SyncFixtures.timestamp,
      retryCount: 0,
      status: PendingOperationStatus.pending,
    );
  }

  test('supports Survey entity type', () {
    expect(handler.supports('Survey'), isTrue);
    expect(handler.supports('Farmer'), isFalse);
    expect(handler.supports('Field'), isFalse);
  });

  test('processes create operation and forwards payload', () async {
    final payload = {
      'id': 'survey-1',
      'farmerName': 'Ada Farmer',
      'cropType': 'Wheat',
      'fieldArea': 12.5,
    };

    final operation = operationWith(
      payload: jsonEncode(payload),
    );

    when(
      () => remoteSyncService.create(
        'Survey',
        operation.id,
        operation.entityId,
        payload,
      ),
    ).thenAnswer(
      (_) async => SyncFixtures.successResult,
    );

    final result = await handler.process(operation);

    expect(result.success, isTrue);

    verify(
      () => remoteSyncService.create(
        'Survey',
        operation.id,
        operation.entityId,
        payload,
      ),
    ).called(1);

    verifyNever(
      () => remoteSyncService.update(
        any(),
        any(),
        any(),
        any(),
      ),
    );

    verifyNever(
      () => remoteSyncService.delete(
        any(),
        any(),
        any(),
        any(),
      ),
    );
  });

  test('processes update operation through remote update', () async {
    final payload = {
      'id': 'survey-1',
      'farmerName': 'Updated Farmer',
      'cropType': 'Rice',
      'fieldArea': 9.5,
    };

    final operation = operationWith(
      operationType: PendingOperationType.update,
      payload: jsonEncode(payload),
    );

    when(
      () => remoteSyncService.update(
        'Survey',
        operation.id,
        operation.entityId,
        payload,
      ),
    ).thenAnswer(
      (_) async => SyncFixtures.successResult,
    );

    final result = await handler.process(operation);

    expect(result.success, isTrue);

    verify(
      () => remoteSyncService.update(
        'Survey',
        operation.id,
        operation.entityId,
        payload,
      ),
    ).called(1);

    verifyNever(
      () => remoteSyncService.create(
        any(),
        any(),
        any(),
        any(),
      ),
    );

    verifyNever(
      () => remoteSyncService.delete(
        any(),
        any(),
        any(),
        any(),
      ),
    );
  });

  test('processes delete operation through remote delete', () async {
    final payload = {
      'id': 'survey-1',
      'farmerName': 'Ada Farmer',
    };

    final operation = operationWith(
      operationType: PendingOperationType.delete,
      payload: jsonEncode(payload),
    );

    when(
      () => remoteSyncService.delete(
        'Survey',
        operation.id,
        operation.entityId,
        payload,
      ),
    ).thenAnswer(
      (_) async => SyncFixtures.successResult,
    );

    final result = await handler.process(operation);

    expect(result.success, isTrue);

    verify(
      () => remoteSyncService.delete(
        'Survey',
        operation.id,
        operation.entityId,
        payload,
      ),
    ).called(1);

    verifyNever(
      () => remoteSyncService.create(
        any(),
        any(),
        any(),
        any(),
      ),
    );

    verifyNever(
      () => remoteSyncService.update(
        any(),
        any(),
        any(),
        any(),
      ),
    );
  });

  test('returns retryable result when remote service throws', () async {
    final operation = operationWith();

    when(
      () => remoteSyncService.create(
        'Survey',
        operation.id,
        operation.entityId,
        <String, dynamic>{},
      ),
    ).thenThrow(
      Exception('Network unavailable'),
    );

    final result = await handler.process(operation);

    expect(result.success, isFalse);
    expect(result.retryable, isTrue);
    expect(result.message, 'Survey upload failed.');
    expect(result.error, isA<Exception>());
  });

  test('logs successful upload', () async {
    final operation = operationWith();

    when(
      () => remoteSyncService.create(
        'Survey',
        operation.id,
        operation.entityId,
        <String, dynamic>{},
      ),
    ).thenAnswer(
      (_) async => SyncFixtures.successResult,
    );

    await handler.process(operation);

    final logs = await logger.watchLogs().first;

    expect(
      logs.map((entry) => entry.eventType),
      contains(SyncLogEventType.uploadSucceeded),
    );
  });

  test('logs failed upload', () async {
    final operation = operationWith();

    when(
      () => remoteSyncService.create(
        'Survey',
        operation.id,
        operation.entityId,
        <String, dynamic>{},
      ),
    ).thenThrow(
      Exception('Network unavailable'),
    );

    await handler.process(operation);

    final logs = await logger.watchLogs().first;

    expect(
      logs.map((entry) => entry.eventType),
      contains(SyncLogEventType.uploadFailed),
    );
  });
}