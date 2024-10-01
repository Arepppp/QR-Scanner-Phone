import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart'; // Add this import for hashing
import 'dart:convert'; // For utf8.encode
import 'scan_choosing_page.dart';
import 'change_password_page.dart';
import 'report_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url:
          'https://eudnptkpagbjkhnasbpp.supabase.co', // Replace with your Supabase URL
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV1ZG5wdGtwYWdiamtobmFzYnBwIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyNTI1ODA2OCwiZXhwIjoyMDQwODM0MDY4fQ.0CR3ty3yCTMAnAWKxo7NR8-V9_vH2Kz4TNDU9BkUvC0', // Replace with your Supabase Anon Key
    );
  } catch (e) {
    print('Supabase initialization failed: $e'); // Log the error
  }

  // Check if user is already logged in
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? empId = prefs.getString('empid');
  bool isSpecialUser = empId != null &&
      (empId == 'canteen1' || empId == 'canteen2' || empId == 'admin');
  bool isAuthenticated = empId != null;

  runApp(MyApp(
    isLoggedIn: isAuthenticated,
    isSpecialUser: isSpecialUser, // Pass the special user flag
    initialized: true, // Pass the initialized flag here
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool isSpecialUser; // Flag for special user type
  final bool initialized; // Flag for initialization status

  const MyApp(
      {super.key,
      required this.isLoggedIn,
      required this.isSpecialUser,
      required this.initialized});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: isLoggedIn
          ? (isSpecialUser ? CanteenReportPage() : ScanChoosingPage())
          : LoginPage(initialized: initialized),
      routes: {
        '/login': (context) => LoginPage(initialized: initialized),
        '/home': (context) => ScanChoosingPage(),
        '/report': (context) => CanteenReportPage(),
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  final bool initialized; // Flag for initialization status

  LoginPage({super.key, required this.initialized});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _showInitializationStatus(); // Show initialization status when the page loads
  }

  // Function to display initialization status
  void _showInitializationStatus() {
    if (widget.initialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Supabase initialized successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initialize Supabase'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _login(BuildContext context) async {
    String userId = _userIdController.text.trim();
    String password = _passwordController.text.trim();

    if (userId.isNotEmpty && password.isNotEmpty) {
      // Check for hardcoded credentials (canteen team and admin)
      if ((userId == 'canteen1' && password == 'pasirgudang') ||
          (userId == 'canteen2' && password == 'tanjunglangsat') ||
          (userId == 'admin' && password == 'pgandtanjung')) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('empid', userId);
        await prefs.setBool('isAuthenticated', true);
        await prefs.setBool(
            'isReportPageUser', true); // Flag to remember report page access

        // Navigate to the report page directly
        Navigator.pushReplacementNamed(context, '/report');
        return; // Return early to avoid running Supabase logic
      }

      // Existing Supabase login logic
      String hashedPassword = hashPassword(password);

      try {
        final response = await Supabase.instance.client.rpc('auth_user',
            params: {'p_empid': userId, 'p_password': hashedPassword}).single();

        // Check if response is null
        if (response == null || response['empid'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid Employee ID or Password')),
          );
        } else {
          String empId = response['empid'] as String;

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('empid', empId);
          await prefs.setBool('isAuthenticated', true);

          // Handle default password logic as before
          bool isDefaultPassword = this.isDefaultPassword(hashedPassword);
          if (isDefaultPassword) {
            _promptPasswordChange(context, empId);
          } else {
            _navigateToHome(context, empId);
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter both Employee ID and Password')),
      );
    }
  }

  bool isDefaultPassword(String password) {
    // Define your default password criteria here
    return password ==
        '9b3344e4190e292a915bab83829b36d6cbcb74f6a7faaee5291ac31e01b02d3c'; // Replace with your actual default logic
  }

// Prompt to change password
  void _promptPasswordChange(BuildContext context, String empId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: const Text(
              'You are using the default password. Please change your password, or you can choose to keep it.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Change Now'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangePasswordPage(
                        empId: empId), // Navigate to ChangePasswordPage
                  ),
                );
              },
            ),
            TextButton(
              child: const Text('Keep Current Password'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                // Navigate to home or report page based on your app flow
                _navigateToHome(
                    context, empId); // Assuming you want to navigate to home
              },
            ),
          ],
        );
      },
    );
  }

// Navigate to home page after login or password change
  void _navigateToHome(BuildContext context, String empId) {
    Navigator.pushReplacementNamed(
      context,
      '/home',
      arguments: empId,
    );
  }

  // Function to show details dialog
  void _showDetailsDialog(BuildContext context, String empId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Success'),
          content: Text('Employee ID: $empId'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _userIdController,
                    decoration:
                        const InputDecoration(labelText: 'Enter Employee ID'),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Enter Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !_passwordVisible,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _login(context),
                    child: const Text('Login'),
                  ),
                ],
              ),
            ),
            // Footer with Image
            Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 10.0, horizontal: 22.0), // More padding for spacing
              child: Center(
                child: Image.network(
                  "https://assets.bharian.com.my/images/articles/LCT_1557473125.jpg",
                  height: 40, // Set a small height for the footer image
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
