import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class CloudSettingsScreen extends StatefulWidget {
  const CloudSettingsScreen({super.key});

  @override
  State<CloudSettingsScreen> createState() => _CloudSettingsScreenState();
}

class _CloudSettingsScreenState extends State<CloudSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cloud Settings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cloud Settings',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This feature is no longer available',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Feature Removed',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'The cloud synchronization feature has been removed from this application. '
                    'All data is now stored locally on your device.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
