class OrderModel {
  final String? id;
  final String customerName;
  final String? tableNumber;
  final double totalPrice;
  final String status;
  final DateTime? createdAt;

  OrderModel({
    this.id,
    required this.customerName,
    this.tableNumber,
    required this.totalPrice,
    required this.status,
    this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      customerName: json['customer_name'],
      tableNumber: json['table_number'],
      totalPrice: (json['total_price'] as num).toDouble(),
      status: json['status'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'customer_name': customerName,
      if (tableNumber != null) 'table_number': tableNumber,
      'total_price': totalPrice,
      'status': status,
    };
  }
}