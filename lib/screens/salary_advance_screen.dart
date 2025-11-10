import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/user.dart';
import '../models/advance.dart';
import '../models/salary.dart';

import '../providers/user_provider.dart';
import '../providers/advance_provider.dart';
import '../providers/salary_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/base_provider.dart';

import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

/// ------------------------------------------------------------
/// Salary & Advance Screen (Upgraded - Option C)
/// - Worker selection by ID (prevents name collision)
/// - Custom Month-Year picker (no extra packages)
/// - Date/Month controllers managed safely (no build() creation)
/// - Salary calculation filtered by selected month
/// - Duplicate salary prevention
/// - Summary tiles & polished UI
/// - Defensive null/empty checks + toasts
/// ------------------------------------------------------------
class SalaryAdvanceScreen extends StatefulWidget {
  const SalaryAdvanceScreen({super.key});

  @override
  State<SalaryAdvanceScreen> createState() => _SalaryAdvanceScreenState();
}

class _SalaryAdvanceScreenState extends State<SalaryAdvanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _advanceFormKey = GlobalKey<FormState>();
  final _salaryFormKey = GlobalKey<FormState>();

  // --------- Advance form state ----------
  final _advanceAmountController = TextEditingController();
  final _advanceDateController = TextEditingController();
  String _advanceDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? _selectedAdvanceWorkerId;

  // --------- Salary form state -----------
  final _salaryMonthController = TextEditingController();
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  String? _selectedSalaryWorkerId;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    _advanceDateController.text = _advanceDate;
    _salaryMonthController.text = _selectedMonth;

    // Initial data load
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final advanceProvider =
          Provider.of<AdvanceProvider>(context, listen: false);
      final salaryProvider =
          Provider.of<SalaryProvider>(context, listen: false);

      await userProvider.loadWorkers();
      await advanceProvider.loadAdvances();
      await salaryProvider.loadSalaries();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _advanceAmountController.dispose();
    _advanceDateController.dispose();
    _salaryMonthController.dispose();
    super.dispose();
  }

  // ---------------- Helpers ----------------

  String _formatCurrency(num v) => '₹${v.toStringAsFixed(2)}';

  DateTime _parseYmd(String ymd) => DateFormat('yyyy-MM-dd').parse(ymd);

  /// Returns first & last date for a given `yyyy-MM`.
  (DateTime start, DateTime end) _monthBounds(String ym) {
    final start = DateFormat('yyyy-MM').parse(ym);
    final end = DateTime(start.year, start.month + 1, 0);
    return (DateTime(start.year, start.month, 1), end);
  }

  bool _isSameMonth(String ymd, String ym) {
    return ymd.startsWith(ym);
  }

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

  Future<void> _pickSalaryMonth() async {
    final initial = DateFormat('yyyy-MM').parse(_selectedMonth);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _MonthYearPickerDialog(
        initialYear: initial.year,
        initialMonth: initial.month,
      ),
    );
    if (result != null) {
      setState(() {
        _selectedMonth = result; // yyyy-MM
        _salaryMonthController.text = _selectedMonth;
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
    final advanceProvider =
        Provider.of<AdvanceProvider>(context, listen: false);

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

  Future<void> _calculateAndSaveSalary() async {
    if (_selectedSalaryWorkerId == null || _selectedSalaryWorkerId!.isEmpty) {
      Fluttertoast.showToast(msg: 'Please select a worker');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('Starting salary calculation...');
      print('Selected worker ID: $_selectedSalaryWorkerId');
      print('Selected month: $_selectedMonth');
      
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final advanceProvider =
          Provider.of<AdvanceProvider>(context, listen: false);
      final salaryProvider =
          Provider.of<SalaryProvider>(context, listen: false);
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);

      // Validate worker selection
      if (_selectedSalaryWorkerId == null) {
        Fluttertoast.showToast(msg: 'Please select a worker');
        return;
      }
      
      final worker = userProvider.workers.firstWhere(
        (u) => u.id.toString() == _selectedSalaryWorkerId,
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

      // 1) Prevent duplicate salary for same worker & month
      await salaryProvider.loadSalaries(); // ensure fresh
      if (_selectedMonth.isEmpty) {
        Fluttertoast.showToast(msg: 'Please select a month');
        return;
      }
      
      final already = salaryProvider.salaries.any(
        (s) => s.workerId == worker.id && s.month == _selectedMonth,
      );
      if (already) {
        Fluttertoast.showToast(
            msg: 'Salary already generated for ${worker.name} in $_selectedMonth');
        return;
      }

      // 2) Load attendance for worker and compute present days for selected month
      await attendanceProvider.loadAttendancesByWorkerId(worker.id!);
      final presentDays = attendanceProvider.attendances
          .where((att) =>
              att.workerId == worker.id &&
              att.present == true &&
              _isSameMonth(att.date, _selectedMonth))
          .length;
      
      // Validate present days
      if (presentDays < 0) {
        Fluttertoast.showToast(msg: 'Invalid present days count');
        return;
      }

      // 3) Compute total wage
      final dailyWage = worker.wage; // assuming wage is per day
      if (dailyWage < 0) {
        Fluttertoast.showToast(msg: 'Invalid daily wage');
        return;
      }
      final totalWage = (dailyWage) * presentDays;

      // 4) Filter advances only in selected month & only 'approved' or 'pending'?
      // Business rule: subtract all advances in that month, regardless of status (common choice: approved).
      // Here we'll subtract approved + pending to be conservative; change if needed.
      await advanceProvider.loadAdvances();
      final advancesInMonth = advanceProvider.advances.where((a) {
        final sameWorker = a.workerId == worker.id;
        final sameMonth = _isSameMonth(a.date, _selectedMonth);
        return sameWorker && sameMonth;
      }).toList();

      final totalAdvance = advancesInMonth.fold<double>(
        0.0,
        (sum, a) => sum + (a.amount ?? 0),
      );
      
      // Validate total advance
      if (totalAdvance < 0) {
        Fluttertoast.showToast(msg: 'Invalid total advance');
        return;
      }

      // 5) Net salary
      double netSalary = totalWage - totalAdvance;
      if (netSalary < 0) netSalary = 0; // prevent negative payout

      // 6) Save salary
      // Validate all required fields before creating Salary object
      if (worker.id == null || worker.id! <= 0) {
        Fluttertoast.showToast(msg: 'Invalid worker ID');
        return;
      }
      
      if (_selectedMonth.isEmpty) {
        Fluttertoast.showToast(msg: 'Please select a month');
        return;
      }
      
      if (presentDays < 0) {
        Fluttertoast.showToast(msg: 'Invalid present days count');
        return;
      }
      
      if (netSalary < 0) {
        Fluttertoast.showToast(msg: 'Invalid salary amount');
        return;
      }
      
      final salary = Salary(
        workerId: worker.id!,
        month: _selectedMonth,
        totalDays: presentDays,
        totalSalary: netSalary,
        paid: false,
      );

      final ok = await salaryProvider.addSalary(salary);

      if (ok) {
        Fluttertoast.showToast(msg: 'Salary calculated and saved!');
        await salaryProvider.loadSalaries();
      } else {
        Fluttertoast.showToast(msg: 'Failed to save salary. Try again.');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error calculating salary. Try again.');
      print('Error calculating salary: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // -------------- UI ----------------------

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final workers =
        userProvider.workers.where((u) => u.role == 'worker').toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Salary & Advance',
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF1E88E5),
              labelColor: const Color(0xFF1E88E5),
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Advance', icon: Icon(Icons.payments)),
                Tab(text: 'Salary', icon: Icon(Icons.account_balance_wallet)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AdvanceTab(
                  formKey: _advanceFormKey,
                  advanceAmountController: _advanceAmountController,
                  advanceDateController: _advanceDateController,
                  isLoading: _isLoading,
                  onPickDate: _pickAdvanceDate,
                  onSave: _addAdvance,
                  selectedWorkerId: _selectedAdvanceWorkerId,
                  onWorkerChanged: (id) =>
                      setState(() => _selectedAdvanceWorkerId = id),
                  workers: workers,
                ),
                _SalaryTab(
                  formKey: _salaryFormKey,
                  monthController: _salaryMonthController,
                  isLoading: _isLoading,
                  onPickMonth: _pickSalaryMonth,
                  onCalculateAndSave: _calculateAndSaveSalary,
                  selectedWorkerId: _selectedSalaryWorkerId,
                  onWorkerChanged: (id) =>
                      setState(() => _selectedSalaryWorkerId = id),
                  selectedMonth: _selectedMonth,
                  workers: workers,
                  formatCurrency: _formatCurrency,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// -------------------- ADVANCE TAB --------------------
class _AdvanceTab extends StatelessWidget {
  const _AdvanceTab({
    required this.formKey,
    required this.advanceAmountController,
    required this.advanceDateController,
    required this.isLoading,
    required this.onPickDate,
    required this.onSave,
    required this.selectedWorkerId,
    required this.onWorkerChanged,
    required this.workers,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController advanceAmountController;
  final TextEditingController advanceDateController;
  final bool isLoading;
  final VoidCallback onPickDate;
  final VoidCallback onSave;

  final String? selectedWorkerId;
  final ValueChanged<String?> onWorkerChanged;

  final List<User> workers;

  @override
  Widget build(BuildContext context) {
    final advanceProvider = Provider.of<AdvanceProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Compute simple summary for recent month (current month)
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final totalThisMonth = advanceProvider.advances
        .where((a) => a.date.startsWith(currentMonth))
        .fold<double>(0.0, (sum, a) => sum + (a.amount ?? 0));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SummaryRow(cards: [
            _SummaryCard(
              title: 'This Month Advances',
              value: '₹${totalThisMonth.toStringAsFixed(2)}',
              icon: Icons.payments,
              color: const Color(0xFFFFA726),
            ),
            _SummaryCard(
              title: 'Total Records',
              value: '${advanceProvider.advances.length}',
              icon: Icons.receipt_long,
              color: const Color(0xFF26A69A),
            ),
          ]),
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
            key: formKey,
            child: Column(
              children: [
                // Worker dropdown by ID
                DropdownButtonFormField<String>(
                  initialValue: selectedWorkerId,
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
                  onChanged: onWorkerChanged,
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
                  controller: advanceAmountController,
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
                  onTap: onPickDate,
                  child: AbsorbPointer(
                    child: CustomTextField(
                      controller: advanceDateController,
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
                  onPressed: onSave,
                  isLoading: isLoading,
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
                          child: const Text('₹', style: TextStyle(color: Colors.white)),
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
    );
  }
}

/// -------------------- SALARY TAB --------------------
class _SalaryTab extends StatelessWidget {
  const _SalaryTab({
    required this.formKey,
    required this.monthController,
    required this.isLoading,
    required this.onPickMonth,
    required this.onCalculateAndSave,
    required this.selectedWorkerId,
    required this.onWorkerChanged,
    required this.selectedMonth,
    required this.workers,
    required this.formatCurrency,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController monthController;
  final bool isLoading;
  final VoidCallback onPickMonth;
  final VoidCallback onCalculateAndSave;

  final String? selectedWorkerId;
  final ValueChanged<String?> onWorkerChanged;

  final String selectedMonth; // yyyy-MM
  final List<User> workers;

  final String Function(num) formatCurrency;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary row (current month snapshots)
          Consumer2<SalaryProvider, AdvanceProvider>(
            builder: (context, salaryProvider, advanceProvider, _) {
              final month = selectedMonth;
              final totalSalaries = salaryProvider.salaries
                  .where((s) => s.month == month)
                  .fold<double>(0.0, (sum, s) => sum + (s.totalSalary ?? 0));
              final totalAdvances = advanceProvider.advances
                  .where((a) => a.date.startsWith(month))
                  .fold<double>(0.0, (sum, a) => sum + (a.amount ?? 0));

              return _SummaryRow(cards: [
                _SummaryCard(
                  title: 'Month Salaries',
                  value: formatCurrency(totalSalaries),
                  icon: Icons.account_balance_wallet,
                  color: const Color(0xFF1E88E5),
                ),
                _SummaryCard(
                  title: 'Month Advances',
                  value: formatCurrency(totalAdvances),
                  icon: Icons.payments,
                  color: const Color(0xFF8E24AA),
                ),
              ]);
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Calculate Salary',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E88E5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Form(
            key: formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedWorkerId,
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
                  onChanged: onWorkerChanged,
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
                GestureDetector(
                  onTap: onPickMonth,
                  child: AbsorbPointer(
                    child: CustomTextField(
                      controller: monthController,
                      labelText: 'Month',
                      hintText: 'Select month (yyyy-MM)',
                      prefixIcon: Icons.calendar_month,
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Please select month'
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Calculate & Save Salary',
                  onPressed: onCalculateAndSave,
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Salary Records',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<SalaryProvider>(
              builder: (context, provider, _) {
                if (provider.state == ViewState.busy) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.salaries.isEmpty) {
                  return Center(
                    child: Text(
                      'No salary records found',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }

                final salaries = List<Salary>.from(provider.salaries)
                  ..sort((a, b) => b.month.compareTo(a.month));

                return ListView.separated(
                  itemCount: salaries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final s = salaries[index];
                    final worker = userProvider.workers.firstWhere(
                      (u) => u.id == s.workerId,
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
                          backgroundColor: const Color(0xFF1E88E5),
                          child: const Text('₹', style: TextStyle(color: Colors.white)),
                        ),
                        title: Text(worker.name,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${s.month} • ${s.totalDays} days',
                          style: GoogleFonts.poppins(),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${(s.totalSalary ?? 0).toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: s.paid == true
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFF44336),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                s.paid == true ? 'Paid' : 'Unpaid',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}

/// -------------------- Shared UI Widgets --------------------
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.cards});
  final List<_SummaryCard> cards;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: cards
          .map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: c)))
          .toList()
        ..last = Expanded(child: cards.last), // remove trailing right padding for last
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey[700])),
                  const SizedBox(height: 4),
                  Text(value,
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
    );
  }
}

/// -------------------- Custom Month-Year Picker --------------------
/// Returns a String in 'yyyy-MM' format on Navigator.pop
class _MonthYearPickerDialog extends StatefulWidget {
  const _MonthYearPickerDialog({
    required this.initialYear,
    required this.initialMonth,
  });

  final int initialYear;
  final int initialMonth;

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _year;
  late int _month;

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
    _month = widget.initialMonth;
  }

  void _selectMonth(int m) {
    setState(() => _month = m);
    final ym = '${_year.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}';
    Navigator.pop(context, ym);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Year selector row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Previous Year',
                    onPressed: () => setState(() => _year--),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    '$_year',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next Year',
                    onPressed: () => setState(() => _year++),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                itemCount: 12,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisExtent: 44,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (_, i) {
                  final m = i + 1;
                  final selected = m == _month;
                  return OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: selected ? const Color(0xFF1E88E5) : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor:
                          selected ? const Color(0xFF1E88E5).withOpacity(0.08) : null,
                    ),
                    onPressed: () => _selectMonth(m),
                    child: Text(
                      _months[i],
                      style: GoogleFonts.poppins(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? const Color(0xFF1E88E5) : null,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
