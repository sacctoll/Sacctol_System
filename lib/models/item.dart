class Item {
  final String name;
  final String category;
  final double price;
  final double originPrice;  // ✅ New field
  final String size;

  Item({
    required this.name,
    required this.category,
    required this.price,
    required this.originPrice,  // ✅ Include in constructor
    required this.size,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'price': price,
        'originPrice': originPrice,  // ✅ Save it
        'size': size,
      };

  factory Item.fromJson(Map<String, dynamic> json) => Item(
  name: json['name'] ?? '',
  category: json['category'] ?? '',
  price: (json['price'] ?? 0).toDouble(),
  originPrice: (json['originPrice'] ?? 0).toDouble(),
  size: json['size'] ?? '',
);

}
