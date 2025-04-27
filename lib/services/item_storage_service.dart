import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/item.dart';

class ItemStorageService {
  static const String _itemsKey = 'saved_items';

  static Future<void> saveItems(List<Item> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_itemsKey, encoded);
  }

  static Future<List<Item>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_itemsKey);
    if (encoded == null) return [];
    final decoded = jsonDecode(encoded) as List;
    return decoded.map((item) => Item.fromJson(item)).toList();
  }

  static Future<void> clearItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_itemsKey);
  }
}
