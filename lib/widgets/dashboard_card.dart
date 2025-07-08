import 'package:flutter/material.dart';
import '../utils/constants.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double? percentage;
  final bool isIncrease;
  final String? percentageLabel;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.percentage,
    this.isIncrease = true,
    this.percentageLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: Constants.cardElevation,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Constants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(Constants.defaultPadding),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(Constants.borderRadius),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Constants.defaultPadding),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: Constants.smallPadding),
                if (percentage != null)
                  Row(
                    children: [
                      Icon(
                        isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isIncrease ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${percentage!.toStringAsFixed(1)}% ${percentageLabel ?? (isIncrease ? 'increase' : 'decrease')}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isIncrease ? Colors.green : Colors.red,
                            ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 