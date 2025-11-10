import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:budget_bear/pages/edit_profile_page.dart';
import 'package:budget_bear/pages/login_page.dart';
import 'package:budget_bear/pages/register_page.dart';
import 'package:budget_bear/widgets/bottom_nav_bar.dart';
import 'package:budget_bear/services/theme_provider.dart';
import 'package:budget_bear/services/firestore.dart';
import 'package:budget_bear/services/email_service.dart';  
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class MorePage extends StatefulWidget {
  const MorePage({Key? key}) : super(key: key);

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  String _name = '';
  String _email = '';

  static const Color accent = Color.fromRGBO(71, 168, 165, 1);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _db.collection('users').doc(user.uid).get();
    setState(() {
      _name = doc['name'] ?? '';
      _email = user.email ?? '';
    });
  }

  Future<void> _showDateRangePicker({bool isForEmail = false}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime? startDate;
    DateTime? endDate;

    final result = await showDialog<Map<String, DateTime>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                isForEmail ? 'Select Date Range for Email' : 'Select Date Range',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Start Date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'From',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                    subtitle: Text(
                      startDate != null
                          ? DateFormat('MMM dd, yyyy').format(startDate!)
                          : 'Select start date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    trailing: const Icon(Icons.calendar_today, color: accent),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: isDark
                                  ? const ColorScheme.dark(
                                      primary: accent,
                                      surface: Color(0xFF1E1E1E),
                                    )
                                  : const ColorScheme.light(primary: accent),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setStateDialog(() => startDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // End Date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'To',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                    subtitle: Text(
                      endDate != null
                          ? DateFormat('MMM dd, yyyy').format(endDate!)
                          : 'Select end date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    trailing: const Icon(Icons.calendar_today, color: accent),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? DateTime.now(),
                        firstDate: startDate ?? DateTime(2000),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: isDark
                                  ? const ColorScheme.dark(
                                      primary: accent,
                                      surface: Color(0xFF1E1E1E),
                                    )
                                  : const ColorScheme.light(primary: accent),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setStateDialog(() => endDate = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: startDate != null && endDate != null
                      ? () {
                          Navigator.pop(context, {
                            'start': startDate!,
                            'end': endDate!,
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(isForEmail ? 'Send Email' : 'Download'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      if (isForEmail) {
        _sendEmailSummary(result['start']!, result['end']!);
      } else {
        _generatePDF(result['start']!, result['end']!);
      }
    }
  }

  Future<void> _sendEmailSummary(DateTime startDate, DateTime endDate) async {
    try {
      // Check if email service is configured BEFORE showing loading
      if (!EmailService.isConfigured()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '❌ Email service not configured',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Steps to fix:\n1. Ensure .env file exists in project root\n2. Add SENDGRID_API_KEY to .env\n3. Add SENDER_EMAIL to .env\n4. Verify sender email in SendGrid dashboard\n5. Run flutter clean && flutter pub get',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 8),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: accent),
        ),
      );

      // Fetch data for the date range
      final data = await _fetchExpenseData(startDate, endDate);

      print('📊 Fetched data: ${data.keys}');
      print('📧 Sending to: $_email');
      print('👤 Recipient name: $_name');

      // Send email using EmailService
      final success = await EmailService.sendExpenseSummaryEmail(
        recipientEmail: _email,
        recipientName: _name,
        startDate: startDate,
        endDate: endDate,
        summaryData: data,
      );

      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);

      // Show result message
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Email sent successfully to $_email'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '❌ Failed to send email',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Check debug logs for details. Common issues:\n• API key invalid/expired\n• Sender email not verified in SendGrid\n• Network connection issue',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (!mounted) return;
      
      // Show detailed error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '❌ Exception while sending email',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                e.toString(),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Print to console for debugging
      print('❌ Email Error Details: $e');
      print('Stack trace:');
      print(StackTrace.current);
    }
  }

  Future<void> _generatePDF(DateTime startDate, DateTime endDate) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: accent),
        ),
      );

      // Fetch data for the date range
      final data = await _fetchExpenseData(startDate, endDate);

      // Create PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            pw.Header(
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
            ),
            pw.SizedBox(height: 20),

            // Summary Section
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F5F7FA'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryItem('Total Income', data['totalIncome'], true),
                      _buildSummaryItem('Total Expenses', data['totalExpenses'], false),
                      _buildSummaryItem('Net Savings', data['netSavings'], data['netSavings'] >= 0),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Category Breakdown
            pw.Text(
              'Expense Breakdown by Category',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            _buildCategoryTable(data['categories']),
            pw.SizedBox(height: 24),

            // Daily Transactions
            pw.Text(
              'Daily Transactions',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            _buildDailyTransactionsTable(data['dailyTransactions']),
          ],
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 16),
            child: pw.Text(
              'Generated on ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ),
        ),
      );

      // Close loading dialog
      Navigator.pop(context);

      // Show PDF preview and allow user to save/share
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'expense_summary_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.pdf',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF generated successfully!'),
          backgroundColor: accent,
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  pw.Widget _buildSummaryItem(String label, double amount, bool isPositive) {
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

  pw.Widget _buildCategoryTable(Map<String, double> categories) {
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

  pw.Widget _buildDailyTransactionsTable(List<Map<String, dynamic>> transactions) {
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

  Future<Map<String, dynamic>> _fetchExpenseData(
      DateTime startDate, DateTime endDate) async {
    double totalIncome = 0.0;
    double totalExpenses = 0.0;
    Map<String, double> categories = {};
    List<Map<String, dynamic>> dailyTransactions = [];

    // Fetch all transactions in the date range
    final user = _auth.currentUser;
    if (user == null) {
      return {
        'totalIncome': 0.0,
        'totalExpenses': 0.0,
        'netSavings': 0.0,
        'categories': {},
        'dailyTransactions': [],
      };
    }

    final querySnapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate.add(const Duration(days: 1))))
        .orderBy('date', descending: true)
        .get();

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] ?? 0.0).toDouble();
      final type = data['type'] ?? 'expense';
      final category = data['category'] ?? 'Unknown';
      final note = data['note'] ?? '';
      final date = (data['date'] as Timestamp).toDate();

      if (type == 'income') {
        totalIncome += amount;
      } else {
        totalExpenses += amount;
        // Aggregate categories (only for expenses)
        categories[category] = (categories[category] ?? 0.0) + amount;
      }

      // Add to daily transactions
      dailyTransactions.add({
        'date': DateFormat('dd MMM yyyy').format(date),
        'category': category,
        'note': note,
        'type': type,
        'amount': amount,
      });
    }

    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netSavings': totalIncome - totalExpenses,
      'categories': categories,
      'dailyTransactions': dailyTransactions,
    };
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Log Out"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(
            showRegisterPage: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => RegisterPage(
                    showLoginPage: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoginPage(showRegisterPage: () {}),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Profile', theme),
          _buildProfileCard(theme),

          const SizedBox(height: 24),
          _buildSectionTitle('Settings', theme),
          _buildSettingsCard(theme),

          const SizedBox(height: 24),
          _buildSectionTitle('Appearance', theme),
          _buildAppearanceCard(theme, themeProvider),

          const SizedBox(height: 24),
          _buildSectionTitle('About', theme),
          _buildAboutCard(theme),

          const SizedBox(height: 40),
          _buildLogoutButton(theme),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
    );
  }

  // ---------- UI COMPONENTS ----------

  Widget _buildProfileCard(ThemeData theme) {
    return Container(
      decoration: _cardDecoration(theme),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundImage: AssetImage('assets/images/bear_avatar.png'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium!.color!.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: accent),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
              _loadUserProfile();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(ThemeData theme) {
    return Container(
      decoration: _cardDecoration(theme),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.email_outlined, color: accent),
            title: Text('Send Email Summary', style: theme.textTheme.bodyMedium),
            subtitle: Text(
              'Email expense summary for a date range',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium!.color!.withOpacity(0.6),
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showDateRangePicker(isForEmail: true),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.download_outlined, color: accent),
            title: Text('Download Expense Summary', style: theme.textTheme.bodyMedium),
            subtitle: Text(
              'Download PDF summary for a date range',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium!.color!.withOpacity(0.6),
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showDateRangePicker(isForEmail: false),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceCard(ThemeData theme, ThemeProvider themeProvider) {
    return Container(
      decoration: _cardDecoration(theme),
      child: SwitchListTile(
        title: Text('Dark Mode', style: theme.textTheme.bodyMedium),
        value: themeProvider.isDarkMode,
        activeColor: accent,
        onChanged: themeProvider.toggleTheme,
      ),
    );
  }

  Widget _buildAboutCard(ThemeData theme) {
    return Container(
      decoration: _cardDecoration(theme),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy & Policy', style: theme.textTheme.bodyMedium),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text('About Budget Bear', style: theme.textTheme.bodyMedium),
            subtitle: Text(
              'Version 1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium!.color!.withOpacity(0.6),
              ),
            ),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Budget Bear',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.pets, color: accent),
                children: const [
                  Text('Budget Bear helps you track and manage your expenses easily.'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(ThemeData theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _logout,
      child: Container(
        decoration: _cardDecoration(theme, color: accent),
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: const Center(
          child: Text(
            'Log Out',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.textTheme.bodyMedium!.color!.withOpacity(0.8),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(ThemeData theme, {Color? color}) {
    return BoxDecoration(
      color: color ?? theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: theme.brightness == Brightness.light
          ? [
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              )
            ]
          : [],
    );
  }
}