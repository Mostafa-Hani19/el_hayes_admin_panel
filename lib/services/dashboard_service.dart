import 'package:supabase_flutter/supabase_flutter.dart';

class HomeDashboardData {
  final int userCount;
  final int orderCount;
  final int productCount;
  final double revenue;
  final int prevUserCount;
  final int prevOrderCount;
  final int prevProductCount;
  final double prevRevenue;

  HomeDashboardData({
    required this.userCount,
    required this.orderCount,
    required this.productCount,
    required this.revenue,
    required this.prevUserCount,
    required this.prevOrderCount,
    required this.prevProductCount,
    required this.prevRevenue,
  });
}

class DashboardService {
  final SupabaseClient _supabase;

  DashboardService(this._supabase);

  Future<int> _fetchCount(
      String table, DateTime lastMonth, DateTime prevMonth) async {
    final response = await _supabase
        .from(table)
        .select('id, created_at')
        .gte('created_at', lastMonth.toIso8601String());
    return response.length;
  }

  Future<int> _fetchPrevCount(
      String table, DateTime lastMonth, DateTime prevMonth) async {
    final response = await _supabase
        .from(table)
        .select('id, created_at')
        .gte('created_at', prevMonth.toIso8601String())
        .lt('created_at', lastMonth.toIso8601String());
    return response.length;
  }

  Future<double> _fetchTotalRevenue(List<dynamic> orderIds) async {
    if (orderIds.isEmpty) return 0.0;
    final response = await _supabase
        .from('order_items')
        .select('price, quantity, order_id')
        .inFilter('order_id', orderIds);
    double total = 0.0;
    for (final item in response) {
      final price = (item['price'] ?? 0).toDouble();
      final quantity = (item['quantity'] ?? 0).toDouble();
      total += price * quantity;
    }
    return total;
  }

  Future<HomeDashboardData> fetchAllDashboardData() async {
    final now = DateTime.now();
    final lastMonth = now.subtract(const Duration(days: 30));
    final prevMonth = now.subtract(const Duration(days: 60));

    final userCountFuture = _fetchCount('profiles', lastMonth, prevMonth);
    final prevUserCountFuture =
        _fetchPrevCount('profiles', lastMonth, prevMonth);
    final orderCountFuture = _fetchCount('orders', lastMonth, prevMonth);
    final prevOrderCountFuture =
        _fetchPrevCount('orders', lastMonth, prevMonth);
    final productCountFuture = _fetchCount('products', lastMonth, prevMonth);
    final prevProductCountFuture =
        _fetchPrevCount('products', lastMonth, prevMonth);

    final deliveredOrdersFuture = _supabase
        .from('orders')
        .select('id')
        .eq('status', 'Delivered')
        .gte('created_at', lastMonth.toIso8601String());

    final prevDeliveredOrdersFuture = _supabase
        .from('orders')
        .select('id')
        .eq('status', 'Delivered')
        .gte('created_at', prevMonth.toIso8601String())
        .lt('created_at', lastMonth.toIso8601String());

    final results = await Future.wait([
      userCountFuture,
      prevUserCountFuture,
      orderCountFuture,
      prevOrderCountFuture,
      productCountFuture,
      prevProductCountFuture,
      deliveredOrdersFuture,
      prevDeliveredOrdersFuture,
    ].cast<Future<dynamic>>());

    final deliveredOrderIds =
        (results[6] as List).map((o) => o['id']).toList();
    final prevDeliveredOrderIds =
        (results[7] as List).map((o) => o['id']).toList();

    final revenueFuture = _fetchTotalRevenue(deliveredOrderIds);
    final prevRevenueFuture = _fetchTotalRevenue(prevDeliveredOrderIds);

    final revenueResults =
        await Future.wait([revenueFuture, prevRevenueFuture]);

    return HomeDashboardData(
      userCount: results[0] as int,
      prevUserCount: results[1] as int,
      orderCount: results[2] as int,
      prevOrderCount: results[3] as int,
      productCount: results[4] as int,
      prevProductCount: results[5] as int,
      revenue: revenueResults[0],
      prevRevenue: revenueResults[1],
    );
  }
} 