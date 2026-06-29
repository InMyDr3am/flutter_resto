import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../services/supabase_service.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  // Fungsi untuk memunculkan detail pesanan saat diklik
  void _showOrderDetails(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 16),
                  Text('Pesanan: ${order.customerName}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Meja: ${order.tableNumber ?? "-"} | Status: ${order.status.toUpperCase()}'),
                  const Divider(height: 30, thickness: 2),
                  const Text('Daftar Makanan:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  // Menampilkan daftar item menggunakan FutureBuilder
                  Expanded(
                    child: FutureBuilder<List<OrderItemModel>>(
                      future: _supabaseService.getOrderItems(order.id!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('Tidak ada detail item.'));
                        }

                        final items = snapshot.data!;
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.orange[100], shape: BoxShape.circle),
                                child: Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                              ),
                              title: Text(item.menuName ?? 'Menu Terhapus', style: const TextStyle(fontSize: 18)),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  
                  // Tombol Aksi untuk Koki / Dapur
                  if (order.status != 'completed')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Ubah status menjadi completed
                          await _supabaseService.updateOrderStatus(order.id!, 'completed');
                          if (context.mounted) Navigator.pop(context); // Tutup popup
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Tandai Selesai Disajikan', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),
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
      appBar: AppBar(
        title: const Text('Pesanan Masuk (Live)'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<List<OrderModel>>(
        // PERUBAHAN DI SINI: Ditambahkan .map untuk menyaring status 'pending' saja
        stream: _supabaseService.getOrdersStream().map(
              (orders) => orders.where((order) => order.status == 'pending').toList(),
            ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada pesanan masuk hari ini.'));
          }

          final orders = snapshot.data!;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
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
                  trailing: const Chip(
                    label: Text(
                      'PENDING',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.orangeAccent,
                  ),
                  onTap: () => _showOrderDetails(order),
                ),
              );
            },
          );
        },
      ),
    );
  }
}