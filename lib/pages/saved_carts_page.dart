import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sacctol_system/models/item.dart';
import 'dart:convert';

import 'package:sacctol_system/services/local_storage_service.dart';

class SavedCartsPage extends StatefulWidget {
  const SavedCartsPage({super.key});

  @override
  State<SavedCartsPage> createState() => _SavedCartsPageState();
}

class _SavedCartsPageState extends State<SavedCartsPage> {
  List<Map<String, dynamic>> _savedCarts = [];
  String _filterType = 'All';
  DateTime? _selectedDate;
  final NumberFormat formatter = NumberFormat("#,###", "en_US");

  @override
  void initState() {
    super.initState();
    _loadSavedCarts();
  }

  Future<void> _loadSavedCarts() async {
    final carts = await LocalStorageService.getSavedCarts();
    setState(() => _savedCarts = carts);
  }

  Future<void> _deleteCart(int index) async {
    setState(() {
      _savedCarts.removeAt(index);
    });
    await LocalStorageService.updateSavedCarts(_savedCarts);
  }

  bool _filterCart(DateTime cartDate) {
    if (_filterType == 'All' || _selectedDate == null) return true;
    if (_filterType == 'Day') {
      return cartDate.year == _selectedDate!.year &&
          cartDate.month == _selectedDate!.month &&
          cartDate.day == _selectedDate!.day;
    } else if (_filterType == 'Week') {
      final weekDay = _selectedDate!.weekday;
      final firstDayOfWeek = _selectedDate!.subtract(
        Duration(days: weekDay - 1),
      );
      final lastDayOfWeek = firstDayOfWeek.add(const Duration(days: 6));
      return cartDate.isAfter(
            firstDayOfWeek.subtract(const Duration(days: 1)),
          ) &&
          cartDate.isBefore(lastDayOfWeek.add(const Duration(days: 1)));
    } else if (_filterType == 'Month') {
      return cartDate.year == _selectedDate!.year &&
          cartDate.month == _selectedDate!.month;
    }
    return true;
  }

  List<Map<String, dynamic>> get _filteredCarts {
    return _savedCarts.where((cart) {
      final date = DateTime.parse(cart['date']);
      return _filterCart(date);
    }).toList();
  }

double _calculateTotalPrice(List<Map<String, dynamic>> carts) {
  return carts.fold(0, (sum, cart) {
    final items = (cart['items'] as List).map((e) {
      final item = Item.fromJson(Map<String, dynamic>.from(e['item']));
      final count = e['count'] ?? 1;
      return {'item': item, 'count': count};
    }).toList();

    return sum + items.fold(0, (s, entry) {
      final item = entry['item'] as Item;
      final count = entry['count'] as int;
      return s + item.price * count;
    });
  });
}


double _calculateTotalOrigin(List<Map<String, dynamic>> carts) {
  return carts.fold(0, (sum, cart) {
    final items = (cart['items'] as List).map((e) {
      final item = Item.fromJson(Map<String, dynamic>.from(e['item']));
      final count = e['count'] ?? 1;
      return {'item': item, 'count': count};
    }).toList();

    return sum + items.fold(0, (s, entry) {
      final item = entry['item'] as Item;
      final count = entry['count'] as int;
      return s + item.originPrice * count;
    });
  });
}


  Widget _buildTotals(BuildContext context) {
    final filteredCarts = _filteredCarts;
    final totalPrice = _calculateTotalPrice(filteredCarts);
    final totalOrigin = _calculateTotalOrigin(filteredCarts);
    final totalProfit = totalPrice - totalOrigin;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).primaryColor, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            'Total Selling Price: ${formatter.format(totalPrice)} L.L',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Total Origin Price (Cost): ${formatter.format(totalOrigin)} L.L',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            'Total Profit: ${formatter.format(totalProfit)} L.L',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCarts = _filteredCarts;

    return Scaffold(
      backgroundColor: Colors.white, // ✅ White background
      appBar: AppBar(
        title: const Text('Saved Carts'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Filter by: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _filterType,
                  items:
                      ['All', 'Day', 'Week', 'Month']
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _filterType = value!;
                      if (_filterType == 'All') {
                        _selectedDate = null;
                      }
                    });
                  },
                ),
                const SizedBox(width: 16),
                if (_filterType != 'All')
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: Text(
                      _selectedDate == null
                          ? 'Select Date'
                          : 'Selected: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                    ),
                  ),
              ],
            ),
            _buildTotals(context), // ✅ Totals at the top with primary color
            const SizedBox(height: 10),
            Expanded(
              child:
                  filteredCarts.isEmpty
                      ? const Center(
                        child: Text('No saved carts for the selected filter.'),
                      )
                      : ListView.builder(
                        itemCount: filteredCarts.length,
                        itemBuilder: (context, index) {
                          final cart = filteredCarts[index];
                          final date = DateTime.parse(cart['date']);
                          final items =
                              (cart['items'] as List)
                                  .map(
                                    (e) => {
                                      'item': Item.fromJson(
                                        Map<String, dynamic>.from(e['item']),
                                      ),
                                      'count': e['count'] ?? 1,
                                    },
                                  )
                                  .toList();
                          final totalPrice = _calculateTotalPrice([cart]);
                          final totalOrigin = _calculateTotalOrigin([cart]);
                          final totalProfit = totalPrice - totalOrigin;

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ExpansionTile(
                              collapsedIconColor:
                                  Theme.of(context).primaryColor,
                              iconColor: Theme.of(context).primaryColor,
                              title: Text(
                                'Cart Date: ${date.toLocal().toString().split(' ')[0]}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selling: ${formatter.format(totalPrice)} L.L',
                                  ),
                                  Text(
                                    'Cost: ${formatter.format(totalOrigin)} L.L',
                                  ),
                                  Text(
                                    'Profit: ${formatter.format(totalProfit)} L.L',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              children: [
                                ...items.map((entry) {
                                  final item = entry['item'] as Item;
                                  final count = entry['count'] as int;
                                  return ListTile(
                                    title: Text(
                                      '${item.name} x$count',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Category: ${item.category}'),
                                        Text(
                                          'Selling Price: ${formatter.format(item.price)} L.L',
                                        ),
                                        Text(
                                          'Origin Price: ${formatter.format(item.originPrice)} L.L',
                                        ),
                                        Text('Size: ${item.size}'),
                                      ],
                                    ),
                                  );
                                }),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      await _deleteCart(index);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Cart deleted'),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
