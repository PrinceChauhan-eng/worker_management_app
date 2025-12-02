import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/user_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/advance_provider.dart';
import '../providers/salary_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../models/user.dart';
import '../models/attendance.dart';
import '../models/advance.dart';
import '../models/salary.dart';
import '../utils/export_utils.dart';
import '../utils/pdf_generator.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  String? _selectedWorkerId;
  String _selectedReportType = 'attendance'; // attendance, salary, advance
  List<List<dynamic>> _currentReportData = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final advanceProvider = Provider.of<AdvanceProvider>(context, listen: false);
    final salaryProvider = Provider.of<SalaryProvider>(context, listen: false);

    await userProvider.loadWorkers();
    await attendanceProvider.loadAttendances();
    await advanceProvider.loadAdvances();
    await salaryProvider.loadSalaries();
    
    // Load initial report data
    _loadReportData();
  }

  void _loadReportData() {
    setState(() {
      switch (_selectedReportType) {
        case 'attendance':
          _loadAttendanceData();
          break;
        case 'salary':
          _loadSalaryData();
          break;
        case 'advance':
          _loadAdvanceData();
          break;
        default:
          _loadAttendanceData();
      }
    });
  }

  void _loadAttendanceData() {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    List<Attendance> attendances = attendanceProvider.attendances
        .where((att) => att.date.startsWith(_selectedMonth))
        .toList();
    
    // Filter by worker if selected
    if (_selectedWorkerId != null) {
      attendances = attendances.where((att) => att.workerId.toString() == _selectedWorkerId).toList();
    }
    
    // Sort by date
    attendances.sort((a, b) => a.date.compareTo(b.date));
    
    // Prepare data for table
    _currentReportData = [
      ['Worker Name', 'Date', 'In Time', 'Out Time', 'Status']
    ];
    
    for (var attendance in attendances) {
      final worker = userProvider.workers.firstWhere(
        (w) => w.id == attendance.workerId,
        orElse: () => User(name: 'Unknown', phone: '', password: '', role: 'worker', wage: 0, joinDate: ''),
      );
      
      String status = 'Absent';
      if (attendance.present) {
        status = attendance.outTime.isEmpty ? 'Logged In' : 'Present';
      }
      
      _currentReportData.add([
        worker.name,
        attendance.date,
        attendance.inTime.isEmpty ? '--' : attendance.inTime,
        attendance.outTime.isEmpty ? '--' : attendance.outTime,
        status,
      ]);
    }
  }

  void _loadSalaryData() {
    final salaryProvider = Provider.of<SalaryProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    List<Salary> salaries = salaryProvider.salaries
        .where((sal) => sal.month == _selectedMonth)
        .toList();
    
    // Filter by worker if selected
    if (_selectedWorkerId != null) {
      salaries = salaries.where((sal) => sal.workerId.toString() == _selectedWorkerId).toList();
    }
    
    // Sort by worker name
    salaries.sort((a, b) {
      final workerA = userProvider.workers.firstWhere(
        (w) => w.id == a.workerId,
        orElse: () => User(name: 'Unknown', phone: '', password: '', role: 'worker', wage: 0, joinDate: ''),
      );
      final workerB = userProvider.workers.firstWhere(
        (w) => w.id == b.workerId,
        orElse: () => User(name: 'Unknown', phone: '', password: '', role: 'worker', wage: 0, joinDate: ''),
      );
      return workerA.name.compareTo(workerB.name);
    });
    
    // Prepare data for table
    _currentReportData = [
      ['Worker Name', 'Month', 'Total Days', 'Gross Salary', 'Advance', 'Net Salary', 'Status']
    ];
    
    for (var salary in salaries) {
      final worker = userProvider.workers.firstWhere(
        (w) => w.id == salary.workerId,
        orElse: () => User(name: 'Unknown', phone: '', password: '', role: 'worker', wage: 0, joinDate: ''),
      );
      
      _currentReportData.add([
        worker.name,
        salary.month,
        salary.totalDays.toString(),
        '₹${(salary.grossSalary ?? 0.0).toStringAsFixed(2)}',
        '₹${(salary.totalAdvance ?? 0.0).toStringAsFixed(2)}',
        '₹${(salary.netSalary ?? 0.0).toStringAsFixed(2)}',
        salary.paid ? 'Paid' : 'Pending',
      ]);
    }
  }

  void _loadAdvanceData() {
    final advanceProvider = Provider.of<AdvanceProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    List<Advance> advances = advanceProvider.advances
        .where((adv) => adv.date.startsWith(_selectedMonth))
        .toList();
    
    // Filter by worker if selected
    if (_selectedWorkerId != null) {
      advances = advances.where((adv) => adv.workerId.toString() == _selectedWorkerId).toList();
    }
    
    // Sort by date
    advances.sort((a, b) => a.date.compareTo(b.date));
    
    // Prepare data for table
    _currentReportData = [
      ['Worker Name', 'Date', 'Amount', 'Purpose', 'Status']
    ];
    
    for (var advance in advances) {
      final worker = userProvider.workers.firstWhere(
        (w) => w.id == advance.workerId,
        orElse: () => User(name: 'Unknown', phone: '', password: '', role: 'worker', wage: 0, joinDate: ''),
      );
      
      _currentReportData.add([
        worker.name,
        advance.date,
        '₹${advance.amount.toStringAsFixed(2)}',
        advance.purpose ?? 'N/A',
        advance.status,
      ]);
    }
  }

  Future<void> _selectMonth(BuildContext context) async {
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
        _loadReportData();
      });
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final fileName = '${_selectedReportType}_report_$_selectedMonth';
      await ExportUtils.exportToCSV(_currentReportData, fileName);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedReportType.toUpperCase()} report exported to CSV successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error exporting to CSV: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToExcel() async {
    try {
      final fileName = '${_selectedReportType}_report_$_selectedMonth';
      
      // For Excel, we'll create one sheet with the current report data
      List<List<List<dynamic>>> sheetsData = [_currentReportData];
      List<String> sheetNames = [_selectedReportType.toUpperCase()];
      
      await ExportUtils.exportToExcel(sheetsData, sheetNames, fileName);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedReportType.toUpperCase()} report exported to Excel successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error exporting to Excel: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportSalaryPDF() async {
    try {
      if (_selectedReportType != 'salary') return;
      
      final salaryProvider = Provider.of<SalaryProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      List<Salary> salaries = salaryProvider.salaries
          .where((sal) => sal.month == _selectedMonth)
          .toList();
      
      // Filter by worker if selected
      if (_selectedWorkerId != null) {
        salaries = salaries.where((sal) => sal.workerId.toString() == _selectedWorkerId).toList();
      }
      
      // For individual salary slip
      if (_selectedWorkerId != null && salaries.isNotEmpty) {
        final salary = salaries.first;
        final worker = userProvider.workers.firstWhere(
          (w) => w.id == salary.workerId,
          orElse: () => User(name: 'Unknown', phone: '', password: '', role: 'worker', wage: 0, joinDate: ''),
        );
        
        await generateSalarySlipPDF(
          workerName: worker.name,
          month: _selectedMonth,
          wage: worker.wage ?? 0.0,
          presentDays: salary.presentDays ?? 0,
          absentDays: salary.absentDays ?? 0,
          advance: salary.totalAdvance ?? 0.0,
          salary: salary.netSalary ?? 0.0,
          companyName: 'Worker Management System',
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Salary slip PDF generated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } 
      // For monthly summary
      else {
        // Prepare data for summary
        final summaryData = <Map<String, dynamic>>[];
        for (var salary in salaries) {
          final worker = userProvider.workers.firstWhere(
            (w) => w.id == salary.workerId,
            orElse: () => User(name: 'Unknown', phone: '', password: '', role: 'worker', wage: 0, joinDate: ''),
          );
          
          summaryData.add({
            'name': worker.name,
            'present': salary.presentDays ?? 0,
            'absent': salary.absentDays ?? 0,
            'basicPay': (worker.wage ?? 0.0) * (salary.presentDays ?? 0),
            'advance': salary.totalAdvance ?? 0.0,
            'salary': salary.netSalary ?? 0.0,
          });
        }
        
        await generateSalarySummaryPDF(
          month: _selectedMonth,
          salaryList: summaryData,
          companyName: 'Worker Management System',
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Monthly salary summary PDF generated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error generating PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Reports & Analytics',
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
              'Reports & Analytics',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E88E5),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'View detailed reports and analytics',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            
            // Summary Box
            Consumer3<AttendanceProvider, SalaryProvider, AdvanceProvider>(
              builder: (context, attendanceProvider, salaryProvider, advanceProvider, _) {
                // Calculate summary data
                final attendances = attendanceProvider.attendances
                    .where((att) => att.date.startsWith(_selectedMonth))
                    .toList();
                
                // Filter by worker if selected
                List<Attendance> filteredAttendances = attendances;
                List<Salary> filteredSalaries = salaryProvider.salaries
                    .where((sal) => sal.month == _selectedMonth)
                    .toList();
                List<Advance> filteredAdvances = advanceProvider.advances
                    .where((adv) => adv.date.startsWith(_selectedMonth))
                    .toList();
                
                if (_selectedWorkerId != null) {
                  filteredAttendances = filteredAttendances
                      .where((att) => att.workerId.toString() == _selectedWorkerId)
                      .toList();
                  filteredSalaries = filteredSalaries
                      .where((sal) => sal.workerId.toString() == _selectedWorkerId)
                      .toList();
                  filteredAdvances = filteredAdvances
                      .where((adv) => adv.workerId.toString() == _selectedWorkerId)
                      .toList();
                }
                
                final totalDays = filteredAttendances.length;
                final presentDays = filteredAttendances.where((att) => att.present).length;
                final absentDays = totalDays - presentDays;
                final totalSalaryPaid = filteredSalaries
                    .where((sal) => sal.paid)
                    .fold<double>(0.0, (sum, sal) => sum + (sal.netSalary ?? 0.0));
                final totalAdvanceUsed = filteredAdvances
                    .fold<double>(0.0, (sum, adv) => sum + (adv.amount ?? 0.0));
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD), // Light blue background
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total Workers: $totalDays", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      Text("Present: $presentDays", style: GoogleFonts.poppins()),
                      Text("Absent: $absentDays", style: GoogleFonts.poppins()),
                      Text("Total Salary: ₹${totalSalaryPaid.toStringAsFixed(2)}", style: GoogleFonts.poppins()),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            
            // Filters Section
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // Updated to consistent radius
              ),
              elevation: 3, // Updated elevation
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filters',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        // Month Selector
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () => _selectMonth(context),
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E88E5),
                                borderRadius: BorderRadius.circular(12), // Updated to consistent radius
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.calendar_month, // Filled icon
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _selectedMonth,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Worker Filter
                        Expanded(
                          flex: 1,
                          child: Consumer<UserProvider>(
                            builder: (context, userProvider, _) {
                              final workers = userProvider.workers
                                  .where((u) => u.role == 'worker')
                                  .toList();
                              
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12), // Updated to consistent radius
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String?>(
                                    isExpanded: true,
                                    hint: Row(
                                      children: [
                                        const Icon(
                                          Icons.person, // Filled icon
                                          size: 20,
                                          color: Color(0xFF1E88E5),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'All Workers',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    value: _selectedWorkerId,
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.people, // Filled icon
                                              size: 20,
                                              color: Color(0xFF1E88E5),
                                            ),
                                            SizedBox(width: 10),
                                            Text('All Workers'),
                                          ],
                                        ),
                                      ),
                                      ...workers.map((worker) {
                                        return DropdownMenuItem(
                                          value: worker.id.toString(),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.person, // Filled icon
                                                size: 20,
                                                color: Color(0xFF1E88E5),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(worker.name),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                    onChanged: (String? value) {
                                      setState(() {
                                        _selectedWorkerId = value;
                                        _loadReportData();
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Report Type Selector
                    Text(
                      'Report Type',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ChoiceChip(
                            label: Text('Attendance', style: GoogleFonts.poppins()),
                            selected: _selectedReportType == 'attendance',
                            selectedColor: const Color(0xFF1E88E5),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedReportType = 'attendance';
                                  _loadReportData();
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 10),
                          ChoiceChip(
                            label: Text('Salary', style: GoogleFonts.poppins()),
                            selected: _selectedReportType == 'salary',
                            selectedColor: const Color(0xFF1E88E5),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedReportType = 'salary';
                                  _loadReportData();
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 10),
                          ChoiceChip(
                            label: Text('Advance', style: GoogleFonts.poppins()),
                            selected: _selectedReportType == 'advance',
                            selectedColor: const Color(0xFF1E88E5),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedReportType = 'advance';
                                  _loadReportData();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Report Table
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16), // Updated to consistent radius
                ),
                elevation: 3, // Updated elevation
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selectedReportType.toUpperCase()} Report',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Month: $_selectedMonth',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: _currentReportData.length > 1
                            ? SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 20,
                                  headingRowColor: WidgetStateColor.resolveWith(
                                    (states) => const Color(0xFFE3F2FD).withOpacity(0.5), // Light blue/grey background
                                  ),
                                  columns: _currentReportData[0]
                                      .map((column) => DataColumn(
                                            label: Text(
                                              column.toString(),
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14, // Minimum size 14
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                  rows: _currentReportData
                                      .skip(1)
                                      .map((row) => DataRow(
                                            cells: row
                                                .map((cell) => DataCell(
                                                      Text(
                                                        cell.toString(),
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 14, // Minimum size 14
                                                        ),
                                                      ),
                                                    ))
                                                .toList(),
                                          ))
                                      .toList(),
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inbox, // Filled icon (changed from outlined)
                                      size: 60,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 15),
                                    Text(
                                      'No data available for selected filters',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      // Export Buttons - Full width primary buttons
                      if (_selectedReportType == 'salary') ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _currentReportData.length > 1 ? _exportSalaryPDF : null,
                            icon: const Icon(Icons.picture_as_pdf), // Filled icon
                            label: const Text("Download Salary PDF"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF44336), // Red color for PDF
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12), // Updated to consistent radius
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _currentReportData.length > 1 ? _exportToCSV : null,
                          icon: const Icon(Icons.download), // Filled icon
                          label: const Text("Download CSV"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50), // Green color for CSV
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), // Updated to consistent radius
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _currentReportData.length > 1 ? _exportToExcel : null,
                          icon: const Icon(Icons.file_open), // Filled icon
                          label: const Text("Download Excel"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3), // Blue color for Excel
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), // Updated to consistent radius
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 30,
          color: const Color(0xFF1E88E5),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E88E5),
          ),
        ),
      ],
    );
  }
}