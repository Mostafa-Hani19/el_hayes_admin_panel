// ignore_for_file: deprecated_member_use, use_super_parameters

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/sidebar_menu.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/monthly_comparison_table.dart';
import '../widgets/top_selling_products_table.dart';
import 'package:go_router/go_router.dart';

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
  bool _isLoadingUsers = false;
  bool _isLoadingOrders = false;
  bool _isLoadingProducts = false;
  bool _isLoadingRevenue = false;

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
        _redirectToLogin(
          'Access denied. Only admins can access the dashboard.',
        );
      }
    } catch (e) {
      _redirectToLogin('Error verifying admin status. Please try again.');
    }
  }

  void _redirectToLogin(String message) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.setErrorMessage(message);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go(Constants.loginRoute);
    });
  }

  Future<void> _fetchUserCount() async {
    setState(() => _isLoadingUsers = true);
    try {
      final supabase = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).supabaseClient;
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
      final supabase = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).supabaseClient;
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
      final supabase = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).supabaseClient;
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
      final supabase = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).supabaseClient;
      final now = DateTime.now();
      final lastMonth = now.subtract(const Duration(days: 30));
      final prevMonth = now.subtract(const Duration(days: 60));
      final deliveredOrders = await supabase
          .from('orders')
          .select('id')
          .eq('status', 'Delivered')
          .gte('created_at', lastMonth.toIso8601String());
      final deliveredOrderIds = (deliveredOrders as List)
          .map((o) => o['id'])
          .toList();
      final prevDeliveredOrders = await supabase
          .from('orders')
          .select('id')
          .eq('status', 'Delivered')
          .gte('created_at', prevMonth.toIso8601String())
          .lt('created_at', lastMonth.toIso8601String());
      final prevDeliveredOrderIds = (prevDeliveredOrders as List)
          .map((o) => o['id'])
          .toList();
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
    final double sectionSpacing = isMobile ? 20 : 40;
    final double cardSpacing = isMobile ? 14 : 28;
    final double welcomeFontSize = isMobile ? 22 : 32;
    final double overviewFontSize = isMobile ? 18 : 24;
    final Color bgGradientStart = Colors.grey[100]!;
    final Color bgGradientEnd = Colors.blueGrey[50]!;
    
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: isMobile ? const SidebarMenu() : null,
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 0.5,
        actions: [
          const SizedBox(width: Constants.smallPadding),
          const SizedBox(width: Constants.smallPadding),
        ],
      ),
      drawer: isMobile ? const SidebarMenu() : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgGradientStart, bgGradientEnd],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMobile) const SidebarMenu(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 32,
                  vertical: isMobile ? 16 : 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    Padding(
                      padding: EdgeInsets.only(bottom: sectionSpacing),
                      child: Text(
                        'Welcome, ${authProvider.currentUser?.fullName ?? "Admin"}!',
                        style: TextStyle(
                          fontSize: welcomeFontSize,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: Colors.blueGrey[900],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    // Overview Section Header
                    Padding(
                      padding: EdgeInsets.only(bottom: cardSpacing / 2),
                      child: Text(
                        'Dashboard Overview',
                        style: TextStyle(
                          fontSize: overviewFontSize,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Cairo',
                          color: Colors.blueGrey[700],
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    // Dashboard Cards
                    Padding(
                      padding: EdgeInsets.only(bottom: sectionSpacing),
                      child: _buildModernGrid(isMobile, isTablet),
                    ),
                    Divider(height: sectionSpacing * 1.2, thickness: 1.2, color: Colors.blueGrey[100]),
                    // Monthly Comparison Table
                    Padding(
                      padding: EdgeInsets.only(bottom: sectionSpacing),
                      child: MonthlyComparisonTable(
                        orderThisMonth: _orderCount,
                        orderLastMonth: _prevOrderCount,
                        orderPercent: _calcPercentage(_orderCount, _prevOrderCount),
                        revenueThisMonth: _revenue,
                        revenueLastMonth: _prevRevenue,
                        revenuePercent: _calcPercentage(_revenue, _prevRevenue),
                      ),
                    ),
                    // Top Selling Products Table
                    const TopSellingProductsTable(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernGrid(bool isMobile, bool isTablet) {
    int crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);
    return LayoutBuilder(
      builder: (context, constraints) {
        double availableWidth = constraints.maxWidth;
        if (!isMobile && availableWidth < 600) {
          crossAxisCount = 2;
        }
        final cardList = [
          _ModernDashboardCard(
            title: 'Total Users',
            value: _isLoadingUsers ? '...' : _userCount.toString(),
            icon: Icons.people,
            color: Colors.blue,
            onTap: () {
              context.go(Constants.usersRoute);
            },
            percentage: !_isLoadingUsers ? _calcPercentage(_userCount, _prevUserCount) : null,
            isIncrease: _userCount >= _prevUserCount,
          ),
          _ModernDashboardCard(
            title: 'Total Orders',
            value: _isLoadingOrders ? '...' : _orderCount.toString(),
            icon: Icons.shopping_cart,
            color: Colors.green,
            onTap: () {
              context.go(Constants.ordersRoute);
            },
            percentage: !_isLoadingOrders ? _calcPercentage(_orderCount, _prevOrderCount) : null,
            isIncrease: _orderCount >= _prevOrderCount,
          ),
          _ModernDashboardCard(
            title: 'Total Products',
            value: _isLoadingProducts ? '...' : _productCount.toString(),
            icon: Icons.inventory,
            color: Colors.orange,
            onTap: () {
              context.go(Constants.productsRoute);
            },
            percentage: !_isLoadingProducts ? _calcPercentage(_productCount, _prevProductCount) : null,
            isIncrease: _productCount >= _prevProductCount,
          ),
          _ModernDashboardCard(
            title: 'Revenue',
            value: _isLoadingRevenue ? '...' : '\$${_revenue.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            color: Colors.purple,
            onTap: () {},
            percentage: !_isLoadingRevenue ? _calcPercentage(_revenue, _prevRevenue) : null,
            isIncrease: _revenue >= _prevRevenue,
          ),
        ];
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: Constants.defaultPadding,
          mainAxisSpacing: Constants.defaultPadding,
          children: cardList,
        );
      },
    );
  }
}

class _ModernDashboardCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double? percentage;
  final bool isIncrease;

  const _ModernDashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
    this.percentage,
    required this.isIncrease,
    Key? key,
  }) : super(key: key);

  @override
  State<_ModernDashboardCard> createState() => _ModernDashboardCardState();
}

class _ModernDashboardCardState extends State<_ModernDashboardCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Constants.isDesktop(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(_hovering && isDesktop ? 0.98 : 0.93),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _hovering && isDesktop
                    ? widget.color.withOpacity(0.18)
                    : Colors.grey.withOpacity(0.10),
                blurRadius: _hovering && isDesktop ? 18 : 10,
                offset: const Offset(0, 16),
              ),
            ],
            border: Border.all(
              color: _hovering && isDesktop
                  ? widget.color.withOpacity(0.25)
                  : Colors.transparent,
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: widget.color.withOpacity(0.13),
                    radius: 24,
                    child: Icon(widget.icon, color: widget.color, size: 28),
                  ),
                  const Spacer(),
                  if (widget.percentage != null)
                    Row(
                      children: [
                        Icon(
                          widget.isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                          color: widget.isIncrease ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.percentage!.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: widget.isIncrease ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                widget.value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey[600],
                  fontFamily: 'Cairo',
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeDashboardData {
  final int userCount;
  final int orderCount;
  final int productCount;
  final double revenue;

  HomeDashboardData({
    required this.userCount,
    required this.orderCount,
    required this.productCount,
    required this.revenue,
  });
}

Stream<HomeDashboardData> homeDashboardStream() async* {
  final supabase = Supabase.instance.client;
  await for (final _ in supabase.from('orders').stream(primaryKey: ['id'])) {
    // Fetch all dashboard data in parallel
    final users = await supabase.from('profiles').select('id');
    final orders = await supabase.from('orders').select('id');
    final products = await supabase.from('products').select('id');
    final deliveredOrders = await supabase
        .from('orders')
        .select('id')
        .eq('status', 'Delivered');
    final deliveredOrderIds = (deliveredOrders as List)
        .map((o) => o['id'])
        .toList();
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
    yield HomeDashboardData(
      userCount: users.length,
      orderCount: orders.length,
      productCount: products.length,
      revenue: revenue,
    );
  }
}

final homeStreamProvider = StreamProvider<HomeDashboardData?>.value(
  value: homeDashboardStream(),
  initialData: null,
);
