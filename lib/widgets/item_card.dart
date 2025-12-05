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

  void _showDetailsDialog(BuildContext context) async {
    final isAuthorized = await _promptPassword(context);
    if (!isAuthorized) return;

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

  Future<bool> _promptPassword(BuildContext context) async {
    final TextEditingController passwordController = TextEditingController();
    const correctPassword = 'admin123';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.lock, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Password Required'),
            ],
          ),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Enter Password',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.password),
            ),
            onSubmitted: (_) {
              if (passwordController.text == correctPassword) {
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
                final entered = passwordController.text;
                Navigator.of(context).pop(entered == correctPassword);
              },
              child: const Text('Enter'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect password'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    return result ?? false;
  }

  void _promptPasswordBeforeEdit(BuildContext context) async {
    final isAuthorized = await _promptPassword(context);
    if (isAuthorized) {
      _showEditDialog(context);
    }
  }

  void _promptPasswordBeforeDelete(BuildContext context) async {
    final isAuthorized = await _promptPassword(context);
    if (!isAuthorized) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Confirm Delete'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${item.name}"?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      await itemProvider.removeItem(item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} deleted'),
          behavior: SnackBarBehavior.fixed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(milliseconds: 500),
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

  void _showTableSelectionDialog(BuildContext context) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final currentCart = cartProvider.currentCart;

    // If there are active carts, show selection dialog
    if (cartProvider.activeCarts.isNotEmpty) {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.shopping_cart, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Select Cart'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Add item to existing cart or create new one?'),
                const SizedBox(height: 16),
                ...cartProvider.activeCarts.map((cart) {
                  return ListTile(
                    leading: Icon(
                      cart.location.startsWith('Table')
                          ? Icons.table_restaurant
                          : Icons.directions_walk,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(cart.location),
                    subtitle: cart.customerName.isNotEmpty
                        ? Text(cart.customerName)
                        : const Text('No name'),
                    trailing: Text('${cart.items.length} items'),
                    onTap: () => Navigator.pop(context, cart.id),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  );
                }),
                const Divider(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Cart'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  onPressed: () => Navigator.pop(context, 'new'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (result == null) return; // User cancelled

      if (result == 'new') {
        // Show create new cart dialog
        _showCreateCartDialog(context);
      } else {
        // Switch to selected cart and add item
        cartProvider.switchCart(result);
        _addItemToCart(context);
      }
    } else {
      // No active carts, create first one
      _showCreateCartDialog(context);
    }
  }

  void _showCreateCartDialog(BuildContext context) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final TextEditingController nameController = TextEditingController();
    String selectedLocation = 'Table 1';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.add_shopping_cart, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  const Text('New Cart'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedLocation,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      items: [
                        'Table 1',
                        'Table 2',
                        'Table 3',
                        'Table 4',
                        'Outside',
                      ].map((location) {
                        return DropdownMenuItem(
                          value: location,
                          child: Text(location),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedLocation = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Customer Name (Optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    cartProvider.createNewCart(selectedLocation, nameController.text);
                    Navigator.pop(context, true);
                  },
                  child: const Text('Create & Add Item'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      _addItemToCart(context);
    }
  }

  void _addItemToCart(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addItem(item);
    
    final count = cartProvider.getItemCount(item);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} x$count added to ${cartProvider.currentCart?.location ?? "cart"}'),
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(milliseconds: 500),
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
              onPressed: () => _showTableSelectionDialog(context),
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
              tooltip: 'Delete Item',
              onPressed: () => _promptPasswordBeforeDelete(context),
            ),
          ],
        ),
      ),
    );
  }
}
