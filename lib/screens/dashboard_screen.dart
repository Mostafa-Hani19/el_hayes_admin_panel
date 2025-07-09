import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/sidebar_menu.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/monthly_comparison_table.dart';
import '../widgets/top_selling_products_table.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _userCount = 0;
  int _orderCount = 0;
  int _productCount = 0;
  double _revenue = 0.0;
  int _prevUserCount = 0;
  int _prevOrderCount = 0;
  int _prevProductCount = 0;
  double _prevRevenue = 0.0;
  // ignore: unused_field
  List<Activity> _activities = [];
  bool _isLoadingUsers = false;
  bool _isLoadingOrders = false;
  bool _isLoadingProducts = false;
  bool _isLoadingRevenue = false;
  // ignore: unused_field
  bool _isLoadingActivities = false;

  @override
  void initState() {
    super.initState();
    _fetchAllDashboardData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAdminStatus());
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _fetchAllDashboardData() {
    _fetchUserCount();
    _fetchOrderCount();
    _fetchProductCount();
    _fetchRevenue();
    _fetchActivities();
  }
  
  Future<void> _checkAdminStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final supabase = authProvider.supabaseClient;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        _redirectToLogin('Session expired. Please login again.');
        return;
      }
      final response = await supabase
          .from('profiles')
          .select('is_admin')
          .eq('id', userId)
          .maybeSingle();
      final isAdmin = response != null && response['is_admin'] == true;
      if (!isAdmin) {
        _redirectToLogin('Access denied. Only admins can access the dashboard.');
      }
    } catch (e) {
      _redirectToLogin('Error verifying admin status. Please try again.');
    }
  }
  
  void _redirectToLogin(String message) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.setErrorMessage(message);
    Navigator.pushReplacementNamed(context, Constants.loginRoute);
  }

  Future<void> _fetchUserCount() async {
    setState(() => _isLoadingUsers = true);
    try {
      final supabase = Provider.of<AuthProvider>(context, listen: false).supabaseClient;
      final now = DateTime.now();
      final lastMonth = now.subtract(const Duration(days: 30));
      final prevMonth = now.subtract(const Duration(days: 60));
      final response = await supabase
        .from('profiles')
        .select('id, created_at')
        .gte('created_at', lastMonth.toIso8601String());
      final prevResponse = await supabase
        .from('profiles')
        .select('id, created_at')
        .gte('created_at', prevMonth.toIso8601String())
        .lt('created_at', lastMonth.toIso8601String());
      setState(() {
        _userCount = response.length;
        _prevUserCount = prevResponse.length;
      });
    } finally {
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _fetchOrderCount() async {
    setState(() => _isLoadingOrders = true);
    try {
      final supabase = Provider.of<AuthProvider>(context, listen: false).supabaseClient;
      final now = DateTime.now();
      final lastMonth = now.subtract(const Duration(days: 30));
      final prevMonth = now.subtract(const Duration(days: 60));
      final response = await supabase
        .from('orders')
        .select('id, created_at')
        .gte('created_at', lastMonth.toIso8601String());
      final prevResponse = await supabase
        .from('orders')
        .select('id, created_at')
        .gte('created_at', prevMonth.toIso8601String())
        .lt('created_at', lastMonth.toIso8601String());
      setState(() {
        _orderCount = response.length;
        _prevOrderCount = prevResponse.length;
      });
    } finally {
      setState(() => _isLoadingOrders = false);
    }
  }

  Future<void> _fetchProductCount() async {
    setState(() => _isLoadingProducts = true);
    try {
      final supabase = Provider.of<AuthProvider>(context, listen: false).supabaseClient;
      final now = DateTime.now();
      final lastMonth = now.subtract(const Duration(days: 30));
      final prevMonth = now.subtract(const Duration(days: 60));
      final response = await supabase
        .from('products')
        .select('id, created_at')
        .gte('created_at', lastMonth.toIso8601String());
      final prevResponse = await supabase
        .from('products')
        .select('id, created_at')
        .gte('created_at', prevMonth.toIso8601String())
        .lt('created_at', lastMonth.toIso8601String());
      setState(() {
        _productCount = response.length;
        _prevProductCount = prevResponse.length;
      });
    } finally {
      setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _fetchRevenue() async {
    setState(() => _isLoadingRevenue = true);
    try {
      final supabase = Provider.of<AuthProvider>(context, listen: false).supabaseClient;
      final now = DateTime.now();
      final lastMonth = now.subtract(const Duration(days: 30));
      final prevMonth = now.subtract(const Duration(days: 60));
      final deliveredOrders = await supabase
        .from('orders')
        .select('id')
        .eq('status', 'Delivered')
        .gte('created_at', lastMonth.toIso8601String());
      final deliveredOrderIds = (deliveredOrders as List).map((o) => o['id']).toList();
      final prevDeliveredOrders = await supabase
        .from('orders')
        .select('id')
        .eq('status', 'Delivered')
        .gte('created_at', prevMonth.toIso8601String())
        .lt('created_at', lastMonth.toIso8601String());
      final prevDeliveredOrderIds = (prevDeliveredOrders as List).map((o) => o['id']).toList();
      double total = 0.0;
      if (deliveredOrderIds.isNotEmpty) {
        final response = await supabase
          .from('order_items')
          .select('price, quantity, order_id')
          .inFilter('order_id', deliveredOrderIds);
        for (final item in response) {
          final price = (item['price'] ?? 0).toDouble();
          final quantity = (item['quantity'] ?? 0).toDouble();
          total += price * quantity;
        }
      }
      double prevTotal = 0.0;
      if (prevDeliveredOrderIds.isNotEmpty) {
        final prevResponse = await supabase
          .from('order_items')
          .select('price, quantity, order_id')
          .inFilter('order_id', prevDeliveredOrderIds);
        for (final item in prevResponse) {
          final price = (item['price'] ?? 0).toDouble();
          final quantity = (item['quantity'] ?? 0).toDouble();
          prevTotal += price * quantity;
        }
      }
      setState(() {
        _revenue = total;
        _prevRevenue = prevTotal;
      });
    } finally {
      setState(() => _isLoadingRevenue = false);
    }
  }

  Future<void> _fetchActivities() async {
    setState(() => _isLoadingActivities = true);
    try {
      final supabase = Provider.of<AuthProvider>(context, listen: false).supabaseClient;
      final response = await supabase
          .from('activities')
          .select('*')
          .order('time', ascending: false)
          .limit(10);
      setState(() {
        _activities = (response as List).map((a) => Activity.fromJson(a)).toList();
      });
    } finally {
      setState(() => _isLoadingActivities = false);
    }
  }

  double _calcPercentage(num current, num previous) {
    if (previous == 0) {
      return current == 0 ? 0 : 100;
    }
    return ((current - previous) / previous) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    // ignore: unused_local_variable
    final isDesktop = Constants.isDesktop(context);
    final isTablet = Constants.isTablet(context);
    final isMobile = Constants.isMobile(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        leading: isMobile ? const SidebarMenu() : null,
        actions: [
          const SizedBox(width: Constants.smallPadding),
                 const SizedBox(width: Constants.smallPadding),
        ],
      ),
      drawer: isMobile ? const SidebarMenu() : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) const SidebarMenu(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Constants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${authProvider.currentUser?.fullName ?? "Admin"}!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: Constants.defaultPadding),
                  _buildResponsiveGrid(isMobile, isTablet),
                  MonthlyComparisonTable(
                    orderThisMonth: _orderCount,
                    orderLastMonth: _prevOrderCount,
                    orderPercent: _calcPercentage(_orderCount, _prevOrderCount),
                    revenueThisMonth: _revenue,
                    revenueLastMonth: _prevRevenue,
                    revenuePercent: _calcPercentage(_revenue, _prevRevenue),
                  ),
                  const TopSellingProductsTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResponsiveGrid(bool isMobile, bool isTablet) {
    int crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);
    return LayoutBuilder(
      builder: (context, constraints) {
        double availableWidth = constraints.maxWidth;
        if (!isMobile && availableWidth < 600) {
          crossAxisCount = 2;
        }
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: Constants.defaultPadding,
          mainAxisSpacing: Constants.defaultPadding,
          children: [
            DashboardCard(
              title: 'Total Users',
              value: _isLoadingUsers ? '...' : _userCount.toString(),
              icon: Icons.people,
              color: Colors.blue,
              onTap: () {
                Navigator.pushReplacementNamed(context, Constants.usersRoute);
              },
              percentage: !_isLoadingUsers ? _calcPercentage(_userCount, _prevUserCount) : null,
              isIncrease: _userCount >= _prevUserCount,
            ),
            DashboardCard(
              title: 'Total Orders',
              value: _isLoadingOrders ? '...' : _orderCount.toString(),
              icon: Icons.shopping_cart,
              color: Colors.green,
              onTap: () {
                Navigator.pushReplacementNamed(context, Constants.ordersRoute);
              },
              percentage: !_isLoadingOrders ? _calcPercentage(_orderCount, _prevOrderCount) : null,
              isIncrease: _orderCount >= _prevOrderCount,
            ),
            DashboardCard(
              title: 'Total Products',
              value: _isLoadingProducts ? '...' : _productCount.toString(),
              icon: Icons.inventory,
              color: Colors.orange,
              onTap: () {
                Navigator.pushReplacementNamed(context, Constants.productsRoute);
              },
              percentage: !_isLoadingProducts ? _calcPercentage(_productCount, _prevProductCount) : null,
              isIncrease: _productCount >= _prevProductCount,
            ),
            DashboardCard(
              title: 'Revenue',
              value: _isLoadingRevenue ? '...' : '\$${_revenue.toStringAsFixed(2)}',
              icon: Icons.attach_money,
              color: Colors.purple,
              percentage: !_isLoadingRevenue ? _calcPercentage(_revenue, _prevRevenue) : null,
              isIncrease: _revenue >= _prevRevenue,
            ),
                // const TopSellingProductsTabel(),

          ],
        );
      }
    );
  }
}

class Activity {
  final String user;
  final String action;
  final String time;
  final String avatar;

  Activity({required this.user, required this.action, required this.time, required this.avatar});

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      user: json['user'] ?? '',
      action: json['action'] ?? '',
      time: json['time'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }
}

// ignore: unused_element
class _ActivityList extends StatelessWidget {
  final List<Activity> activities;
  final bool isLoading;
  const _ActivityList({required this.activities, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (activities.isEmpty) {
      return const Center(child: Text('No recent activities.'));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final activity = activities[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: activity.avatar.isNotEmpty ? NetworkImage(activity.avatar) : null,
            child: activity.avatar.isEmpty ? const Icon(Icons.person) : null,
          ),
          title: Text(activity.user),
          subtitle: Text(activity.action),
          trailing: Text(activity.time),
        );
      },
    );
  }
} 

class HomeDashboardData {
  final int userCount;
  final int orderCount;
  final int productCount;
  final double revenue;
  final List<Activity> activities;

  HomeDashboardData({
    required this.userCount,
    required this.orderCount,
    required this.productCount,
    required this.revenue,
    required this.activities,
  });
}

Stream<HomeDashboardData> homeDashboardStream() async* {
  final supabase = Supabase.instance.client;
  await for (final _ in supabase
      .from('orders')
      .stream(primaryKey: ['id'])) {
    // Fetch all dashboard data in parallel
    final users = await supabase.from('profiles').select('id');
    final orders = await supabase.from('orders').select('id');
    final products = await supabase.from('products').select('id');
    final deliveredOrders = await supabase
        .from('orders')
        .select('id')
        .eq('status', 'Delivered');
    final deliveredOrderIds = (deliveredOrders as List).map((o) => o['id']).toList();
    double revenue = 0.0;
    if (deliveredOrderIds.isNotEmpty) {
      final orderItems = await supabase
          .from('order_items')
          .select('price, quantity, order_id')
          .inFilter('order_id', deliveredOrderIds);
      for (final item in orderItems) {
        final price = (item['price'] ?? 0).toDouble();
        final quantity = (item['quantity'] ?? 0).toDouble();
        revenue += price * quantity;
      }
    }
    final activitiesResp = await supabase
        .from('activities')
        .select('*')
        .order('time', ascending: false)
        .limit(10);
    final activities = (activitiesResp as List)
        .map((a) => Activity.fromJson(a))
        .toList();
    yield HomeDashboardData(
      userCount: users.length,
      orderCount: orders.length,
      productCount: products.length,
      revenue: revenue,
      activities: activities,
    );
  }
}

final homeStreamProvider = StreamProvider<HomeDashboardData?>.value(
  value: homeDashboardStream(),
  initialData: null,
); 