import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  
  // Penyimpanan data untuk pencarian dan filter kategori
  List<MenuModel> _allMenus = [];
  List<MenuModel> _filteredMenus = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  
  // Ini adalah keranjang belanja kasir
  final List<CartItem> _cart = []; 

  @override
  void initState() {
    super.initState();
    _loadAllMenusForPOS();
    _searchController.addListener(_applyFilterAndSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Mengambil data awal dari database
  void _loadAllMenusForPOS() async {
    setState(() => _isLoading = true);
    try {
      final menus = await _supabaseService.getMenus();
      setState(() {
        _allMenus = menus;
        _isLoading = false;
        _applyFilterAndSearch();
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Logika Filter Kategori dan Pencarian Nama Menu
  void _applyFilterAndSearch() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMenus = _allMenus.where((menu) {
        // Filter Kategori (mengabaikan huruf besar/kecil)
        bool matchesCategory = _selectedCategory == 'Semua' || 
            (menu.category != null && menu.category!.toLowerCase() == _selectedCategory.toLowerCase());
        
        // Filter Pencarian Nama
        bool matchesSearch = menu.name.toLowerCase().contains(query);

        return matchesCategory && matchesSearch;
      }).toList();
    });
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
        content: Text('${menu.name} ditambahkan!', style: GoogleFonts.poppins()),
        duration: const Duration(milliseconds: 600),
        backgroundColor: Colors.orange[800],
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('Kirim Pesanan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Latar belakang abu-abu terang
      appBar: AppBar(
        title: Text(
          'Mode Kasir (POS)',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.orange[800], // Oranye solid elegan
        elevation: 0,
      ),
      body: Column(
        children: [
          // === SEARCH BAR DAN FILTER KATEGORI ===
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                // Input Pencarian
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari menu atau minuman...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10), 
                      borderSide: BorderSide.none
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 10),
                // Tab Kategori Chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['Semua', 'Makanan', 'Minuman'].map((cat) {
                    bool isActive = _selectedCategory == cat;
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        _applyFilterAndSearch();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.orange[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cat,
                          style: GoogleFonts.poppins(
                            color: isActive ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // === GRID TAMPILAN MENU ===
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _filteredMenus.isEmpty 
                ? Center(
                    child: Text(
                      'Menu tidak ditemukan.', 
                      style: GoogleFonts.poppins(color: Colors.grey)
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Menampilkan 2 kolom
                      childAspectRatio: 0.95, // Rasio area kotak
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _filteredMenus.length,
                    itemBuilder: (context, index) {
                      final menu = _filteredMenus[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(16), // Efek sentuh membulat
                        onTap: () => _addToCart(menu),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias, // Gambar mengikuti sudut kartu
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
                  ),
          ),
        ],
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
                    color: Colors.grey.withValues(alpha: 0.2),
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