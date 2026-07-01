class PurchaseItemModel {
  final String? id;
  final String? purchaseId;
  final String? ingredientId;
  final double quantity;
  final double cost;
  final String? ingredientName;

  PurchaseItemModel({this.id, this.purchaseId, required this.ingredientId, required this.quantity, required this.cost, this.ingredientName});

  Map<String, dynamic> toJson() => {
    'ingredient_id': ingredientId,
    'quantity': quantity,
    'cost': cost,
  };
}