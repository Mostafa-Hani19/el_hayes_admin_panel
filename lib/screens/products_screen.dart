// استيراد الحزم المطلوبة
// ignore_for_file: use_build_context_synchronously, unused_local_variable, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/sidebar_menu.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';

// Place _ModernProductCard at the very top-level, before ProductsScreen
class _ModernProductCard extends StatefulWidget {
  final Product product;
  final String Function(String) getCategoryName;
  final bool isMobile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ModernProductCard({required this.product, required this.getCategoryName, required this.isMobile, required this.onEdit, required this.onDelete});

  @override
  State<_ModernProductCard> createState() => _ModernProductCardState();
}

class _ModernProductCardState extends State<_ModernProductCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
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
          leading: p.imageUrl.isNotEmpty
              ? Image.network(p.imageUrl, width: 56, height: 56, fit: BoxFit.cover)
              : const Icon(Icons.image, size: 56),
          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.code, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(p.description),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: p.isAvailable ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p.isAvailable ? 'Available' : 'Not Available',
                      style: TextStyle(
                        color: p.isAvailable ? Colors.green[800] : Colors.red[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Category: ${widget.getCategoryName(p.categoryId)}',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Text('EGP ${p.price.toStringAsFixed(2)}')],
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit',
                onPressed: widget.onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete',
                onPressed: widget.onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _categoryFilter = 'all';
  String _availabilityFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCategories();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final supabase = authProvider.supabaseClient;
      final response = await supabase
          .from('products')
          .select('*')
          .order('created_at', ascending: false);
      final List<Product> fetched = response
          .map<Product>((p) => Product.fromJson(p))
          .toList();
      if (mounted) {
        setState(() {
          _products = fetched;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load products: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final supabase = authProvider.supabaseClient;
      final data = await supabase.from('categories').select('id, name');
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Failed to load categories: $e');
    }
  }

  void _applyProductFilters() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
    });
  }

  List<Product> get _filteredProducts {
    return _products.where((p) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery) ||
          p.description.toLowerCase().contains(_searchQuery) ||
          p.code.toLowerCase().contains(_searchQuery);
      final matchesCategory =
          _categoryFilter == 'all' || p.categoryId == _categoryFilter;
      final matchesAvailability =
          _availabilityFilter == 'all' ||
          (_availabilityFilter == 'available' && p.isAvailable) ||
          (_availabilityFilter == 'not_available' && !p.isAvailable);
      return matchesSearch && matchesCategory && matchesAvailability;
    }).toList();
  }

  String _getCategoryName(String id) {
    final cat = _categories.firstWhere(
      (c) => c['id'] == id,
      orElse: () => <String, dynamic>{},
    );
    return cat.isNotEmpty ? cat['name'] ?? '' : id;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Constants.isMobile(context);
    final isTablet = Constants.isTablet(context);
    final isDesktop = Constants.isDesktop(context);
    double maxContentWidth = isMobile
        ? double.infinity
        : isTablet
        ? 700
        : 1100;
    double horizontalPadding = isMobile
        ? 4.0
        : isTablet
        ? 16.0
        : 32.0;
    double verticalPadding = isMobile
        ? 4.0
        : isTablet
        ? 8.0
        : 24.0;
    final Color bgGradientStart = Colors.grey[100]!;
    final Color bgGradientEnd = Colors.blueGrey[50]!;
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Products'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: isMobile ? const SidebarMenu() : null,
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 0.5,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProducts),
        ],
      ),
      drawer: isMobile ? const SidebarMenu() : null,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
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
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _error != null
                                ? Center(child: Text(_error!))
                                : _products.isEmpty
                                    ? const Center(child: Text('No products found'))
                                    : Column(
                                        children: [
                                          const SizedBox(height: 32),
                                          // Modern search/filter bar
                                          Card(
                                            elevation: 3,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(18),
                                            ),
                                            margin: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 8),
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isMobile ? 8 : 24,
                                                vertical: isMobile ? 8 : 16,
                                              ),
                                              child: isMobile
                                                  ? Column(
                                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                                      children: _buildModernFilterRow(isMobile, isTablet),
                                                    )
                                                  : Row(
                                                      children: _buildModernFilterRow(isMobile, isTablet),
                                                    ),
                                            ),
                                          ),
                                          Divider(height: isMobile ? 18 : 32, thickness: 1.2, color: Colors.blueGrey[100]),
                                          Expanded(
                                            child: _buildModernProductLayout(
                                              isMobile,
                                              isTablet,
                                              _filteredProducts,
                                            ),
                                          ),
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
      ),
    );
  }

  List<Widget> _buildModernFilterRow(bool isMobile, bool isTablet) {
    return [
      Expanded(
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search Products',
            hintText: 'Enter name or description',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _applyProductFilters();
              },
            ),
          ),
          onChanged: (value) {
            _applyProductFilters();
          },
        ),
      ),
      SizedBox(width: isMobile ? 8 : 16),
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: DropdownButton<String>(
          value: _categoryFilter,
          underline: const SizedBox(),
          items: [
            const DropdownMenuItem(value: 'all', child: Text('All Categories')),
            ..._categories.map(
              (cat) => DropdownMenuItem(value: cat['id'], child: Text(cat['name'])),
            ),
          ],
          onChanged: (val) {
            setState(() {
              _categoryFilter = val ?? 'all';
            });
          },
        ),
      ),
      SizedBox(width: isMobile ? 8 : 16),
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: DropdownButton<String>(
          value: _availabilityFilter,
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Statuses')),
            DropdownMenuItem(value: 'available', child: Text('Available')),
            DropdownMenuItem(value: 'not_available', child: Text('Not Available')),
          ],
          onChanged: (val) {
            setState(() {
              _availabilityFilter = val ?? 'all';
            });
          },
        ),
      ),
    ];
  }

  Widget _buildModernProductLayout(
    bool isMobile,
    bool isTablet,
    List<Product> filteredProducts,
  ) {
    if (isMobile || isTablet) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filteredProducts.length,
        separatorBuilder: (context, i) => const Divider(),
        itemBuilder: (context, i) => _ModernProductCard(
          product: filteredProducts[i],
          getCategoryName: _getCategoryName,
          isMobile: isMobile,
          onEdit: () => _showEditProductDialog(filteredProducts[i]),
          onDelete: () => _showDeleteProductDialog(filteredProducts[i]),
        ),
      );
    } else {
      // Desktop: DataTable
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Image')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Code')),
              DataColumn(label: Text('Description')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Price')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: filteredProducts.map((p) => _buildProductDataRow(p)).toList(),
          ),
        ),
      );
    }
  }

  DataRow _buildProductDataRow(Product p) {
    return DataRow(
      cells: [
        DataCell(
          p.imageUrl.isNotEmpty
              ? Image.network(
                  p.imageUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                )
              : const Icon(Icons.image, size: 40),
        ),
        DataCell(Text(p.name)),
        DataCell(Text(p.code)),
        DataCell(Text(p.description)),
        DataCell(Text(_getCategoryName(p.categoryId))),
        DataCell(Text('EGP ${p.price.toStringAsFixed(2)}')),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: p.isAvailable ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              p.isAvailable ? 'Available' : 'Not Available',
              style: TextStyle(
                color: p.isAvailable ? Colors.green[800] : Colors.red[800],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit',
                onPressed: () => _showEditProductDialog(p),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete',
                onPressed: () => _showDeleteProductDialog(p),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showAddProductDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final imageUrlController = TextEditingController();
    final priceController = TextEditingController();
    final codeController = TextEditingController();
    String? selectedCategoryId;
    bool isSubmitting = false;
    Uint8List? imageBytes;
    bool isAvailable = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickImage() async {
              final picker = ImagePicker();
              final picked = await picker.pickImage(
                source: ImageSource.gallery,
              );
              if (picked != null) {
                final bytes = await picked.readAsBytes();
                setState(() {
                  imageBytes = bytes;
                });
              }
            }

            Future<String?> uploadImage(Uint8List bytes) async {
              try {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                final supabase = authProvider.supabaseClient;
                final fileName =
                    'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
                await supabase.storage
                    .from('product-images')
                    .uploadBinary(fileName, bytes);
                return supabase.storage
                    .from('product-images')
                    .getPublicUrl(fileName);
              } catch (e) {
                debugPrint('Image upload error: $e');
                return null;
              }
            }

            return AlertDialog(
              title: const Text('Add Product'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter description' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: codeController,
                        decoration: const InputDecoration(labelText: 'Code'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter code' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: pickImage,
                            icon: const Icon(Icons.image),
                            label: const Text('Pick Image'),
                          ),
                          const SizedBox(width: 8),
                          if (imageBytes != null)
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: Image.memory(
                                imageBytes!,
                                fit: BoxFit.cover,
                              ),
                            ),
                        ],
                      ),
                      if (imageBytes == null)
                        TextFormField(
                          controller: imageUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Image URL',
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Pick image or enter URL'
                              : null,
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter price' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedCategoryId,
                        hint: const Text('Select Category'),
                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category['id'],
                            child: Text(category['name']),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => selectedCategoryId = val),
                        validator: (val) =>
                            val == null ? 'Select category' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<bool>(
                        value: isAvailable,
                        decoration: const InputDecoration(
                          labelText: 'Availability Status',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: true,
                            child: Text('Available'),
                          ),
                          DropdownMenuItem(
                            value: false,
                            child: Text('Not Available'),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => isAvailable = val ?? true),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (formKey.currentState?.validate() ?? false) {
                            setState(() => isSubmitting = true);
                            String imageUrl = imageUrlController.text;
                            if (imageBytes != null) {
                              final uploaded = await uploadImage(imageBytes!);
                              if (uploaded != null) {
                                imageUrl = uploaded;
                              } else {
                                setState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Image upload failed'),
                                  ),
                                );
                                return;
                              }
                            }

                            try {
                              final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              );
                              final supabase = authProvider.supabaseClient;
                              await supabase.from('products').insert({
                                'name': nameController.text,
                                'description': descController.text,
                                'image_url': imageUrl,
                                'price': double.parse(priceController.text),
                                'category_id': selectedCategoryId,
                                'is_available': isAvailable,
                                'code': codeController.text,
                              });
                              if (mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Product added successfully'),
                                  ),
                                );
                                _loadProducts();
                              }
                            } catch (e) {
                              setState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditProductDialog(Product product) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product.name);
    final descController = TextEditingController(text: product.description);
    final imageUrlController = TextEditingController(text: product.imageUrl);
    final priceController = TextEditingController(
      text: product.price.toString(),
    );
    final codeController = TextEditingController(text: product.code);
    String? selectedCategoryId = product.categoryId;
    Uint8List? imageBytes;
    bool isSubmitting = false;
    bool isAvailable = product.isAvailable;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickImage() async {
              final picker = ImagePicker();
              final picked = await picker.pickImage(
                source: ImageSource.gallery,
              );
              if (picked != null) {
                final bytes = await picked.readAsBytes();
                setState(() {
                  imageBytes = bytes;
                });
              }
            }

            Future<String?> uploadImage(Uint8List bytes) async {
              try {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                final supabase = authProvider.supabaseClient;
                final fileName =
                    'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
                await supabase.storage
                    .from('product-images')
                    .uploadBinary(fileName, bytes);
                return supabase.storage
                    .from('product-images')
                    .getPublicUrl(fileName);
              } catch (e) {
                debugPrint('Image upload error: $e');
                return null;
              }
            }

            // Before building the DropdownButtonFormField, ensure selectedCategoryId is valid
            final categoryIds = _categories.map((c) => c['id']).toSet();
            if (selectedCategoryId != null && !categoryIds.contains(selectedCategoryId)) {
              selectedCategoryId = null;
            }
            // Remove duplicate categories by ID
            final uniqueCategories = _categories.toSet().toList();

            return AlertDialog(
              title: const Text('Edit Product'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter description' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: codeController,
                        decoration: const InputDecoration(labelText: 'Code'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter code' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: pickImage,
                            icon: const Icon(Icons.image),
                            label: const Text('Pick Image'),
                          ),
                          const SizedBox(width: 8),
                          if (imageBytes != null)
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: Image.memory(
                                imageBytes!,
                                fit: BoxFit.cover,
                              ),
                            )
                          else if (product.imageUrl.isNotEmpty)
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                        ],
                      ),
                      if (imageBytes == null)
                        TextFormField(
                          controller: imageUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Image URL',
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Pick image or enter URL'
                              : null,
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter price' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedCategoryId,
                        hint: const Text('Select Category'),
                        items: uniqueCategories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category['id'],
                            child: Text(category['name']),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => selectedCategoryId = val),
                        validator: (val) =>
                            val == null ? 'Select category' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<bool>(
                        value: isAvailable,
                        decoration: const InputDecoration(
                          labelText: 'Availability Status',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: true,
                            child: Text('Available'),
                          ),
                          DropdownMenuItem(
                            value: false,
                            child: Text('Not Available'),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => isAvailable = val ?? true),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (formKey.currentState?.validate() ?? false) {
                            setState(() => isSubmitting = true);
                            String imageUrl = imageUrlController.text;
                            if (imageBytes != null) {
                              final uploaded = await uploadImage(imageBytes!);
                              if (uploaded != null) {
                                imageUrl = uploaded;
                              } else {
                                setState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Image upload failed'),
                                  ),
                                );
                                return;
                              }
                            }
                            try {
                              final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              );
                              final supabase = authProvider.supabaseClient;
                              final result = await supabase
                                  .from('products')
                                  .update({
                                    'name': nameController.text,
                                    'description': descController.text,
                                    'image_url': imageUrl,
                                    'price': double.parse(priceController.text),
                                    'category_id': selectedCategoryId,
                                    'is_available': isAvailable,
                                    'code': codeController.text,
                                  })
                                  .eq('id', product.id)
                                  .select();
                              if (mounted) {
                                // ignore: unnecessary_type_check
                                if (result is List && result.isNotEmpty) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Product updated successfully',
                                      ),
                                    ),
                                  );
                                  _loadProducts();
                                } else {
                                  setState(() => isSubmitting = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Update failed: No rows affected. Check RLS policies and product ID.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              setState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteProductDialog(Product product) async {
    bool isSubmitting = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete Product'),
              content: Text(
                'Are you sure you want to delete "${product.name}"?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setState(() => isSubmitting = true);
                          try {
                            final authProvider = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );
                            final supabase = authProvider.supabaseClient;
                            final result = await supabase
                                .from('products')
                                .delete()
                                .eq('id', product.id)
                                .select();
                            if (mounted) {
                              // ignore: unnecessary_type_check
                              if (result is List && result.isNotEmpty) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Product deleted successfully',
                                    ),
                                  ),
                                );
                                _loadProducts();
                              } else {
                                setState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Delete failed: No rows affected. Check RLS policies and product ID.',
                                    ),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            setState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
