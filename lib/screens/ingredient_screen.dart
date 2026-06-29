import 'package:flutter/material.dart';
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

  void _showAddIngredientDialog() {
    final nameController = TextEditingController();
    final unitController = TextEditingController();
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Bahan Baku Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Bahan Baku'),
              ),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Satuan (cth: kg, gram, liter)'),
              ),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Stok Awal'),
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
                if (nameController.text.isNotEmpty && unitController.text.isNotEmpty) {
                  final newIngredient = IngredientModel(
                    name: nameController.text,
                    unit: unitController.text,
                    stock: double.tryParse(stockController.text) ?? 0.0,
                  );
                  
                  await _supabaseService.addIngredient(newIngredient);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stok Bahan Baku'),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<List<IngredientModel>>(
        future: _ingredientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada data bahan baku.'));
          }

          final ingredients = snapshot.data!;
          return ListView.builder(
            itemCount: ingredients.length,
            itemBuilder: (context, index) {
              final item = ingredients[index];
              return ListTile(
                leading: const Icon(Icons.inventory, color: Colors.orange),
                title: Text(item.name),
                trailing: Text(
                  '${item.stock} ${item.unit}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddIngredientDialog,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}