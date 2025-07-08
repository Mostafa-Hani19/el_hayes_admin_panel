import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/rendering.dart';
import '../widgets/sidebar_menu.dart';
import '../utils/constants.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String? _error;
  String? _status;
  bool _isUpdating = false;
  double? _deliveryFee;

  @override
  void initState() {
    super.initState();
    _fetchDeliveryFee();
    _loadOrderDetails();
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

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final supabase = authProvider.supabaseClient;
      final orderResp = await supabase
          .from('orders')
          .select('*, profiles:profiles!orders_user_id_fkey(id, full_name)')
          .eq('id', widget.orderId)
          .maybeSingle();
      final itemsResp = await supabase
          .from('order_items')
          .select('*, products:products(id, name, image_url)')
          .eq('order_id', widget.orderId);
      setState(() {
        _order = orderResp;
        _items = List<Map<String, dynamic>>.from(itemsResp);
        final validStatuses = ['Delivered', 'Rejected', 'In Progress'];
        final status = orderResp?['status']?.toString();
        _status = validStatuses.contains(status) ? status : 'In Progress';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load order details: $e';
        _isLoading = false;
      });
    }
  }

  Future<bool> _updateStatus() async {
    if (_order == null) return false;
    setState(() => _isUpdating = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final supabase = authProvider.supabaseClient;
      await supabase
          .from('orders')
          .update({'status': _status})
          .eq('id', widget.orderId);
      return true;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      return false;
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  double get _totalPrice {
    return _items.fold(
      0,
      (total, item) => total + (item['price'] ?? 0) * (item['quantity'] ?? 0),
    );
  }

  double get _totalWithDelivery {
    return _totalPrice + (_deliveryFee ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Constants.isMobile(context);
    final maxContentWidth = 800.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print Order',
            onPressed: () async {
              if (_order == null) return;
              final fontData = await rootBundle.load(
                'assets/fonts/Cairo-Regular.ttf',
              );
              final ttf = pw.Font.ttf(fontData);
              final pdf = pw.Document();
              pdf.addPage(
                pw.Page(
                  build: (context) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Order #: ${_order!['id']}',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (_order != null && _order!['name'] != null && _order!['name'].toString().isNotEmpty) ...[
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Name: ${_order!['name']}',
                          style: pw.TextStyle(font: ttf),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Customer: ${_order!['profiles']?['full_name'] ?? ''}',
                        style: pw.TextStyle(font: ttf),
                      ),
                      pw.Text(
                        'Address: ${_order!['address'] ?? ''}',
                        style: pw.TextStyle(font: ttf),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.Text(
                        'Status: ${_order!['status'] ?? ''}',
                        style: pw.TextStyle(font: ttf),
                      ),
                      pw.Text(
                        'Created: ${_order!['created_at'] ?? ''}',
                        style: pw.TextStyle(font: ttf),
                      ),
                      pw.SizedBox(height: 16),
                      pw.Text(
                        'Products:',
                        style: pw.TextStyle(
                          font: ttf,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Table(
                        border: pw.TableBorder.all(),
                        columnWidths: {
                          0: const pw.FlexColumnWidth(2), // Product
                          1: const pw.FlexColumnWidth(1), // Qty
                          2: const pw.FlexColumnWidth(1), // Price
                          3: const pw.FlexColumnWidth(1), // Subtotal
                        },
                        children: [
                          pw.TableRow(
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.all(4),
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text(
                                  'Product',
                                  style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              pw.Container(
                                padding: const pw.EdgeInsets.all(4),
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  'Qty',
                                  style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              pw.Container(
                                padding: const pw.EdgeInsets.all(4),
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  'Price',
                                  style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              pw.Container(
                                padding: const pw.EdgeInsets.all(4),
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  'Subtotal',
                                  style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          ..._items.map((item) {
                            final product = item['products'];
                            final name = product?['name'] ?? '';
                            final quantity = item['quantity'] ?? 0;
                            final price = item['price'] ?? 0;
                            final subtotal = price * quantity;
                            return pw.TableRow(
                              children: [
                                pw.Container(
                                  padding: const pw.EdgeInsets.all(4),
                                  alignment: pw.Alignment.centerRight,
                                  child: pw.Text(
                                    name,
                                    style: pw.TextStyle(font: ttf),
                                    textDirection: pw.TextDirection.rtl,
                                  ),
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.all(4),
                                  alignment: pw.Alignment.center,
                                  child: pw.Text(
                                    quantity.toString(),
                                    style: pw.TextStyle(font: ttf),
                                  ),
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.all(4),
                                  alignment: pw.Alignment.center,
                                  child: pw.Text(
                                    'EGP ${price.toStringAsFixed(2)}',
                                    style: pw.TextStyle(font: ttf),
                                  ),
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.all(4),
                                  alignment: pw.Alignment.center,
                                  child: pw.Text(
                                    'EGP ${subtotal.toStringAsFixed(2)}',
                                    style: pw.TextStyle(font: ttf),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                      pw.SizedBox(height: 16),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text('Subtotal: ', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
                          pw.Text('EGP ${_totalPrice.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf)),
                        ],
                      ),
                      if (_deliveryFee != null)
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Text('Delivery Fee: ', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
                            pw.Text('EGP ${_deliveryFee!.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf)),
                          ],
                        ),
                      pw.Divider(),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text('Total: ', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 16)),
                          pw.Text('EGP ${(_totalPrice + (_deliveryFee ?? 0)).toStringAsFixed(2)}', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
              try {
                if (kIsWeb) {
                  await Printing.layoutPdf(
                    onLayout: (format) async => pdf.save(),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Print dialog opened!')),
                    );
                  }
                  return;
                }
                if (Platform.isWindows) {
                  await Printing.sharePdf(
                    bytes: await pdf.save(),
                    filename: 'order_${_order!['id']}.pdf',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PDF exported successfully!'),
                      ),
                    );
                  }
                  return;
                }
                await Printing.layoutPdf(
                  onLayout: (format) async => pdf.save(),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Print dialog opened!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to print/export: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      drawer: isMobile ? const SidebarMenu() : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
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
                            : _order == null
                                ? const Center(child: Text('Order not found'))
                                : SingleChildScrollView(
                                    padding: EdgeInsets.all(isMobile ? 12 : 24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildOrderSummary(Theme.of(context)),
                                        const SizedBox(height: 24),
                                        _buildProductTable(Theme.of(context)),
                                        const SizedBox(height: 24),
                                        _buildTotalCard(Theme.of(context)),
                                      ],
                                    ),
                                  ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderSummary(ThemeData theme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: theme.primaryColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Order #: ${_order!['id']}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (_order != null && _order!['name'] != null && _order!['name'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.label, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Name: ',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Expanded(child: Text(_order!['name'])),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.person,
              'Customer: ',
              _order!['profiles']?['full_name'] ?? '',
              theme,
            ),
            _buildInfoRow(
              Icons.location_on,
              'Address: ',
              _order!['address'] ?? '',
              theme,
            ),
            _buildInfoRow(
              Icons.calendar_today,
              'Created: ',
              _order!['created_at'] != null
                  ? DateFormat(
                      'yMMMd, h:mm a',
                    ).format(DateTime.parse(_order!['created_at']))
                  : '',
              theme,
            ),
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  'Status: ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<String>(
                  value: _status,
                  items: const [
                    DropdownMenuItem(
                      value: 'Delivered',
                      child: Text('Delivered'),
                    ),
                    DropdownMenuItem(
                      value: 'Rejected',
                      child: Text('Rejected'),
                    ),
                    DropdownMenuItem(
                      value: 'In Progress',
                      child: Text('In Progress'),
                    ),
                  ],
                  onChanged: (val) async {
                    if (val != null) {
                      final oldStatus = _status;
                      setState(() => _status = val);
                      final success = await _updateStatus();
                      if (!success) {
                        setState(() => _status = oldStatus);
                      }
                    }
                  },
                ),
                if (_isUpdating)
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
            if (_deliveryFee != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Text('Delivery Fee: ${_deliveryFee!.toStringAsFixed(2)} EGP'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildProductTable(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Products',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: const [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Product',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Quantity',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Price',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Subtotal',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                ..._items.map((item) {
                  final product = item['products'];
                  final name = product?['name'] ?? '';
                  final imageUrl = product?['image_url'] ?? '';
                  final quantity = item['quantity'] ?? 0;
                  final price = item['price'] ?? 0;
                  final subtotal = price * quantity;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              if (imageUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              if (imageUrl.isNotEmpty) const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(child: Text(quantity.toString())),
                        Expanded(
                          child: Text('EGP ${price.toStringAsFixed(2)}'),
                        ),
                        Expanded(
                          child: Text('EGP ${subtotal.toStringAsFixed(2)}'),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal:', style: theme.textTheme.titleMedium),
                Text('EGP ${_totalPrice.toStringAsFixed(2)}', style: theme.textTheme.titleMedium),
              ],
            ),
            if (_deliveryFee != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery Fee:', style: theme.textTheme.titleMedium),
                  Text('EGP ${_deliveryFee!.toStringAsFixed(2)}', style: theme.textTheme.titleMedium),
                ],
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text('EGP ${_totalWithDelivery.toStringAsFixed(2)}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
