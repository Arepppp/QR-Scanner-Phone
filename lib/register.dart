import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore database
import 'package:shared_preferences/shared_preferences.dart';
import 'mainPage.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: "AIzaSyC2xioshGzhd0hU0whxjX5R5O9YtzCaSug",
          authDomain: "flutter-project-test-414d0.firebaseapp.com",
          projectId: "flutter-project-test-414d0",
          storageBucket: "flutter-project-test-414d0.appspot.com",
          messagingSenderId: "1067211645239",
          appId: "1:1067211645239:web:0d9898712b799b26237ab2"));

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Register Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RegisterPage(), // The first page to open when the app starts
      routes: {
        '/home': (context) =>
            HomePage(), // Reference the HomePage from test.dart
        '/login': (context) => LoginPage(),
      },
    );
  }
}

class RegisterPage extends StatelessWidget {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  Future<void> _register(BuildContext context) async {
    String userId = _userIdController.text.trim();
    String password = _passwordController.text.trim();
    String name = _nameController.text.trim();

    if (userId.isNotEmpty && password.isNotEmpty && name.isNotEmpty) {
      try {
        // Register user with Firebase Auth
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
                email: '$userId@example.com', // Treat Employee ID as email
                password: password);

        // Store user data in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user?.uid)
            .set({
          'userId': userId,
          'name': name,
          'password': password,
        });

        // Store credentials locally
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);
        await prefs.setString('authToken', 'dummyToken'); // Simulate a token

        // Navigate to the LoginPage after successful registration
        Navigator.pushReplacementNamed(context, '/login');
      } on FirebaseAuthException catch (e) {
        // Handle different error codes and show appropriate messages
        String errorMessage;
        if (e.code == 'weak-password') {
          errorMessage = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'The account already exists for that Employee ID.';
        } else {
          errorMessage = e.message ?? 'Registration failed';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register LOTTE ID')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _userIdController,
              decoration: InputDecoration(labelText: 'Enter Employee ID'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Enter Password'),
              obscureText: true, // Hide password input
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Enter Name'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _register(context),
              child: Text('Register'),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text('Already have an account? Log in'),
            ),
          ],
        ),
      ),
    );
  }
}
