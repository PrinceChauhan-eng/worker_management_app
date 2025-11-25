import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:html' as html;
import 'dart:typed_data';

/// Generate a PDF salary slip for an individual worker
Future<void> generateSalarySlipPDF({
  required String workerName,
  required String month,
  required double wage,
  required int presentDays,
  required int absentDays,
  required double advance,
  required double salary,
  required String companyName,
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (pw.Context ctx) => pw.Column(
        children: [
          pw.Header(
            level: 1,
            child: pw.Text(
              'SALARY SLIP',
              style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Company: $companyName', style: pw.TextStyle(fontSize: 16)),
                  pw.Text('Month: $month', style: pw.TextStyle(fontSize: 16)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Date: ${DateTime.now().toString().split(' ')[0]}', style: pw.TextStyle(fontSize: 16)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Employee Details:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Name: $workerName', style: pw.TextStyle(fontSize: 16)),
                pw.Text('Employee ID: N/A', style: pw.TextStyle(fontSize: 16)),
                pw.Text('Department: General', style: pw.TextStyle(fontSize: 16)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray( // Updated to use TableHelper
            headers: ['Description', 'Details'],
            data: [
              ['Total Days', presentDays + absentDays],
              ['Present Days', presentDays],
              ['Absent Days', absentDays],
              ['Daily Wage', '₹${wage.toStringAsFixed(2)}'],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray( // Updated to use TableHelper
            headers: ['Earnings', 'Amount (₹)'],
            data: [
              ['Basic Pay', ((wage * presentDays).toStringAsFixed(2))],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray( // Updated to use TableHelper
            headers: ['Deductions', 'Amount (₹)'],
            data: [
              ['Advance Deducted', (advance.toStringAsFixed(2))],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 30),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('NET SALARY PAYABLE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text('₹${salary.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          pw.SizedBox(height: 40),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Text('Prepared By', style: pw.TextStyle(fontSize: 14)),
                  pw.SizedBox(height: 30),
                  pw.Text('----------------------', style: pw.TextStyle(fontSize: 14)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('Received By', style: pw.TextStyle(fontSize: 14)),
                  pw.SizedBox(height: 30),
                  pw.Text('----------------------', style: pw.TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );

  // Save and download the PDF
  final bytes = await pdf.save();
  _downloadFile(bytes, '$workerName-$month-salary-slip.pdf');
}

/// Generate a PDF monthly salary summary for all workers
Future<void> generateSalarySummaryPDF({
  required String month,
  required List<Map<String, dynamic>> salaryList,
  required String companyName,
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Header(
          level: 1,
          child: pw.Text(
            'MONTHLY SALARY SUMMARY',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Company: $companyName', style: pw.TextStyle(fontSize: 16)),
            pw.Text('Month: $month', style: pw.TextStyle(fontSize: 16)),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray( // Updated to use TableHelper
          headers: ['Sr.', 'Worker Name', 'Present', 'Absent', 'Basic Pay', 'Advance', 'Net Salary'],
          data: List.generate(salaryList.length, (index) {
            final item = salaryList[index];
            return [
              '${index + 1}',
              item['name'],
              item['present'].toString(),
              item['absent'].toString(),
              '₹${item['basicPay'].toStringAsFixed(2)}',
              '₹${item['advance'].toStringAsFixed(2)}',
              '₹${item['salary'].toStringAsFixed(2)}',
            ];
          }),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.centerLeft,
        ),
        pw.SizedBox(height: 30),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOTAL PAYABLE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                '₹${salaryList.fold<double>(0.0, (sum, item) => sum + (item['salary'] as double)).toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 10),
        child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}'),
      ),
    ),
  );

  // Save and download the PDF
  final bytes = await pdf.save();
  _downloadFile(bytes, 'salary-summary-$month.pdf');
}

/// Helper function to download PDF file in web environment
void _downloadFile(Uint8List bytes, String filename) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = filename;
  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}