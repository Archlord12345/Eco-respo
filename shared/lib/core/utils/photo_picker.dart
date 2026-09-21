import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Sélection d'une photo adaptée à la plateforme : appareil photo ou galerie
/// sur mobile, sélecteur de fichiers sur desktop et web.
class PhotoPicker {
  static bool get _isMobile =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  static Future<Uint8List?> pick(BuildContext context) async {
    if (_isMobile) {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Prendre une photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choisir dans la galerie'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null) return null;
      final file = await ImagePicker().pickImage(source: source, imageQuality: 82, maxWidth: 1600);
      return file?.readAsBytes();
    }
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (files.isEmpty) return null;
    return files.first.readAsBytes();
  }
}
