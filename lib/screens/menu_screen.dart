import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/menu_model.dart';
import '../services/supabase_service.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<MenuModel>> _menusFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // Fungsi untuk memuat ulang data dari database
  void _refreshData() {
    setState(() {
      _menusFuture = _supabaseService.getMenus();
    });
  }

  // Fungsi untuk menampilkan form tambah menu
  void _showAddMenuDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    File? selectedImage; // Variabel penampung file gambar

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Agar UI dialog bisa refresh saat foto dipilih
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Tambah Menu Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tampilan preview gambar
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setStateDialog(() => selectedImage = File(pickedFile.path));
                        }
                      },
                      child: Container(
                        height: 150, width: double.infinity,
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                        child: selectedImage == null 
                          ? const Icon(Icons.add_a_photo, size: 50, color: Colors.grey)
                          : Image.file(selectedImage!, fit: BoxFit.cover),
                      ),
                    ),
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Menu')),
                    TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Harga'), keyboardType: TextInputType.number),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                      String? imageUrl;
                      
                      // Jika user pilih gambar, upload dulu ke Supabase Storage
                      if (selectedImage != null) {
                        imageUrl = await _supabaseService.uploadMenuImage(selectedImage!);
                      }

                      final newMenu = MenuModel(
                        name: nameController.text,
                        price: double.parse(priceController.text),
                        imageUrl: imageUrl, // Masukkan URL gambar ke Database
                      );
                      
                      await _supabaseService.addMenu(newMenu);
                      if (context.mounted) Navigator.pop(context);
                      _refreshData();
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Menu'),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<List<MenuModel>>(
        future: _menusFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada data menu.'));
          }

          final menus = snapshot.data!;
          return ListView.builder(
            itemCount: menus.length,
            itemBuilder: (context, index) {
              final menu = menus[index];
              return ListTile(
                leading: menu.imageUrl != null 
                  ? Image.network(menu.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                  : const Icon(Icons.fastfood, color: Colors.orange),
                title: Text(menu.name),
                subtitle: Text('Rp ${menu.price.toStringAsFixed(0)}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMenuDialog,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}