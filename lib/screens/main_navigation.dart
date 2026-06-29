import 'package:flutter/material.dart';
import 'menu_screen.dart';
import 'ingredient_screen.dart';
import 'order_screen.dart';
import 'pos_screen.dart';
import 'purchase_screen.dart'; // 1. Import halaman Purchase baru

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // 2. Daftarkan PurchaseScreen ke dalam indeks menu ke-2
  final List<Widget> _screens = [
    const PosScreen(),        // Index 0
    const OrderScreen(),      // Index 1
    const PurchaseScreen(),   // Index 2 (Halaman Belanja Baru)
    const MenuScreen(),       // Index 3
    const IngredientScreen(), // Index 4
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
        type: BottomNavigationBarType.fixed, // Penting karena menu kita sekarang ada 5
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Kasir'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Dapur'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Belanja'), // Tombol menu baru
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Stok'),
        ],
      ),
    );
  }
}