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
  bool _includeDelivery = false;
  final TextEditingController _deliveryController = TextEditingController();

  String generateReceipt(cart, {double? deliveryCharge}) {
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
    final cart = cartProvider.items;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Cart'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ✅ Delivery Option
            Row(
              children: [
                Checkbox(
                  value: _includeDelivery,
                  onChanged: (val) => setState(() => _includeDelivery = val ?? false),
                ),
                const Text("Include Delivery Charge"),
                const SizedBox(width: 12),
                if (_includeDelivery)
                  Expanded(
                    child: TextField(
                      controller: _deliveryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Delivery Charge (L.L)",
                      ),
                    ),
                  ),
              ],
            ),

            Expanded(
              child: cart.isEmpty
                  ? const Center(child: Text('Your cart is empty.', style: TextStyle(fontSize: 18)))
                  : ListView.builder(
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        final item = cart[index]['item'];
                        final count = cart[index]['count'];
                        final price = item.price;
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text("${item.name} x$count",
                                style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                            subtitle: Text('${item.size} - ${formatter.format(price)} L.L each'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => cartProvider.removeItem(item),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor, width: 1.5),
              ),
              child: Text(
                "Total: ${formatter.format(cartProvider.totalPrice)} L.L",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Download as .txt'),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                  onPressed: () {
                    final delivery = _includeDelivery ? double.tryParse(_deliveryController.text) ?? 0.0 : null;
                    downloadTextFile(generateReceipt(cart, deliveryCharge: delivery), "receipt.txt");
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Cart'),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                  onPressed: () {
                    cartProvider.saveCart(); // ✅ Never saves delivery
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(duration: Duration(milliseconds: 300), content: Text("Cart saved!")),
                    );
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.print),
                  label: const Text('Print'),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                  onPressed: () {
                    final receipt = generateReceipt(cart); // ✅ Never includes delivery
                    printReceipt(receipt);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
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
