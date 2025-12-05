import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sacctol_system/providers/cart_provider.dart';
import 'package:sacctol_system/utils/txt_download.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final NumberFormat formatter = NumberFormat("#,###", "en_US");
  int _selectedDeliveryOption = 0; // 0=No delivery, 1=100k, 2=150k, 3=200k, 4=Custom
  final TextEditingController _customDeliveryController = TextEditingController();

  double get _deliveryCharge {
    switch (_selectedDeliveryOption) {
      case 1:
        return 100000;
      case 2:
        return 150000;
      case 3:
        return 200000;
      case 4:
        return double.tryParse(_customDeliveryController.text) ?? 0;
      default:
        return 0;
    }
  }

  void _updateDeliveryCharge(CartProvider cartProvider) {
    final cart = cartProvider.currentCart;
    if (cart != null) {
      cartProvider.updateCartDetails(
        cart.id,
        deliveryCharge: _deliveryCharge,
      );
    }
  }

  void _showNewCartDialog(BuildContext context, CartProvider cartProvider) {
    final TextEditingController nameController = TextEditingController();
    String selectedLocation = 'Takeaway';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                  if (value != null) selectedLocation = value;
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              cartProvider.createNewCart(selectedLocation, nameController.text);
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditCartDialog(BuildContext context, CartProvider cartProvider) {
    final cart = cartProvider.currentCart;
    if (cart == null) return;

    final TextEditingController nameController = TextEditingController(text: cart.customerName);
    String selectedLocation = cart.location;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('Edit Cart Details'),
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
                  'Takeaway',
                  'Table 1',
                  'Table 2',
                  'Table 3',
                  'Table 4',
                ].map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) selectedLocation = value;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Customer Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person),
                ),
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
              cartProvider.updateCartDetails(
                cart.id,
                location: selectedLocation,
                customerName: nameController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String generateReceipt(cart, String location, String customerName, {double? deliveryCharge}) {
    final buffer = StringBuffer();
    const int width = 40;
    final timestamp = DateTime.now();

    buffer.writeln(centerText("SACCTOL", width));
    buffer.writeln(centerText("Zawtar El-Charqieh", width));
    buffer.writeln(centerText("Center Swaydan", width));
    buffer.writeln(centerText("+961 81 58 63 34", width));
    buffer.writeln(centerText(timestamp.toLocal().toString().split('.')[0], width));
    buffer.writeln(blankLine(width));
    buffer.writeln(repeat("-", width));
    buffer.writeln(blankLine(width));
    
    if (location.isNotEmpty) {
      buffer.writeln(padBoth("Location", location, width));
    }
    if (customerName.isNotEmpty) {
      buffer.writeln(padBoth("Customer", customerName, width));
    }
    if (location.isNotEmpty || customerName.isNotEmpty) {
      buffer.writeln(blankLine(width));
      buffer.writeln(repeat("-", width));
      buffer.writeln(blankLine(width));
    }

    buffer.writeln(padFourColumns("Item", "Size", "Qty", "Price", width));
    buffer.writeln(blankLine(width));
    buffer.writeln(repeat("-", width));
    buffer.writeln(blankLine(width));

    double total = 0.0;
    for (var entry in cart) {
      final item = entry['item'];
      final count = entry['count'];
      final price = item.price * count;
      buffer.writeln(
        padFourColumns(item.name, item.size, 'x$count', "${formatter.format(price)} L.L", width),
      );
      total += price;
    }

    if (deliveryCharge != null && deliveryCharge > 0) {
      buffer.writeln(blankLine(width));
      buffer.writeln(padBoth("Delivery", "${formatter.format(deliveryCharge)} L.L", width));
      total += deliveryCharge;
    }

    buffer.writeln(blankLine(width));
    buffer.writeln(repeat("-", width));
    buffer.writeln(blankLine(width));
    buffer.writeln(padBoth("TOTAL", "${formatter.format(total)} L.L", width));
    buffer.writeln(blankLine(width));
    buffer.writeln(repeat("-", width));
    buffer.writeln(blankLine(width));
    buffer.writeln(centerText("Thank You!", width));
    buffer.writeln(centerText("Visit Again", width));
    buffer.writeln(blankLine(width));
    buffer.writeln(centerText("Powered by", width));
    buffer.writeln(centerText("Dev-Sherlok", width));
    buffer.writeln(blankLine(width));

    return buffer.toString();
  }

  void printReceipt(String receiptText) {
    final htmlContent = '''
      <html>
        <head>
          <title>Receipt</title>
          <style>
            body { font-family: monospace; font-size: 12px; margin: 20px; }
            pre { white-space: pre-wrap; word-wrap: break-word; }
          </style>
        </head>
        <body>
          <pre>$receiptText</pre>
          <script>window.print();</script>
        </body>
      </html>
    ''';

    final blob = html.Blob([htmlContent], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final currentCart = cartProvider.currentCart;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Active Carts'),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showNewCartDialog(context, cartProvider),
            tooltip: 'New Cart',
          ),
        ],
      ),
      body: cartProvider.activeCarts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No active carts', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Cart'),
                    onPressed: () => _showNewCartDialog(context, cartProvider),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                // Left Sidebar - Cart Tabs
                Container(
                  width: 250,
                  color: Colors.white,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: primaryColor.withOpacity(0.1),
                        child: Row(
                          children: [
                            Icon(Icons.list, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Active Carts',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: cartProvider.activeCarts.length,
                          itemBuilder: (context, index) {
                            final cart = cartProvider.activeCarts[index];
                            final isSelected = cart.id == currentCart?.id;
                            return Container(
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor.withOpacity(0.1) : null,
                                border: Border(
                                  left: BorderSide(
                                    color: isSelected ? primaryColor : Colors.transparent,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  cart.location.startsWith('Table')
                                      ? Icons.table_restaurant
                                      : Icons.shopping_bag,
                                  color: isSelected ? primaryColor : Colors.grey,
                                ),
                                title: Text(
                                  cart.location,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? primaryColor : Colors.black,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (cart.customerName.isNotEmpty)
                                      Text(cart.customerName, style: const TextStyle(fontSize: 12)),
                                    Text('${cart.items.length} items', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                trailing: Text(
                                  '${formatter.format(cart.total)} L.L',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                onTap: () => cartProvider.switchCart(cart.id),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Side - Cart Details
                Expanded(
                  child: currentCart == null
                      ? const Center(child: Text('No cart selected'))
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cart Header
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.location_on, color: primaryColor, size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  currentCart.location,
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: primaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (currentCart.customerName.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.person, color: Colors.grey.shade600, size: 18),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    currentCart.customerName,
                                                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _showEditCartDialog(context, cartProvider),
                                        tooltip: 'Edit Details',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Delivery Charge Section
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Delivery Charge',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _buildDeliveryOption(0, 'No Delivery', cartProvider),
                                          _buildDeliveryOption(1, '100,000 L.L', cartProvider),
                                          _buildDeliveryOption(2, '150,000 L.L', cartProvider),
                                          _buildDeliveryOption(3, '200,000 L.L', cartProvider),
                                          _buildDeliveryOption(4, 'Custom', cartProvider),
                                        ],
                                      ),
                                      if (_selectedDeliveryOption == 4) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _customDeliveryController,
                                                keyboardType: TextInputType.number,
                                                decoration: InputDecoration(
                                                  labelText: 'Custom Amount (L.L)',
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  prefixIcon: const Icon(Icons.attach_money),
                                                ),
                                                onChanged: (_) => _updateDeliveryCharge(cartProvider),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Items List
                              Expanded(
                                child: currentCart.items.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.shopping_basket_outlined, size: 60, color: Colors.grey.shade400),
                                            const SizedBox(height: 16),
                                            const Text('Cart is empty', style: TextStyle(fontSize: 16)),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: currentCart.items.length,
                                        itemBuilder: (context, index) {
                                          final entry = currentCart.items[index];
                                          final item = entry['item'];
                                          final count = entry['count'];
                                          return Card(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 2,
                                            margin: const EdgeInsets.only(bottom: 8),
                                            child: ListTile(
                                              title: Text(
                                                '${item.name} x$count',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: primaryColor,
                                                ),
                                              ),
                                              subtitle: Text(
                                                '${item.size} - ${formatter.format(item.price)} L.L each',
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '${formatter.format(item.price * count)} L.L',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                    onPressed: () => cartProvider.removeItem(item),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),

                              // Total Section
                              Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                                          Text(
                                            '${formatter.format(currentCart.subtotal)} L.L',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      if (currentCart.deliveryCharge > 0) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Delivery:', style: TextStyle(fontSize: 16)),
                                            Text(
                                              '${formatter.format(currentCart.deliveryCharge)} L.L',
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const Divider(height: 20),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total:',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                          Text(
                                            '${formatter.format(currentCart.total)} L.L',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.download),
                                      label: const Text('Download'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () {
                                        final receipt = generateReceipt(
                                          currentCart.items,
                                          currentCart.location,
                                          currentCart.customerName,
                                          deliveryCharge: currentCart.deliveryCharge,
                                        );
                                        downloadTextFile(receipt, "receipt.txt");
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.print),
                                      label: const Text('Print'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () {
                                        final receipt = generateReceipt(
                                          currentCart.items,
                                          currentCart.location,
                                          currentCart.customerName,
                                          deliveryCharge: currentCart.deliveryCharge,
                                        );
                                        printReceipt(receipt);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.check),
                                      label: const Text('Complete'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () {
                                        cartProvider.saveCart(currentCart.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            duration: Duration(milliseconds: 500),
                                            content: Text('Cart completed and saved!'),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(Icons.delete_forever, color: Colors.red, size: 32),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Cart'),
                                          content: const Text('Are you sure you want to delete this cart?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                cartProvider.clearCart(currentCart.id);
                                                Navigator.pop(context);
                                              },
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    tooltip: 'Delete Cart',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDeliveryOption(int value, String label, CartProvider cartProvider) {
    final isSelected = _selectedDeliveryOption == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedDeliveryOption = value;
            _updateDeliveryCharge(cartProvider);
          });
        }
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }


  // === Helper Functions ===
  String centerText(String text, int width) {
    final totalSpaces = width - text.length;
    final leftSpaces = (totalSpaces / 2).floor();
    final rightSpaces = totalSpaces - leftSpaces;
    return '${' ' * leftSpaces}$text${' ' * rightSpaces}';
  }

  String repeat(String char, int count) {
    return List.filled(count, char).join();
  }

  String blankLine(int width) {
    return repeat(' ', width);
  }

  String padBoth(String left, String right, int width) {
    final spaces = width - left.length - right.length;
    return '$left${' ' * spaces}$right';
  }

  String padFourColumns(String col1, String col2, String col3, String col4, int width) {
    const itemColWidth = 16;
    const sizeColWidth = 5;
    const countColWidth = 5;
    const priceColWidth = 14;

    final itemLines = wrapAndCenterText(col1, itemColWidth);
    final sizeLines = wrapAndCenterText(col2, sizeColWidth);
    final countLines = wrapAndCenterText(col3, countColWidth);
    final priceLines = wrapAndCenterText(col4, priceColWidth);

    final maxLines = [itemLines.length, sizeLines.length, countLines.length, priceLines.length].reduce((a, b) => a > b ? a : b);

    final buffer = StringBuffer();
    for (int i = 0; i < maxLines; i++) {
      final itemLine = i < itemLines.length ? itemLines[i] : ''.padRight(itemColWidth);
      final sizeLine = i < sizeLines.length ? sizeLines[i] : ''.padRight(sizeColWidth);
      final countLine = i < countLines.length ? countLines[i] : ''.padRight(countColWidth);
      final priceLine = i < priceLines.length ? priceLines[i] : ''.padRight(priceColWidth);
      buffer.writeln('$itemLine$sizeLine$countLine$priceLine');
    }
    return buffer.toString();
  }

  List<String> wrapAndCenterText(String text, int maxWidth) {
    List<String> result = [];
    for (int i = 0; i < text.length; i += maxWidth) {
      final part = text.substring(i, (i + maxWidth) > text.length ? text.length : (i + maxWidth));
      result.add(centerCellText(part, maxWidth));
    }
    return result;
  }

  String centerCellText(String text, int width) {
    final totalSpaces = width - text.length;
    final leftSpaces = (totalSpaces / 2).floor();
    final rightSpaces = totalSpaces - leftSpaces;
    return '${' ' * leftSpaces}$text${' ' * rightSpaces}';
  }
}
