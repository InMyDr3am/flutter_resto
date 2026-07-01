import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  final _qtyController = TextEditingController();
  final _costController = TextEditingController();
  TextEditingController? _searchFieldController;
  
  List<IngredientModel> _availableIngredients = [];
  final List<PurchaseItemModel> _tempItems = [];
  IngredientModel? _selectedIngredient;
  bool _isLoading = false;

  // Variabel untuk menyimpan tanggal belanja
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  void _loadIngredients() async {
    final data = await _supabaseService.getIngredients();
    if (mounted) setState(() => _availableIngredients = data);
  }

  String formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  // Fungsi untuk memilih tanggal belanja
  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // Tidak bisa pilih tanggal masa depan
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.orange.shade800),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  void _addItemToList() {
    if (_selectedIngredient == null || _qtyController.text.isEmpty || _costController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi semua data item!'), backgroundColor: Colors.red));
      return;
    }

    setState(() {
      _tempItems.add(
        PurchaseItemModel(
          ingredientId: _selectedIngredient!.id,
          ingredientName: _selectedIngredient!.name,
          quantity: double.tryParse(_qtyController.text) ?? 0,
          cost: double.tryParse(_costController.text) ?? 0,
        ),
      );
      _qtyController.clear();
      _costController.clear();
      _selectedIngredient = null;
      if (_searchFieldController != null) _searchFieldController!.clear();
    });
  }

  double get _totalNota => _tempItems.fold(0, (sum, item) => sum + item.cost);

  void _savePurchase() async {
    if (_tempItems.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      // 1. Ambil waktu saat ini (jam, menit, detik)
      final now = DateTime.now();
      
      // 2. Gabungkan tanggal dari kalender dengan waktu saat ini
      final exactDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        now.hour,
        now.minute,
        now.second,
      );

      final newPurchase = PurchaseModel(
        totalCost: _totalNota,
        notes: _notesController.text.isEmpty ? 'Belanja Bahan Baku' : _notesController.text,
        purchaseDate: exactDateTime, // Gunakan waktu yang sudah sangat presisi
      );

      await _supabaseService.createPurchase(newPurchase, _tempItems);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Belanjaan berhasil disimpan!', style: GoogleFonts.poppins()), 
            backgroundColor: Colors.green
          )
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Input Nota Belanja', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange[800],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // BAGIAN ATAS: TOKO & TANGGAL
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _notesController,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    labelText: 'Nama Toko / Keterangan',
                    prefixIcon: Icon(Icons.storefront, color: Colors.orange[800]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _pickDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_month, color: Colors.orange[800]),
                            const SizedBox(width: 12),
                            Text('Tanggal Belanja:', style: GoogleFonts.poppins(color: Colors.grey[700])),
                          ],
                        ),
                        Text(DateFormat('dd MMM yyyy').format(_selectedDate), style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // BAGIAN INPUT ITEM
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tambah Bahan Baku', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Autocomplete<IngredientModel>(
                    displayStringForOption: (option) => option.name,
                    optionsBuilder: (value) {
                      if (value.text.isEmpty) return const Iterable<IngredientModel>.empty();
                      return _availableIngredients.where((ing) => ing.name.toLowerCase().contains(value.text.toLowerCase()));
                    },
                    onSelected: (selection) => setState(() => _selectedIngredient = selection),
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      _searchFieldController = controller;
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: GoogleFonts.poppins(),
                        decoration: InputDecoration(
                          hintText: 'Cari nama bahan baku...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _qtyController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Qty', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: TextField(controller: _costController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Harga (Rp)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
                      const SizedBox(width: 8),
                      IconButton(icon: Icon(Icons.add_box, color: Colors.orange[800], size: 36), onPressed: _addItemToList),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // DAFTAR ITEM SEMENTARA
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tempItems.length,
              itemBuilder: (context, index) {
                final item = _tempItems[index];
                return Card(
                  child: ListTile(
                    title: Text(item.ingredientName ?? 'Bahan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: Text('Qty: ${item.quantity.toInt()}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(formatCurrency(item.cost), style: GoogleFonts.poppins(color: Colors.red[700], fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _tempItems.removeAt(index))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // FOOTER SIMPAN
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Belanja:', style: GoogleFonts.poppins(fontSize: 14)),
                    Text(formatCurrency(_totalNota), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red[700])),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_tempItems.isEmpty || _isLoading) ? null : _savePurchase,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text('Simpan Transaksi', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}