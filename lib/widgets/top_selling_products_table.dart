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

        if (_loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (isMobile) {
          return _buildMobileLayout();
        } else {
          return _buildDesktopLayout(context, constraints);
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    final double titleFontSize = 18;
    final double containerPadding = 16;
    return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
                  ),
                ],
              ),
      margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              padding: EdgeInsets.all(containerPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
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
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _topProducts.length,
            itemBuilder: (context, index) {
              final p = _topProducts[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('Code:', p['code']?.toString() ?? '-'),
                      const SizedBox(height: 4),
                      _buildInfoRow('Units Sold:', '${p['total_quantity_sold']}'),
                      const SizedBox(height: 4),
                      _buildInfoRow('Revenue:',
                          'EGP ${p['total_sales'].toStringAsFixed(2)}'),
                    ],
                  ),
            ),
          );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontFamily: 'Cairo', fontSize: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context, BoxConstraints constraints) {
    final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
    final double titleFontSize = isTablet ? 22 : 24;
    final double headerFontSize = isTablet ? 16 : 18;
    final double cellFontSize = isTablet ? 15 : 20;
    final double containerPadding = isTablet ? 12 : 20;
    final double tableHeaderPadding = isTablet ? 8 : 12;
    final double verticalPadding = isTablet ? 8 : 14;
    final double horizontalPadding = isTablet ? 4 : 8;

        Widget table = Table(
          columnWidths: const {
            0: FlexColumnWidth(2), // Product Name
        1: FlexColumnWidth(), // Product Code
        2: FlexColumnWidth(), // Units Sold
        3: FlexColumnWidth(), // Revenue
          },
      border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey[300]!, width: 0.5)),
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: const Color(0xFFf5f6fa),
            borderRadius: BorderRadius.circular(8),
          ),
          children: [
            ...['Product', 'Code', 'Units Sold', 'Revenue (EGP)']
                .map((header) => Padding(
                  padding: EdgeInsets.all(tableHeaderPadding),
                      child: Text(
                        header,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: headerFontSize,
                            fontFamily: 'Cairo',
                            color: const Color(0xFF22223b)),
                ),
                    ))
                .toList(),
              ],
            ),
            ..._topProducts.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              return TableRow(
            decoration: BoxDecoration(
                color: i % 2 == 0 ? Colors.white : Colors.grey[50]),
                children: [
                  Padding(
                padding: EdgeInsets.symmetric(
                    vertical: verticalPadding, horizontal: horizontalPadding),
                child: Text(p['name'] ?? 'Unknown',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: cellFontSize,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo')),
                  ),
                  Padding(
                padding: EdgeInsets.symmetric(
                    vertical: verticalPadding, horizontal: horizontalPadding),
                child: Text(p['code']?.toString() ?? '-',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: cellFontSize, fontFamily: 'Cairo')),
                  ),
                  Padding(
                padding: EdgeInsets.symmetric(
                    vertical: verticalPadding, horizontal: horizontalPadding),
                child: Text('${p['total_quantity_sold']}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: cellFontSize, fontFamily: 'Cairo')),
                  ),
                  Padding(
                padding: EdgeInsets.symmetric(
                    vertical: verticalPadding, horizontal: horizontalPadding),
                child: Text('EGP ${p['total_sales'].toStringAsFixed(2)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: cellFontSize, fontFamily: 'Cairo')),
                  ),
                ],
              );
            }).toList(),
          ],
        );

    return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
                  ),
                ],
              ),
      margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              padding: EdgeInsets.all(containerPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
            padding: EdgeInsets.only(bottom: isTablet ? 12 : 18),
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
                    table,
                ],
              ),
    );
  }
} 