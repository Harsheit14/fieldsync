import 'package:fieldsync/features/storage/domain/entities/stored_file_entity.dart';
import 'package:fieldsync/features/storage/domain/repositories/storage_repository.dart';
import 'package:fieldsync/features/storage/domain/usecases/read_file_usecase.dart';
import 'package:fieldsync/features/survey/domain/entities/survey_entity.dart';
import 'package:fieldsync/features/survey/presentation/widgets/survey_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStorageRepository implements StorageRepository {
  @override
  Future<StoredFileEntity> saveFile(String sourcePath) async {
    throw UnimplementedError();
  }

  @override
  Future<StoredFileEntity?> readFile(String path) async {
    return null;
  }

  @override
  Future<void> deleteFile(String path) async {}
}

void main() {
  testWidgets('survey card menu exposes Edit and Delete actions', (
    tester,
  ) async {
    var editCount = 0;
    var deleteCount = 0;

    final survey = SurveyEntity(
      id: 'survey-1',
      farmerName: 'Ada Farmer',
      cropType: 'Wheat',
      fieldArea: 12.5,
      latitude: 12.34,
      longitude: 56.78,
      photoPaths: const [],
      status: 'active',
      createdAt: DateTime.utc(2025, 1, 1, 12),
      updatedAt: DateTime.utc(2025, 1, 1, 12),
    );

    final readFileUseCase = ReadFileUseCase(_FakeStorageRepository());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SurveyCard(
            survey: survey,
            readFileUseCase: readFileUseCase,
            onEdit: () => editCount++,
            onDelete: () => deleteCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(editCount, 1);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(deleteCount, 1);
  });
}
