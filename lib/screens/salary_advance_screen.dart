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
  
  // Advance form controllers
  final _advanceAmountController = TextEditingController();
  String _selectedAdvanceWorker = '';
  String _advanceDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  
  // Salary form controllers
  String _selectedSalaryWorker = '';
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.loadWorkers();
      final advanceProvider =
          Provider.of<AdvanceProvider>(context, listen: false);
      advanceProvider.loadAdvances();
      final salaryProvider =
          Provider.of<SalaryProvider>(context, listen: false);
      salaryProvider.loadSalaries();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _advanceAmountController.dispose();
    super.dispose();
  }

  _selectAdvanceDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _advanceDate = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  _selectSalaryMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateFormat('yyyy-MM').format(picked);
      });
    }
  }

  _addAdvance() async {
    if (_advanceFormKey.currentState!.validate()) {
      if (_selectedAdvanceWorker.isEmpty) {
        Fluttertoast.showToast(
          msg: 'Please select a worker',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final advanceProvider =
          Provider.of<AdvanceProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Get selected worker ID
      final worker = userProvider.workers.firstWhere(
          (user) => user.name == _selectedAdvanceWorker && user.role == 'worker');

      // Create advance object
      final advance = Advance(
        workerId: worker.id!,
        amount: double.parse(_advanceAmountController.text),
        date: _advanceDate,
      );

      // Add advance
      final success = await advanceProvider.addAdvance(advance);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        Fluttertoast.showToast(
          msg: 'Advance added successfully!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        // Clear form
        _advanceAmountController.clear();
        setState(() {
          _selectedAdvanceWorker = '';
        });
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to add advance. Please try again.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  _calculateAndSaveSalary() async {
    if (_selectedSalaryWorker.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please select a worker',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final advanceProvider =
        Provider.of<AdvanceProvider>(context, listen: false);
    final salaryProvider =
        Provider.of<SalaryProvider>(context, listen: false);
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);

    // Get selected worker
    final worker = userProvider.workers.firstWhere(
        (user) => user.name == _selectedSalaryWorker && user.role == 'worker');

    // Load worker's attendance for the selected month
    await attendanceProvider.loadAttendancesByWorkerId(worker.id!);
    final workerAttendances = attendanceProvider.attendances
        .where((att) =>
            att.date.startsWith(_selectedMonth) &&
            att.workerId == worker.id! &&
            att.present)
        .toList();

    // Calculate present days
    int presentDays = workerAttendances.length;

    // Calculate total wage
    double totalWage = presentDays * worker.wage;

    // Get total advances for this worker
    double totalAdvance = await advanceProvider.getTotalAdvanceByWorkerId(worker.id!);

    // Calculate net salary
    double netSalary = totalWage - totalAdvance;

    // Create salary object
    final salary = Salary(
      workerId: worker.id!,
      month: _selectedMonth,
      totalDays: presentDays,
      totalSalary: netSalary,
      paid: false,
    );

    // Save salary
    final success = await salaryProvider.addSalary(salary);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Fluttertoast.showToast(
        msg: 'Salary calculated and saved!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } else {
      Fluttertoast.showToast(
        msg: 'Failed to save salary. Please try again.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final workers = userProvider.workers
        .where((user) => user.role == 'worker')
        .toList();

    List<String> workerNames =
        workers.map((worker) => worker.name).toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Salary & Advance',
        onLeadingPressed: () {
          Navigator.pop(context);
        },
      ),
      body: Column(
        children: [
          // Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF1E88E5), // Royal Blue
            labelColor: const Color(0xFF1E88E5), // Royal Blue
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(
                text: 'Advance',
                icon: Icon(Icons.payments),
              ),
              Tab(
                text: 'Salary',
                icon: Icon(Icons.account_balance_wallet),
              ),
            ],
          ),
          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Advance Tab
                _buildAdvanceTab(context, workerNames),
                // Salary Tab
                _buildSalaryTab(context, workerNames),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvanceTab(BuildContext context, List<String> workerNames) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _advanceFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Advance',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E88E5), // Royal Blue
              ),
            ),
            const SizedBox(height: 20),
            // Worker Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedAdvanceWorker.isEmpty ? null : _selectedAdvanceWorker,
              hint: Text(
                'Select Worker',
                style: GoogleFonts.poppins(),
              ),
              items: workerNames.map((String workerName) {
                return DropdownMenuItem(
                  value: workerName,
                  child: Text(
                    workerName,
                    style: GoogleFonts.poppins(),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAdvanceWorker = value!;
                });
              },
              decoration: InputDecoration(
                labelText: 'Worker',
                labelStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a worker';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Amount Field
            CustomTextField(
              controller: _advanceAmountController,
              labelText: 'Amount',
              hintText: 'Enter advance amount',
              prefixIcon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Date Selector
            GestureDetector(
              onTap: () => _selectAdvanceDate(context),
              child: AbsorbPointer(
                child: CustomTextField(
                  labelText: 'Date',
                  hintText: 'Select date',
                  prefixIcon: Icons.calendar_today,
                  controller: TextEditingController(text: _advanceDate),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select date';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
            CustomButton(
              text: 'Add Advance',
              onPressed: _addAdvance,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 20),
            // Advances List
            Text(
              'Recent Advances',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Consumer<AdvanceProvider>(
                builder: (context, advanceProvider, child) {
                  if (advanceProvider.state == ViewState.busy) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (advanceProvider.advances.isEmpty) {
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

                  // Sort advances by date (newest first)
                  final advances = List<Advance>.from(advanceProvider.advances)
                    ..sort((a, b) => b.date.compareTo(a.date));

                  return ListView.builder(
                    itemCount: advances.length,
                    itemBuilder: (context, index) {
                      final advance = advances[index];
                      final worker = userProvider.workers.firstWhere(
                          (user) => user.id == advance.workerId,
                          orElse: () => User(
                              name: 'Unknown',
                              phone: '',
                              password: '',
                              role: '',
                              wage: 0,
                              joinDate: ''));
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFFFA726), // Orange
                            child: Text(
                              '₹',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            worker.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${advance.amount} on ${advance.date}',
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryTab(BuildContext context, List<String> workerNames) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _salaryFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calculate Salary',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E88E5), // Royal Blue
              ),
            ),
            const SizedBox(height: 20),
            // Worker Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedSalaryWorker.isEmpty ? null : _selectedSalaryWorker,
              hint: Text(
                'Select Worker',
                style: GoogleFonts.poppins(),
              ),
              items: workerNames.map((String workerName) {
                return DropdownMenuItem(
                  value: workerName,
                  child: Text(
                    workerName,
                    style: GoogleFonts.poppins(),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSalaryWorker = value!;
                });
              },
              decoration: InputDecoration(
                labelText: 'Worker',
                labelStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a worker';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Month Selector
            GestureDetector(
              onTap: () => _selectSalaryMonth(context),
              child: AbsorbPointer(
                child: CustomTextField(
                  labelText: 'Month',
                  hintText: 'Select month',
                  prefixIcon: Icons.calendar_today,
                  controller: TextEditingController(text: _selectedMonth),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select month';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
            CustomButton(
              text: 'Calculate & Save Salary',
              onPressed: _calculateAndSaveSalary,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 20),
            // Salaries List
            Text(
              'Salary Records',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Consumer<SalaryProvider>(
                builder: (context, salaryProvider, child) {
                  if (salaryProvider.state == ViewState.busy) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (salaryProvider.salaries.isEmpty) {
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

                  // Sort salaries by month (newest first)
                  final salaries = List<Salary>.from(salaryProvider.salaries)
                    ..sort((a, b) => b.month.compareTo(a.month));

                  return ListView.builder(
                    itemCount: salaries.length,
                    itemBuilder: (context, index) {
                      final salary = salaries[index];
                      final worker = userProvider.workers.firstWhere(
                          (user) => user.id == salary.workerId,
                          orElse: () => User(
                              name: 'Unknown',
                              phone: '',
                              password: '',
                              role: '',
                              wage: 0,
                              joinDate: ''));
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1E88E5), // Blue
                            child: Text(
                              '₹',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            worker.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${salary.month} - ${salary.totalDays} days',
                            style: GoogleFonts.poppins(),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${salary.totalSalary.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: salary.paid
                                      ? const Color(0xFF4CAF50) // Green
                                      : const Color(0xFFF44336), // Red
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  salary.paid ? 'Paid' : 'Unpaid',
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
      ),
    );
  }
}