import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  void _refreshData() {
    setState(() {
      _menusFuture = _supabaseService.getMenus();
    });
  }

  // === FUNGSI CREATE / TAMBAH MENU ===
  void _showAddMenuDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    File? selectedImage; 

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Tambah Menu Baru'),
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
                      if (selectedImage != null) {
                        imageUrl = await _supabaseService.uploadMenuImage(selectedImage!);
                      }

                      final newMenu = MenuModel(
                        name: nameController.text,
                        price: double.parse(priceController.text),
                        imageUrl: imageUrl, 
                      );
                      
                      await _supabaseService.addMenu(newMenu);
                      if (context.mounted) Navigator.pop(context);
                      _refreshData();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // === FUNGSI EDIT / UPDATE MENU (DENGAN GAMBAR) ===
  void _showEditMenuDialog(MenuModel menu) {
    final nameController = TextEditingController(text: menu.name);
    final priceController = TextEditingController(text: menu.price.toStringAsFixed(0));
    
    File? newSelectedImage; // Menyimpan file gambar baru jika kasir mengganti foto
    String? currentImageUrl = menu.imageUrl; // Menyimpan URL gambar lama (bisa null atau ada isinya)

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit Menu'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Preview Gambar Saat Edit
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setStateDialog(() {
                            newSelectedImage = File(pickedFile.path);
                            currentImageUrl = null; // Menimpa gambar lama dengan gambar lokal baru
                          });
                        }
                      },
                      child: Container(
                        height: 150, width: double.infinity,
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                        child: newSelectedImage != null
                            ? Image.file(newSelectedImage!, fit: BoxFit.cover)
                            : (currentImageUrl != null
                                ? Image.network(currentImageUrl!, fit: BoxFit.cover)
                                : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey)),
                      ),
                    ),
                    // Tombol Hapus Gambar (opsional jika ingin menghilangkan gambar dari menu)
                    if (currentImageUrl != null || newSelectedImage != null)
                      TextButton(
                        onPressed: () => setStateDialog(() {
                          newSelectedImage = null;
                          currentImageUrl = null;
                        }),
                        child: const Text('Hapus Gambar', style: TextStyle(color: Colors.red)),
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
                      String? finalImageUrl = currentImageUrl;

                      // Jika user mengunggah foto baru dari galeri, upload ke storage
                      if (newSelectedImage != null) {
                        finalImageUrl = await _supabaseService.uploadMenuImage(newSelectedImage!);
                      }

                      final updatedMenu = MenuModel(
                        id: menu.id, // ID wajib diisi agar Supabase tahu data mana yang di-update
                        name: nameController.text,
                        price: double.parse(priceController.text),
                        imageUrl: finalImageUrl, // Null jika dihapus, atau string link gambar
                      );

                      await _supabaseService.updateMenu(updatedMenu);
                      if (context.mounted) Navigator.pop(context);
                      _refreshData();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  child: const Text('Perbarui'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // === FUNGSI DELETE / HAPUS MENU ===
  void _confirmDelete(MenuModel menu) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Menu'),
        content: Text('Anda yakin ingin menghapus ${menu.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              await _supabaseService.deleteMenu(menu.id!);
              if (context.mounted) Navigator.pop(context);
              _refreshData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Menu Restoran'),
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
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                elevation: 2,
                child: ListTile(
                  leading: menu.imageUrl != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          menu.imageUrl!, 
                          width: 50, 
                          height: 50, 
                          fit: BoxFit.cover
                        ),
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.fastfood, color: Colors.orange),
                      ),
                  title: Text(menu.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Rp ${menu.price.toStringAsFixed(0)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditMenuDialog(menu),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(menu),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        onPressed: _showAddMenuDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}