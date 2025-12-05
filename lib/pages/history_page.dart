import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sacctol_system/models/item.dart';
import 'package:sacctol_system/services/local_storage_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _todayCarts = [];
  final NumberFormat formatter = NumberFormat("#,###", "en_US");
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayCarts();
  }

  Future<void> _loadTodayCarts() async {
    setState(() => _isLoading = true);
    
    final allCarts = await LocalStorageService.getSavedCarts();
    final now = DateTime.now();
    
    // Filter carts from today
    final todayCarts = allCarts.where((cart) {
      final cartDate = DateTime.parse(cart['date']);
      return cartDate.year == now.year &&
          cartDate.month == now.month &&
          cartDate.day == now.day;
    }).toList();

    setState(() {
      _todayCarts = todayCarts.reversed.toList(); // Most recent first
      _isLoading = false;
    });
  }

  double _calculateCartTotal(Map<String, dynamic> cart) {
    final items = (cart['items'] as List).map((e) {
      final item = Item.fromJson(Map<String, dynamic>.from(e['item']));
      final count = e['count'] ?? 1;
      return {'item': item, 'count': count};
    }).toList();

    final subtotal = items.fold(0.0, (sum, entry) {
      final item = entry['item'] as Item;
      final count = entry['count'] as int;
      return sum + (item.price * count);
    });

    final deliveryCharge = (cart['deliveryCharge'] ?? 0).toDouble();
    return subtotal + deliveryCharge;
  }

  double _calculateTodayTotal() {
    return _todayCarts.fold(0.0, (sum, cart) => sum + _calculateCartTotal(cart));
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final todayTotal = _calculateTodayTotal();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Today\'s History'),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTodayCarts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's Summary Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.1),
                            primaryColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: primaryColor, size: 28),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat('EEEE, MMM dd, yyyy').format(DateTime.now()),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    '${_todayCarts.length}',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Carts Completed',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                height: 50,
                                width: 1,
                                color: Colors.grey.shade300,
                              ),
                              Column(
                                children: [
                                  Text(
                                    '${formatter.format(todayTotal)} L.L',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total Revenue',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Carts List Header
                  if (_todayCarts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long, color: primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Completed Carts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Carts List
                  Expanded(
                    child: _todayCarts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No carts completed today',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Completed carts will appear here',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _todayCarts.length,
                            itemBuilder: (context, index) {
                              final cart = _todayCarts[index];
                              final date = DateTime.parse(cart['date']);
                              final location = cart['location'] ?? '';
                              final customerName = cart['customerName'] ?? '';
                              final deliveryCharge = (cart['deliveryCharge'] ?? 0).toDouble();
                              
                              final items = (cart['items'] as List).map((e) {
                                final item = Item.fromJson(Map<String, dynamic>.from(e['item']));
                                final count = e['count'] ?? 1;
                                return {'item': item, 'count': count};
                              }).toList();

                              final subtotal = items.fold(0.0, (sum, entry) {
                                final item = entry['item'] as Item;
                                final count = entry['count'] as int;
                                return sum + (item.price * count);
                              });

                              final total = subtotal + deliveryCharge;

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ExpansionTile(
                                  collapsedIconColor: primaryColor,
                                  iconColor: primaryColor,
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '#${_todayCarts.length - index}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                if (location.isNotEmpty) ...[
                                                  Icon(
                                                    location.startsWith('Table')
                                                        ? Icons.table_restaurant
                                                        : Icons.shopping_bag,
                                                    size: 16,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    location,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: primaryColor,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (customerName.isNotEmpty)
                                              Text(
                                                customerName,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat('HH:mm').format(date),
                                          style: TextStyle(color: Colors.grey.shade600),
                                        ),
                                        Text(
                                          '${formatter.format(total)} L.L',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  children: [
                                    const Divider(height: 1),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Items List
                                          ...items.map((entry) {
                                            final item = entry['item'] as Item;
                                            final count = entry['count'] as int;
                                            final itemTotal = item.price * count;

                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          '${item.name} x$count',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                        Text(
                                                          '${item.size} - ${formatter.format(item.price)} L.L each',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey.shade600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    '${formatter.format(itemTotal)} L.L',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),

                                          const Divider(height: 24),

                                          // Subtotal
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Subtotal:',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                              Text(
                                                '${formatter.format(subtotal)} L.L',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Delivery Charge
                                          if (deliveryCharge > 0) ...[
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text(
                                                  'Delivery Charge:',
                                                  style: TextStyle(fontSize: 14),
                                                ),
                                                Text(
                                                  '${formatter.format(deliveryCharge)} L.L',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],

                                          const SizedBox(height: 8),

                                          // Total
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text(
                                                  'Total:',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  '${formatter.format(total)} L.L',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
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
