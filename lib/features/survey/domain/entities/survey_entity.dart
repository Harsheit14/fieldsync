class SurveyEntity {
  const SurveyEntity({
    required this.id,
    required this.farmerName,
    required this.cropType,
    required this.fieldArea,
    required this.latitude,
    required this.longitude,
    required this.photoPaths,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String farmerName;
  final String cropType;
  final double fieldArea;
  final double latitude;
  final double longitude;

  final List<String> photoPaths;

  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
}