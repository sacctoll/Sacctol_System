import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/item.dart';

class LocalStorageService {
  static const String cartsKey = 'saved_carts';

  static Future<void> saveCart(List<Item> cartItems) async {
    final prefs = await SharedPreferences.getInstance();
    final carts = await getSavedCarts();
    final now = DateTime.now().toIso8601String();
    carts.add({'date': now, 'items': cartItems.map((e) => e.toJson()).toList()});
    await prefs.setString(cartsKey, jsonEncode(carts));
  }

  static Future<List<Map<String, dynamic>>> getSavedCarts() async {
    final prefs = await SharedPreferences.getInstance();
    final cartsString = prefs.getString(cartsKey);
    if (cartsString == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(cartsString));
  }

  static Future<void> clearSavedCarts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cartsKey);
  }

  static Future<void> updateSavedCarts(List<Map<String, dynamic>> carts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cartsKey, jsonEncode(carts));
  }

  static Future<SharedPreferences> getPrefs() async {
    return await SharedPreferences.getInstance();
  }
}
