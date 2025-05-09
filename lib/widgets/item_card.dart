import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../providers/cart_provider.dart';
import '../providers/item_provider.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  ItemCard({super.key, required this.item});

  final NumberFormat formatter = NumberFormat("#,###", "en_US");

  void _showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Item Details: ${item.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Category: ${item.category}'),
                Text('Price: ${formatter.format(item.price)} L.L'),
                Text('Origin Price: ${formatter.format(item.originPrice)} L.L'),
                Text('Size: ${item.size}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _promptPasswordBeforeEdit(BuildContext context) async {
  final TextEditingController _passwordController = TextEditingController();
  final correctPassword = 'admin123'; // Change this as needed

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return AlertDialog(
        title: const Text('Password Required'),
        content: TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Enter Password'),
          onSubmitted: (_) {
            if (_passwordController.text == correctPassword) {
              Navigator.of(context).pop(true);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final entered = _passwordController.text;
              Navigator.of(context).pop(entered == correctPassword);
            },
            child: const Text('Enter'),
          ),
        ],
      );
    },
  );

  if (result == true) {
    _showEditDialog(context);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Incorrect password'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}


  void _showEditDialog(BuildContext context) {
    final _nameController = TextEditingController(text: item.name);
    final _categoryController = TextEditingController(text: item.category);
    final _priceController = TextEditingController(text: item.price.toString());
    final _originPriceController = TextEditingController(
      text: item.originPrice.toString(),
    );
    final _sizeController = TextEditingController(text: item.size);
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Edit Item'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: _originPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Origin Price',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: _sizeController,
                    decoration: const InputDecoration(labelText: 'Size'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final updatedItem = Item(
                    name: _nameController.text,
                    category: _categoryController.text,
                    price: double.parse(_priceController.text),
                    originPrice: double.parse(_originPriceController.text),
                    size: _sizeController.text,
                  );
                  itemProvider.editItem(item, updatedItem);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(item.name),
        subtitle: Text('${item.size} - ${formatter.format(item.price)} L.L'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                cartProvider.addItem(item);
                final existingEntry = cartProvider.items.firstWhere(
                  (entry) =>
                      entry['item'].name == item.name &&
                      entry['item'].size == item.size,
                  orElse: () => <String, dynamic>{}, // ✅ valid default
                );
                final count = existingEntry['count'] ?? 1;

                final snackBar = SnackBar(
  content: Text('${item.name} x$count added to cart'),
  behavior: SnackBarBehavior.fixed, // <- Default bottom placement
  duration: const Duration(milliseconds: 300),
);
ScaffoldMessenger.of(context).showSnackBar(snackBar);

              },
              child: const Text('Add to Cart'),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'View Details',
              onPressed: () => _showDetailsDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Item',
              onPressed: () => _promptPasswordBeforeEdit(context),

            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await itemProvider.removeItem(item);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.name} deleted'),
                    behavior: SnackBarBehavior.fixed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    duration: const Duration(milliseconds: 300),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
