import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sacctol_system/models/item.dart';
import 'package:sacctol_system/pages/protected_saved_carts_page.dart';
import 'package:sacctol_system/providers/item_provider.dart';
import 'package:sacctol_system/widgets/item_card.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);
    final List<Item> _allItems = itemProvider.items;
    final primaryColor = Theme.of(context).primaryColor;

    final grouped = <String, List<Item>>{};
    for (var item in _allItems) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Items by Category'),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/cart'),
            icon: const Icon(Icons.shopping_cart),
            tooltip: 'Go to Cart',
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/create'),
            icon: const Icon(Icons.add),
            tooltip: 'Create New Item',
          ),
          IconButton(
            onPressed: () => Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const ProtectedSavedCartsPage()),
),

            icon: const Icon(Icons.list),
            tooltip: 'Saved Carts',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: grouped.isEmpty
            ? const Center(
                child: Text(
                  'No items available. Please add items.',
                  style: TextStyle(fontSize: 18),
                ),
              )
            : ListView(
                children: grouped.entries
                    .map(
                      (entry) => Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ExpansionTile(
                          collapsedIconColor: primaryColor,
                          iconColor: primaryColor,
                          title: Text(
                            entry.key,
                            style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                          ),
                          children: entry.value.map((item) => ItemCard(item: item)).toList(),
                        ),
                      ),
                    )
                    .toList(),
              ),
      ),
    );
  }
}
