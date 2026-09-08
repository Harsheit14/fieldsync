import 'package:dio/dio.dart';
import 'package:fieldsync/features/sync/data/services/remote_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late RemoteSyncServiceImpl service;

  setUp(() {
    dio = MockDio();
    service = RemoteSyncServiceImpl(dio: dio);
  });

  test('returns success when server accepts create operation', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        '/api/sync',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/sync'),
        statusCode: 200,
        data: {
          'success': true,
          'operationId': 'operation-1',
          'entityId': 'survey-1',
          'operationType': 'create',
        },
      ),
    );

    final result = await service.create(
      'Survey',
      'operation-1',
      'survey-1',
      {'id': 'survey-1'},
    );

    expect(result.success, isTrue);

    verify(
      () => dio.post<Map<String, dynamic>>(
        '/api/sync',
        data: {
          'operationId': 'operation-1',
          'entityType': 'Survey',
          'entityId': 'survey-1',
          'operationType': 'create',
          'payload': {'id': 'survey-1'},
        },
      ),
    ).called(1);
  });

  test('returns failure for non-retryable client error', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        '/api/sync',
        data: any(named: 'data'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/api/sync'),
        response: Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/api/sync'),
          statusCode: 409,
          data: {
            'success': false,
            'error': {
              'code': 'SURVEY_CONFLICT',
              'message': 'Survey conflict.',
            },
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    final result = await service.update(
      'Survey',
      'operation-2',
      'survey-1',
      {'id': 'survey-1'},
    );

    expect(result.success, isFalse);
    expect(result.retryable, isFalse);
    expect(result.message, 'Survey conflict.');
  });

  test('returns retryable result for network failure', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        '/api/sync',
        data: any(named: 'data'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/api/sync'),
        type: DioExceptionType.connectionError,
      ),
    );

    final result = await service.create(
      'Survey',
      'operation-3',
      'survey-1',
      {'id': 'survey-1'},
    );

    expect(result.success, isFalse);
    expect(result.retryable, isTrue);
  });

  test('returns retryable result when server returns empty response', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        '/api/sync',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/sync'),
        statusCode: 200,
        data: null,
      ),
    );

    final result = await service.delete(
      'Survey',
      'operation-4',
      'survey-1',
      {'id': 'survey-1'},
    );

    expect(result.success, isFalse);
    expect(result.retryable, isTrue);
    expect(
      result.message,
      'Server returned an empty response.',
    );
  });

  test('returns failure when server explicitly reports success false', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        '/api/sync',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/sync'),
        statusCode: 200,
        data: {
          'success': false,
          'message': 'Synchronization rejected.',
        },
      ),
    );

    final result = await service.create(
      'Survey',
      'operation-5',
      'survey-1',
      {'id': 'survey-1'},
    );

    expect(result.success, isFalse);
    expect(result.retryable, isFalse);
    expect(result.message, 'Synchronization rejected.');
  });
}