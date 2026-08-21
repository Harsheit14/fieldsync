import 'package:flutter/material.dart';
import 'package:fieldsync/features/location/domain/entities/location_entity.dart';
import 'package:fieldsync/features/survey/domain/entities/survey_entity.dart';
import 'package:fieldsync/features/survey/domain/validation/survey_validator.dart';
import 'package:fieldsync/features/survey/presentation/state/validation_state.dart';

import 'photo_section.dart';

class SurveyFormData {
  const SurveyFormData({
    required this.farmerName,
    required this.cropType,
    required this.fieldArea,
    required this.photoPaths,
    this.latitude,
    this.longitude,
  });

  final String farmerName;
  final String cropType;
  final String fieldArea;
  final double? latitude;
  final double? longitude;
  final List<String> photoPaths;
}

class SurveyForm extends StatefulWidget {
  const SurveyForm({
    super.key,
    required this.onSubmit,
    this.onCaptureLocation,
    this.onAddPhoto,
    this.isSubmitting = false,
    this.validationState = const ValidationState.valid(),
    this.initialSurvey,
    this.submitLabel = 'Save survey',
  });

  final ValueChanged<SurveyFormData> onSubmit;

  final Future<LocationEntity?> Function()? onCaptureLocation;

  /// Returns the stored image path after capturing & saving.
  final Future<String?> Function()? onAddPhoto;

  final bool isSubmitting;
  final ValidationState validationState;
  final SurveyEntity? initialSurvey;
  final String submitLabel;

  @override
  State<SurveyForm> createState() => _SurveyFormState();
}

class _SurveyFormState extends State<SurveyForm> {
  final _farmerNameController = TextEditingController();
  final _cropTypeController = TextEditingController();
  final _fieldAreaController = TextEditingController();

  double? _latitude;
  double? _longitude;

  final List<String> _photoPaths = [];

  @override
  void initState() {
    super.initState();

    final survey = widget.initialSurvey;

    if (survey == null) {
      return;
    }

    _farmerNameController.text = survey.farmerName;
    _cropTypeController.text = survey.cropType;
    _fieldAreaController.text = survey.fieldArea.toString();

    _latitude = survey.latitude;
    _longitude = survey.longitude;

    _photoPaths.addAll(survey.photoPaths);
  }

  @override
  void dispose() {
    _farmerNameController.dispose();
    _cropTypeController.dispose();
    _fieldAreaController.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    if (widget.onCaptureLocation == null) {
      return;
    }

    final location = await widget.onCaptureLocation!();

    if (!mounted || location == null) {
      return;
    }

    setState(() {
      _latitude = location.latitude;
      _longitude = location.longitude;
    });
  }

  Future<void> _addPhoto() async {
    if (widget.onAddPhoto == null) {
      return;
    }

    final path = await widget.onAddPhoto!();

    if (!mounted || path == null) {
      return;
    }

    setState(() {
      _photoPaths.add(path);
    });
  }

  void _submit() {
    widget.onSubmit(
      SurveyFormData(
        farmerName: _farmerNameController.text.trim(),
        cropType: _cropTypeController.text.trim(),
        fieldArea: _fieldAreaController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        photoPaths: List.unmodifiable(_photoPaths),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _farmerNameController,
            enabled: !widget.isSubmitting,
            decoration: InputDecoration(
              labelText: 'Farmer name',
              errorText: widget.validationState.messageFor(
                SurveyValidationField.farmerName,
              ),
            ),
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _cropTypeController,
            enabled: !widget.isSubmitting,
            decoration: InputDecoration(
              labelText: 'Crop type',
              errorText: widget.validationState.messageFor(
                SurveyValidationField.cropType,
              ),
            ),
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _fieldAreaController,
            enabled: !widget.isSubmitting,
            decoration: InputDecoration(
              labelText: 'Field area',
              errorText: widget.validationState.messageFor(
                SurveyValidationField.fieldArea,
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
          ),

          const SizedBox(height: 32),

          const Divider(),

          const SizedBox(height: 16),

          Text(
            'Location',
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: 12),

          Text(
            _latitude == null
                ? 'Latitude: --'
                : 'Latitude: ${_latitude!.toStringAsFixed(6)}',
          ),

          const SizedBox(height: 4),

          Text(
            _longitude == null
                ? 'Longitude: --'
                : 'Longitude: ${_longitude!.toStringAsFixed(6)}',
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: widget.isSubmitting ? null : _captureLocation,
            icon: const Icon(Icons.my_location),
            label: const Text('Capture Current Location'),
          ),

          const SizedBox(height: 32),

          const Divider(),

          const SizedBox(height: 16),

          PhotoSection(
            photoPaths: _photoPaths,
            onAddPhoto: _addPhoto,
            isEnabled: !widget.isSubmitting,
          ),

          const SizedBox(height: 32),

          FilledButton(
            onPressed: widget.isSubmitting ? null : _submit,
            child: widget.isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}