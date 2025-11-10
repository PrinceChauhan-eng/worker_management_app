import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/user.dart';
import '../models/advance.dart';

import '../providers/user_provider.dart';
import '../providers/advance_provider.dart';
import '../providers/base_provider.dart';

import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

/// ------------------------------------------------------------
/// Advance Only Screen
/// - Shows only advance functionality without salary processing
/// - Worker selection by ID (prevents name collision)
/// - Custom date picker
/// - Summary tiles & polished UI
/// - Defensive null/empty checks + toasts
/// ------------------------------------------------------------
class AdvanceOnlyScreen extends StatefulWidget {
  const AdvanceOnlyScreen({super.key});

  @override
  State<AdvanceOnlyScreen> createState() => _AdvanceOnlyScreenState();
}

class _AdvanceOnlyScreenState extends State<AdvanceOnlyScreen> {
  final _advanceFormKey = GlobalKey<FormState>();
  
  // --------- Advance form state ----------
  final _advanceAmountController = TextEditingController();
  final _advanceDateController = TextEditingController();
  String _advanceDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? _selectedAdvanceWorkerId;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _advanceDateController.text = _advanceDate;

    // Initial data load
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final advanceProvider = Provider.of<AdvanceProvider>(context, listen: false);

      await userProvider.loadWorkers();
      await advanceProvider.loadAdvances();
    });
  }

  @override
  void dispose() {
    _advanceAmountController.dispose();
    _advanceDateController.dispose();
    super.dispose();
  }

  // ---------------- Helpers ----------------
  String _formatCurrency(num v) => '₹${v.toStringAsFixed(2)}';

  DateTime _parseYmd(String ymd) => DateFormat('yyyy-MM-dd').parse(ymd);

  // -------------- Pickers ------------------
  Future<void> _pickAdvanceDate() async {
    final initial = _parseYmd(_advanceDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _advanceDate = DateFormat('yyyy-MM-dd').format(picked);
        _advanceDateController.text = _advanceDate;
      });
    }
  }

  // -------------- Actions ------------------
  Future<void> _addAdvance() async {
    if (!_advanceFormKey.currentState!.validate()) return;

    if (_selectedAdvanceWorkerId == null || _selectedAdvanceWorkerId!.isEmpty) {
      Fluttertoast.showToast(msg: 'Please select a worker');
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final advanceProvider = Provider.of<AdvanceProvider>(context, listen: false);

    // Validate worker selection
    if (_selectedAdvanceWorkerId == null) {
      Fluttertoast.showToast(msg: 'Please select a worker');
      return;
    }
    
    final worker = userProvider.workers.firstWhere(
      (u) => u.id.toString() == _selectedAdvanceWorkerId,
      orElse: () => User(
          name: 'Unknown',
          phone: '',
          password: '',
          role: 'worker',
          wage: 0,
          joinDate: ''),
    );
    
    if (worker.id == null) {
      Fluttertoast.showToast(msg: 'Invalid worker selected');
      return;
    }

    final amount = double.tryParse(_advanceAmountController.text.trim());
    if (amount == null || amount <= 0) {
      Fluttertoast.showToast(msg: 'Enter a valid amount');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if current user is admin to auto-approve advances
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final isAdmin = userProvider.currentUser?.role == 'admin';
      
      final advance = Advance(
        workerId: worker.id!,
        amount: amount,
        date: _advanceDate,
        status: isAdmin ? 'approved' : 'pending',
        approvedBy: isAdmin ? userProvider.currentUser?.id : null,
        approvedDate: isAdmin ? DateTime.now().toIso8601String() : null,
      );

      final ok = await advanceProvider.addAdvance(advance);

      if (ok) {
        Fluttertoast.showToast(msg: 'Advance added successfully!');
        _advanceAmountController.clear();
        setState(() {
          _selectedAdvanceWorkerId = null;
        });
        // Refresh list
        await advanceProvider.loadAdvances();
      } else {
        Fluttertoast.showToast(msg: 'Failed to add advance. Try again.');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error adding advance. Try again.');
      print('Error adding advance: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // -------------- UI ----------------------
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final workers = userProvider.workers.where((u) => u.role == 'worker').toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Advance Management',
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Summary row
            Consumer<AdvanceProvider>(
              builder: (context, advanceProvider, _) {
                // Compute simple summary for recent month (current month)
                final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
                final totalThisMonth = advanceProvider.advances
                    .where((a) => a.date.startsWith(currentMonth))
                    .fold<double>(0.0, (sum, a) => sum + (a.amount ?? 0));

                return Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    const Color(0xFFFFA726).withOpacity(0.12),
                                child: const Icon(Icons.payments,
                                    color: Color(0xFFFFA726)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('This Month Advances',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[700])),
                                    const SizedBox(height: 4),
                                    Text('₹${totalThisMonth.toStringAsFixed(2)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        )),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    const Color(0xFF26A69A).withOpacity(0.12),
                                child: const Icon(Icons.receipt_long,
                                    color: Color(0xFF26A69A)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Total Records',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[700])),
                                    const SizedBox(height: 4),
                                    Text('${advanceProvider.advances.length}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        )),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add Advance',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E88E5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Form(
              key: _advanceFormKey,
              child: Column(
                children: [
                  // Worker dropdown by ID
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAdvanceWorkerId,
                    hint: Text('Select Worker', style: GoogleFonts.poppins()),
                    items: workers.map((w) {
                      return DropdownMenuItem(
                        value: w.id.toString(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(w.name, style: GoogleFonts.poppins()),
                            Text('₹${w.wage}/day',
                                style: GoogleFonts.poppins(
                                    color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (id) => setState(() => _selectedAdvanceWorkerId = id),
                    decoration: InputDecoration(
                      labelText: 'Worker',
                      labelStyle: GoogleFonts.poppins(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Please select a worker' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _advanceAmountController,
                    labelText: 'Amount',
                    hintText: 'Enter advance amount',
                    prefixIcon: Icons.currency_rupee,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter amount';
                      }
                      final n = double.tryParse(value.trim());
                      if (n == null || n <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickAdvanceDate,
                    child: AbsorbPointer(
                      child: CustomTextField(
                        controller: _advanceDateController,
                        labelText: 'Date',
                        hintText: 'Select date',
                        prefixIcon: Icons.calendar_today,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Please select date'
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Add Advance',
                    onPressed: _addAdvance,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Advances',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer<AdvanceProvider>(
                builder: (context, provider, _) {
                  if (provider.state == ViewState.busy) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.advances.isEmpty) {
                    return Center(
                      child: Text(
                        'No advances found',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  }

                  final advances = List<Advance>.from(provider.advances)
                    ..sort((a, b) => b.date.compareTo(a.date));

                  return ListView.separated(
                    itemCount: advances.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final a = advances[index];
                      final worker = userProvider.workers.firstWhere(
                        (u) => u.id == a.workerId,
                        orElse: () => User(
                            name: 'Unknown',
                            phone: '',
                            password: '',
                            role: '',
                            wage: 0,
                            joinDate: ''),
                      );
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFFFA726),
                            child: const Text('₹',
                                style: TextStyle(color: Colors.white)),
                          ),
                          title: Text(worker.name,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${a.date} • ${a.status ?? 'pending'}',
                            style: GoogleFonts.poppins(),
                          ),
                          trailing: Text(
                            '₹${(a.amount ?? 0).toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                      );
                    },
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