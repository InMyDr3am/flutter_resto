import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/supabase_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  // Mengambil daftar pesanan yang berstatus 'completed' (siap dibayar oleh kasir)
  Stream<List<OrderModel>> _getCompletedOrders() {
    return _supabaseService.getOrdersStream().map(
      (orders) => orders.where((order) => order.status == 'completed').toList(),
    );
  }

  void _showPaymentDialog(OrderModel order) {
    String selectedMethod = 'cash';
    final cashController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Pembayaran: ${order.customerName}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Tagihan: Rp ${order.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                    const SizedBox(height: 20),
                    const Text('Pilih Metode Pembayaran:'),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Cash'),
                            value: 'cash',
                            groupValue: selectedMethod,
                            onChanged: (val) => setStateDialog(() => selectedMethod = val!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('QRIS'),
                            value: 'qris',
                            groupValue: selectedMethod,
                            onChanged: (val) => setStateDialog(() => selectedMethod = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (selectedMethod == 'cash') ...[
                      TextField(
                        controller: cashController,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah Uang Tunai Diterima',
                          prefixText: 'Rp ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    double change = 0.0;
                    if (selectedMethod == 'cash') {
                      final cashReceived = double.tryParse(cashController.text) ?? 0.0;
                      change = cashReceived - order.totalPrice;
                      
                      if (change < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Uang tunai kurang dari total tagihan!'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                    }

                    // Proses pembayaran ke Supabase
                    await _supabaseService.completePayment(
                      order.id!, 
                      selectedMethod, 
                      change
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      
                      // Tampilkan informasi kembalian jika metode cash
                      if (selectedMethod == 'cash') {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Kembalian'),
                            content: Text('Uang Kembalian: Rp ${change.toStringAsFixed(0)}', 
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            actions: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              )
                            ],
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pembayaran QRIS berhasil dicatat!')),
                        );
                      }
                    }
                  },
                  // === PEMBARUAN GAYA TOMBOL DI SINI ===
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[800], // Oranye gelap yang solid & elegan
                    foregroundColor: Colors.white,      // Teks putih bersih agar sangat kontras dan mudah dibaca
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Membuat sudut sedikit membulat agar rapi
                    ),
                  ),
                  child: const Text(
                    'Selesaikan Pembayaran', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
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
        title: const Text('Antrean Pembayaran (Kasir)'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _getCompletedOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada pesanan yang menunggu pembayaran.'));
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
                    child: Icon(Icons.payment, color: Colors.white),
                  ),
                  title: Text(
                    '${order.customerName} (Meja: ${order.tableNumber ?? "-"})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Total Tagihan: Rp ${order.totalPrice.toStringAsFixed(0)}'),
                  trailing: const Chip(
                    label: Text(
                      'BELUM BAYAR',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 17, 5, 4)),
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                  onTap: () => _showPaymentDialog(order),
                ),
              );
            },
          );
        },
      ),
    );
  }
}