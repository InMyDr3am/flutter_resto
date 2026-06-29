import 'package:flutter/material.dart';
import 'menu_screen.dart';
import 'ingredient_screen.dart';
import 'order_screen.dart';
import 'pos_screen.dart';
import 'purchase_screen.dart';
import 'payment_screen.dart';
import 'order_history_screen.dart'; // 1. Import halaman riwayat baru

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // 2. Daftarkan OrderHistoryScreen ke dalam list screen
  final List<Widget> _screens = [
    const PosScreen(),        // Index 0 (Kasir)
    const OrderScreen(),      // Index 1 (Dapur)
    const PaymentScreen(),    // Index 2 (Antrean Pembayaran)
    const OrderHistoryScreen(), // Index 3 (Riwayat Pesanan Lunas Baru)
    const PurchaseScreen(),   // Index 4 (Belanja)
    const MenuScreen(),       // Index 5 (Manajemen Menu)
    const IngredientScreen(), // Index 6 (Stok)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Diperlukan jika menu cukup banyak
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Kasir'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Dapur'),
          BottomNavigationBarItem(icon: Icon(Icons.payments), label: 'Pembayaran'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'), // Menu Riwayat Lunas Baru
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Belanja'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Stok'),
        ],
      ),
    );
  }
}