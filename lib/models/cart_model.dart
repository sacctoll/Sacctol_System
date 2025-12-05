import 'item.dart';

class CartModel {
  final String id;
  final String location; // "Table 1", "Table 2", etc., or "Outside"
  final String customerName;
  final List<Map<String, dynamic>> items; // {"item": Item, "count": int}
  final double deliveryCharge;
  final DateTime createdAt;

  CartModel({
    required this.id,
    required this.location,
    required this.customerName,
    required this.items,
    required this.deliveryCharge,
    required this.createdAt,
  });

  double get subtotal => items.fold(
      0, (sum, entry) => sum + (entry['item'].price * entry['count']));

  double get total => subtotal + deliveryCharge;

  Map<String, dynamic> toJson() => {
        'id': id,
        'location': location,
        'customerName': customerName,
        'items': items
            .map((e) => {"item": e['item'].toJson(), "count": e['count']})
            .toList(),
        'deliveryCharge': deliveryCharge,
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
        createdAt: DateTime.parse(json['createdAt']),
      );
}
