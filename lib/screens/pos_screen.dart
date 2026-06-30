import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/menu_model.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../services/supabase_service.dart';

// Catatan: Pastikan model CartItem Anda mendukung properti note,
// contoh: class CartItem { MenuModel menu; int quantity; String note; ... }

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  
  List<MenuModel> _allMenus = [];
  List<MenuModel> _filteredMenus = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  
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

  void _applyFilterAndSearch() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMenus = _allMenus.where((menu) {
        bool matchesCategory = _selectedCategory == 'Semua' || 
            (menu.category != null && menu.category!.toLowerCase() == _selectedCategory.toLowerCase());
        
        bool matchesSearch = menu.name.toLowerCase().contains(query);

        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  String formatCurrency(double amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID', 
      symbol: 'Rp. ', 
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  void _addToCart(MenuModel menu) {
    setState(() {
      final existingItemIndex = _cart.indexWhere((item) => item.menu.id == menu.id);
      if (existingItemIndex >= 0) {
        _cart[existingItemIndex].quantity++;
      } else {
        _cart.add(CartItem(menu: menu, note: '')); // Inisialisasi catatan kosong default
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${menu.name} ditambahkan!', style: GoogleFonts.poppins()),
        duration: const Duration(milliseconds: 600),
        backgroundColor: Colors.orange[800],
      ),
    );
  }

  double get _cartTotal => _cart.fold(0, (sum, item) => sum + item.totalPrice);

  // === LANGKAH 1: RINCIAN PESANAN DENGAN KOLOM CATATAN (note) ===
  void _showOrderDetails() {
    if (_cart.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Rincian Pesanan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _cart.length,
                        itemBuilder: (context, index) {
                          final cartItem = _cart[index];
                          final noteController = TextEditingController(text: cartItem.note);

                          return Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  cartItem.menu.name, 
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)
                                ),
                                subtitle: Text(
                                  '${cartItem.quantity} x ${formatCurrency(cartItem.menu.price)}', 
                                  style: GoogleFonts.poppins(fontSize: 11)
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                      onPressed: () {
                                        setStateDialog(() {
                                          if (cartItem.quantity > 1) {
                                            cartItem.quantity--;
                                          } else {
                                            _cart.remove(cartItem);
                                          }
                                        });
                                        setState(() {}); 
                                        if (_cart.isEmpty) Navigator.pop(context);
                                      },
                                    ),
                                    Text(
                                      '${cartItem.quantity}', 
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 20),
                                      onPressed: () {
                                        setStateDialog(() {
                                          cartItem.quantity++;
                                        });
                                        setState(() {}); 
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              // Kolom Catatan / Note Khusus per Item Pesanan
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: TextField(
                                  controller: noteController,
                                  decoration: InputDecoration(
                                    hintText: 'Contoh: Tidak pedas, ekstra es batu...',
                                    hintStyle: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                                    prefixIcon: const Icon(Icons.note_add, size: 16, color: Colors.grey),
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Colors.grey, width: 0.5),
                                    ),
                                  ),
                                  style: GoogleFonts.poppins(fontSize: 11),
                                  onChanged: (value) {
                                    cartItem.note = value; // Simpan nilai note ke objek keranjang
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Keseluruhan:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(formatCurrency(_cartTotal), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange[800])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showPaymentDialog(); 
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white),
                  child: const Text('Lanjut Pembayaran'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // === LANGKAH 2: INPUT NAMA DAN MEJA LALU KIRIM KE DAPUR ===
  void _showPaymentDialog() {
    final customerController = TextEditingController(text: 'Umum');
    final tableController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Proses Pembayaran', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total yang harus dibayar: ${formatCurrency(_cartTotal)}', 
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange[800])),
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
                final newOrder = OrderModel(
                  customerName: customerController.text,
                  tableNumber: tableController.text.isEmpty ? null : tableController.text,
                  totalPrice: _cartTotal,
                  status: 'pending', 
                );

                // Mengirimkan catatan (note) ke dalam parameter pesanan *Order Items*
                final List<OrderItemModel> orderItems = _cart.map((cartItem) {
                  return OrderItemModel(
                    menuId: cartItem.menu.id!,
                    quantity: cartItem.quantity,
                    price: cartItem.menu.price, 
                    note: cartItem.note, // Catatan spesifik tersimpan di sini
                  );
                }).toList();

                await _supabaseService.createOrder(newOrder, orderItems);

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
      backgroundColor: Colors.grey[100], 
      appBar: AppBar(
        title: Text(
          'Mode Kasir (POS)',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.orange[800], 
        elevation: 0,
      ),
      body: Column(
        children: [
          // === SEARCH BARIS PENCARIAN DAN FILTER KATEGORI ===
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
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

          // === GRID TAMPILAN MENU (GAYA KARTU MODERN) ===
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
                      crossAxisCount: 2, 
                      childAspectRatio: 0.95, 
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _filteredMenus.length,
                    itemBuilder: (context, index) {
                      final menu = _filteredMenus[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(20), 
                        onTap: () => _addToCart(menu),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          clipBehavior: Clip.antiAlias, 
                          child: Stack(
                            children: [
                              Column(
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
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          menu.name, 
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: Colors.grey[850],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Sugar, flour, butter, toppings', 
                                          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          formatCurrency(menu.price),
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              // Tombol keranjang kecil di sudut kanan bawah kartu
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () => _addToCart(menu),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.3),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.add_shopping_cart, size: 18, color: Colors.black),
                                  ),
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
      
      // Tombol Keranjang Totalan Utama (Floating Fuchsia/Pink Button Modern)
      floatingActionButton: _cart.isEmpty 
        ? null 
        : FloatingActionButton(
            onPressed: _showOrderDetails, 
            backgroundColor: const Color(0xFFF03681), 
            foregroundColor: Colors.white,
            elevation: 6,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.shopping_cart, size: 28),
                if (_cart.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${_cart.fold(0, (sum, item) => sum + item.quantity)}',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFF03681), 
                          fontSize: 10, 
                          fontWeight: FontWeight.bold
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}