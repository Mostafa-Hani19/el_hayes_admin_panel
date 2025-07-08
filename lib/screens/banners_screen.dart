import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/auth_provider.dart';
import '../widgets/sidebar_menu.dart';
import '../utils/constants.dart';
import 'dart:typed_data';

class BannersScreen extends StatefulWidget {
  const BannersScreen({super.key});

  @override
  State<BannersScreen> createState() => _BannersScreenState();
}

class _BannersScreenState extends State<BannersScreen> {
  List<Map<String, dynamic>> _banners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final supabase = authProvider.supabaseClient;
    final data = await supabase.from('banners').select('*').order('created_at', ascending: false);
    setState(() {
      _banners = List<Map<String, dynamic>>.from(data);
      _isLoading = false;
    });
  }

  Future<void> _showAddBannerDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    final discountController = TextEditingController();
    final imageUrlController = TextEditingController();
    Color bgColor = Colors.white;
    Color textColor = Colors.black;
    Uint8List? imageBytes;
    String? uploadedImageUrl;
    bool isUploading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickImage() async {
            final result = await FilePicker.platform.pickFiles(type: FileType.image);
            if (result != null && result.files.single.bytes != null) {
              setState(() => isUploading = true);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final supabase = authProvider.supabaseClient;
              final fileName = 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg';
              try {
                final response = await supabase.storage.from('banners').uploadBinary(fileName, result.files.single.bytes!);
                if (response.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Upload error: Empty response')),
                  );
                  setState(() => isUploading = false);
                  return;
                }
                setState(() {
                  imageBytes = result.files.single.bytes;
                  uploadedImageUrl = supabase.storage.from('banners').getPublicUrl(fileName);
                  isUploading = false;
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Exception during upload: \\${e.toString()}')),
                );
                setState(() => isUploading = false);
              }
            }
          }

          // Future<void> pickBgColor() async {
          //   Color picked = bgColor;
          //   final hexController = TextEditingController(text: '#${bgColor.value.toRadixString(16).substring(2).toUpperCase()}');
          //   await showDialog(
          //     context: context,
          //     builder: (context) => AlertDialog(
          //       title: const Text('Pick Background Color'),
          //       content: Column(
          //         mainAxisSize: MainAxisSize.min,
          //         children: [
          //           ColorPicker(
          //             pickerColor: picked,
          //             onColorChanged: (color) {
          //               picked = color;
          //               hexController.text = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
          //             },
          //             enableAlpha: false,
          //             displayThumbColor: true,
          //             showLabel: true,
          //             pickerAreaHeightPercent: 0.7,
          //           ),
          //           const SizedBox(height: 8),
          //           TextField(
          //             controller: hexController,
          //             decoration: const InputDecoration(labelText: 'Hex'),
          //             onChanged: (value) {
          //               try {
          //                 String v = value;
          //                 if (v.startsWith('#')) v = v.substring(1);
          //                 if (v.length == 6) v = 'FF$v';
          //                 final color = Color(int.parse(v, radix: 16));
          //                 picked = color;
          //               } catch (_) {}
          //             },
          //           ),
          //         ],
          //       ),
          //       actions: [
          //         TextButton(
          //           child: const Text('Select'),
          //           onPressed: () => Navigator.of(context).pop(),
          //         ),
          //       ],
          //     ),
          //   );
          //   setState(() => bgColor = picked);
          // }

          Future<void> pickTextColor() async {
            Color picked = textColor;
            final hexController = TextEditingController(text: '#${textColor.value.toRadixString(16).substring(2).toUpperCase()}');
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Pick Text Color'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ColorPicker(
                      pickerColor: picked,
                      onColorChanged: (color) {
                        picked = color;
                        hexController.text = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                      },
                      enableAlpha: false,
                      displayThumbColor: true,
                      showLabel: true,
                      pickerAreaHeightPercent: 0.7,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: hexController,
                      decoration: const InputDecoration(labelText: 'Hex'),
                      onChanged: (value) {
                        try {
                          String v = value;
                          if (v.startsWith('#')) v = v.substring(1);
                          if (v.length == 6) v = 'FF$v';
                          final color = Color(int.parse(v, radix: 16));
                          picked = color;
                        } catch (_) {}
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    child: const Text('Select'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
            setState(() => textColor = picked);
          }

          return AlertDialog(
            title: const Text('Add Banner'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: subtitleController,
                      decoration: const InputDecoration(labelText: 'Subtitle'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: discountController,
                      decoration: const InputDecoration(labelText: 'Discount'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: isUploading ? null : pickImage,
                          icon: const Icon(Icons.image),
                          label: const Text('Pick Image'),
                        ),
                        const SizedBox(width: 8),
                        if (isUploading)
                          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                        if (imageBytes != null)
                          Image.memory(imageBytes!, width: 56, height: 56, fit: BoxFit.cover),
                      ],
                    ),
                    if (uploadedImageUrl == null)
                      TextFormField(
                        controller: imageUrlController,
                        decoration: const InputDecoration(labelText: 'Image URL'),
                        validator: (v) => (uploadedImageUrl == null && (v == null || v.isEmpty)) ? 'Pick image or enter URL' : null,
                      ),
                    const SizedBox(height: 8),
                    // Row(
                    //   children: [
                    //     const Text('Background: '),
                    //     GestureDetector(
                    //       onTap: pickBgColor,
                    //       child: Container(
                    //         width: 32, height: 32, color: bgColor, margin: const EdgeInsets.only(left: 8),
                    //       ),
                    //     ),
                    //     const SizedBox(width: 16),
                    //     const Text('Text: '),
                    //     GestureDetector(
                    //       onTap: pickTextColor,
                    //       child: Container(
                    //         width: 32, height: 32, color: textColor, margin: const EdgeInsets.only(left: 8),
                    //       ),
                    //     ),
                    //   ],
                    // ),
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
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          final supabase = authProvider.supabaseClient;
                          await supabase.from('banners').insert({
                            'title': titleController.text,
                            'subtitle': subtitleController.text,
                            'discount': discountController.text,
                            'image_url': uploadedImageUrl ?? imageUrlController.text,
                            'background_color': '#${bgColor.value.toRadixString(16).substring(2)}',
                            'text_color': '#${textColor.value.toRadixString(16).substring(2)}',
                            'created_at': DateTime.now().toIso8601String(),
                          });
                          Navigator.pop(context);
                          _loadBanners();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Banners'), automaticallyImplyLeading: false),
      drawer: isMobile ? const SidebarMenu() : null,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBannerDialog,
        tooltip: 'Add Banner',
        child: const Icon(Icons.add),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) const SidebarMenu(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _banners.isEmpty
                    ? const Center(child: Text('No banners found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _banners.length,
                        itemBuilder: (context, i) {
                          final b = _banners[i];
                          return Card(
                            color: b['background_color'] != null && b['background_color'].isNotEmpty
                                ? Color(int.parse('0xff${b['background_color'].replaceAll('#', '')}'))
                                : null,
                            child: ListTile(
                              leading: b['image_url'] != null && b['image_url'].isNotEmpty
                                  ? Image.network(b['image_url'], width: 56, height: 56, fit: BoxFit.cover)
                                  : const Icon(Icons.image, size: 56),
                              title: Text(
                                b['title'] ?? '',
                                style: TextStyle(
                                  color: b['text_color'] != null && b['text_color'].isNotEmpty
                                      ? Color(int.parse('0xff${b['text_color'].replaceAll('#', '')}'))
                                      : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (b['subtitle'] != null && b['subtitle'].isNotEmpty)
                                    Text(b['subtitle']),
                                  if (b['discount'] != null && b['discount'].isNotEmpty)
                                    Text('Discount: ${b['discount']}'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Delete Banner',
                                onPressed: () async {
                                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                  final supabase = authProvider.supabaseClient;
                                  await supabase.from('banners').delete().eq('id', b['id']);
                                  _loadBanners();
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
} 