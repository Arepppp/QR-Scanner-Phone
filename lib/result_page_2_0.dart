import 'package:flutter/material.dart';
import 'scan_choosing_page.dart'; // If scan_choosing_page.dart is directly under lib/

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
      appBar: AppBar(title: Text('Check-In Result')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 100.0,
            ),
            SizedBox(height: 20),
            Text(
              'Check-In Successful',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Timestamp: $formattedDate',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Employee ID: $empid',
              style: TextStyle(fontSize: 18),
            ),
            if (checkInNotice != null)
              Text(
                'Check-In Notice: $checkInNotice',
                style: TextStyle(fontSize: 18, color: Colors.orange),
              ),
            if (checkInLocation != null)
              Text(
                'Location: $checkInLocation',
                style: TextStyle(fontSize: 18, color: Colors.orange),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) {
                  // Check if the route is for scan_choosing_page
                  return route.settings.name == '/scan_choosing_page';
                });
              },
              child: Text('Back to Scan Choosing Page'),
            ),
          ],
        ),
      ),
    );
  }
}
