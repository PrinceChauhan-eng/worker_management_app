import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_provider.dart';
import '../services/database_helper.dart';
import '../services/session_manager.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  String _newPassword = '';
  String _confirmPassword = '';

  _changeAdminPassword() async {
    if (_newPassword.isEmpty || _confirmPassword.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please fill in all password fields',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    if (_newPassword != _confirmPassword) {
      Fluttertoast.showToast(
        msg: 'Passwords do not match',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    if (_newPassword.length < 6) {
      Fluttertoast.showToast(
        msg: 'Password must be at least 6 characters',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser != null) {
      // Create updated user with new password
      final updatedUser = currentUser.copyWith(
        password: _newPassword,
      );

      // Update user in database
      final success = await userProvider.updateUser(updatedUser);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        Fluttertoast.showToast(
          msg: 'Password changed successfully!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        // Clear password fields
        setState(() {
          _newPassword = '';
          _confirmPassword = '';
        });
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to change password. Please try again.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  _resetAllData() async {
    // Show confirmation dialog
    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Reset'),
          content: const Text(
              'Are you sure you want to reset all data? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get database instance
        final dbHelper = DatabaseHelper();
        final db = await dbHelper.db;

        // Delete all records from all tables
        await db.delete('users');
        await db.delete('attendance');
        await db.delete('advance');
        await db.delete('salary');

        // Insert default admin user
        await db.insert('users', {
          'name': 'Admin',
          'phone': 'admin',
          'password': 'admin123',
          'role': 'admin',
          'wage': 0.0,
          'joinDate': DateTime.now().toString(),
        });

        setState(() {
          _isLoading = false;
        });

        Fluttertoast.showToast(
          msg: 'All data reset successfully!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );

        // Logout user
        SessionManager sessionManager = SessionManager();
        await sessionManager.logout();
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.clearCurrentUser();

        // Navigate to login screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        Fluttertoast.showToast(
          msg: 'Failed to reset data. Please try again.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Settings',
        onLeadingPressed: () {
          Navigator.pop(context);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Settings',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E88E5), // Royal Blue
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Manage your app preferences',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            // Change Admin Password
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Change Admin Password',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      obscureText: true,
                      onChanged: (value) {
                        setState(() {
                          _newPassword = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: GoogleFonts.poppins(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.lock),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      obscureText: true,
                      onChanged: (value) {
                        setState(() {
                          _confirmPassword = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: GoogleFonts.poppins(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.lock),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Change Password',
                      onPressed: _changeAdminPassword,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Reset All Data
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reset All Data',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This will delete all records and reset the app to default settings.',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Reset All Data',
                      onPressed: _resetAllData,
                      color: const Color(0xFFF44336), // Red
                      textColor: Colors.white,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Currency Settings
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.currency_rupee,
                  color: Color(0xFF1E88E5), // Royal Blue
                ),
                title: Text(
                  'Currency',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '₹ Indian Rupee (Default)',
                  style: GoogleFonts.poppins(),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Future implementation for currency settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Currency settings feature coming soon!'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Export/Backup Data
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.backup,
                  color: Color(0xFF1E88E5), // Royal Blue
                ),
                title: Text(
                  'Export/Backup Data',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Create backup of all data',
                  style: GoogleFonts.poppins(),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Future implementation for export/backup
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export/Backup feature coming soon!'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}