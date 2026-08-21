import 'package:dio/dio.dart';
import 'package:fieldsync/features/sync/domain/entities/sync_result.dart';

abstract class RemoteSyncService {
  Future<SyncResult> create(
    String entityType,
    String operationId,
    String entityId,
    Map<String, dynamic> payload,
  );

  Future<SyncResult> update(
    String entityType,
    String operationId,
    String entityId,
    Map<String, dynamic> payload,
  );

  Future<SyncResult> delete(
    String entityType,
    String operationId,
    String entityId,
    Map<String, dynamic> payload,
  );
}

class RemoteSyncServiceImpl implements RemoteSyncService {
  const RemoteSyncServiceImpl({
    required this._dio,
  });

  final Dio _dio;

  static const String _syncEndpoint = '/api/sync';

  @override
  Future<SyncResult> create(
    String entityType,
    String operationId,
    String entityId,
    Map<String, dynamic> payload,
  ) {
    return _sendOperation(
      operationType: 'create',
      entityType: entityType,
      operationId: operationId,
      entityId: entityId,
      payload: payload,
    );
  }

  @override
  Future<SyncResult> update(
    String entityType,
    String operationId,
    String entityId,
    Map<String, dynamic> payload,
  ) {
    return _sendOperation(
      operationType: 'update',
      entityType: entityType,
      operationId: operationId,
      entityId: entityId,
      payload: payload,
    );
  }

  @override
  Future<SyncResult> delete(
    String entityType,
    String operationId,
    String entityId,
    Map<String, dynamic> payload,
  ) {
    return _sendOperation(
      operationType: 'delete',
      entityType: entityType,
      operationId: operationId,
      entityId: entityId,
      payload: payload,
    );
  }

  Future<SyncResult> _sendOperation({
    required String operationType,
    required String entityType,
    required String operationId,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _syncEndpoint,
        data: {
          'operationId': operationId,
          'entityType': entityType,
          'entityId': entityId,
          'operationType': operationType,
          'payload': payload,
        },
      );

      final data = response.data;

      if (data == null) {
        return const SyncResult.retry(
          message: 'Server returned an empty response.',
        );
      }

      if (data['success'] == true) {
        return const SyncResult.success(
          message: 'Synchronization completed successfully.',
        );
      }

      return SyncResult.failure(
        message: _extractServerError(data),
      );
    } on DioException catch (error) {
      return _handleDioError(error);
    } catch (error) {
      return SyncResult.retry(
        message: 'Unexpected synchronization error.',
        error: error,
      );
    }
  }

  SyncResult _handleDioError(DioException error) {
    final statusCode = error.response?.statusCode;

    // Client errors are generally not retryable.
    if (statusCode != null &&
        statusCode >= 400 &&
        statusCode < 500) {
      final responseData = error.response?.data;

      if (responseData is Map<String, dynamic>) {
        return SyncResult.failure(
          message: _extractServerError(responseData),
          error: error,
        );
      }

      return SyncResult.failure(
        message: 'Synchronization request was rejected.',
        error: error,
      );
    }

    // Network failures, timeouts and server errors are retryable.
    return SyncResult.retry(
      message: 'Unable to reach synchronization server.',
      error: error,
    );
  }

  String _extractServerError(
    Map<String, dynamic> data,
  ) {
    final error = data['error'];

    if (error is Map<String, dynamic>) {
      final message = error['message'];

      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    final message = data['message'];

    if (message is String && message.isNotEmpty) {
      return message;
    }

    return 'Synchronization request failed.';
  }
}