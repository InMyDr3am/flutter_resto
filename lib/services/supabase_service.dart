import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io'; 
import 'package:flutter/material.dart';
import '../models/menu_model.dart';
import '../models/ingredient_model.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../models/purchase_model.dart';
import '../models/purchase_item_model.dart';

class SupabaseService {
  // Mengambil instance client Supabase yang sudah diinisialisasi di main.dart
  final SupabaseClient _client = Supabase.instance.client;

  // ================= FUNGSI UNTUK MENU =================
  
  // 1. Mengambil semua daftar menu dari database
  Future<List<MenuModel>> getMenus() async {
    try {
      final response = await _client
          .from('menus')
          .select()
          .order('name', ascending: true); // Diurutkan berdasarkan nama A-Z
      
      return (response as List).map((json) => MenuModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data menu: $e');
    }
  }

  // 2. Menambah menu baru ke database
  Future<void> addMenu(MenuModel menu) async {
    try {
      await _client.from('menus').insert(menu.toJson());
    } catch (e) {
      throw Exception('Gagal menambah menu: $e');
    }
  }

  // 3. Fungsi untuk upload gambar ke Storage dan ambil URL-nya
  Future<String> uploadMenuImage(File imageFile) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString(); // Nama file unik
      final path = 'public/$fileName.jpg';

      await _client.storage.from('menu-images').upload(path, imageFile);

      // Ambil URL publik gambar yang baru diupload
      final String publicUrl = _client.storage.from('menu-images').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw Exception('Gagal upload gambar: $e');
    }
  }

  // ================= FUNGSI UNTUK BAHAN BAKU (INGREDIENTS) =================

  // 1. Mengambil semua daftar bahan baku dari database
  Future<List<IngredientModel>> getIngredients() async {
    try {
      final response = await _client
          .from('ingredients')
          .select()
          .order('name', ascending: true);
      
      return (response as List).map((json) => IngredientModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data bahan baku: $e');
    }
  }

  // 2. Menambah bahan baku baru ke database
  Future<void> addIngredient(IngredientModel ingredient) async {
    try {
      await _client.from('ingredients').insert(ingredient.toJson());
    } catch (e) {
      throw Exception('Gagal menambah bahan baku: $e');
    }
  }

  // 3. Fungsi untuk memperbarui data bahan baku
  Future<void> updateIngredient(IngredientModel ingredient) async {
    try {
      await _client.from('ingredients') // Sesuaikan dengan nama tabel Anda di Supabase
          .update({
            'name': ingredient.name,
            'unit': ingredient.unit,
            'stock': ingredient.stock,
          })
          .eq('id', ingredient.id!); // Mencocokkan berdasarkan ID
    } catch (e) {
      throw Exception('Gagal memperbarui bahan baku: $e');
    }
  }

  // 4. Fungsi untuk menghapus data bahan baku
  Future<void> deleteIngredient(String id) async {
    try {
      await _client
          .from('ingredients')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Gagal menghapus bahan baku: $e');
    }
  }


  // ================= FUNGSI UNTUK PESANAN (ORDERS) =================

  // 1. Fungsi untuk membuat pesanan baru beserta rincian itemnya
  Future<void> createOrder(OrderModel order, List<OrderItemModel> items) async {
    try {
      // Langkah A: Masukkan data nota utama ke tabel 'orders' dan ambil ID-nya
      final orderResponse = await _client
          .from('orders')
          .insert(order.toJson())
          .select()
          .single();
      
      final String orderId = orderResponse['id'];

      // Langkah B: Pasangkan orderId yang baru saja dibuat ke setiap item makanan yang dipesan
      final itemsJson = items.map((item) {
        final json = item.toJson();
        json['order_id'] = orderId;
        return json;
      }).toList();

      // Langkah C: Masukkan semua item sekaligus (Bulk Insert) ke tabel 'order_items'
      await _client.from('order_items').insert(itemsJson);
    } catch (e) {
      throw Exception('Gagal membuat pesanan baru: $e');
    }
  }

  // 2. Fungsi Real-time Stream untuk memantau pesanan masuk secara live (Tanpa perlu refresh layar)
  Stream<List<OrderModel>> getOrdersStream() {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false) // Pesanan terbaru muncul paling atas
        .map((maps) => maps.map((json) => OrderModel.fromJson(json)).toList());
  }

  // 3. Fungsi untuk mengambil detail item makanan dari sebuah pesanan
  Future<List<OrderItemModel>> getOrderItems(String orderId) async {
    try {
      final response = await _client
          .from('order_items')
          .select('*, menus(name)') // Mengambil data relasi nama menu sekaligus
          .eq('order_id', orderId);
      
      return (response as List).map((json) => OrderItemModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil detail pesanan: $e');
    }
  }

  // 4. Fungsi untuk mengubah status pesanan (misal: pending -> completed)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Gagal memperbarui status pesanan: $e');
    }
  }

  // 5. Fungsi untuk menyelesaikan pembayaran dan mencatat metode serta kembalian
  Future<void> completePayment(String orderId, String paymentMethod, double changeAmount) async {
    try {
      await _client
          .from('orders')
          .update({
            'status': 'paid', // Diubah dari 'completed' menjadi 'paid' (atau 'purchased')
            'payment_method': paymentMethod,
            'change_amount': changeAmount,
          })
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Gagal memproses pembayaran: $e');
    }
  }

  // 6. Fungsi untuk memperbarui data menu
  Future<void> updateMenu(MenuModel menu) async {
    try {
      await _client
          .from('menus')
          .update(menu.toJson())
          .eq('id', menu.id!);
    } catch (e) {
      throw Exception('Gagal memperbarui menu: $e');
    }
  }

  // 7. Fungsi untuk menghapus data menu
  Future<void> deleteMenu(String menuId) async {
    try {
      await _client
          .from('menus')
          .delete()
          .eq('id', menuId);
    } catch (e) {
      throw Exception('Gagal menghapus menu: $e');
    }
  }

  // 1. Simpan Nota Belanja & Update Stok
  Future<void> createPurchase(PurchaseModel purchase, List<PurchaseItemModel> items) async {
  try {
    // 1. Masukkan Nota ke Tabel purchases
    final res = await _client.from('purchases').insert(purchase.toJson()).select().single();
    final String purchaseId = res['id'];

    // 2. Loop setiap barang yang dibeli
    for (var item in items) {
      
      // A. Simpan ke tabel purchase_items
      await _client.from('purchase_items').insert({
        'purchase_id': purchaseId,
        'ingredient_id': item.ingredientId,
        'quantity': item.quantity,
        'cost': item.cost,
      });

      // B. Ambil Stok Lama dari tabel ingredients
      final ingData = await _client
          .from('ingredients')
          .select('stock')
          .eq('id', item.ingredientId.toString()) // .toString() memastikan UUID terbaca benar
          .single();

      double currentStock = (ingData['stock'] as num).toDouble();
      
      // C. Update tabel ingredients dengan Stok Baru (Lama + Beli)
      await _client
          .from('ingredients')
          .update({'stock': currentStock + item.quantity})
          .eq('id', item.ingredientId.toString());
    }
  } catch (e) {
    throw Exception(e.toString());
  }
}

  // 2. Ambil Riwayat Belanja
  Future<List<PurchaseModel>> getPurchases() async {
    final res = await _client.from('purchases').select().order('purchase_date', ascending: false);
    return (res as List).map((json) => PurchaseModel.fromJson(json)).toList();
  }


// Mengambil riwayat master belanja sebagai Stream
Stream<List<PurchaseModel>> getPurchasesStream() {
  return _client // <--- _client diganti menjadi supabase
      .from('purchases')
      .stream(primaryKey: ['id'])
      .order('purchase_date', ascending: false) 
      .map((list) => list.map((json) => PurchaseModel.fromJson(json)).toList());
}

// Mengambil rincian item berdasarkan ID belanja
Future<List<PurchaseItemModel>> getPurchaseItems(String purchaseId) async {
  try {
    final List<dynamic> res = await _client // <--- _client diganti menjadi supabase
        .from('purchase_items')
        .select('id, purchase_id, ingredient_id, quantity, cost, ingredients(name)')
        .eq('purchase_id', purchaseId);

    return res.map((json) {
      return PurchaseItemModel(
        id: json['id'].toString(),
        ingredientId: json['ingredient_id'].toString(),
        quantity: (json['quantity'] as num).toDouble(),
        cost: (json['cost'] as num).toDouble(),
        ingredientName: json['ingredients'] != null ? json['ingredients']['name'] : 'Bahan Baku',
      );
    }).toList();
  } catch (e) {
    debugPrint('Error mengambil rincian belanja: $e'); // debugPrint sekarang akan berfungsi
    return [];
  }
}
}