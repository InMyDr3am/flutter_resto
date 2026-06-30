import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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

  // Fungsi pembantu format mata uang
  String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    ).format(amount);
  }

  // Fungsi untuk memunculkan detail pesanan saat diklik (Gaya BottomSheet Modern)
  void _showOrderDetails(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Transparan untuk efek rounded modern
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
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
                  // Indikator Drag Bar Minimalis
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
                  
                  // Header Rincian Pesanan
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
                              'Nomor Meja : ${order.tableNumber ?? "-"}', 
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.orange[800], fontWeight: FontWeight.w600)
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          order.status.toUpperCase(),
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange[800]),
                        ),
                      ),
                    ],
                  ),
                  
                  const Divider(height: 32, thickness: 1.5, color: Color(0xFFEEEEEE)),
                  
                  Text('Daftar Pesanan:', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                  const SizedBox(height: 12),
                  
                  // Menampilkan daftar item menggunakan FutureBuilder
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
                                  // Badge Kuantitas Modern
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
                                  // Rincian Menu dan Catatan
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
                  
                  // Total Harga di Bawah
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
                  
                  const SizedBox(height: 16),

                  // Tombol Aksi untuk Koki / Dapur
                  if (order.status != 'completed')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await _supabaseService.updateOrderStatus(order.id!, 'completed');
                          if (context.mounted) Navigator.pop(context); 
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Tandai Selesai Disajikan', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
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
      backgroundColor: Colors.grey[100], // Latar belakang abu-abu terang menonjolkan kartu
      appBar: AppBar(
        title: Text(
          'Pesanan Masuk (Live)',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.orange[800],
        elevation: 0,
        centerTitle: false,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _supabaseService.getOrdersStream().map(
              (orders) => orders.where((order) => order.status == 'pending').toList(),
            ),
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
                  Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('Belum ada pesanan masuk hari ini.', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
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
              
              // Kartu Pesanan Bergaya Modern dengan Efek Visual Bersih
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _showOrderDetails(order),
                  child: Row(
                    children: [
                      // Garis Aksen Oranye Vertikal di Sisi Kiri Kartu
                      Container(
                        width: 8,
                        height: 85,
                        color: Colors.orange[800],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Kiri: Nama & Meja Pelanggan
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
                                      Icon(Icons.payments, size: 14, color: Colors.green[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        formatCurrency(order.totalPrice),
                                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              
                              // Kanan: Kapsul Badge Status PENDING
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  'PENDING',
                                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange[800]),
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