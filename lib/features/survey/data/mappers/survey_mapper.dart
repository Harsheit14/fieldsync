import 'package:drift/drift.dart';
import 'package:fieldsync/core/database/app_database.dart';
import 'package:fieldsync/features/survey/domain/entities/survey_entity.dart';

class SurveyMapper {
  const SurveyMapper();

  Survey toDrift(SurveyEntity entity) {
    return Survey(
      id: entity.id,
      farmerName: entity.farmerName,
      cropType: entity.cropType,
      fieldArea: entity.fieldArea,
      latitude: entity.latitude,
      longitude: entity.longitude,
      photoPaths: entity.photoPaths,
      status: entity.status,
      isDeleted: false,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  SurveysCompanion toCompanion(SurveyEntity entity) {
    return SurveysCompanion.insert(
      id: entity.id,
      farmerName: entity.farmerName,
      cropType: entity.cropType,
      fieldArea: entity.fieldArea,
      latitude: entity.latitude,
      longitude: entity.longitude,
      photoPaths: entity.photoPaths,
      status: entity.status,
      isDeleted: const Value(false),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  SurveyEntity toEntity(Survey survey) {
    return SurveyEntity(
      id: survey.id,
      farmerName: survey.farmerName,
      cropType: survey.cropType,
      fieldArea: survey.fieldArea,
      latitude: survey.latitude,
      longitude: survey.longitude,
      photoPaths: survey.photoPaths,
      status: survey.status,
      createdAt: survey.createdAt,
      updatedAt: survey.updatedAt,
    );
  }
}