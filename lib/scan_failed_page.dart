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
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Added padding for spacing
        child: Column(
          children: [
            Expanded(
              child: Center(
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
            ),
            // Footer with Image
            Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 10.0, horizontal: 22.0), // More padding for spacing
              child: Center(
                child: Image.network(
                  "https://web14.bernama.com/storage/photos/a26df8d233b4c81a46dd35dbcec12a1161f241cdb3922",
                  height: 40, // Set the height of the footer image
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
