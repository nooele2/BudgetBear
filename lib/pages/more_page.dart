import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:budget_bear/widgets/bottom_nav_bar.dart';
import 'package:budget_bear/pages/edit_profile_page.dart';
import 'package:budget_bear/pages/login_page.dart';
import 'package:budget_bear/pages/register_page.dart';

class MorePage extends StatefulWidget {
  const MorePage({Key? key}) : super(key: key);

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _sendMonthlyEmail = false;
  bool _isDarkMode = false;

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

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(
              showRegisterPage: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegisterPage(
                      showLoginPage: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LoginPage(showRegisterPage: () {}),
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
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor =
        _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA);
    final Color textColor =
        _isDarkMode ? Colors.white : const Color(0xFF333333);

    return Scaffold(
      backgroundColor: bgColor,
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
          _buildSectionTitle('Profile', textColor),
          _buildProfileSummaryCard(textColor),

          const SizedBox(height: 24),
          _buildSectionTitle('Settings', textColor),
          _buildSettingsCard(textColor),

          const SizedBox(height: 24),
          _buildSectionTitle('Appearance', textColor),
          _buildAppearanceCard(textColor),

          const SizedBox(height: 24),
          _buildSectionTitle('About', textColor),
          _buildAboutCard(textColor),

          const SizedBox(height: 40),

          // ✅ Logout container with accent background
          InkWell(
  borderRadius: BorderRadius.circular(16),
  onTap: _logout,
  child: Container(
    decoration: _cardDecoration(
      color: accent,
    ),
    padding: const EdgeInsets.symmetric(vertical: 13),
    child: Center(
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
),

        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
    );
  }

  // ---------- UI SECTIONS ----------

  Widget _buildProfileSummaryCard(Color textColor) {
    return Container(
      decoration: _cardDecoration(),
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
                Text(_name,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
                const SizedBox(height: 4),
                Text(_email,
                    style: TextStyle(color: textColor.withOpacity(0.7))),
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
              _loadUserProfile(); // refresh after return
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(Color textColor) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          SwitchListTile(
            title: Text('Send Monthly Email', style: TextStyle(color: textColor)),
            subtitle: Text('Receive monthly expense summary',
                style: TextStyle(color: textColor.withOpacity(0.6))),
            value: _sendMonthlyEmail,
            activeColor: accent,
            onChanged: (v) => setState(() => _sendMonthlyEmail = v),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text('Download Expense Summary',
                style: TextStyle(color: textColor)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceCard(Color textColor) {
    return Container(
      decoration: _cardDecoration(),
      child: SwitchListTile(
        title: Text('Dark Mode', style: TextStyle(color: textColor)),
        value: _isDarkMode,
        activeColor: accent,
        onChanged: (v) => setState(() => _isDarkMode = v),
      ),
    );
  }

  Widget _buildAboutCard(Color textColor) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy & Policy', style: TextStyle(color: textColor)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text('About Budget Bear', style: TextStyle(color: textColor)),
            subtitle: Text('Version 1.0.0',
                style: TextStyle(color: textColor.withOpacity(0.6))),
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

  // ---------- HELPERS ----------

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor.withOpacity(0.8)),
      ),
    );
  }

  // ✅ Updated: supports optional custom background color
  BoxDecoration _cardDecoration({Color? color}) {
    return BoxDecoration(
      color: color ?? (_isDarkMode ? Colors.grey[900] : Colors.white),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))
      ],
    );
  }
}
