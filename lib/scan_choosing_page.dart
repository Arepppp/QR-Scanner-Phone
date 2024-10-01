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

    // Fetch empId from user metadata
    String? empId = prefs.getString('empid');

    // If empId is not available, handle the case
    if (empId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Employee ID not found in SharedPreferences"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Fetch employee name from the database using empId
    String? employeeName = await _getEmployeeName(empId);

    if (employeeName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to fetch employee name"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Display a welcome message with the employee's name
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Welcome'),
            content: Text('Welcome, $employeeName!'),
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

  Future<String?> _getEmployeeName(String empId) async {
    try {
      final response = await Supabase.instance.client
          .from('employees') // Replace with your actual table name
          .select('name')
          .eq('empid', empId)
          .single(); // Fetch a single row

      return response['name'] as String;
    } catch (e) {
      print('Error fetching employee name: $e');
      return null;
    }
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
    final double buttonHeight = MediaQuery.of(context).size.height * 0.35;

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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildImageButton(
                    context,
                    title: 'Canteen Scanning',
                    imageUrl:
                        'https://img.etimg.com/thumb/width-1200,height-900,imgsize-309372,resizemode-75,msid-65916510/magazines/panache/how-the-humble-office-canteen-is-witnessing-a-gastronomic-makeover.jpg',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HomePage()),
                      );
                    },
                    buttonHeight: buttonHeight,
                  ),
                  _buildImageButton(
                    context,
                    title: 'Attendance Scanning',
                    imageUrl:
                        'https://www.mida.gov.my/wp-content/uploads/2020/08/pic1.jpg',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AttendanceScanningPage()),
                      );
                    },
                    buttonHeight: buttonHeight,
                  ),
                ],
              ),
            ),
          ),
          // Footer with Image
          // Footer with Image
          Container(
            padding: EdgeInsets.symmetric(
                vertical: 10.0, horizontal: 22.0), // More padding for spacing
            child: Center(
              child: Image.network(
                "https://assets.bharian.com.my/images/articles/LCT_1557473125.jpg",
                height: 40, // Slightly increased height for better visibility
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Custom widget to create buttons with background images and faded effect
  Widget _buildImageButton(
    BuildContext context, {
    required String title,
    required String imageUrl,
    required VoidCallback onPressed,
    required double buttonHeight,
  }) {
    return Container(
      height: buttonHeight,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image with faded effect
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              color: Colors.black
                  .withOpacity(0.5), // Apply a dark overlay for fade effect
              colorBlendMode: BlendMode.darken,
            ),
          ),
          // Button content
          Center(
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors
                    .transparent, // Make the button background transparent
                shadowColor: Colors.transparent, // Remove button shadow
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  color:
                      Colors.white, // Text color white on darkened background
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
