import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  // SendGrid Configuration
  static String get _sendGridApiKey => dotenv.env['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'] ?? '';
  static String get _senderEmail => dotenv.env['budgetbear77@gmail.com'] ?? '';
  static const String _senderName = 'Budget Bear';

  /// Validates email configuration
  static bool isConfigured() {
    final configured = _sendGridApiKey.isNotEmpty && _senderEmail.isNotEmpty;
    if (!configured) {
      print('⚠️ Email not configured:');
      print('  - API Key: ${_sendGridApiKey.isEmpty ? "MISSING" : "SET (${_sendGridApiKey.length} chars)"}');
      print('  - Sender Email: ${_senderEmail.isEmpty ? "MISSING" : _senderEmail}');
    }
    return configured;
  }

  /// Sends an expense summary email using SendGrid
  static Future<bool> sendExpenseSummaryEmail({
    required String recipientEmail,
    required String recipientName,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> summaryData,
  }) async {
    try {
      // DEBUG: Print environment variables
      print('🔍 DEBUG: Checking environment variables...');
      print('API Key exists: ${dotenv.env['SENDGRID_API_KEY']?.isNotEmpty ?? false}');
      if (dotenv.env['SENDGRID_API_KEY'] != null && dotenv.env['SENDGRID_API_KEY']!.length >= 10) {
        print('API Key first 10 chars: ${dotenv.env['SENDGRID_API_KEY']!.substring(0, 10)}');
      }
      print('Sender Email: ${dotenv.env['SENDER_EMAIL']}');
      print('Is Configured: ${isConfigured()}');
      
      if (!isConfigured()) {
        print('❌ Email service not configured!');
        return false;
      }

      // Build email HTML content
      final emailHtml = _buildEmailHtml(
        recipientName,
        startDate,
        endDate,
        summaryData,
      );

      // SendGrid API endpoint
      final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');

      // Prepare email payload
      final payload = {
        'personalizations': [
          {
            'to': [
              {'email': recipientEmail, 'name': recipientName}
            ],
            'subject': 'Budget Bear - Expense Summary (${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)})'
          }
        ],
        'from': {'email': _senderEmail, 'name': _senderName},
        'content': [
          {'type': 'text/html', 'value': emailHtml}
        ]
      };

      print('📤 Sending email to: $recipientEmail');
      print('From: $_senderEmail');

      // Send request to SendGrid
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_sendGridApiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 202) {
        print('✅ Email sent successfully via SendGrid');
        return true;
      } else {
        print('❌ Failed to send email. Status: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending email: $e');
      return false;
    }
  }

  /// Builds the HTML content for the expense summary email
  static String _buildEmailHtml(
    String name,
    DateTime startDate,
    DateTime endDate,
    Map<String, dynamic> data,
  ) {
    final totalIncome = (data['totalIncome'] ?? 0.0) as double;
    final totalExpenses = (data['totalExpenses'] ?? 0.0) as double;
    final netSavings = (data['netSavings'] ?? 0.0) as double;
    final categories = (data['categories'] ?? {}) as Map<String, double>;
    final dailyTransactions = (data['dailyTransactions'] ?? []) as List<Map<String, dynamic>>;

    // Build category rows
    final categoryRows = categories.entries.map((entry) {
      final total = categories.values.fold(0.0, (sum, val) => sum + val);
      final percentage = total > 0 ? ((entry.value / total) * 100).toStringAsFixed(1) : '0.0';
      return '''
        <tr>
          <td style="padding: 8px; border: 1px solid #ddd;">${entry.key}</td>
          <td style="padding: 8px; border: 1px solid #ddd; text-align: right;">\$${entry.value.toStringAsFixed(2)}</td>
          <td style="padding: 8px; border: 1px solid #ddd; text-align: right;">$percentage%</td>
        </tr>
      ''';
    }).join('');

    // Build transaction rows (limit to 50)
    final transactionRows = dailyTransactions.take(50).map((tx) {
      final txDate = tx['date'] ?? '';
      final txCategory = tx['category'] ?? 'Unknown';
      final txNote = tx['note'] ?? '';
      final txType = tx['type'] ?? 'expense';
      final txAmount = (tx['amount'] ?? 0.0) as double;
      
      return '''
        <tr>
          <td style="padding: 8px; border: 1px solid #ddd;">$txDate</td>
          <td style="padding: 8px; border: 1px solid #ddd;">$txCategory</td>
          <td style="padding: 8px; border: 1px solid #ddd;">${txNote.isEmpty ? '-' : txNote}</td>
          <td style="padding: 8px; border: 1px solid #ddd;">${txType == 'expense' ? 'Expense' : 'Income'}</td>
          <td style="padding: 8px; border: 1px solid #ddd; text-align: right; color: ${txType == 'expense' ? '#e74c3c' : '#27ae60'};">\$${txAmount.toStringAsFixed(2)}</td>
        </tr>
      ''';
    }).join('');

    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Budget Bear - Expense Summary</title>
      </head>
      <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 800px; margin: 0 auto; padding: 20px; background-color: #f5f5f5;">
        
        <div style="background-color: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
          <!-- Header -->
          <div style="background: linear-gradient(135deg, #47A8A5 0%, #3d8f8c 100%); color: white; padding: 30px; border-radius: 10px; margin-bottom: 30px;">
            <h1 style="margin: 0; font-size: 32px;">🐻 Budget Bear</h1>
            <h2 style="margin: 10px 0 0 0; font-weight: normal; font-size: 20px;">Expense Summary Report</h2>
            <p style="margin: 5px 0 0 0; opacity: 0.9;">${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}</p>
          </div>

          <!-- Greeting -->
          <p style="font-size: 16px;">Hi <strong>$name</strong>,</p>
          <p style="font-size: 16px;">Here's your expense summary for the selected period:</p>

          <!-- Summary Cards -->
          <table style="width: 100%; margin: 30px 0;">
            <tr>
              <td style="width: 33%; padding: 10px;">
                <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; border-left: 4px solid #27ae60;">
                  <div style="font-size: 14px; color: #666; margin-bottom: 8px;">Total Income</div>
                  <div style="font-size: 24px; font-weight: bold; color: #27ae60;">\$${totalIncome.toStringAsFixed(2)}</div>
                </div>
              </td>
              <td style="width: 33%; padding: 10px;">
                <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; border-left: 4px solid #e74c3c;">
                  <div style="font-size: 14px; color: #666; margin-bottom: 8px;">Total Expenses</div>
                  <div style="font-size: 24px; font-weight: bold; color: #e74c3c;">\$${totalExpenses.toStringAsFixed(2)}</div>
                </div>
              </td>
              <td style="width: 33%; padding: 10px;">
                <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; border-left: 4px solid ${netSavings >= 0 ? '#47A8A5' : '#e74c3c'};">
                  <div style="font-size: 14px; color: #666; margin-bottom: 8px;">Net Savings</div>
                  <div style="font-size: 24px; font-weight: bold; color: ${netSavings >= 0 ? '#47A8A5' : '#e74c3c'};">\$${netSavings.toStringAsFixed(2)}</div>
                </div>
              </td>
            </tr>
          </table>

          <!-- Category Breakdown -->
          <div style="margin: 30px 0;">
            <h3 style="color: #47A8A5; border-bottom: 2px solid #47A8A5; padding-bottom: 10px; margin-bottom: 15px;">Expense Breakdown by Category</h3>
            ${categories.isNotEmpty ? '''
              <table style="width: 100%; border-collapse: collapse; margin-top: 15px;">
                <thead>
                  <tr style="background: #47A8A5; color: white;">
                    <th style="padding: 12px; text-align: left; border: 1px solid #47A8A5;">Category</th>
                    <th style="padding: 12px; text-align: right; border: 1px solid #47A8A5;">Amount</th>
                    <th style="padding: 12px; text-align: right; border: 1px solid #47A8A5;">Percentage</th>
                  </tr>
                </thead>
                <tbody>
                  $categoryRows
                </tbody>
              </table>
            ''' : '<p style="color: #666; font-style: italic;">No expense data available for this period.</p>'}
          </div>

          <!-- Daily Transactions -->
          <div style="margin: 30px 0;">
            <h3 style="color: #47A8A5; border-bottom: 2px solid #47A8A5; padding-bottom: 10px; margin-bottom: 15px;">Recent Transactions</h3>
            ${dailyTransactions.isNotEmpty ? '''
              <table style="width: 100%; border-collapse: collapse; margin-top: 15px; font-size: 14px;">
                <thead>
                  <tr style="background: #47A8A5; color: white;">
                    <th style="padding: 10px; text-align: left; border: 1px solid #47A8A5;">Date</th>
                    <th style="padding: 10px; text-align: left; border: 1px solid #47A8A5;">Category</th>
                    <th style="padding: 10px; text-align: left; border: 1px solid #47A8A5;">Description</th>
                    <th style="padding: 10px; text-align: left; border: 1px solid #47A8A5;">Type</th>
                    <th style="padding: 10px; text-align: right; border: 1px solid #47A8A5;">Amount</th>
                  </tr>
                </thead>
                <tbody>
                  $transactionRows
                </tbody>
              </table>
              ${dailyTransactions.length > 50 ? '<p style="color: #666; font-style: italic; margin-top: 10px;">Showing first 50 transactions. Total: ${dailyTransactions.length}</p>' : ''}
            ''' : '<p style="color: #666; font-style: italic;">No transactions available for this period.</p>'}
          </div>

          <!-- Tips Section -->
          ${netSavings < 0 ? '''
          <div style="background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; border-radius: 5px;">
            <p style="margin: 0; color: #856404;"><strong>💡 Tip:</strong> Your expenses exceeded your income this period. Consider reviewing your spending categories to identify areas where you can save.</p>
          </div>
          ''' : netSavings > 0 ? '''
          <div style="background: #d4edda; border-left: 4px solid #28a745; padding: 15px; margin: 20px 0; border-radius: 5px;">
            <p style="margin: 0; color: #155724;"><strong>🎉 Great job!</strong> You saved \$${netSavings.toStringAsFixed(2)} this period. Keep up the good work!</p>
          </div>
          ''' : ''}

          <!-- Footer -->
          <div style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; text-align: center; color: #666; font-size: 12px;">
            <p style="margin: 5px 0;">This email was automatically generated by <strong>Budget Bear</strong></p>
            <p style="margin: 5px 0;">Generated on ${DateFormat('EEEE, MMM dd, yyyy').format(DateTime.now())} at ${DateFormat('HH:mm').format(DateTime.now())}</p>
            <p style="margin: 15px 0 5px 0; color: #999;">Questions or feedback? We'd love to hear from you!</p>
          </div>
        </div>

      </body>
      </html>
    ''';
  }
}