// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class TopSellingProductsTabel extends StatefulWidget {
//   const TopSellingProductsTabel({super.key});

//   @override
//   State<TopSellingProductsTabel> createState() =>
//       _TopSellingProductsTabelState();
// }

// class _TopSellingProductsTabelState extends State<TopSellingProductsTabel> {
//   final supabase = Supabase.instance.client;
//   bool _loading = true;
//   List<Map<String, dynamic>> _topProducts = [];

//   @override
//   void initState() {
//     super.initState();
//     _fetchTopSelling();
//   }

//   Future<void> _fetchTopSelling() async {
//     try {
//       final response = await supabase.from('top_selling_products').select();
//       setState(() {
//         _topProducts = List<Map<String, dynamic>>.from(response);
//         _loading = false;
//       });
//     } catch (e) {
//       print('Error loading top selling: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final isMobile = constraints.maxWidth < 600;
//         final isTablet =
//             constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
//         final double titleFontSize = isMobile ? 18 : (isTablet ? 22 : 24);
//         final double headerFontSize = isMobile ? 13 : (isTablet ? 16 : 18);
//         final double cellFontSize = isMobile ? 13 : (isTablet ? 16 : 20);
//         final double containerPadding = isMobile ? 8 : 20;
//         final double tableHeaderPadding = isMobile ? 6 : 12;
//         final double verticalPadding = isMobile ? 8 : 14;
//         final double horizontalPadding = isMobile ? 4 : 8;

//         if (_loading) {
//           return Center(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.07),
//                     blurRadius: 12,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
//               padding: EdgeInsets.all(containerPadding),
//               child: const Center(child: CircularProgressIndicator()),
//             ),
//           );
//         }

//         return Center(
//           child: ConstrainedBox(
//             constraints: BoxConstraints(
//               maxWidth: isMobile ? double.infinity : (isTablet ? 600 : 900),
//             ),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.07),
//                     blurRadius: 12,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
//               padding: EdgeInsets.all(containerPadding),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Padding(
//                     padding: EdgeInsets.only(bottom: isMobile ? 10 : 18),
//                     child: Center(
//                       child: Text(
//                         'Top Selling Products',
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: titleFontSize,
//                           fontFamily: 'Cairo',
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   ),
//                   Table(
//                     columnWidths: const {
//                       0: FlexColumnWidth(2),
//                       1: FlexColumnWidth(),
//                       2: FlexColumnWidth(),
//                     },
//                     border: TableBorder(
//                       horizontalInside: BorderSide(
//                         color: Colors.grey,
//                         width: 0.3,
//                       ),
//                     ),
//                     children: [
//                       TableRow(
//                         decoration: const BoxDecoration(
//                           color: Color(0xFFf5f6fa),
//                         ),
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(tableHeaderPadding),
//                             child: Text(
//                               'Product',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: headerFontSize,
//                                 fontFamily: 'Cairo',
//                                 color: const Color(0xFF22223b),
//                               ),
//                             ),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(tableHeaderPadding),
//                             child: Text(
//                               'Units Sold',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: headerFontSize,
//                                 fontFamily: 'Cairo',
//                                 color: const Color(0xFF22223b),
//                               ),
//                             ),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(tableHeaderPadding),
//                             child: Text(
//                               'Revenue (EGP)',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: headerFontSize,
//                                 fontFamily: 'Cairo',
//                                 color: const Color(0xFF22223b),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       ..._topProducts.asMap().entries.map((entry) {
//                         final i = entry.key;
//                         final p = entry.value;
//                         return TableRow(
//                           decoration: BoxDecoration(
//                             color: i % 2 == 0 ? Colors.white : Colors.grey[100],
//                           ),
//                           children: [
//                             Padding(
//                               padding: EdgeInsets.symmetric(
//                                 vertical: verticalPadding,
//                                 horizontal: horizontalPadding,
//                               ),
//                               child: Text(
//                                 p['name'] ?? 'Unknown',
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   fontSize: cellFontSize,
//                                   fontWeight: FontWeight.w600,
//                                   fontFamily: 'Cairo',
//                                 ),
//                               ),
//                             ),
//                             Padding(
//                               padding: EdgeInsets.symmetric(
//                                 vertical: verticalPadding,
//                                 horizontal: horizontalPadding,
//                               ),
//                               child: Text(
//                                 '${p['total_quantity_sold']}',
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   fontSize: cellFontSize,
//                                   fontFamily: 'Cairo',
//                                 ),
//                               ),
//                             ),
//                             Padding(
//                               padding: EdgeInsets.symmetric(
//                                 vertical: verticalPadding,
//                                 horizontal: horizontalPadding,
//                               ),
//                               child: Text(
//                                 'EGP ${p['total_sales'].toStringAsFixed(2)}',
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   fontSize: cellFontSize,
//                                   fontFamily: 'Cairo',
//                                 ),
//                               ),
//                             ),
//                           ],
//                         );
//                       }).toList(),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
