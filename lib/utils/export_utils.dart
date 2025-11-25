import 'dart:html' as html;
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

class ExportUtils {
  /// Export data to CSV format and trigger download
  static Future<void> exportToCSV(List<List<dynamic>> data, String fileName) async {
    try {
      // Convert data to CSV format
      String csv = const ListToCsvConverter().convert(data);
      
      // Create and trigger download
      final bytes = csv.codeUnits;
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = '$fileName.csv';
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print('Error exporting to CSV: $e');
      rethrow;
    }
  }

  /// Export data to Excel format and trigger download
  static Future<void> exportToExcel(List<List<List<dynamic>>> sheetsData, List<String> sheetNames, String fileName) async {
    try {
      // Create Excel workbook
      final excel = Excel.createExcel();
      
      // Add data to sheets
      for (int i = 0; i < sheetsData.length; i++) {
        final sheetName = sheetNames.length > i ? sheetNames[i] : 'Sheet${i + 1}';
        final sheet = excel[sheetName];
        
        // Add data rows
        for (var row in sheetsData[i]) {
          sheet.appendRow(row);
        }
      }
      
      // Save and trigger download
      final bytes = excel.save();
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = '$fileName.xlsx';
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
      
      // No need to close workbook in web environment
    } catch (e) {
      print('Error exporting to Excel: $e');
      rethrow;
    }
  }
}