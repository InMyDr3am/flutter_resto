import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ingredient_model.dart';
import '../services/supabase_service.dart';

class IngredientScreen extends StatefulWidget {
  const IngredientScreen({super.key});

  @override
  State<IngredientScreen> createState() => _IngredientScreenState();
}

class _IngredientScreenState extends State<IngredientScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<IngredientModel>> _ingredientsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _ingredientsFuture = _supabaseService.getIngredients();
    });
  }

  // === DIALOG UNTUK TAMBAH ATAU EDIT BAHAN BAKU ===
  void _showIngredientDialog({IngredientModel? ingredient}) {
    final nameController = TextEditingController(text: ingredient?.name ?? '');
    final unitController = TextEditingController(text: ingredient?.unit ?? '');
    final stockController = TextEditingController(text: ingredient?.stock.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(ingredient == null ? 'Tambah Bahan Baku' : 'Edit Bahan Baku', 
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Bahan')),
              TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Satuan (kg, gram, liter)')),
              TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Stok'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final data = IngredientModel(
                  id: ingredient?.id,
                  name: nameController.text,
                  unit: unitController.text,
                  stock: double.tryParse(stockController.text) ?? 0.0,
                );

                if (ingredient == null) {
                  await _supabaseService.addIngredient(data);
                } else {
                  await _supabaseService.updateIngredient(data);
                }
                if (context.mounted) Navigator.pop(context);
                _refreshData();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // === FUNGSI DELETE ===
  void _deleteIngredient(String? id) async {
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus bahan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _supabaseService.deleteIngredient(id);
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Stok Bahan Baku', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange[800],
        elevation: 0,
      ),
      body: FutureBuilder<List<IngredientModel>>(
        future: _ingredientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Data kosong.'));

          final ingredients = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: ingredients.length,
            itemBuilder: (context, index) {
              final item = ingredients[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.orange[50], child: Icon(Icons.inventory_2, color: Colors.orange[800])),
                  title: Text(item.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text('${item.stock} ${item.unit}', style: GoogleFonts.poppins()),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _showIngredientDialog(ingredient: item); // <--- Pastikan 'item' ini sudah memuat id
                      else if (value == 'delete') _deleteIngredient(item.id!); // <--- Pastikan 'item.id' ini tidak null
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
                      const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Hapus'))),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showIngredientDialog(),
        backgroundColor: Colors.orange[800],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}