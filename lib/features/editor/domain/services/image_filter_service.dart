import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_filters/flutter_image_filters.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ImageFilterService {
  static const filters = [
    'None',
    'Brightness',
    'Bulge Distortion',
    'CGA Colorspace',
    'Color Invert',
    'Contrast',
    'Crosshatch',
    'Exposure',
    'False Color',
    'Gamma',
    'Glass Sphere',
    'Grayscale',
    'Halftone',
    'Highlight Shadow',
    'Hue',
    'Luminance',
    'Monochrome',
    'Opacity',
    'Posterize',
    'Saturation',
    'Solarize',
    'Swirl',
    'Vibrance',
    'Vignette',
    'White Balance',
    'Zoom Blur',
  ];

  static const _intensitySupportedFilters = {
    'Brightness',
    'Bulge Distortion',
    'Contrast',
    'Exposure',
    'Gamma',
    'Glass Sphere',
    'Highlight Shadow',
    'Monochrome',
    'Opacity',
    'Posterize',
    'Saturation',
    'Solarize',
    'Swirl',
    'Vibrance',
    'White Balance',
  };

  bool supportsIntensity(String filterName) {
    return _intensitySupportedFilters.contains(filterName);
  }

  String getFilterName(String filter) {
    switch (filter) {
      case 'None':
        return 'Оригинал';
      case 'Brightness':
        return 'Яркость';
      case 'Bulge Distortion':
        return 'Искажение';
      case 'CGA Colorspace':
        return 'CGA';
      case 'Color Invert':
        return 'Инверсия';
      case 'Contrast':
        return 'Контраст';
      case 'Crosshatch':
        return 'Штриховка';
      case 'Exposure':
        return 'Экспозиция';
      case 'False Color':
        return 'Ложный цвет';
      case 'Gamma':
        return 'Гамма';
      case 'Glass Sphere':
        return 'Стеклянный шар';
      case 'Grayscale':
        return 'Ч/Б';
      case 'Halftone':
        return 'Полутон';
      case 'Highlight Shadow':
        return 'Тени';
      case 'Hue':
        return 'Оттенок';
      case 'Luminance':
        return 'Свечение';
      case 'Monochrome':
        return 'Монохром';
      case 'Opacity':
        return 'Прозрачность';
      case 'Posterize':
        return 'Постер';
      case 'Saturation':
        return 'Насыщенность';
      case 'Solarize':
        return 'Соляризация';
      case 'Swirl':
        return 'Завихрение';
      case 'Vibrance':
        return 'Сочность';
      case 'Vignette':
        return 'Виньетка';
      case 'White Balance':
        return 'Баланс белого';
      case 'Zoom Blur':
        return 'Размытие зумом';
      default:
        return filter;
    }
  }

  Future<File?> applyFilter(File imageFile, String filterName, {double intensity = 1.0}) async {
    try {
      debugPrint('Applying filter: $filterName');
      
      if (filterName == 'None') {
        return imageFile;
      }

      // Создаем временный файл для сохранения результата с уникальным именем
      final String tempPath = imageFile.path.replaceAll(
        RegExp(r'\.[^.]*$'),
        '_${filterName.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.jpg'
      );
      
      debugPrint('Will save filtered image to: $tempPath');
      
      // Загружаем изображение как текстуру
      final texture = await TextureSource.fromFile(imageFile);
      
      // Создаем конфигурацию фильтра в зависимости от типа
      final configuration = createFilterConfiguration(filterName, intensity: intensity);
      
      if (configuration == null) {
        debugPrint('Error: Failed to create filter configuration');
        return null;
      }
      
      // Применяем фильтр и экспортируем результат
      final image = await configuration.export(texture, texture.size);
      
      if (image == null) {
        debugPrint('Error: Failed to apply filter - null result');
        return null;
      }
      
      // Получаем байты изображения
      final bytes = await image.toByteData();
      
      if (bytes == null) {
        debugPrint('Error: Failed to get image bytes');
        return null;
      }
      
      // Конвертируем в формат изображения
      final img.Image decodedImage = img.Image(
        width: image.width,
        height: image.height,
      );
      
      // Копируем данные пиксели
      final byteData = bytes.buffer.asUint8List();
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final i = (y * image.width + x) * 4;
          decodedImage.setPixelRgba(
            x, 
            y, 
            byteData[i],     // R
            byteData[i + 1], // G
            byteData[i + 2], // B
            byteData[i + 3], // A
          );
        }
      }
      
      // Сохраняем как JPEG
      final jpegBytes = img.encodeJpg(decodedImage, quality: 90);
      
      // Сохраняем результат во временный файл
      final File filteredFile = File(tempPath);
      await filteredFile.writeAsBytes(jpegBytes);
      
      debugPrint('Filter applied successfully: $tempPath');
      return filteredFile;
    } catch (e, stackTrace) {
      debugPrint('Error applying filter: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  ShaderConfiguration? createFilterConfiguration(String filterName, {double intensity = 1.0}) {
    switch (filterName) {
      case 'Brightness':
        return BrightnessShaderConfiguration()..brightness = intensity;
      case 'Bulge Distortion':
        return BulgeDistortionShaderConfiguration()..scale = intensity;
      case 'CGA Colorspace':
        return CGAColorspaceShaderConfiguration();
      case 'Color Invert':
        return ColorInvertShaderConfiguration();
      case 'Contrast':
        return ContrastShaderConfiguration()..contrast = intensity;
      case 'Crosshatch':
        return CrosshatchShaderConfiguration();
      case 'Exposure':
        return ExposureShaderConfiguration()..exposure = intensity;
      case 'False Color':
        return FalseColorShaderConfiguration();
      case 'Gamma':
        return GammaShaderConfiguration()..gamma = intensity;
      case 'Glass Sphere':
        return GlassSphereShaderConfiguration()..radius = intensity * 0.5;
      case 'Grayscale':
        return GrayscaleShaderConfiguration();
      case 'Halftone':
        return HalftoneShaderConfiguration();
      case 'Highlight Shadow':
        return HighlightShadowShaderConfiguration()
          ..shadows = intensity
          ..highlights = intensity;
      case 'Hue':
        return HueShaderConfiguration();
      case 'Luminance':
        return LuminanceShaderConfiguration();
      case 'Monochrome':
        return MonochromeShaderConfiguration()..intensity = intensity;
      case 'Opacity':
        return OpacityShaderConfiguration()..opacity = intensity;
      case 'Posterize':
        return PosterizeShaderConfiguration()..colorLevels = (intensity * 10).toDouble();
      case 'Saturation':
        return SaturationShaderConfiguration()..saturation = intensity;
      case 'Solarize':
        return SolarizeShaderConfiguration()..threshold = intensity;
      case 'Swirl':
        return SwirlShaderConfiguration()..radius = intensity * 0.5;
      case 'Vibrance':
        return VibranceShaderConfiguration()..vibrance = intensity;
      case 'Vignette':
        return VignetteShaderConfiguration();
      case 'White Balance':
        return WhiteBalanceShaderConfiguration()
          ..temperature = intensity * 5000
          ..tint = intensity * 100;
      case 'Zoom Blur':
        return ZoomBlurShaderConfiguration();
      default:
        return null;
    }
  }
}