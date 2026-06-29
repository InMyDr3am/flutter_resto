import 'package:flutter/material.dart';
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Menu Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Menu'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Harga (Rp)'),
                keyboardType: TextInputType.number,
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
                if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                  final newMenu = MenuModel(
                    name: nameController.text,
                    price: double.parse(priceController.text),
                  );
                  
                  await _supabaseService.addMenu(newMenu);
                  if (context.mounted) Navigator.pop(context);
                  _refreshData(); // Refresh layar setelah berhasil ditambah
                }
              },
              child: const Text('Simpan'),
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
                leading: const Icon(Icons.fastfood, color: Colors.orange),
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