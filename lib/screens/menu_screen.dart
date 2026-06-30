import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/menu_model.dart';
import '../services/supabase_service.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  
  List<MenuModel> _allMenus = [];
  List<MenuModel> _filteredMenus = [];
  bool _isLoading = true;

  String _selectedCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMenus();
    _searchController.addListener(_filterMenus);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMenus() async {
    setState(() => _isLoading = true);
    try {
      final menus = await _supabaseService.getMenus();
      setState(() {
        _allMenus = menus;
        _filterMenus(); // Terapkan filter awal
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat menu: $e')),
      );
    }
  }

  // Logika Pencarian dan Kategori
  void _filterMenus() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMenus = _allMenus.where((menu) {
        // Filter Kategori
        bool matchesCategory = _selectedCategory == 'Semua' || 
            (menu.category != null && menu.category!.toLowerCase() == _selectedCategory.toLowerCase());
        
        // Filter Pencarian Nama Menu
        bool matchesSearch = menu.name.toLowerCase().contains(query);

        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  // === FUNGSI CREATE (TAMBAH DENGAN PILIHAN KATEGORI) ===
  void _showAddMenuDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String category = 'Makanan'; // Default kategori saat tambah menu
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Tambah Menu Baru', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setStateDialog(() => selectedImage = File(pickedFile.path));
                        }
                      },
                      child: Container(
                        height: 120, width: double.infinity,
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                        child: selectedImage == null 
                          ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                          : Image.file(selectedImage!, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Menu')),
                    TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Harga'), keyboardType: TextInputType.number),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: ['Makanan', 'Minuman'].map((String cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (String? val) {
                        if (val != null) setStateDialog(() => category = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                      String? imageUrl;
                      if (selectedImage != null) {
                        imageUrl = await _supabaseService.uploadMenuImage(selectedImage!);
                      }

                      final newMenu = MenuModel(
                        name: nameController.text,
                        price: double.parse(priceController.text),
                        imageUrl: imageUrl,
                        category: category.toLowerCase(),
                      );
                      
                      await _supabaseService.addMenu(newMenu);
                      if (context.mounted) Navigator.pop(context);
                      _loadMenus();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // (Fungsi Edit dan Delete bisa disesuaikan dengan dropdown kategori yang sama seperti _showAddMenuDialog)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Manajemen Menu', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange[800],
      ),
      body: Column(
        children: [
          // SEARCH BAR & FILTER KATEGORI DI ATAS
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                // Kolom Pencarian
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama menu...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 10),
                // Tombol Kategori Chips / Tabs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['Semua', 'Makanan', 'Minuman'].map((cat) {
                    bool isActive = _selectedCategory == cat;
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        _filterMenus();
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
          
          // DAFTAR LIST MENU
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _filteredMenus.isEmpty 
                ? Center(child: Text('Menu tidak ditemukan.', style: GoogleFonts.poppins(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredMenus.length,
                    itemBuilder: (context, index) {
                      final menu = _filteredMenus[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),
                          leading: menu.imageUrl != null 
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(menu.imageUrl!, width: 60, height: 60, fit: BoxFit.cover),
                              )
                            : Container(
                                width: 60, height: 60,
                                decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.fastfood, color: Colors.orange),
                              ),
                          title: Text(menu.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rp ${menu.price.toStringAsFixed(0)}'),
                              const SizedBox(height: 4),
                              Chip(
                                label: Text(menu.category?.toUpperCase() ?? 'UMUM', style: const TextStyle(fontSize: 10)),
                                backgroundColor: Colors.orange[100],
                              )
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => {}, // Panggil _showEditMenuDialog(menu) disini
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => {}, // Panggil _confirmDelete(menu) disini
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
        onPressed: _showAddMenuDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}