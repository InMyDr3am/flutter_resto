import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../services/supabase_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    ).format(amount);
  }

  Stream<List<OrderModel>> _getPaidOrders() {
    return _supabaseService.getOrdersStream().map(
      (orders) => orders.where((order) => order.status == 'paid').toList(),
    );
  }

  // === DIPERBARUI: MENAMPILKAN METODE PEMBAYARAN & CATATAN PADA RIWAYAT ===
  void _showOrderHistoryDetail(OrderModel order) {
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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.green[700], fontWeight: FontWeight.w600)
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Text(
                          'LUNAS',
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green[800]),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32, thickness: 1.5, color: Color(0xFFEEEEEE)),
                  
                  Text('Item Dibeli:', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                  const SizedBox(height: 12),
                  
                  // Rincian Item (Ditambah Tampilan Catatan/note)
                  Expanded(
                    child: FutureBuilder<List<OrderItemModel>>(
                      future: _supabaseService.getOrderItems(order.id!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Text('Tidak ada rincian item.', style: GoogleFonts.poppins(color: Colors.grey))
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
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                                    child: Text('${item.quantity}x', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.green[800])),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.menuName ?? 'Menu Terhapus', 
                                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[850])
                                        ),
                                        // Tampilkan Note Spesifik per Item Jika Ada
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
                                        ],
                                      ],
                                    ),
                                  ),
                                  Text(
                                    formatCurrency(item.price * item.quantity),
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey[700], fontSize: 13),
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
                  
                  // Total Tagihan & Ikon Metode Pembayaran
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Pembayaran:', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                            Text(formatCurrency(order.totalPrice), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800])),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Metode Bayar:', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                            Row(
                              children: [
                                Icon(
                                  order.paymentMethod?.toLowerCase() == 'qris' ? Icons.qr_code_2 : Icons.money, 
                                  size: 16, 
                                  color: Colors.orange[800],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  order.paymentMethod?.toUpperCase() ?? '-',
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[850]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Riwayat Pesanan Lunas',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.orange[800],
        elevation: 0,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _getPaidOrders(),
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
                  Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('Belum ada riwayat pesanan yang lunas.', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
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
              
              // Kartu Riwayat Bersih Modern dengan Aksen Hijau
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _showOrderHistoryDetail(order),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 85,
                        color: Colors.green[700],
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
                                      Icon(Icons.payments, size: 14, color: Colors.green[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        formatCurrency(order.totalPrice),
                                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(width: 12),
                                      // Tampilkan Ikon Metode Bayar Kecil di List Utama
                                      Icon(
                                        order.paymentMethod?.toLowerCase() == 'qris' ? Icons.qr_code_2 : Icons.money, 
                                        size: 14, 
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        order.paymentMethod?.toUpperCase() ?? '-',
                                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                                ),
                                child: Text(
                                  'LUNAS',
                                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green[800]),
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