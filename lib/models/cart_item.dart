import 'menu_model.dart';

class CartItem {
  final MenuModel menu;
  int quantity;
  String note;

  CartItem({
    required this.menu,
    this.quantity = 1,
    this.note = '',
  });

  // Menghitung total harga per item (harga menu x jumlah)
  double get totalPrice => menu.price * quantity;
}