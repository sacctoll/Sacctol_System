import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/item.dart';

class ItemProvider with ChangeNotifier {
  List<Item> _items = [];

  List<Item> get items => _items;

  /// ✅ Load items from SharedPreferences on startup
  ItemProvider() {
    loadItems();
  }

  /// Load items from local storage
  Future<void> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? itemsString = prefs.getString('saved_items');
    if (itemsString != null) {
      final List decoded = jsonDecode(itemsString);
      _items = decoded.map((e) => Item.fromJson(e)).toList();
      notifyListeners();
    }
  }

  /// Save the current items list to local storage
  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString('saved_items', encoded);
  }

  /// Add a new item and persist it
  Future<void> addItem(Item item) async {
    _items.add(item);
    await _saveItems();
    notifyListeners();
  }

  /// Remove an item and persist the change
  Future<void> removeItem(Item item) async {
    _items.remove(item);
    await _saveItems();
    notifyListeners();
  }

  /// Edit an existing item and persist the change
  Future<void> editItem(Item oldItem, Item newItem) async {
    final index = _items.indexOf(oldItem);
    if (index != -1) {
      _items[index] = newItem;
      await _saveItems();
      notifyListeners();
    }
  }

  /// Optional: Clear all items (for testing or reset purposes)
  Future<void> clearItems() async {
    _items.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_items');
    notifyListeners();
  }
}
