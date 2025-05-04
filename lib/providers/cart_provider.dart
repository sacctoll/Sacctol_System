import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/item.dart';

class CartProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _items = []; // Now contains {"item": Item, "count": int}

  List<Map<String, dynamic>> get items => _items;

  double get totalPrice => _items.fold(0, (sum, entry) => sum + (entry['item'].price * entry['count']));

  CartProvider() {
    loadCart();
  }
  int getItemCount(Item item) {
  final existing = _items.firstWhere(
    (element) => element['item'] == item,
    orElse: () => {},
  );
  return existing.isNotEmpty ? existing['count'] as int : 0;
}


  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartString = prefs.getString('cart_items');
    if (cartString != null) {
      final List decoded = jsonDecode(cartString);
      _items.clear();
      _items.addAll(decoded.map((e) => {
            "item": Item.fromJson(e['item']),
            "count": e['count'],
          }));
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _items.map((e) => {"item": e['item'].toJson(), "count": e['count']}).toList(),
    );
    await prefs.setString('cart_items', encoded);
  }

  Future<void> addItem(Item item) async {
    final existing = _items.indexWhere((e) => e['item'].name == item.name && e['item'].size == item.size);
    if (existing != -1) {
      _items[existing]['count'] += 1;
    } else {
      _items.add({"item": item, "count": 1});
    }
    await _saveCart();
    notifyListeners();
  }

  Future<void> removeItem(Item item) async {
    final index = _items.indexWhere((e) => e['item'].name == item.name && e['item'].size == item.size);
    if (index != -1) {
      if (_items[index]['count'] > 1) {
        _items[index]['count'] -= 1;
      } else {
        _items.removeAt(index);
      }
      await _saveCart();
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart_items');
    notifyListeners();
  }

  Future<void> saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedCartsString = prefs.getString('saved_carts');
    final List savedCarts = savedCartsString != null ? jsonDecode(savedCartsString) : [];
    savedCarts.add({
      "date": DateTime.now().toIso8601String(),
      "items": _items.map((e) => {"item": e['item'].toJson(), "count": e['count']}).toList(),
    });
    await prefs.setString('saved_carts', jsonEncode(savedCarts));
    await clearCart();
  }
}
