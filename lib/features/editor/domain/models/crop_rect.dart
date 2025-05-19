class CropRect {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const CropRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  Map<String, dynamic> toJson() => {
    'left': left,
    'top': top,
    'right': right,
    'bottom': bottom,
  };

  factory CropRect.fromJson(Map<String, dynamic> json) => CropRect(
    left: json['left'] as double,
    top: json['top'] as double,
    right: json['right'] as double,
    bottom: json['bottom'] as double,
  );
} 