import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mainPage.dart'; // Update with actual file name
import 'attendance_scanning_page.dart'; // Update with actual file name
import 'login.dart'; // Update with actual file name

class ScanChoosingPage extends StatefulWidget {
  const ScanChoosingPage({super.key});

  @override
  _ScanChoosingPageState createState() => _ScanChoosingPageState();
}

class _ScanChoosingPageState extends State<ScanChoosingPage> {

  @override
  void initState() {
    super.initState();
    checkUserSession(); // Check user session on init
  }

  Future<void> checkUserSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isAuthenticated = prefs.getBool('isAuthenticated') ?? false;

    // If no valid session is found, redirect to login
    if (!isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Fetch empid from user metadata
    String? empid = prefs.getString('empid');

    // If empid is not available, handle the case
    if (empid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Employee ID not found in SharedPreferences"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Display a welcome message with empid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Welcome'),
            content: Text('Welcome, $empid!'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () async {
                // Clear session variable on Supabase server side
                try {
                  await Supabase.instance.client.rpc('reset_config', params: {
                    'key': 'myapp.user_id',
                  });
                } catch (e) {
                  // Handle potential errors when clearing session variable
                  print('Error clearing session variable: $e');
                }

                // Clear all stored preferences
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                // Navigate to login page and remove all previous routes from the stack
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(initialized: true),
                  ),
                  (route) => false, // Remove all previous routes
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Options'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _showLogoutConfirmation(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 60), // Set the size of the button
                  textStyle: TextStyle(fontSize: 20), // Set the font size
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                ),
                child: Text('Canteen Scanning'),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AttendanceScanningPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 60), // Set the size of the button
                  textStyle: TextStyle(fontSize: 20), // Set the font size
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                ),
                child: Text('Attendance Scanning'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
