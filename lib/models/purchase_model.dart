class PurchaseModel {
  final String? id;
  final double totalCost;
  final String? notes;
  final DateTime purchaseDate;

  PurchaseModel({this.id, required this.totalCost, this.notes, required this.purchaseDate});

  factory PurchaseModel.fromJson(Map<String, dynamic> json) => PurchaseModel(
    id: json['id'],
    totalCost: (json['total_cost'] as num).toDouble(),
    notes: json['notes'],
    purchaseDate: DateTime.parse(json['purchase_date']),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'total_cost': totalCost,
    'notes': notes,
    'purchase_date': purchaseDate.toIso8601String(),
  };
}