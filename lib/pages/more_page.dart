import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:budget_bear/pages/edit_profile_page.dart';
import 'package:budget_bear/pages/login_page.dart';
import 'package:budget_bear/pages/register_page.dart';
import 'package:budget_bear/widgets/bottom_nav_bar.dart';
import 'package:budget_bear/services/theme_provider.dart';
import 'package:budget_bear/services/email_service.dart';
import 'package:budget_bear/services/profile_service.dart';
import 'package:budget_bear/services/expense_data_service.dart';
import 'package:budget_bear/services/pdf_service.dart';
import 'package:budget_bear/widgets/date_range_dialog.dart';

class MorePage extends StatefulWidget {
  const MorePage({Key? key}) : super(key: key);

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ProfileService _profileService = ProfileService();
  final ExpenseDataService _expenseDataService = ExpenseDataService();

  String _name = '';
  String _email = '';

  static const Color accent = Color.fromRGBO(71, 168, 165, 1);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _profileService.getUserProfile();
    setState(() {
      _name = profile['name'] ?? '';
      _email = profile['email'] ?? '';
    });
  }

  Future<void> _handleDateRangeSelection({required bool isForEmail}) async {
    final result = await DateRangeDialog.show(
      context: context,
      isForEmail: isForEmail,
    );

    if (result != null) {
      if (isForEmail) {
        await _sendEmailSummary(result['start']!, result['end']!);
      } else {
        await _downloadPDF(result['start']!, result['end']!);
      }
    }
  }

  Future<void> _sendEmailSummary(DateTime startDate, DateTime endDate) async {
    try {
      if (!EmailService.isConfigured()) {
        _showConfigurationError();
        return;
      }

      _showLoadingDialog();

      final data = await _expenseDataService.fetchExpenseData(startDate, endDate);

      final success = await EmailService.sendExpenseSummaryEmail(
        recipientEmail: _email,
        recipientName: _name,
        startDate: startDate,
        endDate: endDate,
        summaryData: data,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        _showSuccessSnackBar('Email sent successfully to $_email');
      } else {
        _showErrorSnackBar(
          'Failed to send email',
          'Check debug logs for details.',
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!mounted) return;
      _showErrorSnackBar('Error', e.toString());
    }
  }

  Future<void> _downloadPDF(DateTime startDate, DateTime endDate) async {
    try {
      _showLoadingDialog();

      final data = await _expenseDataService.fetchExpenseData(startDate, endDate);

      await PdfService.generateExpensePDF(
        startDate: startDate,
        endDate: endDate,
        data: data,
      );

      if (!mounted) return;
      Navigator.pop(context);

      _showSuccessSnackBar('PDF generated successfully!');
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!mounted) return;
      _showErrorSnackBar('Error generating PDF', e.toString());
    }
  }

  Future<void> _logout() async {
    final confirm = await _showLogoutConfirmation();

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

  // UI Helper Methods
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: accent),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '❌ $title',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(message, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showConfigurationError() {
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
  }

  Future<bool?> _showLogoutConfirmation() {
    return showDialog<bool>(
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA);
    final textColor = isDark ? Colors.white : const Color(0xFF333333);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Settings',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
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

  // UI Component Builders
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
            onTap: () => _handleDateRangeSelection(isForEmail: true),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.download_outlined, color: accent),
            title:
                Text('Download Expense Summary', style: theme.textTheme.bodyMedium),
            subtitle: Text(
              'Download PDF summary for a date range',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium!.color!.withOpacity(0.6),
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _handleDateRangeSelection(isForEmail: false),
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
                  Text(
                      'Budget Bear helps you track and manage your expenses easily.'),
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