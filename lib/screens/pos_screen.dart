import 'package:flutter/material.dart';
import '../models/menu_model.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../services/supabase_service.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<MenuModel>> _menusFuture;
  
  // Ini adalah keranjang belanja kasir
  final List<CartItem> _cart = []; 

  @override
  void initState() {
    super.initState();
    _menusFuture = _supabaseService.getMenus();
  }

  // Fungsi menambah menu ke keranjang
  void _addToCart(MenuModel menu) {
    setState(() {
      // Cek apakah menu sudah ada di keranjang
      final existingItemIndex = _cart.indexWhere((item) => item.menu.id == menu.id);
      if (existingItemIndex >= 0) {
        _cart[existingItemIndex].quantity++;
      } else {
        _cart.add(CartItem(menu: menu));
      }
    });
    
    // Tampilkan notifikasi kecil di bawah (Snackbar)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${menu.name} ditambahkan!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // Menghitung total belanja saat ini
  double get _cartTotal => _cart.fold(0, (sum, item) => sum + item.totalPrice);

  // Fungsi memproses pesanan (Checkout)
  void _checkout() {
    if (_cart.isEmpty) return;

    final customerController = TextEditingController(text: 'Umum');
    final tableController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Proses Pembayaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total: Rp ${_cartTotal.toStringAsFixed(0)}', 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: customerController,
                decoration: const InputDecoration(labelText: 'Nama Pelanggan'),
              ),
              TextField(
                controller: tableController,
                decoration: const InputDecoration(labelText: 'Nomor Meja (Opsional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // 1. Buat cetakan master Order
                final newOrder = OrderModel(
                  customerName: customerController.text,
                  tableNumber: tableController.text.isEmpty ? null : tableController.text,
                  totalPrice: _cartTotal,
                  status: 'pending', // Masuk antrean dapur
                );

                // 2. Buat rincian order items dari keranjang
                final List<OrderItemModel> orderItems = _cart.map((cartItem) {
                  return OrderItemModel(
                    menuId: cartItem.menu.id!,
                    quantity: cartItem.quantity,
                    price: cartItem.menu.price, // Kunci harga saat ini
                  );
                }).toList();

                // 3. Kirim ke Supabase
                await _supabaseService.createOrder(newOrder, orderItems);

                // 4. Bersihkan keranjang dan tutup dialog
                setState(() {
                  _cart.clear();
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pesanan berhasil dikirim ke Dapur!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Kirim Pesanan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Kasir (POS)'),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<List<MenuModel>>(
        future: _menusFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada menu.'));
          }

          final menus = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Menampilkan 2 kolom menu
              childAspectRatio: 1.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: menus.length,
            itemBuilder: (context, index) {
              final menu = menus[index];
              return InkWell(
                onTap: () => _addToCart(menu),
                child: Card(
                  child: Column(
                    children: [
                      Expanded(
                        // === GANTI HANYA BAGIAN INI SAJA ===
                        child: menu.imageUrl != null
                            ? Image.network(menu.imageUrl!, fit: BoxFit.cover, width: double.infinity)
                            : const Icon(Icons.fastfood, size: 40, color: Colors.orange),
                        // ===================================
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(menu.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Text('Rp ${menu.price.toStringAsFixed(0)}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      // Tampilkan tombol keranjang di bawah jika ada isinya
      bottomNavigationBar: _cart.isEmpty 
        ? null 
        : Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: ElevatedButton(
              onPressed: _checkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Keranjang (${_cart.length} item) - Rp ${_cartTotal.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
    );
  }
}