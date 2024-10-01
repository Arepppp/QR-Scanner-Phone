import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChangePasswordPage extends StatefulWidget {
  final String empId;

  ChangePasswordPage({required this.empId});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _passwordVisible1 = false; // Separate visibility for new password
  bool _passwordVisible2 = false; // Separate visibility for confirm password

  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _changePassword(BuildContext context) async {
    String newPassword = _newPasswordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    // Check if both password fields are filled
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showErrorDialog(context, 'Please fill in both password fields');
      return;
    }

    // Check if passwords match
    if (newPassword != confirmPassword) {
      _showErrorDialog(context, 'Passwords do not match');
      return;
    }

    String hashedPassword = hashPassword(newPassword);

    try {
      // Execute SQL query to update the password
      await Supabase.instance.client
          .from('employees') // Replace with your actual table name
          .update({
        'password': hashedPassword
      }) // Assuming 'password' is the column name
          .eq('empid', widget.empId); // Assuming 'empid' is the column to match

      // Mark user as authenticated after successful password change
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAuthenticated', true);

      // Navigate to the home page after successful password change
      Navigator.pushReplacementNamed(context, '/home', arguments: widget.empId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change password: $e')),
      );
    }
  }

  // Show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Enter New Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible1
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible1 = !_passwordVisible1;
                          });
                        },
                      ),
                    ),
                    obscureText: !_passwordVisible1,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible2
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible2 = !_passwordVisible2;
                          });
                        },
                      ),
                    ),
                    obscureText: !_passwordVisible2,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _changePassword(context),
                    child: const Text('Change Password'),
                  ),
                ],
              ),
            ),
          ),
          // Footer with Image using Expanded
          Container(
            color: Colors.white, // Background color of the footer
            padding: EdgeInsets.all(4.0),
            child: Center(
              child: Image.network(
                "https://web14.bernama.com/storage/photos/a26df8d233b4c81a46dd35dbcec12a1161f241cdb3922",
                height: 20, // Set the height of the logo
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
