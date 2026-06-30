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
  
  // Variabel penampung filter tanggal
  DateTime? _selectedDate;

  String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    ).format(amount);
  }

  // Format tanggal untuk ditampilkan rapi ke layar
  String formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd-MM-yyyy').format(date);
  }

  // Mengambil pesanan berstatus 'completed' dan memfilternya berdasarkan tanggal (jika dipilih)
  Stream<List<OrderModel>> _getPaidOrders() {
    return _supabaseService.getOrdersStream().map((orders) {
      // 1. Saring status completed
      var filtered = orders.where((order) => order.status == 'paid').toList();

      // 2. Saring berdasarkan tanggal (jika user memilih tanggal)
      if (_selectedDate != null) {
        filtered = filtered.where((order) {
          if (order.createdAt == null) return false;
          // Ambil tanggalnya saja (abaikan jam/menit/detik)
          DateTime orderDate = DateTime(
            order.createdAt!.year,
            order.createdAt!.month,
            order.createdAt!.day,
          );
          DateTime filterDate = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
          );
          return orderDate.isAtSameMomentAs(filterDate);
        }).toList();
      }
      return filtered;
    });
  }

  // Fungsi pemilih tanggal (Date Picker)
  Future<void> _pickDate(BuildContext context) async {
    final initialDate = _selectedDate ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade800, // Warna tema orange
              onPrimary: Colors.white,
              onSurface: Colors.grey.shade800,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

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
                            const SizedBox(height: 2),
                            // Tampilkan waktu/tanggal pesanan dibuat di detail
                            Text(
                              'Waktu Pesan: ${order.createdAt != null ? DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt!) : "-"}', 
                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])
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
      body: Column(
        children: [
          // === FILTER / PEMILIH TANGGAL MODERN ===
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Tanggal Riwayat', 
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedDate == null 
                          ? 'Menampilkan Semua Tanggal' 
                          : 'Tanggal: ${formatDate(_selectedDate)}',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange[800], fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_selectedDate != null) ...[
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _selectedDate = null; // Reset filter (tampilkan semua)
                          });
                        },
                      ),
                    ],
                    ElevatedButton.icon(
                      onPressed: () => _pickDate(context),
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: Text('Pilih', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[50],
                        foregroundColor: Colors.orange[800],
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // === STREAM BUILDER RIWAYAT ===
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
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
                        Text('Belum ada riwayat pesanan lunas untuk tanggal ini.', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center,),
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
          ),
        ],
      ),
    );
  }
}