import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../models/advance.dart';
import '../models/user.dart';
import '../providers/advance_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_app_bar.dart';

class ManageAdvancesScreen extends StatefulWidget {
  const ManageAdvancesScreen({super.key});

  @override
  State<ManageAdvancesScreen> createState() => _ManageAdvancesScreenState();
}

class _ManageAdvancesScreenState extends State<ManageAdvancesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final advanceProvider = Provider.of<AdvanceProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    await advanceProvider.loadAdvances();
    await userProvider.loadWorkers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Manage Advances',
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1E88E5),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF1E88E5),
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Approved'),
                Tab(text: 'Rejected'),
                Tab(text: 'Deducted'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAdvanceList('pending'),
                _buildAdvanceList('approved'),
                _buildAdvanceList('rejected'),
                _buildAdvanceList('deducted'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvanceList(String status) {
    return Consumer2<AdvanceProvider, UserProvider>(
      builder: (context, advanceProvider, userProvider, child) {
        final advances = advanceProvider.advances
            .where((adv) => adv.status == status)
            .toList();

        // Sort by date (newest first)
        advances.sort((a, b) => b.date.compareTo(a.date));

        if (advances.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 20),
                Text(
                  'No $status advances',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: advances.length,
            itemBuilder: (context, index) {
              final advance = advances[index];
              final worker = userProvider.workers.firstWhere(
                (w) => w.id == advance.workerId,
                orElse: () => User(
                  name: 'Unknown',
                  phone: '',
                  password: '',
                  role: 'worker',
                  wage: 0,
                  joinDate: '',
                ),
              );

              return _buildAdvanceCard(advance, worker, status);
            },
          ),
        );
      },
    );
  }

  Widget _buildAdvanceCard(Advance advance, User worker, String status) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'deducted':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _showAdvanceDetails(advance, worker),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          worker.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          advance.purpose ?? 'Advance',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
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
                      Text(
                        DateFormat('dd MMM yyyy').format(
                          DateFormat('yyyy-MM-dd').parse(advance.date),
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (advance.note != null && advance.note!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
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
              if (status == 'pending') ...[
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectAdvance(advance, worker),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveAdvance(advance, worker),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
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
  }

  void _showAdvanceDetails(Advance advance, User worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Advance Request Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Worker', worker.name),
              _buildDetailRow('Phone', worker.phone),
              _buildDetailRow('Amount', '₹${advance.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Date', DateFormat('dd MMM yyyy').format(
                DateFormat('yyyy-MM-dd').parse(advance.date))),
              _buildDetailRow('Purpose', advance.purpose ?? 'N/A'),
              if (advance.note != null && advance.note!.isNotEmpty)
                _buildDetailRow('Note', advance.note!),
              _buildDetailRow('Status', advance.status.toUpperCase()),
              if (advance.approvedDate != null)
                _buildDetailRow(
                  'Approved On',
                  DateFormat('dd MMM yyyy').format(
                    DateFormat('yyyy-MM-dd').parse(advance.approvedDate!)),
                ),
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
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveAdvance(Advance advance, User worker) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Approve Advance',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Approve ₹${advance.amount.toStringAsFixed(2)} advance for ${worker.name}?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final adminId = userProvider.currentUser?.id ?? 0;

      final updatedAdvance = Advance(
        id: advance.id,
        workerId: advance.workerId,
        amount: advance.amount,
        date: advance.date,
        purpose: advance.purpose,
        note: advance.note,
        status: 'approved',
        approvedBy: adminId,
        approvedDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );

      final advanceProvider = Provider.of<AdvanceProvider>(context, listen: false);
      bool success = await advanceProvider.updateAdvance(updatedAdvance);

      if (success) {
        Fluttertoast.showToast(
          msg: 'Advance approved successfully!',
          backgroundColor: Colors.green,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to approve advance',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _rejectAdvance(Advance advance, User worker) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reject Advance',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Reject ₹${advance.amount.toStringAsFixed(2)} advance for ${worker.name}?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updatedAdvance = Advance(
        id: advance.id,
        workerId: advance.workerId,
        amount: advance.amount,
        date: advance.date,
        purpose: advance.purpose,
        note: advance.note,
        status: 'rejected',
      );

      final advanceProvider = Provider.of<AdvanceProvider>(context, listen: false);
      bool success = await advanceProvider.updateAdvance(updatedAdvance);

      if (success) {
        Fluttertoast.showToast(
          msg: 'Advance rejected',
          backgroundColor: Colors.orange,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to reject advance',
          backgroundColor: Colors.red,
        );
      }
    }
  }
}
