class OrderItemModel {
  final String? id;
  final String? orderId;
  final String menuId;
  final int quantity;
  final double price;
  final String? menuName; // Tambahan properti opsional untuk mempermudah pemanggilan nama makanan di UI

  OrderItemModel({
    this.id,
    this.orderId,
    required this.menuId,
    required this.quantity,
    required this.price,
    this.menuName,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      orderId: json['order_id'],
      menuId: json['menu_id'],
      quantity: json['quantity'],
      price: (json['price'] as num).toDouble(),
      menuName: json['menus']?['name'], // Supabase otomatis menggabungkan relasi nama menu jika kita panggil
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      'menu_id': menuId,
      'quantity': quantity,
      'price': price,
    };
  }
}