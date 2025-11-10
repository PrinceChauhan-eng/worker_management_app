import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../providers/advance_provider.dart';
import '../widgets/custom_app_bar.dart';
import 'request_advance_screen.dart'; // Add this import

class MyAdvanceScreen extends StatefulWidget {
  const MyAdvanceScreen({super.key});

  @override
  State<MyAdvanceScreen> createState() => _MyAdvanceScreenState();
}

class _MyAdvanceScreenState extends State<MyAdvanceScreen> {
  @override
  void initState() {
    super.initState();
    _loadAdvances();
  }

  Future<void> _loadAdvances() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final advanceProvider = Provider.of<AdvanceProvider>(context, listen: false);
      
      if (userProvider.currentUser != null) {
        await advanceProvider.loadAdvancesByWorkerId(userProvider.currentUser!.id!);
      }
    } catch (e) {
      print('Error loading advances: $e');
    }
  }

  void _showAdvanceDetails(advance) {
    final statusColor = advance.isPending
        ? Colors.orange
        : advance.isApproved
            ? Colors.green
            : advance.isDeducted
                ? Colors.blue
                : Colors.red;
    
    final statusText = advance.isPending
        ? 'Pending Approval'
        : advance.isApproved
            ? 'Approved'
            : advance.isDeducted
                ? 'Deducted from Salary'
                : 'Rejected';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Advance Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Amount', '₹${advance.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Date', DateFormat('dd MMM yyyy').format(
                DateFormat('yyyy-MM-dd').parse(advance.date))),
              _buildDetailRow('Purpose', advance.purpose ?? 'N/A'),
              if (advance.note != null && advance.note!.isNotEmpty)
                _buildDetailRow('Note', advance.note!),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: statusColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Status: $statusText',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (advance.approvedDate != null) ...[
                const SizedBox(height: 10),
                _buildDetailRow(
                  'Approved On',
                  DateFormat('dd MMM yyyy').format(
                    DateFormat('yyyy-MM-dd').parse(advance.approvedDate!)),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
            const SizedBox(height: 20),
            // Request Advance Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RequestAdvanceScreen(),
                    ),
                  ).then((value) {
                    // Refresh advances when returning from request screen
                    if (value == true) {
                      _loadAdvances();
                    }
                  });
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  'Request Advance',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5), // Royal Blue
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
              child: RefreshIndicator(
                onRefresh: _loadAdvances,
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
                            const SizedBox(height: 20),
                            TextButton(
                              onPressed: _loadAdvances,
                              child: Text(
                                'Refresh',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF1E88E5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: advances.length,
                        itemBuilder: (context, index) {
                          final advance = advances[index];
                          final statusColor = advance.isPending
                              ? Colors.orange
                              : advance.isApproved
                                  ? Colors.green
                                  : advance.isDeducted
                                      ? Colors.blue
                                      : Colors.red;
                          
                          final statusText = advance.isPending
                              ? 'Pending'
                              : advance.isApproved
                                  ? 'Approved'
                                  : advance.isDeducted
                                      ? 'Deducted'
                                      : 'Rejected';
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: InkWell(
                              onTap: () => _showAdvanceDetails(advance),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFA726).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.payments,
                                                color: Color(0xFFFFA726),
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  advance.purpose ?? 'Advance',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  DateFormat('dd MMM yyyy').format(
                                                    DateFormat('yyyy-MM-dd').parse(advance.date),
                                                  ),
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '₹${advance.amount.toStringAsFixed(2)}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF4CAF50),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: statusColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: statusColor,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                statusText,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: statusColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (advance.note != null && advance.note!.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      const Divider(),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.note_outlined,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              advance.note!,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}