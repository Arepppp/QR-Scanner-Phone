import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mainPage.dart'; // Ensure you have this file or replace with your home page file
import 'login.dart'; // Ensure you have this file or replace with your login page file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://eudnptkpagbjkhnasbpp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV1ZG5wdGtwYWdiamtobmFzYnBwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjUyNTgwNjgsImV4cCI6MjA0MDgzNDA2OH0.VzaMVXDED6n2uX2YnQriSORP3v_4itChXXAFWfMJ1Bg',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Register Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthWrapper(), // Use AuthWrapper for checking auth state
      routes: {
        '/home': (context) => HomePage(),
        '/register': (context) => RegisterPage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.data?.session != null) {
            return HomePage(); // User is logged in, show HomePage
          }
        }
        return const Center(child: CircularProgressIndicator()); // Show loading indicator while checking auth state
      },
    );
  }
}


class RegisterPage extends StatelessWidget {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  RegisterPage({super.key});

  Future<void> _register(BuildContext context) async {
  String userId = _userIdController.text.trim();
  String password = _passwordController.text.trim();
  String name = _nameController.text.trim();

  if (userId.isNotEmpty && password.isNotEmpty && name.isNotEmpty) {
    try {
      final email = '$userId@example.com'; // Supabase requires email format

      // Register user with Supabase Auth
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      // Check if user registration was successful
      if (response.user != null) {
        final supabaseUserId = response.user!.id; // Get the Supabase user ID

        // Store user data in Supabase database (without password)
        await Supabase.instance.client.from('users').insert({
          'userId': supabaseUserId,
          'name': name,
        });

        // Store credentials locally
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', supabaseUserId);
        await prefs.setString('authToken', response.session?.accessToken ?? ''); // Store the token

        // Navigate to the LoginPage after successful registration
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on AuthException catch (e) {
      // Show error message if there's an authentication error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      // Show generic error message for other exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter all fields')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register LOTTE ID')),
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
              decoration: const InputDecoration(labelText: 'Enter Password'),
              obscureText: true, // Hide password input
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Enter Name'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _register(context),
              child: const Text('Register'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Already have an account? Log in'),
            ),
          ],
        ),
      ),
    );
  }
}