import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/sidebar_menu.dart';
import '../utils/constants.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  double? _deliveryFee;
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _fetchDeliveryFee();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final supabase = authProvider.supabaseClient;

      final response = await supabase
          .from('orders')
          .select('*, profiles:profiles!orders_user_id_fkey(id, full_name)')
          .order('created_at', ascending: false);

      setState(() {
        _orders = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load orders: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDeliveryFee() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final supabase = authProvider.supabaseClient;
    final data = await supabase
        .from('settings')
        .select('value')
        .eq('key', 'delivery_fee')
        .maybeSingle();
    setState(() {
      _deliveryFee = double.tryParse(data?['value'] ?? '0') ?? 0;
    });
  }

  void _applyFilters() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
    });
  }

  List<Map<String, dynamic>> get _filteredOrders {
    return _orders.where((order) {
      final orderNumber = order['id'].toString().toLowerCase();
      final customerName = (order['profiles']?['full_name'] ?? '').toString().toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          orderNumber.contains(_searchQuery) ||
          customerName.contains(_searchQuery);

      final matchesStatus = _statusFilter == 'all' || order['status'] == _statusFilter;

      final createdAt = DateTime.tryParse(order['created_at'] ?? '') ?? DateTime.now();
      final matchesFrom = _fromDate == null || !createdAt.isBefore(_fromDate!);
      final matchesTo = _toDate == null || !createdAt.isAfter(_toDate!);

      return matchesSearch && matchesStatus && matchesFrom && matchesTo;
    }).toList();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  Color _statusColor(String? status) {
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

  String shortOrderId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 4)}...${id.substring(id.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Constants.isMobile(context);
    // ignore: unused_local_variable
    final isTablet = Constants.isTablet(context);
    final maxContentWidth = 900.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      drawer: isMobile ? const SidebarMenu() : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) const SidebarMenu(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : maxContentWidth,
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      if (_deliveryFee != null)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 16.0),
                                          child: Text(
                                            'Delivery Fee: ${_deliveryFee!.toStringAsFixed(2)} EGP',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
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
                                                _applyFilters();
                                              },
                                            ),
                                          ),
                                          onChanged: (_) => _applyFilters(),
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
                                              ? '${DateFormat('yMMMd').format(_fromDate!)} - ${DateFormat('yMMMd').format(_toDate!)}'
                                              : 'Filter by Date',
                                        ),
                                        onPressed: _pickDateRange,
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
                              Expanded(
                                child: _filteredOrders.isEmpty
                                    ? const Center(child: Text('No orders match your filters.'))
                                    : ListView.separated(
                                        itemCount: _filteredOrders.length,
                                        separatorBuilder: (_, __) => const Divider(),
                                        itemBuilder: (context, i) {
                                          final order = _filteredOrders[i];
                                          return Card(
                                            elevation: 2,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            child: ListTile(
                                              leading: CircleAvatar(
                                                child: Text(shortOrderId(order['id'].toString()).substring(0, 4)),
                                              ),
                                              title: Text(
                                                'Order #${shortOrderId(order['id'].toString())}',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  if (order['name'] != null && order['name'].toString().isNotEmpty)
                                                    Text(order['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                                                  Text('Customer: ${order['profiles']?['full_name'] ?? ''}'),
                                                  Text('Phone: ${order['phone'] ?? ''}'),
                                                  Text('Address: ${order['address'] ?? ''}'),
                                                  Row(
                                                    children: [
                                                      Chip(
                                                        label: Text(order['status'] ?? '', style: const TextStyle(color: Colors.white)),
                                                        backgroundColor: _statusColor(order['status']),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(order['created_at'] != null
                                                          ? DateFormat('yMMMd, h:mm a').format(DateTime.parse(order['created_at']))
                                                          : ''),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              trailing: IconButton(
                                                icon: const Icon(Icons.visibility),
                                                tooltip: 'View Details',
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          OrderDetailsScreen(orderId: order['id'].toString()),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
