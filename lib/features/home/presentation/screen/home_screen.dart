import 'package:chamelion_app/features/editor/presentation/screen/edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      debugPrint('Starting image pick from ${source.toString()}');
      
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (image != null) {
        debugPrint('Image picked successfully: ${image.path}');
        debugPrint('Image mime type: ${image.mimeType}');
        debugPrint('Image extension: ${path.extension(image.path)}');
        
        final int fileSize = await image.length();
        debugPrint('Original file size: $fileSize bytes');
        
        final File imageFile = File(image.path);
        final Uint8List bytes = await imageFile.readAsBytes();
        debugPrint('First few bytes: ${bytes.take(8).toList()}'); // Проверяем магические числа файла
        
        final bool exists = await imageFile.exists();
        debugPrint('Image file exists: $exists');
        
        if (exists) {
          final int finalFileSize = await imageFile.length();
          debugPrint('Final file size: $finalFileSize bytes');
          
          if (!mounted) return;
          
          try {
            // Пробуем декодировать изображение
            final decodedImage = await decodeImageFromList(bytes);
            debugPrint('Image successfully decoded. Width: ${decodedImage.width}, Height: ${decodedImage.height}');
            
            setState(() {
              _selectedImage = imageFile;
            });
            
            debugPrint('Navigating to EditScreen');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditScreen(imageFile: _selectedImage!),
              ),
            );
          } catch (imageError) {
            debugPrint('Error decoding image: $imageError');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ошибка при обработке изображения: ${imageError.toString()}'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          debugPrint('Error: Image file does not exist at path: ${image.path}');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Файл изображения не найден'),
            ),
          );
        }
      } else {
        debugPrint('No image selected');
      }
    } catch (e, stackTrace) {
      debugPrint('Error picking image: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      
      String errorMessage = 'Ошибка при выборе изображения';
      if (e.toString().contains('invalid_image')) {
        errorMessage = 'Недопустимый формат изображения. Поддерживаются форматы: JPEG, PNG';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Фоторедактор'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: Text(
                'Галерея',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: Text(
                'Камера',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}