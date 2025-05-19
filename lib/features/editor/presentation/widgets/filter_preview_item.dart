import 'package:flutter/material.dart';
import 'package:flutter_image_filters/flutter_image_filters.dart';
import '../../domain/services/image_filter_service.dart';

class FilterPreviewItem extends StatefulWidget {
  final TextureSource texture;
  final String filterName;
  final bool isSelected;
  final VoidCallback onTap;
  final String displayName;

  const FilterPreviewItem({
    super.key,
    required this.texture,
    required this.filterName,
    required this.isSelected,
    required this.onTap,
    required this.displayName,
  });

  @override
  State<FilterPreviewItem> createState() => _FilterPreviewItemState();
}

class _FilterPreviewItemState extends State<FilterPreviewItem> {
  late Future<ShaderConfiguration?> _configurationFuture;

  @override
  void initState() {
    super.initState();
    _configurationFuture = _initializeFilter();
  }

  Future<ShaderConfiguration?> _initializeFilter() async {
    if (widget.filterName == 'None') return null;
    return ImageFilterService().createFilterConfiguration(widget.filterName);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.isSelected ? Colors.blue : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: FutureBuilder<ShaderConfiguration?>(
                    future: _configurationFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.red,
                          ),
                        );
                      }

                      final configuration = snapshot.data;
                      if (widget.filterName == 'None' || configuration == null) {
                        return ImageShaderPreview(
                          texture: widget.texture,
                          configuration: NoneShaderConfiguration(),
                        );
                      }

                      return ImageShaderPreview(
                        texture: widget.texture,
                        configuration: configuration,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.displayName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
} 