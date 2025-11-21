import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/user_provider.dart';
import '../../models/user.dart';
import '../add_worker_screen.dart';
import '../../utils/logger.dart';
import './worker_attendance_screen.dart';

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    if (!_isLoading) {
      setState(() => _isLoading = true);
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.loadWorkers();
      } catch (e) {
        Logger.error('Error loading workers: $e', e);
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workers Management',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Manage your workforce',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Workers List',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddWorkerScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      'Add Worker',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Expanded(
                child: Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    // Load workers if not already loaded
                    if (userProvider.workers.isEmpty && !_isLoading) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _loadWorkers();
                      });
                    }

                    final workers = userProvider.workers
                        .where((u) => u.role == 'worker')
                        .toList();

                    if (_isLoading && workers.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (workers.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No workers yet',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AddWorkerScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add First Worker'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        await _loadWorkers();
                      },
                      child: ListView.builder(
                        itemCount: workers.length,
                        itemBuilder: (context, index) {
                          return buildWorkerCard(context, workers[index]);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildWorkerCard(BuildContext context, User worker) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1E88E5),
          child: Text(
            worker.name[0].toUpperCase(),
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
        title: Text(
          worker.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              worker.phone,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '₹${worker.wage.toStringAsFixed(2)}/day',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () {
            showWorkerDetails(context, worker);
          },
        ),
      ),
    );
  }

  void showWorkerDetails(BuildContext context, User worker) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF1E88E5),
                      child: Text(
                        worker.name[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  worker.name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  worker.role.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: worker.role == 'admin'
                        ? Colors.red
                        : const Color(0xFF1E88E5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Phone', worker.phone),
                      const SizedBox(height: 10),
                      _buildInfoRow('Join Date', worker.joinDate),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                          'Daily Wage', '₹${worker.wage.toStringAsFixed(2)}'),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                          'Designation', worker.designation ?? 'Not set'),
                      if (worker.email != null && worker.email!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildInfoRow('Email', worker.email!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Close the bottom sheet
                          _editWorker(context, worker);
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Close the bottom sheet
                          _deleteWorker(context, worker);
                        },
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Add Attendance Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close the bottom sheet
                      _markAttendance(context, worker);
                    },
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Mark Attendance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[900],
            ),
          ),
        ),
      ],
    );
  }

  void _editWorker(BuildContext context, User worker) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddWorkerScreen(editUser: worker),
      ),
    );
  }

  void _deleteWorker(BuildContext context, User worker) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Worker',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete ${worker.name}? This action cannot be undone.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close the dialog
                final provider =
                    Provider.of<UserProvider>(context, listen: false);
                final success = await provider.deleteUser(worker.id!);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${worker.name} deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete worker'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _markAttendance(BuildContext context, User worker) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerAttendanceScreen(preselectedWorker: worker),
      ),
    );
  }
}
