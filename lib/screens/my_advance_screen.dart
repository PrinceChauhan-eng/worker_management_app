import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../providers/advance_provider.dart';
import '../widgets/custom_app_bar.dart';

class MyAdvanceScreen extends StatefulWidget {
  const MyAdvanceScreen({super.key});

  @override
  State<MyAdvanceScreen> createState() => _MyAdvanceScreenState();
}

class _MyAdvanceScreenState extends State<MyAdvanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final advanceProvider =
          Provider.of<AdvanceProvider>(context, listen: false);
      
      if (userProvider.currentUser != null) {
        advanceProvider.loadAdvancesByWorkerId(userProvider.currentUser!.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final advanceProvider = Provider.of<AdvanceProvider>(context);
    
    final workerId = userProvider.currentUser?.id;
    
    // Filter advances for current worker
    final advances = workerId != null 
        ? advanceProvider.advances
            .where((adv) => adv.workerId == workerId)
            .toList()
        : [];
    
    // Calculate total advances
    double totalAdvance = 0;
    for (var advance in advances) {
      totalAdvance += advance.amount;
    }

    // Sort advances by date (newest first)
    advances.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Advances',
        onLeadingPressed: () {
          Navigator.pop(context);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advance History',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E88E5), // Royal Blue
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'View all your advance transactions',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            // Total Advance Summary
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 3,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E88E5), // Royal Blue
                      Color(0xFFFFA726), // Orange
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Advances',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '₹${totalAdvance.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Advances List
            Text(
              'Advance Transactions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: advances.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.payment_outlined,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No advance transactions found',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: advances.length,
                      itemBuilder: (context, index) {
                        final advance = advances[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFA726), // Orange
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.payments,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              'Advance',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat('dd MMM yyyy').format(
                                DateFormat('yyyy-MM-dd').parse(advance.date),
                              ),
                              style: GoogleFonts.poppins(),
                            ),
                            trailing: Text(
                              '₹${advance.amount.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4CAF50), // Green
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}