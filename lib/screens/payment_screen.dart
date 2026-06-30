import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../services/supabase_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    ).format(amount);
  }

  // Mengambil daftar pesanan yang berstatus 'completed' (siap dibayar oleh kasir)
  Stream<List<OrderModel>> _getCompletedOrders() {
    return _supabaseService.getOrdersStream().map(
      (orders) => orders.where((order) => order.status == 'completed').toList(),
    );
  }

  // === ALUR BOTTOMSHEET: RINCIAN PESANAN LALU OPSI PEMBAYARAN ===
  void _showPaymentOptions(OrderModel order) {
    String selectedPaymentMethod = 'Cash'; 
    final cashController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Indikator Drag Bar
                      Center(
                        child: Container(
                          width: 40, height: 5, 
                          decoration: BoxDecoration(
                            color: Colors.grey[300], 
                            borderRadius: BorderRadius.circular(10)
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Header Nota
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.customerName, 
                                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[850])
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Meja : ${order.tableNumber ?? "-"}', 
                                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.orange[800], fontWeight: FontWeight.w600)
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Text(
                              'BELUM BAYAR',
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red[800]),
                            ),
                          ),
                        ],
                      ),
                      
                      const Divider(height: 32, thickness: 1.5, color: Color(0xFFEEEEEE)),
                      
                      Text('Rincian Pesanan:', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                      const SizedBox(height: 12),
                      
                      // Daftar Item Pesanan
                      Expanded(
                        child: FutureBuilder<List<OrderItemModel>>(
                          future: _supabaseService.getOrderItems(order.id!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(
                                child: Text('Tidak ada detail item.', style: GoogleFonts.poppins(color: Colors.grey))
                              );
                            }

                            final items = snapshot.data!;
                            return ListView.separated(
                              controller: scrollController,
                              itemCount: items.length,
                              separatorBuilder: (context, index) => const Divider(color: Color(0xFFF5F5F5)),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                bool hasnote = item.note != null && item.note!.isNotEmpty;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[50],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${item.quantity}x', 
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.orange[800], fontSize: 13),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.menuName ?? 'Menu Terhapus', 
                                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[850])
                                            ),
                                            if (hasnote) ...[
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.red[50],
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Catatan: ${item.note}', 
                                                  style: GoogleFonts.poppins(color: Colors.red[700], fontSize: 11, fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                            ]
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Total Tagihan
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Tagihan:', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                            Text(formatCurrency(order.totalPrice), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[800])),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Opsi Pembayaran (Cash / QRIS) Modern
                      Text('Metode Pembayaran:', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedPaymentMethod == 'Cash' 
                                      ? Colors.orange.shade800 
                                      : Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: selectedPaymentMethod == 'Cash' 
                                    ? Colors.orange.shade50.withOpacity(0.2) 
                                    : Colors.white,
                              ),
                              child: RadioListTile<String>(
                                value: 'Cash',
                                groupValue: selectedPaymentMethod,
                                title: Text('Cash', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                                secondary: const Icon(Icons.money, color: Colors.green),
                                activeColor: Colors.orange[800],
                                controlAffinity: ListTileControlAffinity.trailing,
                                onChanged: (value) {
                                  setStateDialog(() => selectedPaymentMethod = value!);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedPaymentMethod == 'QRIS' 
                                      ? Colors.orange.shade800 
                                      : Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: selectedPaymentMethod == 'QRIS' 
                                    ? Colors.orange.shade50.withOpacity(0.2) 
                                    : Colors.white,
                              ),
                              child: RadioListTile<String>(
                                value: 'QRIS',
                                groupValue: selectedPaymentMethod,
                                title: Text('QRIS', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                                secondary: const Icon(Icons.qr_code_2, color: Colors.blue),
                                activeColor: Colors.orange[800],
                                controlAffinity: ListTileControlAffinity.trailing,
                                onChanged: (value) {
                                  setStateDialog(() => selectedPaymentMethod = value!);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Input Jumlah Uang Cash (Hanya Tampil Jika Metode Cash)
                      if (selectedPaymentMethod == 'Cash') ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: cashController,
                          style: GoogleFonts.poppins(),
                          decoration: InputDecoration(
                            labelText: 'Jumlah Tunai Diterima',
                            labelStyle: GoogleFonts.poppins(fontSize: 13),
                            prefixText: 'Rp. ',
                            prefixStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      
                      const SizedBox(height: 24),

                      // Tombol Selesaikan Pembayaran
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            double change = 0.0;
                            if (selectedPaymentMethod == 'Cash') {
                              final cashReceived = double.tryParse(cashController.text) ?? 0.0;
                              change = cashReceived - order.totalPrice;
                              
                              if (change < 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Uang tunai kurang dari total tagihan!', style: GoogleFonts.poppins()), 
                                    backgroundColor: Colors.red
                                  ),
                                );
                                return;
                              }
                            }

                            // Proses pembayaran ke Supabase
                            await _supabaseService.completePayment(
                              order.id!, 
                              selectedPaymentMethod.toLowerCase(), 
                              change
                            );

                            if (context.mounted) {
                              Navigator.pop(context); // Tutup BottomSheet Utama

                              // Jika Cash, tampilkan pop-up rincian kembalian
                              if (selectedPaymentMethod == 'Cash') {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Kembalian', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                    content: Text('Uang Kembalian: ${formatCurrency(change)}', 
                                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800])),
                                    actions: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange[800],
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('OK', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                      )
                                    ],
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Pembayaran QRIS berhasil dicatat!', style: GoogleFonts.poppins()),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('Selesaikan Pembayaran', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                );
              });
            },
          );
        },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Background terang modern
      appBar: AppBar(
        title: Text(
          'Antrean Pembayaran (Kasir)',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.orange[800],
        elevation: 0,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _getCompletedOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}', style: GoogleFonts.poppins()));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('Tidak ada pesanan yang menunggu pembayaran.', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          final orders = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              
              // Kartu antrean pembayaran modern berkontur merah/oranye
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _showPaymentOptions(order),
                  child: Row(
                    children: [
                      // Garis aksen merah sisi kiri kartu
                      Container(
                        width: 8,
                        height: 85,
                        color: Colors.red[800],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    order.customerName,
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.grey[850]),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.table_restaurant, size: 14, color: Colors.orange[800]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Meja ${order.tableNumber ?? "-"}',
                                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(Icons.payments, size: 14, color: Colors.red[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        formatCurrency(order.totalPrice),
                                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.red[700], fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              
                              // Tombol Badge Kapsul Belum Bayar
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                                ),
                                child: Text(
                                  'BELUM\nBAYAR',
                                  style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red[800], height: 1),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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