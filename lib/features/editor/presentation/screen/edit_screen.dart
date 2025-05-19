import 'package:chamelion_app/features/editor/domain/services/image_crop_service.dart';
import 'package:chamelion_app/features/editor/domain/services/image_save_service.dart';
import 'package:chamelion_app/features/editor/domain/services/image_filter_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import '../widgets/filter_list.dart';

class EditScreen extends StatefulWidget {
  final File imageFile;

  const EditScreen({super.key, required this.imageFile});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _cropService = ImageCropService();
  final _saveService = ImageSaveService();
  final _filterService = ImageFilterService();
  File? _editedImage;
  File? _originalImage;
  bool _isSaving = false;
  String _selectedFilter = 'None';
  bool _isApplyingFilter = false;
  List<File> _filteredImages = [];
  double _filterIntensity = 1.0;

  @override
  void initState() {
    super.initState();
    _editedImage = widget.imageFile;
    _originalImage = widget.imageFile;
    _selectedFilter = 'None';
  }

  @override
  void dispose() {
    // Очищаем временные файлы при закрытии экрана
    for (final file in _filteredImages) {
      try {
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        debugPrint('Error deleting temporary file: $e');
      }
    }
    super.dispose();
  }

  Future<void> _cropImage() async {
    try {
      debugPrint('Starting crop operation...');
      final croppedFile = await _cropService.cropImage(
        _editedImage ?? widget.imageFile,
      );
      debugPrint(
        'Crop operation completed. Result: ${croppedFile?.path ?? 'null'}',
      );

      if (croppedFile != null && mounted) {
        setState(() {
          _editedImage = croppedFile;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Изображение успешно обрезано'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error in _cropImage: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при кадрировании: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  Future<bool> get _isImageVertical async {
  try {
    final image = await decodeImageFromList(
      (_editedImage ?? widget.imageFile).readAsBytesSync()
    );
    return image.height > image.width;
  } catch (e) {
    debugPrint('Error checking image orientation: $e');
    return true; // По умолчанию считаем вертикальным
  }
}

  Future<void> _showPermissionDeniedDialog({bool isPermanent = false}) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Требуется разрешение'),
            content: Text(
              isPermanent
                  ? 'Для сохранения фотографий необходим доступ к галерее. '
                      'Пожалуйста, предоставьте разрешение в настройках устройства.'
                  : 'Для сохранения фотографий необходим доступ к галерее. '
                      'Пожалуйста, предоставьте разрешение.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  if (isPermanent) {
                    await PhotoManager.openSetting();
                  } else {
                    final PermissionState result =
                        await PhotoManager.requestPermissionExtend();
                    if (!mounted) return;
                    if (result.isAuth) {
                      _saveImage(); // Повторяем попытку сохранения
                    }
                  }
                },
                child: Text(isPermanent ? 'Открыть настройки' : 'Разрешить'),
              ),
            ],
          ),
    );
  }

  Future<void> _saveImage() async {
    try {
      // ignore: unnecessary_null_comparison
      if (_editedImage == null && widget.imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка: изображение не найдено'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final fileToSave = _editedImage ?? widget.imageFile;
      debugPrint('Attempting to save file: ${fileToSave.path}');

      if (!await fileToSave.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка: файл изображения не существует'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await _saveService.saveImage(fileToSave);

      if (!mounted) return;

      switch (result) {
        case SaveImageResult.success:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Изображение сохранено в галерею'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
          break;

        case SaveImageResult.permissionDenied:
          await _showPermissionDeniedDialog(isPermanent: false);
          break;

        case SaveImageResult.permissionPermanentlyDenied:
          await _showPermissionDeniedDialog(isPermanent: true);
          break;

        case SaveImageResult.error:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось сохранить изображение в галерею'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
          break;
      }
    } catch (e) {
      debugPrint('Error in _saveImage: $e');
      if (!mounted) return;

      String errorMessage = 'Ошибка при сохранении';
      if (e is FileSystemException) {
        errorMessage = 'Ошибка доступа к файлу';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Нет разрешения на сохранение в галерею';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _applyFilter() async {
    if (_originalImage == null || _isApplyingFilter) return;

    setState(() {
      _isApplyingFilter = true;
    });

    try {
      debugPrint('Applying filter $_selectedFilter to image');
      final filteredImage = await _filterService.applyFilter(
        _originalImage!,
        _selectedFilter,
        intensity: _filterIntensity,
      );

      if (filteredImage != null && mounted) {
        debugPrint(
          'Filter applied successfully, updating UI with new image: ${filteredImage.path}',
        );

        // Добавляем новый файл в список для последующей очистки
        _filteredImages.add(filteredImage);

        setState(() {
          _editedImage = filteredImage;
          _isApplyingFilter = false;
        });
      } else {
        debugPrint('Failed to apply filter: filteredImage is null');
        if (mounted) {
          setState(() {
            _isApplyingFilter = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error applying filter: $e');
      if (mounted) {
        setState(() {
          _isApplyingFilter = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при применении фильтра: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                if (_editedImage != null)
                  FilterList(
                    imageFile: _originalImage!,
                    onFilterSelected: (filter) async {
                      if (_selectedFilter != filter) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                        setModalState(() {
                          _selectedFilter = filter;
                        });
                        await _applyFilter();
                      }
                    },
                    selectedFilter: _selectedFilter,
                    filterService: _filterService,
                    onIntensityChanged: (double intensity) {
    setState(() {
      _filterIntensity = intensity;
    });
    _applyFilter();
  },
                  ),
                if (_filterService.supportsIntensity(_selectedFilter))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      children: [
                        const Text(
                          'Интенсивность',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          '${(_filterIntensity * 100).toInt()}%',
                          style: const TextStyle(color: Colors.white),
                        ),
                        Slider(
                          value: _filterIntensity,
                          onChanged: (value) {
                            setState(() {
                              _filterIntensity = value;
                            });
                            setModalState(() {
                              _filterIntensity = value;
                            });
                            _applyFilter();
                          },
                          activeColor: Colors.white,
                          inactiveColor: Colors.white.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Кнопка назад
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
            // Основной контент
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(7.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child:
                    _isApplyingFilter
                        ? const Center(child: CircularProgressIndicator())
                        : Image.file(
                          _editedImage ?? widget.imageFile,
                          key: ValueKey(
                            _editedImage?.path ?? widget.imageFile.path,
                          ),
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('Error loading image in widget: $error');
                            debugPrint('Stack trace: $stackTrace');
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Ошибка загрузки изображения: ${error.toString()}',
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
              ),
            ),
            const SizedBox(height: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _cropImage,
                      icon: const Icon(Icons.crop),
                      label: const Text('Обрезать'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _editedImage == null ? null : _showFilters,
                      icon: const Icon(Icons.filter),
                      label: const Text('Фильтры'),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: _saveImage,
                  icon: const Icon(Icons.save),
                  label: const Text('Сохранить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
