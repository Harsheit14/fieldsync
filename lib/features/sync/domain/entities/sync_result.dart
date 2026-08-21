class SyncResult {
  const SyncResult._({
    required this.success,
    required this.retryable,
    this.message,
    this.error,
  });

  const SyncResult.success({String? message})
      : this._(success: true, retryable: false, message: message);

  const SyncResult.retry({String? message, Object? error})
      : this._(
          success: false,
          retryable: true,
          message: message,
          error: error,
        );

  const SyncResult.failure({String? message, Object? error})
      : this._(
          success: false,
          retryable: false,
          message: message,
          error: error,
        );

  final bool success;
  final bool retryable;
  final String? message;
  final Object? error;
}