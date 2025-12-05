import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sacctol_system/models/item.dart';
import 'package:sacctol_system/services/local_storage_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
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
    final filtered = _savedCarts.where((cart) {
      final date = DateTime.parse(cart['date']);
      return _filterCart(date);
    }).toList();

    return filtered.reversed.toList();
  }

  Map<String, Map<String, dynamic>> _getItemsSummary(
      List<Map<String, dynamic>> carts) {
    final Map<String, Map<String, dynamic>> itemsSummary = {};

    for (final cart in carts) {
      final items = (cart['items'] as List).map((e) {
        final item = Item.fromJson(Map<String, dynamic>.from(e['item']));
        final count = e['count'] ?? 1;
        return {'item': item, 'count': count};
      }).toList();

      for (final entry in items) {
        final item = entry['item'] as Item;
        final count = entry['count'] as int;
        final key = '${item.name} (${item.size})';

        if (itemsSummary.containsKey(key)) {
          itemsSummary[key]!['quantity'] += count;
          itemsSummary[key]!['totalRevenue'] += item.price * count;
          itemsSummary[key]!['totalCost'] += item.originPrice * count;
        } else {
          itemsSummary[key] = {
            'item': item,
            'quantity': count,
            'totalRevenue': item.price * count,
            'totalCost': item.originPrice * count,
          };
        }
      }
    }

    return itemsSummary;
  }

  double _calculateTotalRevenue() {
    final filteredCarts = _filteredCarts;
    return filteredCarts.fold(0.0, (sum, cart) {
      final items = (cart['items'] as List).map((e) {
        final item = Item.fromJson(Map<String, dynamic>.from(e['item']));
        final count = e['count'] ?? 1;
        return {'item': item, 'count': count};
      }).toList();

      return sum +
          items.fold(0.0, (s, entry) {
            final item = entry['item'] as Item;
            final count = entry['count'] as int;
            return s + item.price * count;
          });
    });
  }

  double _calculateTotalCost() {
    final filteredCarts = _filteredCarts;
    return filteredCarts.fold(0.0, (sum, cart) {
      final items = (cart['items'] as List).map((e) {
        final item = Item.fromJson(Map<String, dynamic>.from(e['item']));
        final count = e['count'] ?? 1;
        return {'item': item, 'count': count};
      }).toList();

      return sum +
          items.fold(0.0, (s, entry) {
            final item = entry['item'] as Item;
            final count = entry['count'] as int;
            return s + item.originPrice * count;
          });
    });
  }

  int _getTotalTransactions() {
    return _filteredCarts.length;
  }

  int _getTotalItemsSold() {
    final filteredCarts = _filteredCarts;
    return filteredCarts.fold(0, (sum, cart) {
      final items = (cart['items'] as List);
      return sum +
          items.fold(0, (s, e) {
            return s + (e['count'] as int? ?? 1);
          });
    });
  }

  Widget _buildKeyMetrics() {
    final totalRevenue = _calculateTotalRevenue();
    final totalCost = _calculateTotalCost();
    final totalProfit = totalRevenue - totalCost;
    final transactions = _getTotalTransactions();
    final itemsSold = _getTotalItemsSold();
    final avgTransactionValue = transactions > 0 ? totalRevenue / transactions : 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Revenue',
                '${formatter.format(totalRevenue)} L.L',
                Icons.attach_money,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Total Profit',
                '${formatter.format(totalProfit)} L.L',
                Icons.trending_up,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Transactions',
                '$transactions',
                Icons.receipt_long,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Items Sold',
                '$itemsSold',
                Icons.inventory_2,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Avg Transaction',
                '${formatter.format(avgTransactionValue)} L.L',
                Icons.calculate,
                Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Total Cost',
                '${formatter.format(totalCost)} L.L',
                Icons.money_off,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 30),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.arrow_upward, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSellingItems() {
    final itemsSummary = _getItemsSummary(_filteredCarts);
    final sortedItems = itemsSummary.entries.toList()
      ..sort((a, b) => b.value['quantity'].compareTo(a.value['quantity']));

    final top5 = sortedItems.take(5).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Top 5 Best Sellers',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (top5.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No sales data available'),
                ),
              )
            else
              ...top5.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final itemName = item.key;
                final quantity = item.value['quantity'];
                final revenue = item.value['totalRevenue'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: index == 0
                        ? Colors.amber.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: index == 0 ? Colors.amber : Colors.grey.shade300,
                      width: index == 0 ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: index == 0
                              ? Colors.amber
                              : index == 1
                                  ? Colors.grey.shade400
                                  : index == 2
                                      ? Colors.brown.shade300
                                      : Colors.blue.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sold: $quantity units',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${formatter.format(revenue)} L.L',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueByCategory() {
    final filteredCarts = _filteredCarts;
    final Map<String, double> categoryRevenue = {};
    final Map<String, int> categoryQuantity = {};

    for (final cart in filteredCarts) {
      final items = (cart['items'] as List).map((e) {
        final item = Item.fromJson(Map<String, dynamic>.from(e['item']));
        final count = e['count'] ?? 1;
        return {'item': item, 'count': count};
      }).toList();

      for (final entry in items) {
        final item = entry['item'] as Item;
        final count = entry['count'] as int;
        final category = item.category;

        categoryRevenue[category] =
            (categoryRevenue[category] ?? 0) + (item.price * count);
        categoryQuantity[category] = (categoryQuantity[category] ?? 0) + count;
      }
    }

    final sortedCategories = categoryRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Revenue by Category',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (sortedCategories.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No category data available'),
                ),
              )
            else
              ...sortedCategories.map((entry) {
                final category = entry.key;
                final revenue = entry.value;
                final quantity = categoryQuantity[category] ?? 0;
                final maxRevenue = sortedCategories.first.value;
                final percentage = (revenue / maxRevenue * 100).toInt();

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${formatter.format(revenue)} L.L',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$quantity items sold',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedSalesTable() {
    final itemsSummary = _getItemsSummary(_filteredCarts);
    final sortedItems = itemsSummary.entries.toList()
      ..sort((a, b) => b.value['totalRevenue'].compareTo(a.value['totalRevenue']));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.table_chart, color: Colors.purple.shade700, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Detailed Sales Table',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (sortedItems.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No sales data available'),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    Colors.purple.shade50,
                  ),
                  border: TableBorder.all(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Item',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Qty Sold',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Revenue',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Cost',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Profit',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Margin %',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: sortedItems.map((entry) {
                    final itemName = entry.key;
                    final quantity = entry.value['quantity'];
                    final revenue = entry.value['totalRevenue'];
                    final cost = entry.value['totalCost'];
                    final profit = revenue - cost;
                    final margin = revenue > 0 ? (profit / revenue * 100) : 0;

                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 150,
                            child: Text(
                              itemName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(Text('$quantity')),
                        DataCell(
                          Text(
                            '${formatter.format(revenue)}',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${formatter.format(cost)}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${formatter.format(profit)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${margin.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: margin > 30
                                  ? Colors.green
                                  : margin > 15
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final recentCarts = _filteredCarts.take(10).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.teal.shade700, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (recentCarts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No recent transactions'),
                ),
              )
            else
              ...recentCarts.map((cart) {
                final date = DateTime.parse(cart['date']);
                final items = (cart['items'] as List);
                final totalRevenue = items.fold(0.0, (sum, e) {
                  final item =
                      Item.fromJson(Map<String, dynamic>.from(e['item']));
                  final count = e['count'] ?? 1;
                  return sum + (item.price * count);
                });

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.shopping_cart,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('MMM dd, yyyy - HH:mm').format(date),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${items.length} items',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${formatter.format(totalRevenue)} L.L',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Business Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSavedCarts,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Filter Section
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.filter_list,
                        color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Filter by: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _filterType,
                      items: ['All', 'Day', 'Week', 'Month']
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
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            _selectedDate == null
                                ? 'Select Date'
                                : DateFormat('MMM dd, yyyy')
                                    .format(_selectedDate!),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Key Metrics
            _buildKeyMetrics(),
            const SizedBox(height: 20),

            // Top Selling Items
            _buildTopSellingItems(),
            const SizedBox(height: 20),

            // Revenue by Category
            _buildRevenueByCategory(),
            const SizedBox(height: 20),

            // Detailed Sales Table
            _buildDetailedSalesTable(),
            const SizedBox(height: 20),

            // Recent Transactions
            _buildRecentTransactions(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
