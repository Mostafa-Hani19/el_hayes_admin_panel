import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ModernDashboardCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double? percentage;
  final bool isIncrease;

  const ModernDashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
    this.percentage,
    required this.isIncrease,
    Key? key,
  }) : super(key: key);

  @override
  State<ModernDashboardCard> createState() => _ModernDashboardCardState();
}

class _ModernDashboardCardState extends State<ModernDashboardCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Constants.isDesktop(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _hovering && isDesktop
                    ? widget.color.withOpacity(0.15)
                    : Colors.black.withOpacity(0.05),
                blurRadius: _hovering && isDesktop ? 20 : 15,
                offset: Offset(0, _hovering && isDesktop ? 25 : 20),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: widget.color.withOpacity(0.13),
                    radius: 24,
                    child: Icon(widget.icon, color: widget.color, size: 28),
                  ),
                  const Spacer(),
                  if (widget.percentage != null)
                    Row(
                      children: [
                        Icon(
                          widget.isIncrease
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: widget.isIncrease ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.percentage!.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color:
                                widget.isIncrease ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                widget.value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey[600],
                  fontFamily: 'Cairo',
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 