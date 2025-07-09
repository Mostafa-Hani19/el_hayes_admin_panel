// ignore_for_file: avoid_print, deprecated_member_use, unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TopSellingProductsTable extends StatefulWidget {
  const TopSellingProductsTable({super.key});

  @override
  State<TopSellingProductsTable> createState() => _TopSellingProductsTableState();
}

class _TopSellingProductsTableState extends State<TopSellingProductsTable> {
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
        final double titleFontSize = isMobile ? 18 : (isTablet ? 22 : 24);
        final double headerFontSize = isMobile ? 12 : (isTablet ? 16 : 18);
        final double cellFontSize = isMobile ? 11 : (isTablet ? 15 : 20);
        final double containerPadding = isMobile ? 6 : 20;
        final double tableHeaderPadding = isMobile ? 4 : 12;
        final double verticalPadding = isMobile ? 6 : 14;
        final double horizontalPadding = isMobile ? 2 : 8;

        if (_loading) {
          return Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
              padding: EdgeInsets.all(containerPadding),
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        }

        Widget table = Table(
          columnWidths: const {
            0: FlexColumnWidth(2), // Product Name
            1: FlexColumnWidth(),  // Product Code
            2: FlexColumnWidth(),  // Units Sold
            3: FlexColumnWidth(),  // Revenue
          },
          border: TableBorder(horizontalInside: BorderSide(color: Colors.grey, width: 0.3)),
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFf5f6fa)),
              children: [
                Padding(
                  padding: EdgeInsets.all(tableHeaderPadding),
                  child: Text('Product', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: headerFontSize, fontFamily: 'Cairo', color: Color(0xFF22223b))),
                ),
                Padding(
                  padding: EdgeInsets.all(tableHeaderPadding),
                  child: Text('Code', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: headerFontSize, fontFamily: 'Cairo', color: Color(0xFF22223b))),
                ),
                Padding(
                  padding: EdgeInsets.all(tableHeaderPadding),
                  child: Text('Units Sold', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: headerFontSize, fontFamily: 'Cairo', color: Color(0xFF22223b))),
                ),
                Padding(
                  padding: EdgeInsets.all(tableHeaderPadding),
                  child: Text('Revenue (EGP)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: headerFontSize, fontFamily: 'Cairo', color: Color(0xFF22223b))),
                ),
              ],
            ),
            ..._topProducts.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              return TableRow(
                decoration: BoxDecoration(color: i % 2 == 0 ? Colors.white : Colors.grey[100]),
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
                    child: Text(p['name'] ?? 'Unknown', textAlign: TextAlign.center, style: TextStyle(fontSize: cellFontSize, fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
                    child: Text(p['code']?.toString() ?? '-', textAlign: TextAlign.center, style: TextStyle(fontSize: cellFontSize, fontFamily: 'Cairo')),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
                    child: Text('${p['total_quantity_sold']}', textAlign: TextAlign.center, style: TextStyle(fontSize: cellFontSize, fontFamily: 'Cairo')),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
                    child: Text('EGP ${p['total_sales'].toStringAsFixed(2)}', textAlign: TextAlign.center, style: TextStyle(fontSize: cellFontSize, fontFamily: 'Cairo')),
                  ),
                ],
              );
            }).toList(),
          ],
        );

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : (isTablet ? 600 : 900),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
              padding: EdgeInsets.all(containerPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: isMobile ? 10 : 18),
                    child: Center(
                      child: Text(
                        'Top Selling Products',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: titleFontSize,
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  if (isMobile)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: table,
                    )
                  else
                    table,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 