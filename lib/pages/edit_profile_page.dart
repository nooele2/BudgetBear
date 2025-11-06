import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isSaving = false;

  static const Color accent = Color.fromRGBO(71, 168, 165, 1);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _emailController.text = user.email ?? '';
    final doc = await _db.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      _nameController.text = doc['name'] ?? '';
    }
    setState(() {});
  }

  Future<void> _updateProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      setState(() => _isSaving = true);

      await _db.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
      });

      if (_emailController.text.trim() != user.email) {
        await user.verifyBeforeUpdateEmail(_emailController.text.trim());
        await _db.collection('users').doc(user.uid).update({
          'email': _emailController.text.trim(),
        });
        _showSnackBar('Verification email sent to new address.');
      } else {
        _showSnackBar('Profile updated successfully!');
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? 'Failed to update profile.');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _changePassword() async {
    final newPassword = _newPasswordController.text.trim();
    if (newPassword.isEmpty) {
      _showSnackBar('Please enter a new password');
      return;
    }

    try {
      await _auth.currentUser!.updatePassword(newPassword);
      _newPasswordController.clear();
      _showSnackBar('Password changed successfully!');
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? 'Failed to change password.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: accent),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Center(
              child: CircleAvatar(
                radius: 35,
                backgroundImage: AssetImage('assets/images/bear_avatar.png'),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: _inputDecoration('Display Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: _inputDecoration('Email'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: _inputDecoration('New Password'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: OutlinedButton(
                onPressed: _changePassword,
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: const BorderSide(color: accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Change Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: accent),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: accent, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
