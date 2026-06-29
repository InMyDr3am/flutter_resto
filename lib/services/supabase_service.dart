import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_model.dart';
import '../models/ingredient_model.dart';

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
}