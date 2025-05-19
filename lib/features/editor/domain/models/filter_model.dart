class FilterModel {
  final String name;
  final String type;
  final double intensity;

  const FilterModel({
    required this.name,
    required this.type,
    this.intensity = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'intensity': intensity,
  };

  factory FilterModel.fromJson(Map<String, dynamic> json) => FilterModel(
    name: json['name'] as String,
    type: json['type'] as String,
    intensity: json['intensity'] as double,
  );
} 