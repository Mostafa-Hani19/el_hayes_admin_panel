import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthlyComparisonTable extends StatelessWidget {
  final int orderThisMonth;
  final int orderLastMonth;
  final double orderPercent;
  final double revenueThisMonth;
  final double revenueLastMonth;
  final double revenuePercent;

  const MonthlyComparisonTable({
    super.key,
    required this.orderThisMonth,
    required this.orderLastMonth,
    required this.orderPercent,
    required this.revenueThisMonth,
    required this.revenueLastMonth,
    required this.revenuePercent,
  });

  Color _getPercentColor(double percent) {
    if (percent > 0) return Colors.green;
    if (percent < 0) return Colors.red;
    return Colors.grey;
  }

  IconData? _getPercentIcon(double percent) {
    if (percent > 0) return Icons.arrow_upward;
    if (percent < 0) return Icons.arrow_downward;
    return null;
  }

  String _formatCurrency(double value) {
    final format = NumberFormat.currency(locale: 'en', symbol: ' ');
    return format.format(value);
  }

  @override
  Widget build(BuildContext context) {
    // Responsive breakpoints
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 1024;

    // Responsive sizes
    final double titleFontSize = isMobile
        ? 20
        : (isTablet ? 22 : 24);
    final double headerFontSize = isMobile
        ? 14
        : (isTablet ? 16 : 18);
    final double cellFontSize = isMobile
        ? 14
        : (isTablet ? 16 : 18);
    final double percentFontSize = isMobile
        ? 13
        : (isTablet ? 15 : 17);
    final double iconSize = isMobile ? 18 : 22;
    final double verticalPadding = isMobile ? 10 : 14;
    final double horizontalPadding = isMobile ? 6 : 8;
    final double containerPadding = isMobile ? 16 : 24;
    final double tableHeaderPadding = isMobile ? 8 : 12;

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
      padding: EdgeInsets.all(containerPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text(
              'Monthly Comparison',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: titleFontSize,
                fontFamily: 'Cairo',
                color: Colors.blueGrey[800],
              ),
            ),
          ),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.8),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
              3: FlexColumnWidth(1.2),
            },
            border: TableBorder(
              horizontalInside:
                  BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            children: [
              TableRow(
                decoration:
                    BoxDecoration(color: Colors.grey[50]),
                children: [
                  ...['Item', 'This Month', 'Last Month', 'Change']
                      .map((header) => Padding(
                            padding: EdgeInsets.all(tableHeaderPadding),
                            child: Text(
                              header,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: headerFontSize,
                                  fontFamily: 'Cairo',
                                  color: Colors.blueGrey[700]),
                            ),
                          ))
                      ,
                ],
              ),
              // Orders row
              TableRow(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: verticalPadding,
                        horizontal: horizontalPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart,
                            color: Colors.blueAccent, size: iconSize),
                        const SizedBox(width: 8),
                        Text('Orders',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: cellFontSize,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: verticalPadding,
                        horizontal: horizontalPadding),
                    child: Text(
                      '$orderThisMonth',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: cellFontSize,
                          fontFamily: 'Cairo',
                          color: Colors.blueGrey[800]),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: verticalPadding,
                        horizontal: horizontalPadding),
                    child: Text(
                      '$orderLastMonth',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: cellFontSize,
                          color: Colors.grey[600],
                          fontFamily: 'Cairo'),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: verticalPadding,
                        horizontal: horizontalPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_getPercentIcon(orderPercent) != null)
                          Icon(_getPercentIcon(orderPercent),
                              color: _getPercentColor(orderPercent),
                              size: iconSize - 2),
                        const SizedBox(width: 4),
                        Text(
                          '${orderPercent >= 0 ? "+" : ""}${orderPercent.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: _getPercentColor(orderPercent),
                            fontWeight: FontWeight.bold,
                            fontSize: percentFontSize,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Revenue row
              TableRow(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: verticalPadding,
                        horizontal: horizontalPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.attach_money,
                            color: Colors.deepPurple, size: iconSize),
                        const SizedBox(width: 8),
                        Text('Revenue',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: cellFontSize,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: verticalPadding,
                        horizontal: horizontalPadding),
                    child: Text(
                      _formatCurrency(revenueThisMonth),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: cellFontSize,
                          fontFamily: 'Cairo',
                          color: Colors.blueGrey[800]),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: verticalPadding,
                        horizontal: horizontalPadding),
                    child: Text(
                      _formatCurrency(revenueLastMonth),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: cellFontSize,
                          color: Colors.grey[600],
                          fontFamily: 'Cairo'),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: verticalPadding,
                        horizontal: horizontalPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_getPercentIcon(revenuePercent) != null)
                          Icon(_getPercentIcon(revenuePercent),
                              color: _getPercentColor(revenuePercent),
                              size: iconSize - 2),
                        const SizedBox(width: 4),
                        Text(
                          '${revenuePercent >= 0 ? "+" : ""}${revenuePercent.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: _getPercentColor(revenuePercent),
                            fontWeight: FontWeight.bold,
                            fontSize: percentFontSize,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
} 