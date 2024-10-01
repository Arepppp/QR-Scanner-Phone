import 'package:flutter/material.dart';

class ResultPage2_0 extends StatelessWidget {
  final DateTime timestamp;
  final String empid;
  final String? checkInNotice;
  final String? checkInLocation;

  ResultPage2_0({
    required this.timestamp,
    required this.empid,
    this.checkInNotice,
    this.checkInLocation,
  });

  @override
  Widget build(BuildContext context) {
    String formattedDate =
        "${timestamp.toLocal().toString().split(' ')[0]} ${timestamp.toLocal().toString().split(' ')[1]}";

    return Scaffold(
      appBar: AppBar(title: const Text('Check-In Result')),
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
                      Icons.check_circle,
                      color: Colors.green,
                      size: 100.0,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Check-In Successful',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Timestamp: $formattedDate',
                      style: const TextStyle(fontSize: 18),
                    ),
                    Text(
                      'Employee ID: $empid',
                      style: const TextStyle(fontSize: 18),
                    ),
                    if (checkInNotice != null)
                      Text(
                        'Check-In Notice: $checkInNotice',
                        style:
                            const TextStyle(fontSize: 18, color: Colors.orange),
                      ),
                    if (checkInLocation != null)
                      Text(
                        'Location: $checkInLocation',
                        style:
                            const TextStyle(fontSize: 18, color: Colors.orange),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      child: const Text('Back to Scan Choosing Page'),
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
