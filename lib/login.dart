import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart'; // Add this import for hashing
import 'dart:convert'; // For utf8.encode
import 'scan_choosing_page.dart'; // Import your home page

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool initialized = false; // Flag to track initialization

  try {
    await Supabase.initialize(
      url:
          'https://eudnptkpagbjkhnasbpp.supabase.co', // Replace with your Supabase URL
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV1ZG5wdGtwYWdiamtobmFzYnBwIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyNTI1ODA2OCwiZXhwIjoyMDQwODM0MDY4fQ.0CR3ty3yCTMAnAWKxo7NR8-V9_vH2Kz4TNDU9BkUvC0', // Replace with your Supabase Anon Key
    );
    initialized = true; // Set flag to true if initialization is successful
  } catch (e) {
    print('Supabase initialization failed: $e'); // Log the error
  }

  // Check if user is already logged in
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? empId = prefs.getString('empid');

  bool isAuthenticated = empId != null;

  runApp(MyApp(
    isLoggedIn: isAuthenticated,
    initialized: true, // Pass the initialized flag here
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool initialized; // Flag for initialization status

  const MyApp({super.key, required this.isLoggedIn, required this.initialized});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: isLoggedIn ? ScanChoosingPage() : LoginPage(initialized: initialized),
      routes: {
        '/login': (context) => LoginPage(initialized: initialized),
        '/home': (context) => ScanChoosingPage(),
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

    String hashedPassword = hashPassword(password);

    if (userId.isNotEmpty && password.isNotEmpty) {
      try {
        final response = await Supabase.instance.client.rpc('auth_user',
            params: {'p_empid': userId, 'p_password': hashedPassword}).single();

        if (response == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: No response from server')),
          );
          return;
        }

        if (response['empid'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid Employee ID or Password')),
          );
        } else {
          String empId = response['empid'] as String;

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('empid', empId);

          // Set the Supabase session variable
          await Supabase.instance.client.rpc('set_config', params: {
            'key': 'myapp.user_id',
            'value': empId,
          });

          // Save a custom token or flag to SharedPreferences if needed
          await prefs.setBool('isAuthenticated', true);

          // Show details dialog on successful login
          _showDetailsDialog(context, empId);

          // Navigate to HomePage after successful login
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: empId, // Pass empId as an argument
          );
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(labelText: 'Enter Employee ID'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Enter Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
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
    );
  }
}
