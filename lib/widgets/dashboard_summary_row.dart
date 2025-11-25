import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

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
    final card1 = _buildCard(
      title: "Total Workers",
      value: totalWorkers.toString(),
      icon: Icons.people,
      color: const Color(0xFF1E88E5),
    );
    final card2 = _buildCard(
      title: "Logged In",
      value: loggedIn.toString(),
      icon: Icons.check_circle,
      color: const Color(0xFF4CAF50),
    );
    final card3 = _buildCard(
      title: "Absent",
      value: absent.toString(),
      icon: Icons.cancel,
      color: const Color(0xFFF44336),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Tablet / Desktop
        if (constraints.maxWidth > 650) {
          return Row(
            children: [
              Expanded(child: card1),
              const SizedBox(width: 14),
              Expanded(child: card2),
              const SizedBox(width: 14),
              Expanded(child: card3),
            ],
          );
        }
        // Mobile
        return Column(
          children: [
            card1,
            const SizedBox(height: 14),
            card2,
            const SizedBox(height: 14),
            card3,
          ],
        );
      },
    );
  }

  Widget _buildCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 1),
      duration: const Duration(milliseconds: 200),
      builder: (context, scale, child) {
        return GestureDetector(
          onTapDown: (_) {}, // For animation in future if needed
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(0.12),         // glass transparency
              border: Border.all(
                color: Colors.white.withOpacity(0.25),       // glass edge line
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 25,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),                // glass glow shadow
                ),
              ],
              // glass blur effect
              backgroundBlendMode: BlendMode.overlay,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.95),
                            color.withOpacity(0.65),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, size: 32, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.85),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}