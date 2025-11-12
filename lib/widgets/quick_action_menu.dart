import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickActionMenu extends StatelessWidget {
  final VoidCallback onViewLocation;
  final VoidCallback onSalarySlip;
  final VoidCallback onAttendanceLog;

  const QuickActionMenu({
    super.key,
    required this.onViewLocation,
    required this.onSalarySlip,
    required this.onAttendanceLog,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionItem(
            context,
            icon: Icons.location_on,
            label: 'View Location',
            color: Colors.blue,
            onTap: onViewLocation,
          ),
          const SizedBox(height: 12),
          _buildActionItem(
            context,
            icon: Icons.account_balance_wallet,
            label: 'Salary Slip',
            color: Colors.green,
            onTap: onSalarySlip,
          ),
          const SizedBox(height: 12),
          _buildActionItem(
            context,
            icon: Icons.check_circle,
            label: 'Attendance Log',
            color: Colors.orange,
            onTap: onAttendanceLog,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}