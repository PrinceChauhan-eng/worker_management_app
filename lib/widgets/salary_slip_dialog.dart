import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../models/salary.dart';
import '../models/user.dart';
import '../models/advance.dart';
import '../models/notification.dart';
import '../providers/salary_provider.dart';
import '../providers/notification_provider.dart';

class SalarySlipDialog extends StatefulWidget {
  final Salary salary;
  final User worker;
  final List<Advance> advances;

  const SalarySlipDialog({
    super.key,
    required this.salary,
    required this.worker,
    required this.advances,
  });

  @override
  State<SalarySlipDialog> createState() => _SalarySlipDialogState();
}

class _SalarySlipDialogState extends State<SalarySlipDialog> {
  final pdf = pw.Document();

  @override
  Widget build(BuildContext context) {
    final totalAdvance = widget.advances.fold<double>(
      0.0,
      (sum, adv) => sum + adv.amount,
    );

    return DraggableScrollableSheet(
      expand: true,
      initialChildSize: 0.95, // Increased from 0.9 to 0.95 for better visibility
      minChildSize: 0.5,
      maxChildSize: 1.0, // Increased from 0.95 to 1.0 for full screen capability
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with drag handle
                Center(
                  child: Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                
                // Title and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Salary Slip',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Worker Info
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.worker.name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Worker ID: ${widget.worker.id}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Phone: ${widget.worker.phone}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Salary Info
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Month',
                        widget.salary.month,
                        Icons.calendar_month,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInfoCard(
                        'Present Days',
                        '${widget.salary.presentDays ?? 0}',
                        Icons.check_circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Daily Wage',
                        '₹${widget.worker.wage.toStringAsFixed(2)}',
                        Icons.account_balance,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInfoCard(
                        'Status',
                        widget.salary.paid ? 'Paid' : 'Unpaid',
                        widget.salary.paid ? Icons.check_circle : Icons.pending,
                        color: widget.salary.paid ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Salary Breakdown',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                _buildBreakdownItem(
                  'Gross Salary',
                  '₹${widget.salary.grossSalary?.toStringAsFixed(2) ?? ((widget.worker.wage) * (widget.salary.presentDays ?? 0)).toStringAsFixed(2)}',
                  Icons.calculate,
                ),
                const Divider(),
                if (widget.advances.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Advances Taken',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...widget.advances.map((advance) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    advance.purpose ?? 'Advance',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                Text(
                                  '₹${advance.amount.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                            if (advance.note != null && advance.note!.isNotEmpty)
                              Text(
                                advance.note!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            Text(
                              DateFormat('dd MMM yyyy').format(DateTime.parse(advance.date)),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )),
                  const Divider(),
                ],
                _buildBreakdownItem(
                  'Total Advances',
                  '₹${totalAdvance.toStringAsFixed(2)}',
                  Icons.payments,
                  isBold: true,
                  valueColor: Colors.red,
                ),
                const Divider(),
                _buildBreakdownItem(
                  'Net Salary',
                  '₹${widget.salary.netSalary?.toStringAsFixed(2) ?? widget.salary.totalSalary.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  isBold: true,
                  valueColor: const Color(0xFF4CAF50),
                ),
                const SizedBox(height: 20),
                if (widget.salary.paidDate != null)
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF4CAF50),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Paid on ${DateFormat('dd MMM yyyy').format(DateTime.parse(widget.salary.paidDate!))}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 30),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (!widget.salary.paid) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _markAsPaid,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle, size: 18, color: Colors.white),
                          label: Text(
                            'Mark Paid',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _sendSalarySlip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.send, size: 18, color: Colors.white),
                        label: Text(
                          'Send',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _downloadSalarySlip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.download, size: 18, color: Colors.white),
                        label: Text(
                          'Download',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color ?? const Color(0xFF1E88E5),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(
    String label,
    String value,
    IconData icon, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF1E88E5),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[700],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Future<void> _sendSalarySlip() async {
    // Show options for sending
    final selectedOption = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Send Salary Slip',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'How would you like to send the salary slip to ${widget.worker.name}?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'whatsapp'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.message, size: 18),
                const SizedBox(width: 5),
                Text(
                  'WhatsApp',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'email'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.email, size: 18),
                const SizedBox(width: 5),
                Text(
                  'Email',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (selectedOption == null) return;

    if (selectedOption == 'whatsapp') {
      _sendViaWhatsApp();
    } else if (selectedOption == 'email') {
      _sendViaEmail();
    }
  }

  Future<void> _sendViaWhatsApp() async {
    try {
      // Create a message with salary details
      final totalAdvance = widget.advances.fold<double>(
        0.0,
        (sum, adv) => sum + adv.amount,
      );
      
      final message = '''
*Salary Slip*
=================
*Worker:* ${widget.worker.name}
*Month:* ${widget.salary.month} ${widget.salary.year}
*Present Days:* ${widget.salary.presentDays}/${widget.salary.totalDays}
*Daily Wage:* ₹${widget.worker.wage.toStringAsFixed(2)}
*Gross Salary:* ₹${widget.salary.grossSalary?.toStringAsFixed(2) ?? '0.00'}
*Total Advances:* ₹${totalAdvance.toStringAsFixed(2)}
*Net Salary:* ₹${widget.salary.netSalary?.toStringAsFixed(2) ?? widget.salary.totalSalary.toStringAsFixed(2)}
*Status:* ${widget.salary.paid ? 'Paid' : 'Unpaid'}
${widget.salary.paidDate != null ? '*Paid Date:* ${DateFormat('dd MMM yyyy').format(DateTime.parse(widget.salary.paidDate!))}' : ''}
      ''';

      // Show the message in a dialog and provide instructions
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Send via WhatsApp',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To send the salary slip to ${widget.worker.name}, copy the message below and send it via WhatsApp to ${widget.worker.phone}:',
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText(
                    message,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Note: In a production environment, this would automatically open WhatsApp with the message pre-filled.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        );
        
        // Check if context is still mounted before using it
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Message prepared for WhatsApp. Copy and send manually.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to prepare WhatsApp message: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendViaEmail() async {
    try {
      // In a real implementation, you would send the actual PDF via email
      // For now, we'll show a success message
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Email functionality would be implemented here',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      // Check if context is still mounted before using it
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send via Email: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadSalarySlip() async {
    try {
      // Generate PDF
      final pdf = await _generateSalarySlipPdf();
      
      // Save or share the PDF
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );
      
      // Check if context is still mounted before using it
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Salary slip downloaded successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Check if context is still mounted before using it
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to download salary slip: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<pw.Document> _generateSalarySlipPdf() async {
    final pdf = pw.Document();
    
    final totalAdvance = widget.advances.fold<double>(
      0.0,
      (sum, adv) => sum + adv.amount,
    );

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'SALARY SLIP',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Worker: ${widget.worker.name}',
                        style: pw.TextStyle(fontSize: 16),
                      ),
                      pw.Text(
                        'Worker ID: ${widget.worker.id}',
                        style: pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        'Phone: ${widget.worker.phone}',
                        style: pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Month: ${widget.salary.month} ${widget.salary.year}',
                        style: pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        'Paid Date: ${widget.salary.paidDate != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(widget.salary.paidDate!)) : 'N/A'}',
                        style: pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.TableHelper.fromTextArray(
                headers: ['Description', 'Amount'],
                data: [
                  ['Gross Salary', '₹${widget.salary.grossSalary?.toStringAsFixed(2) ?? '0.00'}'],
                  if (widget.advances.isNotEmpty) ...[
                    ...widget.advances.map((adv) => [
                          adv.purpose ?? 'Advance',
                          '₹${adv.amount.toStringAsFixed(2)}'
                        ]),
                  ],
                  ['Total Advances', '₹${totalAdvance.toStringAsFixed(2)}'],
                  [
                    pw.Text('Net Salary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      '₹${widget.salary.netSalary?.toStringAsFixed(2) ?? widget.salary.totalSalary.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    )
                  ],
                ],
                border: null,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
                cellAlignment: pw.Alignment.centerRight,
                cellStyle: pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'This is a computer generated salary slip and does not require signature.',
                style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<void> _markAsPaid() async {
    // Close the dialog first
    Navigator.pop(context);
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Mark Salary as Paid',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to mark this salary as paid and send a notification to ${widget.worker.name}?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: Text(
              'Mark Paid',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    
    // Check if context is still mounted before proceeding
    if (confirmed == true && context.mounted) {
      try {
        // Update the salary in the database
        final salaryProvider = Provider.of<SalaryProvider>(
          context,
          listen: false,
        );
        
        final updatedSalary = Salary(
          id: widget.salary.id,
          workerId: widget.salary.workerId,
          month: widget.salary.month,
          year: widget.salary.year,
          totalDays: widget.salary.totalDays,
          presentDays: widget.salary.presentDays,
          absentDays: widget.salary.absentDays,
          grossSalary: widget.salary.grossSalary,
          totalAdvance: widget.salary.totalAdvance,
          netSalary: widget.salary.netSalary,
          totalSalary: widget.salary.totalSalary,
          paid: true,
          paidDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        );
        
        await salaryProvider.updateSalary(updatedSalary);
        
        // Send notification to worker
        // Get the context again to ensure it's still mounted
        if (context.mounted) {
          final notificationProvider = Provider.of<NotificationProvider>(
            context,
            listen: false,
          );
          
          final notification = NotificationModel(
            title: 'Salary Paid',
            message: 'Your salary for ${widget.salary.month} has been paid.',
            type: 'salary',
            userId: widget.worker.id!,
            userRole: 'worker',
            isRead: false,
            createdAt: DateTime.now().toIso8601String(),
          );
          
          await notificationProvider.addNotification(notification);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Salary marked as paid and notification sent to worker!',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: const Color(0xFF4CAF50),
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error marking salary as paid: $e',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}