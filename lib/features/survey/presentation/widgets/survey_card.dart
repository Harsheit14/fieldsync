import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fieldsync/features/survey/domain/entities/survey_entity.dart';

class SurveyCard extends StatelessWidget {
  const SurveyCard({
    super.key,
    required this.survey,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
    this.isDeleteLoading = false,
  });

  final SurveyEntity survey;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isDeleteLoading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final locationLabel = _locationLabel();
    final createdLabel = _formatDateTime(survey.createdAt);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SurveyThumbnail(photoPath: _firstPhotoPath()),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                survey.farmerName,
                                style: textTheme.titleMedium,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Chip(label: Text(survey.status)),
                            if (onEdit != null || onDelete != null) ...[
                              const SizedBox(width: 8),
                              if (isDeleteLoading)
                                const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              else
                                PopupMenuButton<_SurveyCardAction>(
                                  tooltip: 'Survey actions',
                                  onSelected: (action) {
                                    switch (action) {
                                      case _SurveyCardAction.edit:
                                        onEdit?.call();
                                        break;
                                      case _SurveyCardAction.delete:
                                        onDelete?.call();
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    if (onEdit != null)
                                      const PopupMenuItem(
                                        value: _SurveyCardAction.edit,
                                        child: Text('Edit'),
                                      ),
                                    if (onDelete != null)
                                      PopupMenuItem(
                                        value: _SurveyCardAction.delete,
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Created $createdLabel',
                          style: textTheme.bodySmall,
                        ),
                        if (locationLabel != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            locationLabel,
                            style: textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _SurveyDetail(label: 'Crop type', value: survey.cropType),
                  _SurveyDetail(
                    label: 'Field area',
                    value: survey.fieldArea.toString(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _firstPhotoPath() {
    if (survey.photoPaths.isEmpty) {
      return null;
    }

    final path = survey.photoPaths.first.trim();
    return path.isEmpty ? null : path;
  }

  String? _locationLabel() {
    if (survey.latitude == 0 && survey.longitude == 0) {
      return null;
    }

    return 'Location: ${survey.latitude.toStringAsFixed(5)}, ${survey.longitude.toStringAsFixed(5)}';
  }

  String _formatDateTime(DateTime dateTime) {
    final localDate = dateTime.toLocal();
    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

enum _SurveyCardAction { edit, delete }

class _SurveyThumbnail extends StatelessWidget {
  const _SurveyThumbnail({required this.photoPath});

  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (photoPath == null) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.photo_outlined, color: colorScheme.outline),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Image.file(
          File(photoPath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Icon(
                Icons.broken_image_outlined,
                color: colorScheme.outline,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SurveyDetail extends StatelessWidget {
  const _SurveyDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: textTheme.labelMedium),
        const SizedBox(height: 2),
        Text(value, style: textTheme.bodyMedium),
      ],
    );
  }
}
