import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/purchase_model.dart';
import '../models/purchase_item_model.dart';
import '../services/supabase_service.dart';
import 'add_purchase_screen.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  DateTime? _selectedFilterDate;

  String formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  // Mengambil data dan memfilter berdasarkan tanggal jika ada
  Stream<List<PurchaseModel>> _getFilteredPurchases() {
    return _supabaseService.getPurchasesStream().map((purchases) {
      if (_selectedFilterDate != null) {
        return purchases.where((p) {
          if (p.purchaseDate == null) return false;
          return p.purchaseDate!.year == _selectedFilterDate!.year &&
                 p.purchaseDate!.month == _selectedFilterDate!.month &&
                 p.purchaseDate!.day == _selectedFilterDate!.day;
        }).toList();
      }
      return purchases;
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedFilterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: Colors.orange.shade800)),
        child: child!,
      ),
    );
    if (pickedDate != null) setState(() => _selectedFilterDate = pickedDate);
  }

  // Memunculkan Detail Belanja (Rincian Item)
  void _showPurchaseDetail(PurchaseModel purchase) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  Text(purchase.notes ?? 'Belanja Bahan', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(purchase.purchaseDate != null ? DateFormat('dd MMM yyyy, HH:mm').format(purchase.purchaseDate!) : '-', style: GoogleFonts.poppins(color: Colors.grey)),
                  const Divider(height: 30, thickness: 1.5),
                  
                  Text('Rincian Pembelian:', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  
                  // Mengambil rincian item belanja
                  Expanded(
                    child: FutureBuilder<List<PurchaseItemModel>>(
                      future: _supabaseService.getPurchaseItems(purchase.id!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Tidak ada rincian.'));

                        final items = snapshot.data!;
                        return ListView.separated(
                          controller: scrollController,
                          itemCount: items.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange[50], shape: BoxShape.circle), child: Text('${item.quantity.toInt()}x', style: GoogleFonts.poppins(color: Colors.orange[800], fontWeight: FontWeight.bold))),
                              title: Text(item.ingredientName ?? 'Bahan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                              trailing: Text(formatCurrency(item.cost), style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Pengeluaran:', style: GoogleFonts.poppins(color: Colors.red[900])),
                        Text(formatCurrency(purchase.totalCost), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[900])),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Riwayat Pengeluaran', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange[800],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // FILTER TANGGAL
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Filter Tanggal', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                    Text(_selectedFilterDate == null ? 'Semua Tanggal' : DateFormat('dd MMM yyyy').format(_selectedFilterDate!), style: GoogleFonts.poppins(color: Colors.orange[800], fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    if (_selectedFilterDate != null)
                      IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => setState(() => _selectedFilterDate = null)),
                    ElevatedButton.icon(
                      onPressed: () => _pickDate(context),
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: Text('Pilih', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[50], foregroundColor: Colors.orange[800], elevation: 0),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // DAFTAR RIWAYAT
          Expanded(
            child: StreamBuilder<List<PurchaseModel>>(
              stream: _getFilteredPurchases(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('Belum ada riwayat belanja.', style: GoogleFonts.poppins()));

                final purchases = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: purchases.length,
                  itemBuilder: (context, index) {
                    final purchase = purchases[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _showPurchaseDetail(purchase),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(purchase.notes ?? 'Belanja', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(purchase.purchaseDate != null ? DateFormat('dd/MM/yyyy').format(purchase.purchaseDate!) : '-', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                                child: Text(formatCurrency(purchase.totalCost), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red[700])),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Tombol Tambah Belanja
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // 1. Gunakan 'await' untuk menunggu hasil dari halaman AddPurchaseScreen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPurchaseScreen()),
          );

          // 2. Jika result 'true' (artinya berhasil disimpan), paksa layar untuk refresh
          if (result == true) {
            setState(() {
              // setState kosong ini akan memicu StreamBuilder menarik data terbaru dari Supabase
            });
          }
        },
        backgroundColor: Colors.orange[800],
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: Text('Catat Belanja', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}