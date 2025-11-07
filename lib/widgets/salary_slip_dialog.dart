import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/salary.dart';
import '../models/user.dart';
import '../models/advance.dart';

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

    return AlertDialog(
      title: Text(
        'Salary Slip',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Close',
            style: GoogleFonts.poppins(),
          ),
        ),
        TextButton(
          onPressed: _sendSalarySlip,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.send, size: 18),
              const SizedBox(width: 5),
              Text(
                'Send',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: _downloadSalarySlip,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.download, size: 18, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                'Download',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
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
*Present Days:* ${widget.salary.presentDays ?? 0}/${widget.salary.totalDays ?? 0}
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
              pw.Table.fromTextArray(
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
}