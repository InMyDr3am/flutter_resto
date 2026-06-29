import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/supabase_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  // Menyaring pesanan yang statusnya sudah 'paid' (berhasil dibayar)
  Stream<List<OrderModel>> _getPaidOrders() {
    return _supabaseService.getOrdersStream().map(
      (orders) => orders.where((order) => order.status == 'paid').toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan Lunas'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _getPaidOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada riwayat pesanan yang lunas.'));
          }

          final orders = snapshot.data!;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.assignment_turned_in, color: Colors.white),
                  ),
                  title: Text(
                    '${order.customerName} (Meja: ${order.tableNumber ?? "-"})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Total: Rp ${order.totalPrice.toStringAsFixed(0)} • ${order.paymentMethod?.toUpperCase() ?? "-"}'),
                  trailing: const Chip(
                    label: Text(
                      'LUNAS',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    backgroundColor: Colors.green,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}