// scan_failed_page.dart
import 'package:flutter/material.dart';

class ScanFailedPage extends StatelessWidget {
  final String errorMessage;

  const ScanFailedPage({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Failed'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.clear,
              color: Colors.red,
              size: 100,
            ),
            const SizedBox(height: 20),
            Text(
              errorMessage,
              style: const TextStyle(fontSize: 18, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to the scanner page
              },
              child: const Text('Back to Scanner'),
            ),
          ],
        ),
      ),
    );
  }
}
