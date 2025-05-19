import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_filters/flutter_image_filters.dart';
import '../../domain/services/image_filter_service.dart';
import 'filter_preview_item.dart';

class FilterList extends StatefulWidget {
  final File imageFile;
  final Function(String) onFilterSelected;
  final String selectedFilter;
  final ImageFilterService filterService;
  final Function(double) onIntensityChanged;

  const FilterList({
    super.key,
    required this.imageFile,
    required this.onFilterSelected,
    required this.selectedFilter,
    required this.filterService,
    required this.onIntensityChanged,
  });

  @override
  State<FilterList> createState() => _FilterListState();
}

class _FilterListState extends State<FilterList> {
  TextureSource? _texture;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTexture();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadTexture() async {
    try {
      final texture = await TextureSource.fromFile(widget.imageFile);
      if (mounted) {
        setState(() {
          _texture = texture;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading texture: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 140,
        color: Colors.black87,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_texture == null) {
      return Container(
        height: 140,
        color: Colors.black87,
        child: const Center(
          child: Text(
            'Ошибка загрузки изображения',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Container(
      height: 140,
      color: Colors.black87,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: ImageFilterService.filters.length,
              itemBuilder: (context, index) {
                final filter = ImageFilterService.filters[index];
                final isSelected = filter == widget.selectedFilter;
                
                return FilterPreviewItem(
                  texture: _texture!,
                  filterName: filter,
                  isSelected: isSelected,
                  onTap: () => widget.onFilterSelected(filter),
                  displayName: widget.filterService.getFilterName(filter),
                );
              },
            ),
          ),
          
        ],
      ),
    );
  }
} 