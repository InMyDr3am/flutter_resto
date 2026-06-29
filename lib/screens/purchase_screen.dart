import 'package:flutter/material.dart';
import '../models/purchase_model.dart';
import '../services/supabase_service.dart';
import 'add_purchase_screen.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<PurchaseModel>> _purchasesFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _purchasesFuture = _supabaseService.getPurchases();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pengeluaran Belanja'), backgroundColor: Colors.orange),
      body: FutureBuilder<List<PurchaseModel>>(
        future: _purchasesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada riwayat belanja.'));
          }

          final purchases = snapshot.data!;
          return ListView.builder(
            itemCount: purchases.length,
            itemBuilder: (context, index) {
              final p = purchases[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.shopping_bag, color: Colors.orange),
                  title: Text(p.notes ?? 'Belanja Bahan Baku'),
                  subtitle: Text('${p.purchaseDate.day}/${p.purchaseDate.month}/${p.purchaseDate.year}'),
                  trailing: Text('Rp ${p.totalCost.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () async {
          // Buka form tambah belanja dan tunggu hasilnya
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPurchaseScreen()),
          );
          // Jika sukses simpan data, memuat ulang halaman utama riwayat
          if (result == true) _refreshData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}