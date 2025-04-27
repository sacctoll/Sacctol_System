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
      builder: (_) => AlertDialog(
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

  void _showEditDialog(BuildContext context) {
    final _nameController = TextEditingController(text: item.name);
    final _categoryController = TextEditingController(text: item.category);
    final _priceController = TextEditingController(text: item.price.toString());
    final _originPriceController = TextEditingController(text: item.originPrice.toString());
    final _sizeController = TextEditingController(text: item.size);
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category')),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _originPriceController,
                decoration: const InputDecoration(labelText: 'Origin Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(controller: _sizeController, decoration: const InputDecoration(labelText: 'Size')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.name} added to cart')),
                );
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
              onPressed: () => _showEditDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await itemProvider.removeItem(item);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.name} deleted')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
