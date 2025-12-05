import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/item.dart';
import '../models/cart_model.dart';

class CartProvider with ChangeNotifier {
  List<CartModel> _activeCarts = [];
  String? _currentCartId;

  List<CartModel> get activeCarts => _activeCarts;
  CartModel? get currentCart => _activeCarts.firstWhere(
        (cart) => cart.id == _currentCartId,
        orElse: () => _activeCarts.isNotEmpty ? _activeCarts.first : _createDefaultCart(),
      );

  List<Map<String, dynamic>> get items => currentCart?.items ?? [];
  double get totalPrice => currentCart?.subtotal ?? 0;
  double get deliveryCharge => currentCart?.deliveryCharge ?? 0;
  double get grandTotal => currentCart?.total ?? 0;

  CartProvider() {
    loadCarts();
  }

  CartModel _createDefaultCart() {
    final cart = CartModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      location: 'Table 1',
      customerName: '',
      items: [],
      deliveryCharge: 0,
      hasDiscount: false,
      createdAt: DateTime.now(),
    );
    _activeCarts.add(cart);
    _currentCartId = cart.id;
    return cart;
  }

  Future<void> loadCarts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartsString = prefs.getString('active_carts');
    final String? currentId = prefs.getString('current_cart_id');
    
    if (cartsString != null) {
      final List decoded = jsonDecode(cartsString);
      _activeCarts = decoded.map((e) => CartModel.fromJson(e)).toList();
      _currentCartId = currentId;
    }
    
    if (_activeCarts.isEmpty) {
      _createDefaultCart();
    }
    
    notifyListeners();
  }

  Future<void> _saveCarts() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_activeCarts.map((e) => e.toJson()).toList());
    await prefs.setString('active_carts', encoded);
    if (_currentCartId != null) {
      await prefs.setString('current_cart_id', _currentCartId!);
    }
  }

  void createNewCart(String location, String customerName) {
    final newCart = CartModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      location: location,
      customerName: customerName,
      items: [],
      deliveryCharge: 0,
      hasDiscount: false,
      createdAt: DateTime.now(),
    );
    _activeCarts.add(newCart);
    _currentCartId = newCart.id;
    _saveCarts();
    notifyListeners();
  }

  void switchCart(String cartId) {
    _currentCartId = cartId;
    _saveCarts();
    notifyListeners();
  }

  void updateCartDetails(String cartId, {String? location, String? customerName, double? deliveryCharge, bool? hasDiscount}) {
    final index = _activeCarts.indexWhere((cart) => cart.id == cartId);
    if (index != -1) {
      final cart = _activeCarts[index];
      _activeCarts[index] = CartModel(
        id: cart.id,
        location: location ?? cart.location,
        customerName: customerName ?? cart.customerName,
        items: cart.items,
        deliveryCharge: deliveryCharge ?? cart.deliveryCharge,
        hasDiscount: hasDiscount ?? cart.hasDiscount,
        createdAt: cart.createdAt,
      );
      _saveCarts();
      notifyListeners();
    }
  }

  int getItemCount(Item item) {
    final cart = currentCart;
    if (cart == null) return 0;
    
    final existing = cart.items.firstWhere(
      (element) => element['item'].name == item.name && element['item'].size == item.size,
      orElse: () => {},
    );
    return existing.isNotEmpty ? existing['count'] as int : 0;
  }

  Future<void> addItem(Item item) async {
    final cart = currentCart;
    if (cart == null) return;

    final items = List<Map<String, dynamic>>.from(cart.items);
    final existing = items.indexWhere(
      (e) => e['item'].name == item.name && e['item'].size == item.size,
    );

    if (existing != -1) {
      items[existing]['count'] += 1;
    } else {
      items.add({"item": item, "count": 1});
    }

    final index = _activeCarts.indexWhere((c) => c.id == cart.id);
    _activeCarts[index] = CartModel(
      id: cart.id,
      location: cart.location,
      customerName: cart.customerName,
      items: items,
      deliveryCharge: cart.deliveryCharge,
      hasDiscount: cart.hasDiscount,
      createdAt: cart.createdAt,
    );

    await _saveCarts();
    notifyListeners();
  }

  Future<void> removeItem(Item item) async {
    final cart = currentCart;
    if (cart == null) return;

    final items = List<Map<String, dynamic>>.from(cart.items);
    final index = items.indexWhere(
      (e) => e['item'].name == item.name && e['item'].size == item.size,
    );

    if (index != -1) {
      if (items[index]['count'] > 1) {
        items[index]['count'] -= 1;
      } else {
        items.removeAt(index);
      }

      final cartIndex = _activeCarts.indexWhere((c) => c.id == cart.id);
      _activeCarts[cartIndex] = CartModel(
        id: cart.id,
        location: cart.location,
        customerName: cart.customerName,
        items: items,
        deliveryCharge: cart.deliveryCharge,
        hasDiscount: cart.hasDiscount,
        createdAt: cart.createdAt,
      );

      await _saveCarts();
      notifyListeners();
    }
  }

  Future<void> clearCart(String cartId) async {
    _activeCarts.removeWhere((cart) => cart.id == cartId);
    
    if (_currentCartId == cartId) {
      _currentCartId = _activeCarts.isNotEmpty ? _activeCarts.first.id : null;
    }
    
    if (_activeCarts.isEmpty) {
      _createDefaultCart();
    }
    
    await _saveCarts();
    notifyListeners();
  }

  Future<void> saveCart(String cartId) async {
    final cart = _activeCarts.firstWhere((c) => c.id == cartId);
    
    final prefs = await SharedPreferences.getInstance();
    final String? savedCartsString = prefs.getString('saved_carts');
    final List savedCarts = savedCartsString != null ? jsonDecode(savedCartsString) : [];
    
    savedCarts.add({
      "date": DateTime.now().toIso8601String(),
      "location": cart.location,
      "customerName": cart.customerName,
      "deliveryCharge": cart.deliveryCharge,
      "hasDiscount": cart.hasDiscount,
      "items": cart.items.map((e) => {"item": e['item'].toJson(), "count": e['count']}).toList(),
    });
    
    await prefs.setString('saved_carts', jsonEncode(savedCarts));
    await clearCart(cartId);
  }
}
