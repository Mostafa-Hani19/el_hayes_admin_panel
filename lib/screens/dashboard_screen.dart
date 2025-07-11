// ignore_for_file: deprecated_member_use, use_super_parameters

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/sidebar_menu.dart';
import '../widgets/monthly_comparison_table.dart';
import '../widgets/top_selling_products_table.dart';
import 'package:go_router/go_router.dart';
import 'package:el_hayes_admin_panel/services/dashboard_service.dart';
import 'package:el_hayes_admin_panel/widgets/modern_dashboard_card.dart';

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
  bool _isLoading = true;
  late final DashboardService _dashboardService;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _dashboardService = DashboardService(authProvider.supabaseClient);
    _fetchAllDashboardData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAdminStatus());
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _fetchAllDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _dashboardService.fetchAllDashboardData();
      if (mounted) {
        setState(() {
          _userCount = data.userCount;
          _prevUserCount = data.prevUserCount;
          _orderCount = data.orderCount;
          _prevOrderCount = data.prevOrderCount;
          _productCount = data.productCount;
          _prevProductCount = data.prevProductCount;
          _revenue = data.revenue;
          _prevRevenue = data.prevRevenue;
        });
      }
    } catch (e) {
      // Handle error appropriately
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
    final double sectionSpacing = isMobile ? 24 : 48;
    final double cardSpacing = isMobile ? 16 : 24;
    final double welcomeFontSize = isMobile ? 24 : 34;
    final double overviewFontSize = isMobile ? 20 : 26;
    const Color bgGradientStart = Color(0xFFf3f6f9);
    const Color bgGradientEnd = Color(0xFFe9eef3);
    
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: isMobile ? const SidebarMenu() : null,
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        actions: [
          const SizedBox(width: Constants.smallPadding),
          const SizedBox(width: Constants.smallPadding),
        ],
      ),
      drawer: isMobile ? const SidebarMenu() : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
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
                      padding: EdgeInsets.only(bottom: cardSpacing),
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
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildModernGrid(isMobile, isTablet),
                    ),
                    Divider(
                        height: sectionSpacing,
                        thickness: 1,
                        color: Colors.grey.withOpacity(0.1)),
                    // Monthly Comparison Table
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: sectionSpacing / 2),
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
    final cardList = [
      ModernDashboardCard(
        title: 'Total Users',
        value: _userCount.toString(),
        icon: Icons.people,
        color: Colors.blue,
        onTap: () {
          context.go(Constants.usersRoute);
        },
        percentage: _calcPercentage(_userCount, _prevUserCount),
        isIncrease: _userCount >= _prevUserCount,
      ),
      ModernDashboardCard(
        title: 'Total Orders',
        value: _orderCount.toString(),
        icon: Icons.shopping_cart,
        color: Colors.green,
        onTap: () {
          context.go(Constants.ordersRoute);
        },
        percentage: _calcPercentage(_orderCount, _prevOrderCount),
        isIncrease: _orderCount >= _prevOrderCount,
      ),
      ModernDashboardCard(
        title: 'Total Products',
        value: _productCount.toString(),
        icon: Icons.inventory,
        color: Colors.orange,
        onTap: () {
          context.go(Constants.productsRoute);
        },
        percentage: _calcPercentage(_productCount, _prevProductCount),
        isIncrease: _productCount >= _prevProductCount,
      ),
      ModernDashboardCard(
        title: 'Revenue',
        value: '\$${_revenue.toStringAsFixed(2)}',
        icon: Icons.attach_money,
        color: Colors.purple,
        onTap: () {},
        percentage: _calcPercentage(_revenue, _prevRevenue),
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
  }
}
