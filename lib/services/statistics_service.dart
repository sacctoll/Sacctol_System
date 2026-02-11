import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/item.dart';
import '../services/local_storage_service.dart';

class StatisticsService {
  static final NumberFormat formatter = NumberFormat("#,###", "en_US");
  static final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');
  static final DateFormat monthFormatter = DateFormat('yyyy-MM');

  // Generate comprehensive statistics report
  static Future<Map<String, dynamic>> generateComprehensiveReport() async {
    final carts = await LocalStorageService.getSavedCarts();
    
    if (carts.isEmpty) {
      return {
        'error': 'No data available',
        'message': 'No saved carts found to generate statistics.'
      };
    }

    final DateTime now = DateTime.now();
    final stats = <String, dynamic>{};

    // Overall totals
    stats['overall'] = _calculateOverallStats(carts);
    
    // Daily breakdown
    stats['daily'] = _calculateDailyBreakdown(carts);
    
    // Monthly breakdown
    stats['monthly'] = _calculateMonthlyBreakdown(carts);
    
    // Yearly breakdown
    stats['yearly'] = _calculateYearlyBreakdown(carts);
    
    // Product performance
    stats['products'] = _calculateProductPerformance(carts);
    
    // Category performance
    stats['categories'] = _calculateCategoryPerformance(carts);
    
    // Time-based analytics
    stats['timeAnalytics'] = _calculateTimeAnalytics(carts);
    
    // Financial metrics
    stats['financialMetrics'] = _calculateFinancialMetrics(carts);

    // Business insights
    stats['businessInsights'] = _generateBusinessInsights(stats);
    
    stats['generatedAt'] = now.toIso8601String();
    
    return stats;
  }

  static Map<String, dynamic> _calculateOverallStats(List<Map<String, dynamic>> carts) {
    double totalRevenue = 0;
    double totalCost = 0;
    double totalProfit = 0;
    int totalTransactions = carts.length;
    int totalItemsSold = 0;
    double totalDiscountsGiven = 0;
    double totalDeliveryCharges = 0;

    for (final cart in carts) {
      final items = (cart['items'] as List).map((e) {
        final item = Item.fromJson(Map<String, dynamic>.from(e['item']));
        final count = e['count'] ?? 1;
        return {'item': item, 'count': count};
      }).toList();

      double cartRevenue = 0;
      double cartCost = 0;

      for (final entry in items) {
        final item = entry['item'] as Item;
        final count = entry['count'] as int;
        cartRevenue += item.price * count;
        cartCost += item.originPrice * count;
        totalItemsSold += count;
      }

      final hasDiscount = cart['hasDiscount'] ?? false;
      final discountAmount = hasDiscount ? cartRevenue * 0.20 : 0.0;
      final deliveryCharge = (cart['deliveryCharge'] ?? 0).toDouble();

      totalRevenue += (cartRevenue - discountAmount);
      totalCost += cartCost;
      totalDiscountsGiven += discountAmount;
      totalDeliveryCharges += deliveryCharge;
    }

    totalProfit = totalRevenue - totalCost + totalDeliveryCharges;

    return {
      'totalRevenue': totalRevenue,
      'totalCost': totalCost,
      'totalProfit': totalProfit,
      'totalTransactions': totalTransactions,
      'totalItemsSold': totalItemsSold,
      'totalDiscountsGiven': totalDiscountsGiven,
      'totalDeliveryCharges': totalDeliveryCharges,
      'averageOrderValue': totalTransactions > 0 ? (totalRevenue + totalDeliveryCharges) / totalTransactions : 0,
      'profitMargin': totalRevenue > 0 ? (totalProfit / (totalRevenue + totalDeliveryCharges)) * 100 : 0,
      'discountPercentage': totalRevenue > 0 ? (totalDiscountsGiven / totalRevenue) * 100 : 0,
    };
  }

  static Map<String, List<Map<String, dynamic>>> _calculateDailyBreakdown(List<Map<String, dynamic>> carts) {
    final Map<String, List<Map<String, dynamic>>> dailyData = {};

    for (final cart in carts) {
      final date = DateTime.parse(cart['date']);
      final dayKey = dateFormatter.format(date);

      if (!dailyData.containsKey(dayKey)) {
        dailyData[dayKey] = [];
      }
      dailyData[dayKey]!.add(cart);
    }

    final dailyBreakdown = <String, Map<String, dynamic>>{};
    for (final entry in dailyData.entries) {
      dailyBreakdown[entry.key] = _calculateOverallStats(entry.value);
    }

    return {'breakdown': dailyBreakdown.entries.map((e) => {'date': e.key, ...e.value}).toList()};
  }

  static Map<String, List<Map<String, dynamic>>> _calculateMonthlyBreakdown(List<Map<String, dynamic>> carts) {
    final Map<String, List<Map<String, dynamic>>> monthlyData = {};

    for (final cart in carts) {
      final date = DateTime.parse(cart['date']);
      final monthKey = monthFormatter.format(date);

      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = [];
      }
      monthlyData[monthKey]!.add(cart);
    }

    final monthlyBreakdown = <String, Map<String, dynamic>>{};
    for (final entry in monthlyData.entries) {
      monthlyBreakdown[entry.key] = _calculateOverallStats(entry.value);
    }

    return {'breakdown': monthlyBreakdown.entries.map((e) => {'date': e.key, ...e.value}).toList()};
  }

  static Map<String, List<Map<String, dynamic>>> _calculateYearlyBreakdown(List<Map<String, dynamic>> carts) {
    final Map<String, List<Map<String, dynamic>>> yearlyData = {};

    for (final cart in carts) {
      final date = DateTime.parse(cart['date']);
      final yearKey = date.year.toString();

      if (!yearlyData.containsKey(yearKey)) {
        yearlyData[yearKey] = [];
      }
      yearlyData[yearKey]!.add(cart);
    }

    final yearlyBreakdown = <String, Map<String, dynamic>>{};
    for (final entry in yearlyData.entries) {
      yearlyBreakdown[entry.key] = _calculateOverallStats(entry.value);
    }

    return {'breakdown': yearlyBreakdown.entries.map((e) => {'date': e.key, ...e.value}).toList()};
  }

  static Map<String, List<Map<String, dynamic>>> _calculateProductPerformance(List<Map<String, dynamic>> carts) {
    final Map<String, Map<String, dynamic>> productStats = {};

    for (final cart in carts) {
      final items = (cart['items'] as List).map((e) {
        final item = Item.fromJson(Map<String, dynamic>.from(e['item']));
        final count = e['count'] ?? 1;
        return {'item': item, 'count': count};
      }).toList();

      for (final entry in items) {
        final item = entry['item'] as Item;
        final count = entry['count'] as int;
        final productKey = item.name;

        if (!productStats.containsKey(productKey)) {
          productStats[productKey] = {
            'name': item.name,
            'category': item.category,
            'size': item.size,
            'price': item.price,
            'originPrice': item.originPrice,
            'totalSold': 0,
            'totalRevenue': 0.0,
            'totalCost': 0.0,
            'appearances': 0,
          };
        }

        productStats[productKey]!['totalSold'] += count;
        productStats[productKey]!['totalRevenue'] += item.price * count;
        productStats[productKey]!['totalCost'] += item.originPrice * count;
        productStats[productKey]!['appearances'] += 1;
      }
    }

    // Calculate profit and sort by performance
    final productList = productStats.values.map((product) {
      final profit = product['totalRevenue'] - product['totalCost'];
      final profitMargin = product['totalRevenue'] > 0 ? (profit / product['totalRevenue']) * 100 : 0;
      
      return {
        ...product,
        'profit': profit,
        'profitMargin': profitMargin,
      };
    }).toList();

    productList.sort((a, b) => b['totalRevenue'].compareTo(a['totalRevenue']));

    return {'products': productList};
  }

  static Map<String, List<Map<String, dynamic>>> _calculateCategoryPerformance(List<Map<String, dynamic>> carts) {
    final Map<String, Map<String, dynamic>> categoryStats = {};

    for (final cart in carts) {
      final items = (cart['items'] as List).map((e) {
        final item = Item.fromJson(Map<String, dynamic>.from(e['item']));
        final count = e['count'] ?? 1;
        return {'item': item, 'count': count};
      }).toList();

      for (final entry in items) {
        final item = entry['item'] as Item;
        final count = entry['count'] as int;
        final categoryKey = item.category;

        if (!categoryStats.containsKey(categoryKey)) {
          categoryStats[categoryKey] = {
            'category': categoryKey,
            'totalSold': 0,
            'totalRevenue': 0.0,
            'totalCost': 0.0,
            'uniqueProducts': <String>{},
          };
        }

        categoryStats[categoryKey]!['totalSold'] += count;
        categoryStats[categoryKey]!['totalRevenue'] += item.price * count;
        categoryStats[categoryKey]!['totalCost'] += item.originPrice * count;
        (categoryStats[categoryKey]!['uniqueProducts'] as Set<String>).add(item.name);
      }
    }

    final categoryList = categoryStats.values.map((category) {
      final profit = category['totalRevenue'] - category['totalCost'];
      final profitMargin = category['totalRevenue'] > 0 ? (profit / category['totalRevenue']) * 100 : 0;
      
      return {
        'category': category['category'],
        'totalSold': category['totalSold'],
        'totalRevenue': category['totalRevenue'],
        'totalCost': category['totalCost'],
        'profit': profit,
        'profitMargin': profitMargin,
        'uniqueProducts': (category['uniqueProducts'] as Set<String>).length,
      };
    }).toList();

    categoryList.sort((a, b) => b['totalRevenue'].compareTo(a['totalRevenue']));

    return {'categories': categoryList};
  }

  static Map<String, dynamic> _calculateTimeAnalytics(List<Map<String, dynamic>> carts) {
    if (carts.isEmpty) return {};

    final dates = carts.map((cart) => DateTime.parse(cart['date'])).toList();
    dates.sort();

    final firstSale = dates.first;
    final lastSale = dates.last;
    final daysBetween = lastSale.difference(firstSale).inDays + 1;

    // Day of week analysis
    final Map<int, int> dayOfWeekSales = {};
    final Map<int, double> dayOfWeekRevenue = {};

    for (final cart in carts) {
      final date = DateTime.parse(cart['date']);
      final dayOfWeek = date.weekday;

      dayOfWeekSales[dayOfWeek] = (dayOfWeekSales[dayOfWeek] ?? 0) + 1;
      
      final cartRevenue = _calculateCartRevenue(cart);
      dayOfWeekRevenue[dayOfWeek] = (dayOfWeekRevenue[dayOfWeek] ?? 0) + cartRevenue;
    }

    final weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayOfWeekAnalysis = List.generate(7, (index) {
      final dayIndex = index + 1;
      return {
        'day': weekDays[index],
        'sales': dayOfWeekSales[dayIndex] ?? 0,
        'revenue': dayOfWeekRevenue[dayIndex] ?? 0.0,
      };
    });

    return {
      'firstSale': firstSale.toIso8601String(),
      'lastSale': lastSale.toIso8601String(),
      'totalDays': daysBetween,
      'averageSalesPerDay': carts.length / daysBetween,
      'dayOfWeekAnalysis': dayOfWeekAnalysis,
    };
  }

  static double _calculateCartRevenue(Map<String, dynamic> cart) {
    final items = (cart['items'] as List).map((e) {
      final item = Item.fromJson(Map<String, dynamic>.from(e['item']));
      final count = e['count'] ?? 1;
      return {'item': item, 'count': count};
    }).toList();

    double revenue = 0;
    for (final entry in items) {
      final item = entry['item'] as Item;
      final count = entry['count'] as int;
      revenue += item.price * count;
    }

    final hasDiscount = cart['hasDiscount'] ?? false;
    final discountAmount = hasDiscount ? revenue * 0.20 : 0.0;
    final deliveryCharge = (cart['deliveryCharge'] ?? 0).toDouble();

    return revenue - discountAmount + deliveryCharge;
  }

  static Map<String, dynamic> _calculateFinancialMetrics(List<Map<String, dynamic>> carts) {
    if (carts.isEmpty) return {};

    final revenues = <double>[];
    final profits = <double>[];

    for (final cart in carts) {
      final cartRevenue = _calculateCartRevenue(cart);
      final cartCost = _calculateCartCost(cart);
      revenues.add(cartRevenue);
      profits.add(cartRevenue - cartCost);
    }

    revenues.sort();
    profits.sort();

    return {
      'averageOrderValue': revenues.isNotEmpty ? revenues.reduce((a, b) => a + b) / revenues.length : 0,
      'medianOrderValue': revenues.isNotEmpty ? revenues[revenues.length ~/ 2] : 0,
      'highestOrderValue': revenues.isNotEmpty ? revenues.last : 0,
      'lowestOrderValue': revenues.isNotEmpty ? revenues.first : 0,
      'averageProfit': profits.isNotEmpty ? profits.reduce((a, b) => a + b) / profits.length : 0,
      'medianProfit': profits.isNotEmpty ? profits[profits.length ~/ 2] : 0,
      'highestProfit': profits.isNotEmpty ? profits.last : 0,
      'lowestProfit': profits.isNotEmpty ? profits.first : 0,
    };
  }

  static double _calculateCartCost(Map<String, dynamic> cart) {
    final items = (cart['items'] as List).map((e) {
      final item = Item.fromJson(Map<String, dynamic>.from(e['item']));
      final count = e['count'] ?? 1;
      return {'item': item, 'count': count};
    }).toList();

    double cost = 0;
    for (final entry in items) {
      final item = entry['item'] as Item;
      final count = entry['count'] as int;
      cost += item.originPrice * count;
    }

    return cost;
  }

  static Map<String, dynamic> _generateBusinessInsights(Map<String, dynamic> stats) {
    final insights = <String>[];

    final overall = stats['overall'];
    if (overall != null) {
      final profitMargin = overall['profitMargin'];
      if (profitMargin > 30) {
        insights.add('Excellent profit margin of ${profitMargin.toStringAsFixed(2)}%');
      } else if (profitMargin > 20) {
        insights.add('Good profit margin of ${profitMargin.toStringAsFixed(2)}%');
      } else if (profitMargin > 10) {
        insights.add('Fair profit margin of ${profitMargin.toStringAsFixed(2)}%. Consider optimizing costs.');
      } else {
        insights.add('Low profit margin of ${profitMargin.toStringAsFixed(2)}%. Urgent cost optimization needed.');
      }

      final averageOrderValue = overall['averageOrderValue'];
      insights.add('Average order value is ${formatter.format(averageOrderValue)} L.L');

      final discountPercentage = overall['discountPercentage'];
      if (discountPercentage > 15) {
        insights.add('High discount rate of ${discountPercentage.toStringAsFixed(2)}%. Consider reducing discounts.');
      }
    }

    final products = stats['products']?['products'];
    if (products != null && products.isNotEmpty) {
      final topProduct = products[0];
      insights.add('Top selling product: ${topProduct['name']} with revenue of ${formatter.format(topProduct['totalRevenue'])} L.L');
      
      final topProfitProduct = [...products]..sort((a, b) => b['profit'].compareTo(a['profit']));
      if (topProfitProduct.isNotEmpty) {
        final mostProfitable = topProfitProduct[0];
        insights.add('Most profitable product: ${mostProfitable['name']} with profit of ${formatter.format(mostProfitable['profit'])} L.L');
      }
    }

    final timeAnalytics = stats['timeAnalytics'];
    if (timeAnalytics != null && timeAnalytics['dayOfWeekAnalysis'] != null) {
      final dayAnalysis = timeAnalytics['dayOfWeekAnalysis'] as List;
      dayAnalysis.sort((a, b) => b['revenue'].compareTo(a['revenue']));
      if (dayAnalysis.isNotEmpty) {
        final bestDay = dayAnalysis[0];
        insights.add('Best performing day: ${bestDay['day']} with revenue of ${formatter.format(bestDay['revenue'])} L.L');
      }
    }

    return {
      'insights': insights,
      'recommendations': [
        'Focus on promoting top-performing products',
        'Analyze low-performing days for improvement opportunities',
        'Consider bundling products to increase average order value',
        'Monitor profit margins regularly and adjust pricing when needed',
        'Track seasonal trends for better inventory planning',
      ],
    };
  }

  // Generate comprehensive text report with beautiful formatting
  static Future<String?> generateTextContent(Map<String, dynamic> stats) async {
    try {
      final StringBuffer buffer = StringBuffer();
      
      // Header with beautiful formatting
      buffer.writeln('╔═══════════════════════════════════════════════════════════════════╗');
      buffer.writeln('║                    📊 SACCTOL SALES REPORT                      ║');
      buffer.writeln('╚═══════════════════════════════════════════════════════════════════╝');
      buffer.writeln();
      buffer.writeln('📅 Generated: ${DateFormat('EEEE, MMMM dd, yyyy • h:mm a').format(DateTime.now())}');
      buffer.writeln('═' * 70);
      buffer.writeln();
      
      // Overall Summary with enhanced design
      final overall = stats['overall'];
      if (overall != null) {
        buffer.writeln('💰 FINANCIAL OVERVIEW');
        buffer.writeln('─' * 70);
        buffer.writeln('💵 Total Revenue ................ ${formatter.format(overall['totalRevenue'])} L.L');
        buffer.writeln('🏷️  Total Cost .................. ${formatter.format(overall['totalCost'])} L.L');
        buffer.writeln('💸 Total Profit ................. ${formatter.format(overall['totalProfit'])} L.L');
        buffer.writeln('📊 Profit Margin ................ ${overall['profitMargin'].toStringAsFixed(2)}%');
        buffer.writeln();
        
        buffer.writeln('📈 BUSINESS PERFORMANCE');
        buffer.writeln('─' * 70);
        buffer.writeln('🛒 Total Orders ................. ${overall['totalTransactions']}');
        buffer.writeln('📦 Total Items Sold ............. ${overall['totalItemsSold']}');
        buffer.writeln('💳 Average Order Value .......... ${formatter.format(overall['averageOrderValue'])} L.L');
        buffer.writeln('🎁 Total Discounts .............. ${formatter.format(overall['totalDiscountsGiven'])} L.L');
        buffer.writeln('🚚 Delivery Charges ............. ${formatter.format(overall['totalDeliveryCharges'])} L.L');
        buffer.writeln();
      }
      
      // Financial Metrics with better presentation
      final financialMetrics = stats['financialMetrics'];
      if (financialMetrics != null) {
        buffer.writeln('💎 ORDER VALUE ANALYSIS');
        buffer.writeln('─' * 70);
        buffer.writeln('🔥 Highest Order ................ ${formatter.format(financialMetrics['highestOrderValue'])} L.L');
        buffer.writeln('💧 Lowest Order ................. ${formatter.format(financialMetrics['lowestOrderValue'])} L.L');
        buffer.writeln('⚖️  Median Order ................. ${formatter.format(financialMetrics['medianOrderValue'])} L.L');
        buffer.writeln('💰 Avg Profit per Order ......... ${formatter.format(financialMetrics['averageProfit'])} L.L');
        buffer.writeln();
      }
      
      // Top Products with ranking
      final products = stats['products']?['products'];
      if (products != null && products.isNotEmpty) {
        buffer.writeln('🏆 TOP SELLING PRODUCTS');
        buffer.writeln('─' * 70);
        final topProducts = products.take(10).toList();
        for (int i = 0; i < topProducts.length; i++) {
          final product = topProducts[i];
          final rank = ['🥇', '🥈', '🥉'][i < 3 ? i : 3] + (i >= 3 ? ' #${i + 1}' : '');
          buffer.writeln('$rank ${product['name']}');
          buffer.writeln('   📂 Category: ${product['category']}');
          buffer.writeln('   📊 Sold: ${product['totalSold']} units');
          buffer.writeln('   💰 Revenue: ${formatter.format(product['totalRevenue'])} L.L');
          buffer.writeln('   💸 Profit: ${formatter.format(product['profit'])} L.L (${product['profitMargin'].toStringAsFixed(1)}%)');
          buffer.writeln();
        }
      }
      
      // Category Performance with visual indicators
      final categories = stats['categories']?['categories'];
      if (categories != null && categories.isNotEmpty) {
        buffer.writeln('🏷️ CATEGORY PERFORMANCE');
        buffer.writeln('─' * 70);
        for (final category in categories) {
          final performanceIcon = category['profitMargin'] > 30 ? '🚀' : 
                                 category['profitMargin'] > 20 ? '📈' : 
                                 category['profitMargin'] > 10 ? '🔄' : '⚠️';
          buffer.writeln('$performanceIcon ${category['category'].toUpperCase()}');
          buffer.writeln('   📦 ${category['uniqueProducts']} different products');
          buffer.writeln('   🛒 ${category['totalSold']} total units sold');
          buffer.writeln('   💰 Revenue: ${formatter.format(category['totalRevenue'])} L.L');
          buffer.writeln('   💸 Profit: ${formatter.format(category['profit'])} L.L (${category['profitMargin'].toStringAsFixed(1)}%)');
          buffer.writeln();
        }
      }
      
      // Time Analytics with calendar view
      final timeAnalytics = stats['timeAnalytics'];
      if (timeAnalytics != null) {
        buffer.writeln('📅 TIME & TRENDS ANALYSIS');
        buffer.writeln('─' * 70);
        buffer.writeln('🗓️  Business Period: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(timeAnalytics['firstSale']))} → ${DateFormat('MMM dd, yyyy').format(DateTime.parse(timeAnalytics['lastSale']))}');
        buffer.writeln('⏱️  Total Active Days: ${timeAnalytics['totalDays']} days');
        buffer.writeln('📊 Average Sales/Day: ${timeAnalytics['averageSalesPerDay'].toStringAsFixed(1)} orders');
        buffer.writeln();
        
        final dayAnalysis = timeAnalytics['dayOfWeekAnalysis'];
        if (dayAnalysis != null) {
          buffer.writeln('🗓️  WEEKLY PERFORMANCE PATTERN');
          buffer.writeln('─' * 70);
          final sortedDays = List.from(dayAnalysis)..sort((a, b) => b['revenue'].compareTo(a['revenue']));
          for (int i = 0; i < sortedDays.length; i++) {
            final day = sortedDays[i];
            final performanceIcon = i == 0 ? '🔥' : i == 1 ? '⭐' : i == 2 ? '✨' : '📊';
            buffer.writeln('$performanceIcon ${day['day'].padRight(10)} ${day['sales'].toString().padLeft(3)} orders → ${formatter.format(day['revenue'])} L.L');
          }
          buffer.writeln();
        }
      }
      
      // Complete Daily Performance - ALL DATA
      final daily = stats['daily']?['breakdown'];
      if (daily != null && daily.isNotEmpty) {
        // Sort by date (most recent first)
        final sortedDays = List.from(daily)..sort((a, b) => b['date'].compareTo(a['date']));
        
        buffer.writeln('📊 COMPLETE DAILY PERFORMANCE (All ${sortedDays.length} days)');
        buffer.writeln('─' * 70);
        double totalDailyProfit = 0;
        int totalDailyOrders = 0;
        
        for (final day in sortedDays) {
          final orders = (day['totalTransactions'] as num? ?? 0).toInt();
          final profit = (day['totalProfit'] as num? ?? 0).toDouble();
          final revenue = (day['totalRevenue'] as num? ?? 0).toDouble();
          totalDailyProfit += profit;
          totalDailyOrders += orders;
          
          final performanceIcon = orders >= 10 ? '🔥' : orders >= 5 ? '📈' : orders >= 1 ? '📊' : '💤';
          buffer.writeln('$performanceIcon ${day['date']} → ${orders.toString().padLeft(2)} orders | Rev: ${formatter.format(revenue)} L.L | Profit: ${formatter.format(profit)} L.L');
        }
        buffer.writeln('─' * 70);
        buffer.writeln('📊 Daily Summary: ${sortedDays.length} days | ${totalDailyOrders} total orders | ${formatter.format(totalDailyProfit)} L.L total profit');
        buffer.writeln();
      }
      
      // Complete Monthly Performance - ALL DATA
      final monthly = stats['monthly']?['breakdown'];
      if (monthly != null && monthly.isNotEmpty) {
        // Sort by month (most recent first)
        final sortedMonths = List.from(monthly)..sort((a, b) => b['date'].compareTo(a['date']));
        
        buffer.writeln('📅 COMPLETE MONTHLY PERFORMANCE (All ${sortedMonths.length} months)');
        buffer.writeln('─' * 70);
        double totalMonthlyProfit = 0;
        int totalMonthlyOrders = 0;
        
        for (final month in sortedMonths) {
          final orders = (month['totalTransactions'] as num? ?? 0).toInt();
          final profit = (month['totalProfit'] as num? ?? 0).toDouble();
          final revenue = (month['totalRevenue'] as num? ?? 0).toDouble();
          final itemsSold = (month['totalItemsSold'] as num? ?? 0).toInt();
          totalMonthlyProfit += profit;
          totalMonthlyOrders += orders;
          
          final performanceIcon = orders >= 50 ? '🚀' : orders >= 20 ? '🔥' : orders >= 10 ? '📈' : orders >= 1 ? '📊' : '💤';
          final monthName = DateFormat('MMMM yyyy').format(DateTime.parse(month['date'] + '-01'));
          buffer.writeln('$performanceIcon $monthName');
          buffer.writeln('   🛒 Orders: ${orders.toString().padLeft(3)} | 📦 Items: ${itemsSold.toString().padLeft(4)} | 💰 Revenue: ${formatter.format(revenue)} L.L | 💸 Profit: ${formatter.format(profit)} L.L');
          if (revenue > 0) {
            final profitMargin = (profit / revenue) * 100;
            buffer.writeln('   📊 Profit Margin: ${profitMargin.toStringAsFixed(1)}% | 💳 Avg Order: ${formatter.format(orders > 0 ? revenue / orders : 0)} L.L');
          }
          buffer.writeln();
        }
        buffer.writeln('─' * 70);
        buffer.writeln('📅 Monthly Summary: ${sortedMonths.length} months | ${totalMonthlyOrders} total orders | ${formatter.format(totalMonthlyProfit)} L.L total profit');
        buffer.writeln();
      }
      
      // Yearly Performance if data spans multiple years
      final yearly = stats['yearly']?['breakdown'];
      if (yearly != null && yearly.isNotEmpty) {
        // Sort by year (most recent first)
        final sortedYears = List.from(yearly)..sort((a, b) => b['date'].compareTo(a['date']));
        
        buffer.writeln('🗓️ YEARLY PERFORMANCE (All ${sortedYears.length} years)');
        buffer.writeln('─' * 70);
        for (final year in sortedYears) {
          final orders = (year['totalTransactions'] as num? ?? 0).toInt();
          final profit = (year['totalProfit'] as num? ?? 0).toDouble();
          final revenue = (year['totalRevenue'] as num? ?? 0).toDouble();
          final itemsSold = (year['totalItemsSold'] as num? ?? 0).toInt();
          
          final performanceIcon = orders >= 200 ? '🏆' : orders >= 100 ? '🚀' : orders >= 50 ? '🔥' : '📈';
          buffer.writeln('$performanceIcon Year ${year['date']}');
          buffer.writeln('   🛒 Orders: ${orders.toString().padLeft(4)} | 📦 Items: ${itemsSold.toString().padLeft(5)} | 💰 Revenue: ${formatter.format(revenue)} L.L | 💸 Profit: ${formatter.format(profit)} L.L');
          if (revenue > 0) {
            final profitMargin = (profit / revenue) * 100;
            buffer.writeln('   📊 Profit Margin: ${profitMargin.toStringAsFixed(1)}% | 💳 Avg Order: ${formatter.format(orders > 0 ? revenue / orders : 0)} L.L');
          }
          buffer.writeln();
        }
        buffer.writeln();
      }
      
      // Business Insights with actionable recommendations
      final insights = stats['businessInsights'];
      if (insights != null) {
        final insightsList = insights['insights'] ?? [];
        final recommendations = insights['recommendations'] ?? [];
        
        if (insightsList.isNotEmpty) {
          buffer.writeln('💡 KEY BUSINESS INSIGHTS');
          buffer.writeln('─' * 70);
          for (final insight in insightsList) {
            buffer.writeln('✨ $insight');
          }
          buffer.writeln();
        }
        
        if (recommendations.isNotEmpty) {
          buffer.writeln('🎯 ACTIONABLE RECOMMENDATIONS');
          buffer.writeln('─' * 70);
          for (int i = 0; i < recommendations.length; i++) {
            buffer.writeln('${i + 1}. ${recommendations[i]}');
          }
          buffer.writeln();
        }
      }
      
      // Footer with branding
      buffer.writeln('═' * 70);
      buffer.writeln('📱 Generated by Sacctol System');
      buffer.writeln('📊 Professional Sales Analytics Platform');
      buffer.writeln('🕒 ${DateFormat('h:mm a').format(DateTime.now())} • ${DateFormat('MMM dd, yyyy').format(DateTime.now())}');
      buffer.writeln('═' * 70);
      
      return buffer.toString();
    } catch (e) {
      if (kDebugMode) {
        print('Error generating text content: $e');
      }
      return null;
    }
  }

  // Share statistics
  static Future<void> shareStatistics() async {
    try {
      final stats = await generateComprehensiveReport();
      
      if (stats.containsKey('error')) {
        throw Exception(stats['message']);
      }

      // Create a text summary
      final overall = stats['overall'];
      final insights = stats['businessInsights']?['insights'] ?? [];
      
      final String summary = '''
📊 Sacctol System Sales Report
Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}

💰 FINANCIAL SUMMARY
• Total Revenue: ${formatter.format(overall['totalRevenue'])} L.L
• Total Cost: ${formatter.format(overall['totalCost'])} L.L  
• Total Profit: ${formatter.format(overall['totalProfit'])} L.L
• Profit Margin: ${overall['profitMargin'].toStringAsFixed(2)}%

📈 BUSINESS METRICS
• Total Transactions: ${overall['totalTransactions']}
• Total Items Sold: ${overall['totalItemsSold']}
• Average Order Value: ${formatter.format(overall['averageOrderValue'])} L.L
• Total Discounts Given: ${formatter.format(overall['totalDiscountsGiven'])} L.L

🎯 KEY INSIGHTS
${insights.map((insight) => '• $insight').join('\n')}

Generated by Sacctol System
      ''';

      await Share.share(
        summary,
        subject: 'Sacctol System Sales Statistics',
      );
    } catch (e) {
      throw Exception('Error sharing statistics: $e');
    }
  }
}