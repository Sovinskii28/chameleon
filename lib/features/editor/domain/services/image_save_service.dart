import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

enum SaveImageResult {
  success,
  permissionDenied,
  permissionPermanentlyDenied,
  error
}

class ImageSaveService {
  Future<SaveImageResult> saveImage(File imageFile) async {
    try {
      debugPrint('Starting save operation for file: ${imageFile.path}');
      
      // Запрашиваем разрешения в зависимости от платформы
      if (Platform.isIOS) {
        // Сначала проверяем статус через permission_handler
        final photosStatus = await Permission.photos.status;
        debugPrint('Initial iOS photos permission status: $photosStatus');
        
        if (photosStatus.isDenied) {
          // Если разрешение не предоставлено, запрашиваем через permission_handler
          final requestStatus = await Permission.photos.request();
          debugPrint('iOS photos permission request result: $requestStatus');
          
          if (requestStatus.isDenied) {
            return SaveImageResult.permissionDenied;
          }
          if (requestStatus.isPermanentlyDenied) {
            return SaveImageResult.permissionPermanentlyDenied;
          }
        }
        
        // Дополнительно проверяем через photo_manager для полной уверенности
        final pmStatus = await PhotoManager.requestPermissionExtend();
        debugPrint('PhotoManager permission status: $pmStatus');
        
        if (!pmStatus.isAuth) {
          debugPrint('PhotoManager permission denied');
          if (pmStatus == PermissionState.limited || pmStatus == PermissionState.denied) {
            return SaveImageResult.permissionDenied;
          } else {
            return SaveImageResult.permissionPermanentlyDenied;
          }
        }
      } else if (Platform.isAndroid) {
        // Для Android запрашиваем разрешения через permission_handler
        final status = await Permission.storage.request();
        debugPrint('Android storage permission status: $status');
        
        if (status.isDenied) {
          return SaveImageResult.permissionDenied;
        }
        if (status.isPermanentlyDenied) {
          return SaveImageResult.permissionPermanentlyDenied;
        }
        
        // На Android 13+ также нужно разрешение на фото и видео
        if (await Permission.photos.shouldShowRequestRationale) {
          final photoStatus = await Permission.photos.request();
          debugPrint('Android photos permission status: $photoStatus');
          
          if (photoStatus.isDenied) {
            return SaveImageResult.permissionDenied;
          }
          if (photoStatus.isPermanentlyDenied) {
            return SaveImageResult.permissionPermanentlyDenied;
          }
        }
      }
      
      // Проверяем существование файла
      if (!await imageFile.exists()) {
        debugPrint('Error: File does not exist at path: ${imageFile.path}');
        return SaveImageResult.error;
      }

      // Проверяем размер файла
      final fileSize = await imageFile.length();
      debugPrint('File size: $fileSize bytes');
      
      if (fileSize == 0) {
        debugPrint('Error: File is empty');
        return SaveImageResult.error;
      }

      // Сохраняем изображение используя gal
      final String fileName = "edited_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}";
      debugPrint('Saving image with filename: $fileName');
      
      try {
        // Проверяем доступность файла для чтения
        final bytes = await imageFile.readAsBytes();
        debugPrint('Successfully read ${bytes.length} bytes from file');
        
        await Gal.putImage(imageFile.path);
        debugPrint('Image saved successfully through Gal.putImage');
        return SaveImageResult.success;
      } catch (saveError) {
        debugPrint('Error in Gal.putImage: $saveError');
        debugPrint('Error type: ${saveError.runtimeType}');
        
        if (saveError.toString().contains('permission')) {
          return SaveImageResult.permissionDenied;
        }
        
        // Пробуем получить более подробную информацию об ошибке
        if (Platform.isIOS) {
          final photosStatus = await Permission.photos.status;
          debugPrint('Current iOS photos permission status: $photosStatus');
          
          final pmStatus = await PhotoManager.requestPermissionExtend();
          debugPrint('Current PhotoManager status: $pmStatus');
        }
        
        throw saveError; // Пробрасываем ошибку для внешней обработки
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving image: $e');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Stack trace: $stackTrace');
      
      if (e.toString().contains('permission') || 
          e.toString().contains('denied') || 
          e.toString().contains('Permission')) {
        return SaveImageResult.permissionDenied;
      }
      
      return SaveImageResult.error;
    }
  }
} 