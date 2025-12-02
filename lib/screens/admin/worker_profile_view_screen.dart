import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user.dart';

class WorkerProfileViewScreen extends StatelessWidget {
  final User worker;

  const WorkerProfileViewScreen({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${worker.name}'s Profile", style: GoogleFonts.poppins()),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(worker),
            const SizedBox(height: 20),
            _jobInfo(worker),
          ],
        ),
      ),
    );
  }

  // --------------------- HEADER ---------------------
  Widget _header(User worker) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E88E5).withOpacity(0.9),
            const Color(0xFF1E88E5).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundImage: worker.profilePhoto != null
                ? NetworkImage(worker.profilePhoto!)
                : null,
            child: worker.profilePhoto == null
                ? const Icon(Icons.person, size: 50, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.name,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  "Worker",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Phone: ${worker.phone ?? 'Not set'}",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------- JOB DETAILS ---------------------
  Widget _jobInfo(User worker) {
    return _infoCard(
      "Job Information",
      [
        _infoRow("Designation", worker.designation ?? "Not set"),
        _infoRow("Daily Wage", "₹${worker.wage.toStringAsFixed(2)}"),
        _infoRow("Phone", worker.phone ?? "Not set"),
        _infoRow("Email", worker.email ?? "Not set"),
        _infoRow("Address", worker.address ?? "Not set"),
      ],
    );
  }

  Widget _infoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(label, style: GoogleFonts.poppins(fontSize: 14))),
          Expanded(
              flex: 4,
              child: Text(value, style: GoogleFonts.poppins(fontSize: 14))),
        ],
      ),
    );
  }
}