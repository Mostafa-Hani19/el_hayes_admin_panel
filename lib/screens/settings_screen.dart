// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/sidebar_menu.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _feeController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _coupons = [];
  bool _isLoadingCoupons = true;

  @override
  void initState() {
    super.initState();
    _fetchDeliveryFee();
    _fetchCoupons();
  }

  Future<void> _fetchDeliveryFee() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final supabase = authProvider.supabaseClient;
    final data = await supabase
        .from('settings')
        .select('value')
        .eq('key', 'delivery_fee')
        .maybeSingle();
    _feeController.text = data?['value'] ?? '';
    setState(() => _isLoading = false);
  }

  Future<void> _saveDeliveryFee() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final supabase = authProvider.supabaseClient;
    final value = _feeController.text.trim();
    if (value.isEmpty) return;
    await supabase.from('settings').upsert({
      'key': 'delivery_fee',
      'value': value,
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Delivery fee updated!')));
  }

  Future<void> _fetchCoupons() async {
    setState(() => _isLoadingCoupons = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final supabase = authProvider.supabaseClient;
    try {
      final data = await supabase
          .from('coupons')
          .select('*')
          .order('created_at', ascending: false);
      setState(() {
        _coupons = List<Map<String, dynamic>>.from(data);
        _isLoadingCoupons = false;
      });
    } catch (e) {
      print('Error fetching coupons: $e');
      setState(() => _isLoadingCoupons = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching coupons: $e')),
      );
    }
  }

  void _showCreateCouponSheet(BuildContext context) {
    final codeController = TextEditingController();
    String selectedType = 'percentage';
    final valueController = TextEditingController();
    bool isActive = true;
    final formKey = GlobalKey<FormState>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        final isMobile = width < 600;
        final maxWidth = isMobile ? double.infinity : 420.0;
        final horizontalPadding = isMobile ? 16.0 : 32.0;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.card_giftcard, size: 28, color: Colors.deepPurple),
                          const SizedBox(width: 12),
                          Text('Create Coupon', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: 'Coupon Code',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., SAVE20',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Coupon code is required';
                          }
                          if (value.trim().length < 3) {
                            return 'Coupon code must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        items: const [
                          DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
                          DropdownMenuItem(value: 'fixed_amount', child: Text('Fixed Amount (EGP)')),
                        ],
                        onChanged: (v) => setState(() => selectedType = v!),
                        decoration: const InputDecoration(
                          labelText: 'Discount Type',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a discount type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: valueController,
                        decoration: InputDecoration(
                          labelText: selectedType == 'percentage' ? 'Percentage Value' : 'Fixed Amount',
                          border: const OutlineInputBorder(),
                          hintText: selectedType == 'percentage' ? 'e.g., 20' : 'e.g., 50',
                          suffixText: selectedType == 'percentage' ? '%' : 'EGP',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Value is required';
                          }
                          final numValue = double.tryParse(value);
                          if (numValue == null) {
                            return 'Please enter a valid number';
                          }
                          if (selectedType == 'percentage' && (numValue <= 0 || numValue > 100)) {
                            return 'Percentage must be between 1 and 100';
                          }
                          if (selectedType == 'fixed_amount' && numValue <= 0) {
                            return 'Amount must be greater than 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Create'),
                            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 44)),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) {
                                return;
                              }
                              
                              final supabase = Provider.of<AuthProvider>(context, listen: false).supabaseClient;
                              try {
                                final value = double.parse(valueController.text.trim());
                                final code = codeController.text.trim().toUpperCase();
                                
                                print('Creating coupon with data:');
                                print('Code: $code');
                                print('Type: $selectedType');
                                print('Value: $value');
                                print('Is Active: $isActive');
                                
                                // Test the database connection first
                                print('Testing database connection...');
                                final testResponse = await supabase.from('coupons').select('count').limit(1);
                                print('Test response: $testResponse');
                                
                                await supabase.from('coupons').insert({
                                  'code': code,
                                  'type': selectedType,
                                  'value': value,
                                  'is_active': isActive,
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Coupon created successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _fetchCoupons();
                              } catch (e) {
                                print('Error creating coupon: $e');
                                String errorMessage = 'Failed to create coupon: $e';
                                
                                if (e.toString().contains('duplicate key')) {
                                  errorMessage = 'Coupon code already exists';
                                } else if (e.toString().contains('check constraint')) {
                                  errorMessage = 'Invalid value for discount type';
                                } else if (e.toString().contains('type')) {
                                  errorMessage = 'Invalid discount type. Use "percentage" or "fixed_amount"';
                                }
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorMessage),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteCoupon(String couponId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final supabase = authProvider.supabaseClient;
    try {
      print('Deleting coupon with ID: $couponId');
      await supabase.from('coupons').delete().eq('id', couponId);
      print('Delete operation completed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coupon deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchCoupons();
    } catch (e) {
      print('Error deleting coupon: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete coupon: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteCouponDialog(String couponId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Coupon'),
          ],
        ),
        content: const Text('Are you sure you want to delete this coupon? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCoupon(couponId);
            },
            label: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatCouponValue(Map<String, dynamic> coupon) {
    final type = coupon['type'] as String?;
    final value = coupon['value'];
    
    if (type == 'percentage') {
      return '${value.toStringAsFixed(0)}%';
    } else {
      return '${value.toStringAsFixed(2)} EGP';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString.substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Constants.isMobile(context);
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
        leading: isMobile ? const SidebarMenu() : null,
      ),
      drawer: isMobile ? const SidebarMenu() : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final maxWidth = isMobile ? double.infinity : 500.0;
          return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) const SidebarMenu(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 32),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(Icons.delivery_dining, color: Colors.deepPurple),
                                        SizedBox(width: 8),
                                        Text('Delivery Fee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: _feeController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Delivery Fee (EGP)',
                                        border: OutlineInputBorder(),
                                        hintText: 'e.g., 25',
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _saveDeliveryFee,
                                      icon: const Icon(Icons.save),
                                      label: const Text('Save Delivery Fee'),
                                      style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                                  const SizedBox(height: 32),
                                  if (authProvider.isAdmin)
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.card_giftcard),
                                      label: const Text('Create Coupon'),
                                      style: ElevatedButton.styleFrom(minimumSize: Size(isMobile ? 140 : 180, 48)),
                                      onPressed: () => _showCreateCouponSheet(context),
                                    ),
                                  const SizedBox(height: 24),
                                  if (_isLoadingCoupons)
                                    const Center(child: CircularProgressIndicator()),
                                  if (!_isLoadingCoupons && _coupons.isEmpty)
                                    Card(
                                      elevation: 1,
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Center(
                                          child: Column(
                                            children: const [
                                              Icon(Icons.local_offer_outlined, size: 48, color: Colors.grey),
                                              SizedBox(height: 16),
                                              Text('No coupons found', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                              Text('Create your first coupon to get started', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (!_isLoadingCoupons && _coupons.isNotEmpty)
                                    ...[
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Row(
                                          children: const [
                                            Icon(Icons.local_offer, color: Colors.deepPurple),
                                            SizedBox(width: 8),
                                            Text('All Coupons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                          ],
                                        ),
                                      ),
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _coupons.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                                        itemBuilder: (context, i) {
                                          final c = _coupons[i];
                                          return Card(
                                            elevation: 2,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            child: ListTile(
                                                                                             leading: CircleAvatar(
                                                 backgroundColor: c['is_active'] == true ? Colors.green : Colors.grey,
                                                 child: Icon(
                                                   c['type'] == 'percentage' ? Icons.percent : Icons.attach_money,
                                                   color: Colors.white,
                                                 ),
                                               ),
                                              title: Text(
                                                c['code'] ?? '',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                                                                     Text('${c['type'] == 'percentage' ? 'Percentage' : 'Fixed Amount'}: ${_formatCouponValue(c)}'),
                                                  Text('Created: ${_formatDate(c['created_at']?.toString())}'),
                                                ],
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: c['is_active'] == true ? Colors.green : Colors.grey,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      c['is_active'] == true ? 'Active' : 'Inactive',
                                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                                    ),
                                                  ),
                                                  if (authProvider.isAdmin) ...[
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete, color: Colors.red),
                                                      tooltip: 'Delete Coupon',
                                                      onPressed: () => _showDeleteCouponDialog(c['id']),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                ],
                              ),
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
}
