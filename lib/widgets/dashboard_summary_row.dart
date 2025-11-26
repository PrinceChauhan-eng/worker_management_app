import 'package:flutter/material.dart';

// Glass card widget for dashboard summary
class DashboardGlassCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final double height;
  final double iconSize;

  const DashboardGlassCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    this.height = 110,
    this.iconSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: iconSize / 2,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(Icons.work, color: color, size: iconSize),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: iconSize / 1.4,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                Text(title,
                    style: TextStyle(
                        fontSize: iconSize / 2.4,
                        color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardSummaryRow extends StatelessWidget {
  final int totalWorkers;
  final int loggedIn;
  final int absent;

  const DashboardSummaryRow({
    super.key,
    required this.totalWorkers,
    required this.loggedIn,
    required this.absent,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 380;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: DashboardGlassCard(
                height: isMobile ? 82 : 110,
                iconSize: isMobile ? 26 : 32,
                title: "Total Workers",
                value: totalWorkers.toString(),
                color: const Color(0xFF1E88E5),
              ),
            ),
            const SizedBox(width: 12),

            Flexible(
              child: DashboardGlassCard(
                height: isMobile ? 82 : 110,
                iconSize: isMobile ? 26 : 32,
                title: "Logged In",
                value: loggedIn.toString(),
                color: const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 12),

            Flexible(
              child: DashboardGlassCard(
                height: isMobile ? 82 : 110,
                iconSize: isMobile ? 26 : 32,
                title: "Absent",
                value: absent.toString(),
                color: const Color(0xFFF44336),
              ),
            ),
          ],
        );
      },
    );
  }
}