import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TopSellingProductsCard extends StatefulWidget {
  const TopSellingProductsCard({super.key});

  @override
  State<TopSellingProductsCard> createState() => _TopSellingProductsCardState();
}

class _TopSellingProductsCardState extends State<TopSellingProductsCard> {
  final supabase = Supabase.instance.client;
  bool _loading = true;
  List<Map<String, dynamic>> _topProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchTopSelling();
  }

  Future<void> _fetchTopSelling() async {
    try {
      final response = await supabase.from('top_selling_products').select();
      setState(() {
        _topProducts = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      print('Error loading top selling: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📈 Top Selling Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._topProducts.map((p) => ListTile(
              title: Text(p['name'] ?? 'Unknown'),
              subtitle: Text('Sold: ${p['total_quantity_sold']} units'),
              trailing: Text('EGP ${p['total_sales'].toStringAsFixed(2)}'),
            )),
          ],
        ),
      ),
    );
  }
}
