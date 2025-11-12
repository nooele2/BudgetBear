import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  // Note: This color constant is not used in the PDF generation
  // PDF uses PdfColor.fromHex('#47A8A5') directly

  /// Generate PDF report for expense data
  static Future<void> generateExpensePDF({
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> data,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(startDate, endDate),
          pw.SizedBox(height: 20),
          _buildSummarySection(data),
          pw.SizedBox(height: 24),
          _buildCategorySection(data['categories']),
          pw.SizedBox(height: 24),
          _buildTransactionsSection(data['dailyTransactions']),
        ],
        footer: (context) => _buildFooter(),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'expense_summary_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.pdf',
    );
  }

  /// Build PDF header
  static pw.Widget _buildHeader(DateTime startDate, DateTime endDate) {
    return pw.Header(
      level: 0,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Budget Bear',
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#47A8A5'),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Expense Summary Report',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}',
            style: const pw.TextStyle(
              fontSize: 14,
              color: PdfColors.grey700,
            ),
          ),
          pw.Divider(thickness: 2),
        ],
      ),
    );
  }

  /// Build summary section
  static pw.Widget _buildSummarySection(Map<String, dynamic> data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F7FA'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryItem('Total Income', data['totalIncome'], true),
          _buildSummaryItem('Total Expenses', data['totalExpenses'], false),
          _buildSummaryItem(
              'Net Savings', data['netSavings'], data['netSavings'] >= 0),
        ],
      ),
    );
  }

  /// Build individual summary item
  static pw.Widget _buildSummaryItem(String label, double amount, bool isPositive) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '\$${amount.toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: isPositive ? PdfColors.green : PdfColors.red,
          ),
        ),
      ],
    );
  }

  /// Build category breakdown section
  static pw.Widget _buildCategorySection(Map<String, double> categories) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Expense Breakdown by Category',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        _buildCategoryTable(categories),
      ],
    );
  }

  /// Build category table
  static pw.Widget _buildCategoryTable(Map<String, double> categories) {
    if (categories.isEmpty) {
      return pw.Text('No expense data available');
    }

    return pw.Table.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#47A8A5'),
      ),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      headers: ['Category', 'Amount', 'Percentage'],
      data: categories.entries.map((entry) {
        final total = categories.values.fold(0.0, (sum, val) => sum + val);
        final percentage = (entry.value / total * 100).toStringAsFixed(1);
        return [
          entry.key,
          '\$${entry.value.toStringAsFixed(2)}',
          '$percentage%',
        ];
      }).toList(),
    );
  }

  /// Build transactions section
  static pw.Widget _buildTransactionsSection(
      List<Map<String, dynamic>> transactions) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Daily Transactions',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        _buildTransactionsTable(transactions),
      ],
    );
  }

  /// Build transactions table
  static pw.Widget _buildTransactionsTable(
      List<Map<String, dynamic>> transactions) {
    if (transactions.isEmpty) {
      return pw.Text('No transactions available');
    }

    return pw.Table.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#47A8A5'),
      ),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      cellHeight: 35,
      headers: ['Date', 'Category', 'Description', 'Type', 'Amount'],
      data: transactions.map((tx) {
        return [
          tx['date'],
          tx['category'],
          tx['note'].isEmpty ? '-' : tx['note'],
          tx['type'] == 'expense' ? 'Expense' : 'Income',
          '\$${tx['amount'].toStringAsFixed(2)}',
        ];
      }).toList(),
    );
  }

  /// Build footer
  static pw.Widget _buildFooter() {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 16),
      child: pw.Text(
        'Generated on ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
        style: const pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey600,
        ),
      ),
    );
  }
}