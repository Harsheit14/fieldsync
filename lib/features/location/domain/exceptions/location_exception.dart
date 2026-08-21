class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocationServiceDisabledException extends LocationException {
  const LocationServiceDisabledException()
      : super('Location services are disabled.');
}

class LocationPermissionDeniedException extends LocationException {
  const LocationPermissionDeniedException()
      : super('Location permission was denied.');
}

class LocationPermissionDeniedForeverException extends LocationException {
  const LocationPermissionDeniedForeverException()
      : super(
          'Location permission has been permanently denied. Please enable it from Settings.',
        );
}