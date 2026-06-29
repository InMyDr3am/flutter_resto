class OrderModel {
  final String? id;
  final String customerName;
  final String? tableNumber;
  final double totalPrice;
  String status;
  final String? paymentMethod; // Tambahan: 'cash' atau 'qris'
  final double? changeAmount;    // Tambahan: nominal kembalian

  OrderModel({
    this.id,
    required this.customerName,
    this.tableNumber,
    required this.totalPrice,
    required this.status,
    this.paymentMethod,
    this.changeAmount,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'],
        customerName: json['customer_name'],
        tableNumber: json['table_number'],
        totalPrice: (json['total_price'] as num).toDouble(),
        status: json['status'],
        paymentMethod: json['payment_method'],
        changeAmount: json['change_amount'] != null ? (json['change_amount'] as num).toDouble() : null,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'customer_name': customerName,
        'table_number': tableNumber,
        'total_price': totalPrice,
        'status': status,
        'payment_method': paymentMethod,
        'change_amount': changeAmount,
      };

  // Kloning objek dengan pembaruan status & data pembayaran
  OrderModel copyWith({
    String? status,
    String? paymentMethod,
    double? changeAmount,
  }) {
    return OrderModel(
      id: id,
      customerName: customerName,
      tableNumber: tableNumber,
      totalPrice: totalPrice,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      changeAmount: changeAmount ?? this.changeAmount,
    );
  }
}