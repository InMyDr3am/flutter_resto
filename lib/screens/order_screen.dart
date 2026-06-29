import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/supabase_service.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Masuk (Live)'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _supabaseService.getOrdersStream(),
        builder: (context, snapshot) {
          // Menampilkan loading saat sedang menyambungkan data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          // Menampilkan error jika ada masalah koneksi
          else if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          } 
          // Menampilkan pesan kosong jika belum ada pesanan
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada pesanan masuk hari ini.'));
          }

          final orders = snapshot.data!;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.receipt, color: Colors.white),
                  ),
                  title: Text(
                    '${order.customerName} (Meja: ${order.tableNumber ?? "-"})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Total: Rp ${order.totalPrice.toStringAsFixed(0)}'),
                  trailing: Chip(
                    label: Text(
                      order.status.toUpperCase(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    // Warna chip berubah sesuai status pesanan
                    backgroundColor: order.status == 'pending' ? Colors.red[100] : Colors.green[100],
                  ),
                  onTap: () {
                    // Nanti kita tambahkan fitur klik untuk melihat detail item pesanannya
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}