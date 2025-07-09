// ignore_for_file: use_build_context_synchronously, unused_local_variable, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/sidebar_menu.dart';
import '../utils/constants.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _categories = [];
  Map<String, int> _productCounts = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final supabase = authProvider.supabaseClient;
      final response = await supabase.from('categories').select('*').order('name');
      final List<Category> fetched = [];
      for (final c in response) {
        try {
          fetched.add(Category.fromJson(c));
        } catch (e) {
          debugPrint('Error parsing category: $e');
        }
      }
      // Fetch product counts for each category
      final countsResp = await supabase
        .from('products')
        .select('category_id, id');
      final Map<String, int> counts = {};
      for (final c in fetched) {
        counts[c.id] = 0;
      }
      for (final row in countsResp) {
        if (row['category_id'] != null) {
          counts[row['category_id']] = (counts[row['category_id']] ?? 0) + 1;
        }
      }
      setState(() {
        _categories = fetched;
        _productCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load categories: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Constants.isMobile(context);
    final isTablet = Constants.isTablet(context);
    final isDesktop = Constants.isDesktop(context);
    final Color bgGradientStart = Colors.grey[100]!;
    final Color bgGradientEnd = Colors.blueGrey[50]!;
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Categories'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: isMobile ? const SidebarMenu() : null,
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
          ),
        ],
      ),
      drawer: isMobile ? const SidebarMenu() : null,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        tooltip: 'Add Category',
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMobile) const SidebarMenu(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _categories.isEmpty
                          ? const Center(child: Text('No categories found'))
                          : Column(
                              children: [
                                const SizedBox(height: 16),
                                Divider(height: isMobile ? 18 : 32, thickness: 1.2, color: Colors.blueGrey[100]),
                                Expanded(
                                  child: ListView.separated(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _categories.length,
                                    separatorBuilder: (context, i) => const Divider(),
                                    itemBuilder: (context, i) {
                                      final c = _categories[i];
                                      return _ModernCategoryCard(
                                        category: c,
                                        productCount: _productCounts[c.id] ?? 0,
                                        isMobile: isMobile,
                                        onShowProducts: () => _showProductsInCategory(c),
                                        onEdit: () => _showEditCategoryDialog(c),
                                        onDelete: () => _showDeleteCategoryDialog(c),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCategoryDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    Uint8List? imageBytes;
    bool isSubmitting = false;
    // ignore: duplicate_ignore
    // ignore: unused_local_variable
    String? uploadedImageUrl;

    Future<void> pickImage(StateSetter setState) async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          imageBytes = bytes;
        });
      }
    }

    Future<String?> uploadImage(Uint8List bytes) async {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final supabase = authProvider.supabaseClient;
        final fileName = 'category_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('category-images').uploadBinary(fileName, bytes);
        final publicUrl = supabase.storage.from('category-images').getPublicUrl(fileName);
        return publicUrl;
      } catch (e) {
        debugPrint('Image upload error: $e');
        return null;
      }
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Category'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Category Name'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter a name' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => pickImage(setState),
                          icon: const Icon(Icons.image),
                          label: const Text('Pick Image'),
                        ),
                        const SizedBox(width: 8),
                        if (imageBytes != null)
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: Image.memory(imageBytes!, fit: BoxFit.cover),
                          ),
                      ],
                    ),
                  ],
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
                            String? imageUrl;
                            if (imageBytes != null) {
                              imageUrl = await uploadImage(imageBytes!);
                              if (imageUrl == null) {
                                setState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Image upload failed')),
                                );
                                return;
                              }
                            }
                            try {
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              final supabase = authProvider.supabaseClient;
                              await supabase.from('categories').insert({
                                'name': nameController.text,
                                if (imageUrl != null) 'image_url': imageUrl,
                              });
                              if (mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Category added successfully')),
                                );
                                _loadCategories();
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
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditCategoryDialog(Category category) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category.name);
    Uint8List? imageBytes;
    bool isSubmitting = false;
    // ignore: 
    String? uploadedImageUrl;

    Future<void> pickImage(StateSetter setState) async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          imageBytes = bytes;
        });
      }
    }

    Future<String?> uploadImage(Uint8List bytes) async {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final supabase = authProvider.supabaseClient;
        final fileName = 'category_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('category-images').uploadBinary(fileName, bytes);
        final publicUrl = supabase.storage.from('category-images').getPublicUrl(fileName);
        return publicUrl;
      } catch (e) {
        debugPrint('Image upload error: $e');
        return null;
      }
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Category'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Category Name'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter a name' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => pickImage(setState),
                          icon: const Icon(Icons.image),
                          label: const Text('Pick Image'),
                        ),
                        const SizedBox(width: 8),
                        if (imageBytes != null)
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: Image.memory(imageBytes!, fit: BoxFit.cover),
                          )
                        else if (category.imageUrl != null && category.imageUrl!.isNotEmpty)
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: Image.network(category.imageUrl!, fit: BoxFit.cover),
                          ),
                      ],
                    ),
                  ],
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
                            String? imageUrl = category.imageUrl;
                            if (imageBytes != null) {
                              imageUrl = await uploadImage(imageBytes!);
                              if (imageUrl == null) {
                                setState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Image upload failed')),
                                );
                                return;
                              }
                            }
                            try {
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              final supabase = authProvider.supabaseClient;
                              final result = await supabase.from('categories').update({
                                'name': nameController.text,
                                'image_url': imageUrl,
                              }).eq('id', category.id).select();
                              if (mounted) {
                                // ignore: unnecessary_type_check
                                if (result is List && result.isNotEmpty) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Category updated successfully')),
                                  );
                                  _loadCategories();
                                } else {
                                  setState(() => isSubmitting = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Update failed: No rows affected. Check RLS policies and category ID.')),
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
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteCategoryDialog(Category category) async {
    bool isSubmitting = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete Category'),
              content: Text('Are you sure you want to delete "${category.name}"?'),
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
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final supabase = authProvider.supabaseClient;
                            final result = await supabase.from('categories').delete().eq('id', category.id).select();
                            if (mounted) {
                              // ignore: unnecessary_type_check
                              if (result is List && result.isNotEmpty) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Category deleted successfully')),
                                );
                                _loadCategories();
                              } else {
                                setState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Delete failed: No rows affected. Check RLS policies and category ID.')),
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
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showProductsInCategory(Category category) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final supabase = authProvider.supabaseClient;
    List products = [];
    bool isLoading = true;
    String? error;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> loadProducts() async {
              setState(() { isLoading = true; error = null; });
              try {
                final resp = await supabase
                  .from('products')
                  .select('id, name, image_url, price')
                  .eq('category_id', category.id)
                  .order('created_at', ascending: false);
                setState(() { products = resp; isLoading = false; });
              } catch (e) {
                setState(() { error = 'Failed to load products: $e'; isLoading = false; });
              }
            }
            if (isLoading) loadProducts();
            return AlertDialog(
              title: Text('Products in ${category.name}'),
              content: SizedBox(
                width: 350,
                child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                    ? Text(error!)
                    : products.isEmpty
                      ? const Text('No products in this category.')
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: products.length,
                          separatorBuilder: (c, i) => const Divider(),
                          itemBuilder: (c, i) {
                            final p = products[i];
                            return ListTile(
                              leading: (p['image_url'] != null && p['image_url'].toString().isNotEmpty)
                                ? Image.network(p['image_url'], width: 40, height: 40, fit: BoxFit.cover)
                                : const Icon(Icons.image),
                              title: Text(p['name'] ?? ''),
                              trailing: Text('EGP ${p['price']?.toStringAsFixed(2) ?? ''}'),
                            );
                          },
                        ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ModernCategoryCard extends StatefulWidget {
  final Category category;
  final int productCount;
  final bool isMobile;
  final VoidCallback onShowProducts;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ModernCategoryCard({required this.category, required this.productCount, required this.isMobile, required this.onShowProducts, required this.onEdit, required this.onDelete});

  @override
  State<_ModernCategoryCard> createState() => _ModernCategoryCardState();
}

class _ModernCategoryCardState extends State<_ModernCategoryCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.category;
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
          leading: c.imageUrl != null && c.imageUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(c.imageUrl!, width: 40, height: 40, fit: BoxFit.cover),
                )
              : const Icon(Icons.category),
          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Products: ${widget.productCount}'),
          onTap: widget.onShowProducts,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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