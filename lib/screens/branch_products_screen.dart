// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/branch_model.dart';
import '../models/branch_product_model.dart';
import '../models/product_model.dart';
import '../services/branch_product_service.dart';
import '../widgets/sidebar_menu.dart';
import '../utils/constants.dart';

class BranchProductsScreen extends StatefulWidget {
  final Branch branch;
  const BranchProductsScreen({super.key, required this.branch});

  @override
  State<BranchProductsScreen> createState() => _BranchProductsScreenState();
}

class _BranchProductsScreenState extends State<BranchProductsScreen> {
  late BranchProductService branchProductService;
  List<BranchProduct> branchProducts = [];
  List<Product> products = [];
  List<Product> filteredProducts = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all'; // 'all', 'available', 'unavailable'

  @override
  void initState() {
    super.initState();
    branchProductService = BranchProductService(Supabase.instance.client);
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final productResponse = await Supabase.instance.client
        .from('products')
        .select();
    final productList = productResponse as List;
    products = productList.map((e) => Product.fromJson(e)).toList();
    branchProducts = await branchProductService.fetchBranchProducts(
      widget.branch.id,
    );
    // Ensure all products are available by default if not set
    for (final product in products) {
      if (!branchProducts.any((bp) => bp.productId == product.id)) {
        branchProducts.add(
          BranchProduct(
            id: '',
            branchId: widget.branch.id,
            productId: product.id,
            isAvailable: true,
          ),
        );
      }
    }
    filteredProducts = products;
    setState(() {
      isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        filteredProducts = products;
      });
    } else {
      setState(() {
        filteredProducts = products
            .where((p) => p.code.contains(query))
            .toList();
      });
    }
  }

  bool _isProductAvailable(String productId) {
    final bp = branchProducts.firstWhere(
      (bp) => bp.productId == productId,
      orElse: () => BranchProduct(
        id: '',
        branchId: widget.branch.id,
        productId: productId,
        isAvailable: false,
      ),
    );
    return bp.isAvailable;
  }

  Future<void> _toggleAvailability(String productId, bool isAvailable) async {
    setState(() {
      final index = branchProducts.indexWhere((bp) => bp.productId == productId);
      if (index != -1) {
        branchProducts[index] = BranchProduct(
          id: branchProducts[index].id,
          branchId: widget.branch.id,
          productId: productId,
          isAvailable: isAvailable,
        );
      } else {
        branchProducts.add(BranchProduct(
          id: '',
          branchId: widget.branch.id,
          productId: productId,
          isAvailable: isAvailable,
        ));
      }
    });

    try {
      if (isAvailable) {
        // If set to available, delete the row from branch_products
        await branchProductService.deleteBranchProduct(widget.branch.id, productId);
      } else {
        // If set to unavailable, upsert the row as unavailable
        await branchProductService.setProductAvailability(widget.branch.id, productId, false);
      }
      await _loadData();
    } catch (e) {
      setState(() {
        final index = branchProducts.indexWhere((bp) => bp.productId == productId);
        if (index != -1) {
          branchProducts[index] = BranchProduct(
            id: branchProducts[index].id,
            branchId: widget.branch.id,
            productId: productId,
            isAvailable: !isAvailable,
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update availability: $e')),
      );
    }
  }

  List<Product> get _filteredProducts {
    return filteredProducts.where((p) {
      if (_statusFilter == 'available') return _isProductAvailable(p.id);
      if (_statusFilter == 'unavailable') return !_isProductAvailable(p.id);
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Constants.isMobile(context);
    final isTablet = Constants.isTablet(context);
    final isDesktop = Constants.isDesktop(context);
    final maxContentWidth = isDesktop
        ? 1100.0
        : isTablet
        ? 800.0
        : double.infinity;
    final horizontalPadding = isMobile
        ? 4.0
        : isTablet
        ? 16.0
        : 32.0;
    final verticalPadding = isMobile
        ? 4.0
        : isTablet
        ? 8.0
        : 24.0;
    final Color bgGradientStart = Colors.grey[100]!;
    final Color bgGradientEnd = Colors.blueGrey[50]!;
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Products for ${widget.branch.name}',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
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
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: theme.textTheme.bodyLarge,
                                decoration: InputDecoration(
                                  labelText: 'Search by product code',
                                  prefixIcon: const Icon(Icons.search),
                                  border: const OutlineInputBorder(),
                                  filled: true,
                                  fillColor: theme.cardColor.withOpacity(0.9),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: _statusFilter,
                              items: const [
                                DropdownMenuItem(
                                  value: 'all',
                                  child: Text('All'),
                                ),
                                DropdownMenuItem(
                                  value: 'available',
                                  child: Text('Available'),
                                ),
                                DropdownMenuItem(
                                  value: 'unavailable',
                                  child: Text('Unavailable'),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _statusFilter = val ?? 'all';
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _filteredProducts.isEmpty
                              ? const Center(child: Text('No products found'))
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isWide = constraints.maxWidth > 600;
                                    return ListView.separated(
                                      itemCount: _filteredProducts.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final product =
                                            _filteredProducts[index];
                                        final available = _isProductAvailable(
                                          product.id,
                                        );
                                        return Card(
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          color: theme.cardColor,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                              horizontal: 8,
                                            ),
                                            child: isWide
                                                ? Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 3,
                                                        child: ListTile(
                                                          title: Text(
                                                            product.name,
                                                            style: theme
                                                                .textTheme
                                                                .titleMedium
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                          subtitle: Text(
                                                            'Code: ${product.code}',
                                                            style: theme
                                                                .textTheme
                                                                .bodySmall,
                                                          ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .end,
                                                          children: [
                                                            Text(
                                                              available
                                                                  ? 'Available'
                                                                  : 'Unavailable',
                                                              style: TextStyle(
                                                                color: available
                                                                    ? Colors
                                                                          .green
                                                                    : Colors
                                                                          .red,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Switch(
                                                              value: available,
                                                              onChanged: (val) =>
                                                                  _toggleAvailability(
                                                                    product.id,
                                                                    val,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : ListTile(
                                                    title: Text(
                                                      product.name,
                                                      style: theme
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                    subtitle: Text(
                                                      'Code: ${product.code}',
                                                      style: theme
                                                          .textTheme
                                                          .bodySmall,
                                                    ),
                                                    trailing: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          available
                                                              ? 'Available'
                                                              : 'Unavailable',
                                                          style: TextStyle(
                                                            color: available
                                                                ? Colors.green
                                                                : Colors.red,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Switch(
                                                          value: available,
                                                          onChanged: (val) =>
                                                              _toggleAvailability(
                                                                product.id,
                                                                val,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                          ),
                                        );
                                      },
                                    );
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
