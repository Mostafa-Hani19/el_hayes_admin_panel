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

  @override
  void initState() {
    super.initState();
    _fetchDeliveryFee();
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
    await supabase
        .from('settings')
        .upsert({'key': 'delivery_fee', 'value': value});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delivery fee updated!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Constants.isMobile(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), automaticallyImplyLeading: false),
      drawer: isMobile ? const SidebarMenu() : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) const SidebarMenu(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextField(
                              controller: _feeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Delivery Fee (EGP)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _saveDeliveryFee,
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
