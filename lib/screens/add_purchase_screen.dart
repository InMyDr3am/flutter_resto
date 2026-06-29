import 'package:flutter/material.dart';
import '../models/ingredient_model.dart';
import '../models/purchase_model.dart';
import '../models/purchase_item_model.dart';
import '../services/supabase_service.dart';

class AddPurchaseScreen extends StatefulWidget {
  const AddPurchaseScreen({super.key});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final _notesController = TextEditingController();
  
  List<IngredientModel> _availableIngredients = [];
  final List<PurchaseItemModel> _tempItems = [];
  
  IngredientModel? _selectedIngredient;
  final _qtyController = TextEditingController();
  final _costController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  // Mengambil daftar bahan baku yang terdaftar untuk opsi Dropdown
  void _loadIngredients() async {
    final data = await _supabaseService.getIngredients();
    setState(() {
      _availableIngredients = data;
    });
  }

  // Menambahkan item bahan baku ke daftar sementara di aplikasi
  void _addItemToList() {
    if (_selectedIngredient == null || _qtyController.text.isEmpty || _costController.text.isEmpty) return;

    setState(() {
      _tempItems.add(
        PurchaseItemModel(
          ingredientId: _selectedIngredient!.id!,
          ingredientName: _selectedIngredient!.name,
          quantity: double.parse(_qtyController.text),
          cost: double.parse(_costController.text),
        ),
      );
      // Reset input item setelah ditambah
      _qtyController.clear();
      _costController.clear();
      _selectedIngredient = null;
    });
  }

  // Menghitung total keseluruhan nota
  double get _totalNota => _tempItems.fold(0, (sum, item) => sum + item.cost);

  // Menyimpan Nota beserta detailnya ke Supabase
  void _savePurchase() async {
    if (_tempItems.isEmpty) return;

    final newPurchase = PurchaseModel(
      totalCost: _totalNota,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      purchaseDate: DateTime.now(),
    );

    await _supabaseService.createPurchase(newPurchase, _tempItems);
    if (context.mounted) {
      Navigator.pop(context, true); // Kembali ke halaman riwayat dengan sinyal 'true' (sukses)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Nota Belanja'), backgroundColor: Colors.orange),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Catatan Nota (cth: Toko Makmur / Belanja Bulanan)'),
            ),
            const Divider(height: 30),
            
            // FORM INPUT ITEM BAHAN BAKU
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButton<IngredientModel>(
                    hint: const Text('Pilih Bahan'),
                    value: _selectedIngredient,
                    items: _availableIngredients.map((ing) {
                      return DropdownMenuItem(value: ing, child: Text(ing.name));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedIngredient = val),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _qtyController,
                    decoration: const InputDecoration(labelText: 'Jumlah'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _costController,
                    decoration: const InputDecoration(labelText: 'Total Harga'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_box, color: Colors.orange, size: 30),
                  onPressed: _addItemToList,
                )
              ],
            ),
            const SizedBox(height: 20),
            
            // DAFTAR ITEM YANG AKAN DIBELI
            Expanded(
              child: ListView.builder(
                itemCount: _tempItems.length,
                itemBuilder: (context, index) {
                  final item = _tempItems[index];
                  return ListTile(
                    title: Text(item.ingredientName ?? 'Bahan'),
                    subtitle: Text('Qty: ${item.quantity}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Rp ${item.cost.toStringAsFixed(0)}'),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => _tempItems.removeAt(index)),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // TOMBOL SIMPAN
            Container(
              padding: const EdgeInsets.only(top: 10),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _tempItems.isEmpty ? null : _savePurchase,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text('Simpan Belanja - Rp ${_totalNota.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}