class IngredientModel {
  final String? id; // UUID di Dart adalah String
  final String name;
  final String unit;
  final double stock;

  IngredientModel({this.id, required this.name, required this.unit, required this.stock});

  // Tambahkan toJson
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'unit': unit,
      'stock': stock,
    };
  }

  // Tambahkan fromJson
  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    return IngredientModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      unit: json['unit'] as String,
      stock: (json['stock'] as num).toDouble(),
    );
  }
}