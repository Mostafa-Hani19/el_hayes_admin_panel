// ignore_for_file: use_build_context_synchronously, unused_local_variable, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/auth_provider.dart';
import '../widgets/sidebar_menu.dart';
import '../utils/constants.dart';
import 'dart:typed_data';

class TickersScreen extends StatefulWidget {
  const TickersScreen({super.key});

  @override
  State<TickersScreen> createState() => _TickersScreenState();
}

class _TickersScreenState extends State<TickersScreen> {
  List<Map<String, dynamic>> _tickers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTickers();
  }

  Future<void> _loadTickers() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final supabase = authProvider.supabaseClient;
    final data = await supabase
        .from('tickers')
        .select('*')
        .order('created_at', ascending: false);
    setState(() {
      _tickers = List<Map<String, dynamic>>.from(data);
      _isLoading = false;
    });
  }

  Future<void> _showAddTickerDialog() async {
    final formKey = GlobalKey<FormState>();
    final imageUrlController = TextEditingController();
    Uint8List? imageBytes;
    String? uploadedImageUrl;
    bool isUploading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickImage() async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.image,
            );
            if (result != null && result.files.single.bytes != null) {
              setState(() => isUploading = true);
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final supabase = authProvider.supabaseClient;
              final fileName =
                  'ticker_${DateTime.now().millisecondsSinceEpoch}.jpg';
              try {
                final response = await supabase.storage
                    .from('tickers')
                    .uploadBinary(fileName, result.files.single.bytes!);
                if (response.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Upload error: Empty response'),
                    ),
                  );
                  setState(() => isUploading = false);
                  return;
                }
                setState(() {
                  imageBytes = result.files.single.bytes;
                  uploadedImageUrl = supabase.storage
                      .from('tickers')
                      .getPublicUrl(fileName);
                  isUploading = false;
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Exception during upload: \\${e.toString()}'),
                  ),
                );
                setState(() => isUploading = false);
              }
            }
          }

          return AlertDialog(
            title: const Text('Add Ticker Banner'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: isUploading ? null : pickImage,
                          icon: const Icon(Icons.image),
                          label: const Text('Pick Image'),
                        ),
                        const SizedBox(width: 8),
                        if (isUploading)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        if (imageBytes != null)
                          Image.memory(
                            imageBytes!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                      ],
                    ),
                    if (uploadedImageUrl == null)
                      TextFormField(
                        controller: imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                        ),
                        validator: (v) =>
                            (uploadedImageUrl == null &&
                                (v == null || v.isEmpty))
                            ? 'Pick image or enter URL'
                            : null,
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isUploading
                    ? null
                    : () async {
                        if (formKey.currentState?.validate() ?? false) {
                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          final supabase = authProvider.supabaseClient;
                          await supabase.from('tickers').insert({
                            'image_url':
                                uploadedImageUrl ?? imageUrlController.text,
                            'created_at': DateTime.now().toIso8601String(),
                          });
                          Navigator.pop(context);
                          _loadTickers();
                        }
                      },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Constants.isMobile(context);
    // ignore: 
    final isTablet = Constants.isTablet(context);
    final isDesktop = Constants.isDesktop(context);
    final Color bgGradientStart = Colors.grey[100]!;
    final Color bgGradientEnd = Colors.blueGrey[50]!;
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Ticker Banners'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: isMobile ? const SidebarMenu() : null,
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 0.5,
      ),
      drawer: isMobile ? const SidebarMenu() : null,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTickerDialog,
        tooltip: 'Add Ticker Banner',
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
                  : _tickers.isEmpty
                      ? const Center(child: Text('No ticker banners found'))
                      : Column(
                          children: [
                            const SizedBox(height: 24),
                            Divider(height: isMobile ? 18 : 32, thickness: 1.2, color: Colors.blueGrey[100]),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _tickers.length,
                                itemBuilder: (context, i) {
                                  final t = _tickers[i];
                                  return _ModernTickerCard(
                                    imageUrl: t['image_url'],
                                    onDelete: () async {
                                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                      final supabase = authProvider.supabaseClient;
                                      await supabase.from('tickers').delete().eq('id', t['id']);
                                      _loadTickers();
                                    },
                                    isMobile: isMobile,
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
}

class _ModernTickerCard extends StatefulWidget {
  final String? imageUrl;
  final VoidCallback onDelete;
  final bool isMobile;
  const _ModernTickerCard({required this.imageUrl, required this.onDelete, required this.isMobile});

  @override
  State<_ModernTickerCard> createState() => _ModernTickerCardState();
}

class _ModernTickerCardState extends State<_ModernTickerCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
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
          leading: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
              ? Image.network(widget.imageUrl!, width: 56, height: 56, fit: BoxFit.cover)
              : const Icon(Icons.image, size: 56),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Delete Ticker Banner',
            onPressed: widget.onDelete,
          ),
        ),
      ),
    );
  }
}
