class MenuModel {
  final String? id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final String? category;

  MenuModel({
    this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.category
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'price': price,
      if (imageUrl != null) 'image_url': imageUrl,
      'category': category,
    };
  }
}