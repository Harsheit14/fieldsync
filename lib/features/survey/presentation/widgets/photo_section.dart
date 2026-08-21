import 'package:flutter/material.dart';

class PhotoSection extends StatelessWidget {
  const PhotoSection({
    super.key,
    required this.photoPaths,
    required this.onAddPhoto,
    this.onRemovePhoto,
    this.isEnabled = true,
  });

  final List<String> photoPaths;
  final VoidCallback onAddPhoto;
  final ValueChanged<int>? onRemovePhoto;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        if (photoPaths.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No photos attached.',
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: photoPaths.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final path = photoPaths[index];

              return ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text(
                  path.split('/').last,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: onRemovePhoto == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: isEnabled
                            ? () => onRemovePhoto!(index)
                            : null,
                      ),
              );
            },
          ),

        const SizedBox(height: 16),

        FilledButton.icon(
          onPressed: isEnabled ? onAddPhoto : null,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Add Photo'),
        ),
      ],
    );
  }
}