import 'menu_model.dart';

class CartItem {
  final MenuModel menu;
  int quantity;

  CartItem({
    required this.menu,
    this.quantity = 1,
  });

  // Menghitung total harga per item (harga menu x jumlah)
  double get totalPrice => menu.price * quantity;
}