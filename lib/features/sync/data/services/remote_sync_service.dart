import 'package:dio/dio.dart';
import 'package:fieldsync/features/sync/domain/entities/pending_operation_entity.dart';
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
  RemoteSyncServiceImpl({required this._dio});

  final Dio _dio;

  @override
  Future<SyncResult> create(
    String entityType,
    String operationId,
    String entityId,
    Map<String, dynamic> payload,
  ) {
    return _send(
      operationType: PendingOperationType.create,
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
    return _send(
      operationType: PendingOperationType.update,
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
    return _send(
      operationType: PendingOperationType.delete,
      entityType: entityType,
      operationId: operationId,
      entityId: entityId,
      payload: payload,
    );
  }

  Future<SyncResult> _send({
    required PendingOperationType operationType,
    required String entityType,
    required String operationId,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/sync',
        data: {
          'operationId': operationId,
          'entityType': entityType,
          'entityId': entityId,
          'operationType': operationType.name,
          'payload': payload,
        },
      );

      final data = response.data;

      if (data == null) {
        return SyncResult.retry(
          message: 'Server returned an empty response.',
        );
      }

      if (data['success'] == true) {
        return SyncResult.success(
          message: 'Synchronization completed.',
        );
      }

      return _mapBusinessFailure(
        statusCode: response.statusCode,
        data: data,
      );
    } on DioException catch (error) {
      return _mapDioException(error);
    } catch (error) {
      return SyncResult.retry(
        message: 'Synchronization request failed.',
        error: error,
      );
    }
  }

  SyncResult _mapBusinessFailure({
    required int? statusCode,
    required Map<String, dynamic> data,
  }) {
    final rawError = data['error'];

    String message = 'Synchronization failed.';

    if (rawError is Map) {
      final serverMessage = rawError['message'];

      if (serverMessage != null &&
          serverMessage.toString().trim().isNotEmpty) {
        message = serverMessage.toString();
      }
    }

    if (data['message'] != null &&
        data['message'].toString().trim().isNotEmpty) {
      message = data['message'].toString();
    }

    switch (statusCode) {
      case 400:
      case 401:
      case 403:
      case 404:
      case 409:
        return SyncResult.failure(
          message: message,
        );

      default:
        if (statusCode != null && statusCode >= 500) {
          return SyncResult.retry(
            message: message,
          );
        }

        return SyncResult.failure(
          message: message,
        );
    }
  }

  SyncResult _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;

    if (statusCode != null) {
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        return _mapBusinessFailure(
          statusCode: statusCode,
          data: data,
        );
      }

      if (statusCode >= 500) {
        return SyncResult.retry(
          message: 'Server error while synchronizing.',
          error: error,
        );
      }

      if (statusCode >= 400) {
        return SyncResult.failure(
          message: 'Synchronization request was rejected.',
          error: error,
        );
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.transformTimeout:
        return SyncResult.retry(
          message: 'Network unavailable.',
          error: error,
        );

      case DioExceptionType.cancel:
        return SyncResult.retry(
          message: 'Synchronization request was cancelled.',
          error: error,
        );

      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return SyncResult.retry(
          message: 'Synchronization request failed.',
          error: error,
        );
    }
  }
}