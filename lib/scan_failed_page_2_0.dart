import 'package:flutter/material.dart';

class ScanFailedPage2_0 extends StatelessWidget {
  final String errorMessage;

  ScanFailedPage2_0({required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Failed'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 100.0,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Scan Failed',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    errorMessage,
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text('Back to Home'),
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
    );
  }
}