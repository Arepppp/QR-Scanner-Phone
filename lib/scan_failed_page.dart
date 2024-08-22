// scan_failed_page.dart
import 'package:flutter/material.dart';

class ScanFailedPage extends StatelessWidget {
  final String errorMessage;

  ScanFailedPage({required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Failed'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.clear,
              color: Colors.red,
              size: 100,
            ),
            SizedBox(height: 20),
            Text(
              errorMessage,
              style: TextStyle(fontSize: 18, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to the scanner page
              },
              child: Text('Back to Scanner'),
            ),
          ],
        ),
      ),
    );
  }
}
