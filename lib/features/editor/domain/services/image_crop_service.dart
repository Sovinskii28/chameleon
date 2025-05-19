import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

class ImageCropService {
  Future<File?> cropImage(File imageFile) async {
    try {
      debugPrint('Starting image crop for file: ${imageFile.path}');
      
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Обрезать изображение',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Обрезать',
            cancelButtonTitle: 'Отмена',
            doneButtonTitle: 'Готово',
          ),
        ],
      );

      if (croppedFile != null) {
        debugPrint('Image cropped successfully: ${croppedFile.path}');
        return File(croppedFile.path);
      } else {
        debugPrint('Cropping cancelled by user');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error cropping image: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}