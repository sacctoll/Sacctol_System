import 'item.dart';

class CartModel {
  final String id;
  final String location; // "Table 1", "Table 2", etc., or "Takeaway"
  final String customerName;
  final List<Map<String, dynamic>> items; // {"item": Item, "count": int}
  final double deliveryCharge;
  final bool hasDiscount; // 20% discount flag
  final DateTime createdAt;

  CartModel({
    required this.id,
    required this.location,
    required this.customerName,
    required this.items,
    required this.deliveryCharge,
    this.hasDiscount = false,
    required this.createdAt,
  });

  double get subtotal => items.fold(
      0, (sum, entry) => sum + (entry['item'].price * entry['count']));

  double get discountAmount => hasDiscount ? subtotal * 0.20 : 0;

  double get subtotalAfterDiscount => subtotal - discountAmount;

  double get total => subtotalAfterDiscount + deliveryCharge;

  Map<String, dynamic> toJson() => {
        'id': id,
        'location': location,
        'customerName': customerName,
        'items': items
            .map((e) => {"item": e['item'].toJson(), "count": e['count']})
            .toList(),
        'deliveryCharge': deliveryCharge,
        'hasDiscount': hasDiscount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CartModel.fromJson(Map<String, dynamic> json) => CartModel(
        id: json['id'] ?? '',
        location: json['location'] ?? '',
        customerName: json['customerName'] ?? '',
        items: (json['items'] as List)
            .map((e) => {
                  "item": Item.fromJson(Map<String, dynamic>.from(e['item'])),
                  "count": e['count'] ?? 1,
                })
            .toList(),
        deliveryCharge: (json['deliveryCharge'] ?? 0).toDouble(),
        hasDiscount: json['hasDiscount'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );
}
