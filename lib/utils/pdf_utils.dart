import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import '../models/salary.dart';
import '../models/user.dart';

class PdfUtils {
  static Future<pw.Document> generateSalarySlipPdf(Salary salary, User worker, List<dynamic> advances) async {
    final pdf = pw.Document();
    
    final totalAdvance = advances.fold<double>(
      0.0,
      (sum, adv) => sum + (adv['amount'] as double? ?? 0.0),
    );

    final netSalary = salary.netSalary ?? salary.totalSalary;
    final grossSalary = salary.grossSalary ?? (worker.wage * (salary.presentDays ?? 0));

    pdf.addPage(
      pw.Page(
        build: (context) {
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
                        'Worker: ${worker.name}',
                        style: pw.TextStyle(fontSize: 16),
                      ),
                      pw.Text(
                        'Worker ID: ${worker.id}',
                        style: pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        'Month: ${salary.month} ${salary.year}',
                        style: pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (salary.paidDate != null)
                        pw.Text(
                          'Paid Date: ${DateFormat('dd MMM yyyy').format(DateTime.parse(salary.paidDate!))}',
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
                  ['Present Days', '${salary.presentDays ?? 0}'],
                  ['Daily Wage', '₹${worker.wage.toStringAsFixed(2)}'],
                  ['Gross Salary', '₹${grossSalary.toStringAsFixed(2)}'],
                  if (advances.isNotEmpty) ...[
                    ...advances.map((adv) => [
                          adv['purpose'] ?? 'Advance',
                          '₹${(adv['amount'] as double?)?.toStringAsFixed(2) ?? '0.00'}'
                        ]),
                  ],
                  ['Total Advances', '₹${totalAdvance.toStringAsFixed(2)}'],
                  [
                    pw.Text('Net Salary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      '₹${netSalary.toStringAsFixed(2)}',
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
              if (salary.paidDate != null)
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.green),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Text(
                    'PAID',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green,
                    ),
                  ),
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