class IngredientModel {
  final String? id;
  final String name;
  final String unit;
  final double stock;

  IngredientModel({
    this.id,
    required this.name,
    required this.unit,
    required this.stock,
  });

  // Mengubah data dari Supabase (JSON) menjadi Object Dart
  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    return IngredientModel(
      id: json['id'],
      name: json['name'],
      unit: json['unit'],
      stock: (json['stock'] as num).toDouble(),
    );
  }

  // Mengubah Object Dart menjadi JSON untuk dikirim ke Supabase
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'unit': unit,
      'stock': stock,
    };
  }
}