import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sacctol_system/models/item.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:sacctol_system/services/local_storage_service.dart';
import 'package:sacctol_system/services/statistics_service.dart';
import 'package:share_plus/share_plus.dart';
// Web-specific import
import 'dart:html' as html show Blob, Url, AnchorElement, document if (dart.library.io) '';

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
    final filtered =
        _savedCarts.where((cart) {
          final date = DateTime.parse(cart['date']);
          return _filterCart(date);
        }).toList();

    return filtered.reversed.toList();
  }

  double _calculateTotalPrice(List<Map<String, dynamic>> carts) {
    return carts.fold(0, (sum, cart) {
      final items =
          (cart['items'] as List).map((e) {
            final item = Item.fromJson(Map<String, dynamic>.from(e['item']));
            final count = e['count'] ?? 1;
            return {'item': item, 'count': count};
          }).toList();

      final subtotal = items.fold(0.0, (s, entry) {
        final item = entry['item'] as Item;
        final count = entry['count'] as int;
        return s + item.price * count;
      });

      final hasDiscount = cart['hasDiscount'] ?? false;
      final discountAmount = hasDiscount ? subtotal * 0.20 : 0.0;
      final subtotalAfterDiscount = subtotal - discountAmount;
      final deliveryCharge = (cart['deliveryCharge'] ?? 0).toDouble();

      return sum + subtotalAfterDiscount + deliveryCharge;
    });
  }

  double _calculateTotalOrigin(List<Map<String, dynamic>> carts) {
    return carts.fold(0, (sum, cart) {
      final items =
          (cart['items'] as List).map((e) {
            final item = Item.fromJson(Map<String, dynamic>.from(e['item']));
            final count = e['count'] ?? 1;
            return {'item': item, 'count': count};
          }).toList();

      return sum +
          items.fold(0, (s, entry) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export Statistics',
            onPressed: () => _showDownloadDialog(context),
          ),
        ],
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
                          final hasDiscount = cart['hasDiscount'] ?? false;
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
                                '#${filteredCarts.length - index} | Cart Date: ${date.toLocal().toString().split(' ')[0]}',
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
                                  if (hasDiscount)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        '20% OFF',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
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
                                      final cartToDelete = filteredCarts[index];
                                      final actualIndex = _savedCarts.indexOf(
                                        cartToDelete,
                                      );
                                      if (actualIndex != -1) {
                                        await _deleteCart(actualIndex);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            duration: Duration(
                                              milliseconds: 300,
                                            ),
                                            content: Text('Cart deleted'),
                                          ),
                                        );
                                      }

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
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

  void _showDownloadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.analytics,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Export Statistics',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Export your sales statistics:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              _buildExportOption(
                context,
                icon: kIsWeb ? Icons.download : Icons.share,
                title: kIsWeb ? 'Download Report' : 'Share Report',
                subtitle: kIsWeb ? 'Download directly to your computer' : 'Share via apps or save to files',
                onTap: () => _exportToText(dialogContext),
              ),
              const SizedBox(height: 12),
              _buildExportOption(
                context,
                icon: Icons.share,
                title: 'Share Quick Summary',
                subtitle: 'Brief summary for messaging',
                onTap: () => _shareStatistics(dialogContext),
              ),
              const SizedBox(height: 12),
              _buildExportOption(
                context,
                icon: Icons.preview,
                title: 'View Detailed Report',
                subtitle: 'Interactive statistics view',
                onTap: () => _showDetailedReport(dialogContext),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).primaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToText(BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop();
    
    _showLoadingDialog(context, 'Generating your report...');

    try {
      final stats = await StatisticsService.generateComprehensiveReport();
      
      if (stats.containsKey('error')) {
        Navigator.of(context).pop();
        _showErrorSnackBar(stats['message']);
        return;
      }

      final textContent = await StatisticsService.generateTextContent(stats);
      Navigator.of(context).pop();
      
      if (textContent != null) {
        final fileName = 'Sacctol_Sales_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.txt';
        
        if (kIsWeb) {
          // Web platform - direct download
          _downloadFileWeb(textContent, fileName);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.download_done, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Report downloaded to your Downloads folder!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // Mobile platforms - use share
          await Share.shareXFiles(
            [XFile.fromData(
              Uint8List.fromList(utf8.encode(textContent)),
              mimeType: 'text/plain',
              name: fileName,
            )],
            subject: 'Sacctol Sales Report - ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
            text: 'Here is your comprehensive sales report from Sacctol System.',
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.share, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Report shared successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        _showErrorSnackBar('Failed to generate report');
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackBar('Error: $e');
    }
  }

  // Web-specific download function using browser's download API
  void _downloadFileWeb(String content, String fileName) {
    try {
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes], 'text/plain');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..download = fileName
        ..style.display = 'none';
      
      html.document.body?.children.add(anchor);
      
      // Trigger the download
      anchor.click();
      
      // Clean up
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint('Download error: $e');
      _showErrorSnackBar('Download failed: $e');
    }
  }

  Future<void> _shareStatistics(BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop();
    
    _showLoadingDialog(context, 'Preparing statistics...');

    try {
      await StatisticsService.shareStatistics();
      Navigator.of(context).pop();
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackBar('Error: $e');
    }
  }

  Future<void> _showDetailedReport(BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop();
    
    _showLoadingDialog(context, 'Generating detailed report...');

    try {
      final stats = await StatisticsService.generateComprehensiveReport();
      Navigator.of(context).pop();
      
      if (stats.containsKey('error')) {
        _showErrorSnackBar(stats['message']);
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DetailedStatsPage(statistics: stats),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackBar('Error: $e');
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class DetailedStatsPage extends StatefulWidget {
  final Map<String, dynamic> statistics;

  const DetailedStatsPage({super.key, required this.statistics});

  @override
  State<DetailedStatsPage> createState() => _DetailedStatsPageState();
}

class _DetailedStatsPageState extends State<DetailedStatsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat formatter = NumberFormat("#,###", "en_US");

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detailed Statistics'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Products'),
            Tab(text: 'Categories'),
            Tab(text: 'Time Analysis'),
            Tab(text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildProductsTab(),
          _buildCategoriesTab(),
          _buildTimeAnalysisTab(),
          _buildInsightsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final overall = widget.statistics['overall'];
    final financialMetrics = widget.statistics['financialMetrics'];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMetricCard(
            'Financial Overview',
            [
              _buildMetricRow('Total Revenue', '${formatter.format(overall['totalRevenue'])} L.L', Colors.green),
              _buildMetricRow('Total Cost', '${formatter.format(overall['totalCost'])} L.L', Colors.orange),
              _buildMetricRow('Total Profit', '${formatter.format(overall['totalProfit'])} L.L', Colors.blue),
              _buildMetricRow('Profit Margin', '${overall['profitMargin'].toStringAsFixed(2)}%', Colors.purple),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetricCard(
            'Business Metrics',
            [
              _buildMetricRow('Total Transactions', overall['totalTransactions'].toString(), Colors.indigo),
              _buildMetricRow('Total Items Sold', overall['totalItemsSold'].toString(), Colors.teal),
              _buildMetricRow('Average Order Value', '${formatter.format(overall['averageOrderValue'])} L.L', Colors.pink),
              _buildMetricRow('Total Discounts', '${formatter.format(overall['totalDiscountsGiven'])} L.L', Colors.red),
            ],
          ),
          if (financialMetrics != null) ...[
            const SizedBox(height: 16),
            _buildMetricCard(
              'Order Analysis',
              [
                _buildMetricRow('Highest Order', '${formatter.format(financialMetrics['highestOrderValue'])} L.L', Colors.green),
                _buildMetricRow('Lowest Order', '${formatter.format(financialMetrics['lowestOrderValue'])} L.L', Colors.red),
                _buildMetricRow('Median Order', '${formatter.format(financialMetrics['medianOrderValue'])} L.L', Colors.blue),
                _buildMetricRow('Average Profit per Order', '${formatter.format(financialMetrics['averageProfit'])} L.L', Colors.purple),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    final products = widget.statistics['products']?['products'] ?? [];
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(
              product['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category: ${product['category']}'),
                Text('Sold: ${product['totalSold']} units'),
                Text('Revenue: ${formatter.format(product['totalRevenue'])} L.L'),
                Text('Profit: ${formatter.format(product['profit'])} L.L'),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: product['profitMargin'] > 20 ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${product['profitMargin'].toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesTab() {
    final categories = widget.statistics['categories']?['categories'] ?? [];
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(
              category['category'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Products: ${category['uniqueProducts']}'),
                Text('Sold: ${category['totalSold']} units'),
                Text('Revenue: ${formatter.format(category['totalRevenue'])} L.L'),
                Text('Profit: ${formatter.format(category['profit'])} L.L'),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: category['profitMargin'] > 20 ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${category['profitMargin'].toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeAnalysisTab() {
    final timeAnalytics = widget.statistics['timeAnalytics'];
    final dayAnalysis = timeAnalytics?['dayOfWeekAnalysis'] ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (timeAnalytics != null)
            _buildMetricCard(
              'Time Range',
              [
                _buildMetricRow('First Sale', DateFormat('yyyy-MM-dd').format(DateTime.parse(timeAnalytics['firstSale'])), Colors.blue),
                _buildMetricRow('Last Sale', DateFormat('yyyy-MM-dd').format(DateTime.parse(timeAnalytics['lastSale'])), Colors.blue),
                _buildMetricRow('Total Days', timeAnalytics['totalDays'].toString(), Colors.green),
                _buildMetricRow('Avg Sales/Day', timeAnalytics['averageSalesPerDay'].toStringAsFixed(2), Colors.purple),
              ],
            ),
          const SizedBox(height: 16),
          _buildMetricCard(
            'Day of Week Performance',
            dayAnalysis.map<Widget>((day) => _buildMetricRow(
              day['day'],
              '${day['sales']} sales - ${formatter.format(day['revenue'])} L.L',
              Theme.of(context).primaryColor,
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    final insights = widget.statistics['businessInsights'];
    final insightsList = insights?['insights'] ?? [];
    final recommendations = insights?['recommendations'] ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInsightCard(
            'Key Insights',
            insightsList,
            Icons.lightbulb,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            'Recommendations',
            recommendations,
            Icons.trending_up,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, List<dynamic> items, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.toString(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
  