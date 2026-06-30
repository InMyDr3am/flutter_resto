import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // ... (biarkan bagian atas file seperti import dan deklarasi class tetap sama)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Latar belakang abu-abu terang agar terkesan bersih
      appBar: AppBar(
        title: Text(
          'Mode Kasir (POS)',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.orange[800], // Oranye yang lebih solid dan elegan
        elevation: 0,
      ),
      body: FutureBuilder<List<MenuModel>>(
        future: _menusFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Belum ada menu yang tersedia.',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final menus = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Menampilkan 2 kolom
              childAspectRatio: 0.95, // Memperluas area kotak agar pas untuk gambar dan teks
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: menus.length,
            itemBuilder: (context, index) {
              final menu = menus[index];
              return InkWell(
                borderRadius: BorderRadius.circular(16), // Efek sentuh membulat
                onTap: () => _addToCart(menu),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // Sudut kartu membulat modern
                  ),
                  clipBehavior: Clip.antiAlias, // Memastikan gambar mengikuti sudut kartu
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: menu.imageUrl != null
                            ? Image.network(
                                menu.imageUrl!, 
                                fit: BoxFit.cover, 
                                width: double.infinity
                              )
                            : Container(
                                color: Colors.orange[50],
                                child: const Center(
                                  child: Icon(Icons.fastfood, size: 50, color: Colors.orange),
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              menu.name, 
                              style: GoogleFonts.poppins(
                                fontSize: 14, 
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[850],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rp ${menu.price.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                fontSize: 13, 
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      
      // Tombol Keranjang Bawah (Modern Floating Bar)
      bottomNavigationBar: _cart.isEmpty 
          ? null 
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _checkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Lihat Keranjang (${_cart.length} Item) • Rp ${_cartTotal.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}