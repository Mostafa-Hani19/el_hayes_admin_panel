// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/sidebar_menu.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../models/order_model.dart';
import 'package:go_router/go_router.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all';
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Order> _applyFilters(List<Order> orders) {
    final searchQuery = _searchController.text.toLowerCase().trim();
    final filtered = orders.where((order) {
      final matchesStatus = _statusFilter == 'all' || order.status == _statusFilter;
      final matchesDate = (_fromDate == null || order.createdAt.isAfter(_fromDate!)) &&
          (_toDate == null || order.createdAt.isBefore(_toDate!));
      final matchesSearch = searchQuery.isEmpty ||
          order.id.toLowerCase().contains(searchQuery) ||
          order.phone.toLowerCase().contains(searchQuery);
      return matchesStatus && matchesDate && matchesSearch;
    }).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Delivered':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'In Progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = Provider.of<List<Order>>(context);
    final filteredOrders = _applyFilters(orders);
    final isMobile = MediaQuery.of(context).size.width < 600;
    // ignore: unused_local_variable
    final isTablet = MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1024;
    // ignore: unused_local_variable
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final maxContentWidth = 900.0;
    final Color bgGradientStart = Colors.grey[100]!;
    final Color bgGradientEnd = Colors.blueGrey[50]!;

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Orders'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: isMobile ? const SidebarMenu() : null,
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 0.5,
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
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isMobile ? double.infinity : maxContentWidth,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 4.0 : 24.0,
                      vertical: isMobile ? 4.0 : 16.0,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: isMobile ? 180 : 300,
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      labelText: 'Search Orders',
                                      hintText: 'Order number or customer name',
                                      prefixIcon: const Icon(Icons.search),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                DropdownButton<String>(
                                  value: _statusFilter,
                                  items: const [
                                    DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                                    DropdownMenuItem(value: 'Delivered', child: Text('Delivered')),
                                    DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                                    DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                                  ],
                                  onChanged: (val) => setState(() => _statusFilter = val ?? 'all'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.date_range),
                                  label: Text(
                                    _fromDate != null && _toDate != null
                                        ? '${_fromDate!.toLocal()} - ${_toDate!.toLocal()}'
                                        : 'Filter by Date',
                                  ),
                                  onPressed: () async {
                                    final picked = await showDateRangePicker(
                                      context: context,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _fromDate = picked.start;
                                        _toDate = picked.end;
                                      });
                                    }
                                  },
                                ),
                                if (_fromDate != null || _toDate != null)
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    tooltip: 'Clear date filter',
                                    onPressed: () {
                                      setState(() {
                                        _fromDate = null;
                                        _toDate = null;
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Divider(height: isMobile ? 18 : 32, thickness: 1.2, color: Colors.blueGrey[100]),
                        Expanded(
                          child: filteredOrders.isEmpty
                              ? const Center(child: Text('No orders match your filters.'))
                              : ListView.separated(
                                  itemCount: filteredOrders.length,
                                  separatorBuilder: (_, __) => const Divider(),
                                  itemBuilder: (context, i) {
                                    final order = filteredOrders[i];
                                    return _ModernOrderCard(order: order, statusColor: _statusColor(order.status), isMobile: isMobile);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernOrderCard extends StatefulWidget {
  final Order order;
  final Color statusColor;
  final bool isMobile;
  const _ModernOrderCard({required this.order, required this.statusColor, required this.isMobile});

  @override
  State<_ModernOrderCard> createState() => _ModernOrderCardState();
}

class _ModernOrderCardState extends State<_ModernOrderCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        margin: EdgeInsets.symmetric(horizontal: widget.isMobile ? 8 : 16, vertical: widget.isMobile ? 4 : 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(_hovering ? 0.98 : 0.93),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _hovering ? Colors.blue.withOpacity(0.13) : Colors.grey.withOpacity(0.08),
              blurRadius: _hovering ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: _hovering ? Colors.blue.withOpacity(0.18) : Colors.transparent,
            width: 1.1,
          ),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Text(order.id.substring(0, 4)),
          ),
          title: Text(
            'Order #${order.id}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer: ${order.userId}'),
              Text('Phone: ${order.phone}'),
              Text('Address: ${order.address}'),
              Row(
                children: [
                  if (!order.isSeen)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'New',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  Chip(
                    label: Text(order.status, style: const TextStyle(color: Colors.white)),
                    backgroundColor: widget.statusColor,
                  ),
                  const SizedBox(width: 8),
                  Text(order.createdAt != null ? order.createdAt.toString() : ''),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.visibility),
            tooltip: 'View Details',
            onPressed: () async {
              if (!order.isSeen) {
                final supabase = Supabase.instance.client;
                await supabase.from('orders').update({'is_seen': true}).eq('id', order.id);
              }
              context.go('/order_details/${order.id}');
            },
          ),
        ),
      ),
    );
  }
}

Stream<List<Order>> ordersStream() async* {
  final supabase = Supabase.instance.client;
  await for (final data in supabase.from('orders').stream(primaryKey: ['id'])) {
    yield (data as List).map((json) => Order.fromJson(json, [])).toList();
  }
}

final ordersStreamProvider = StreamProvider<List<Order>>.value(
  value: ordersStream(),
  initialData: const [],
); 
